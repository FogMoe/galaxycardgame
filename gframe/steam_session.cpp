#include "steam_session.h"

#ifdef YGOPRO_USE_STEAM_SDK

#include "game.h"
#include "duelclient.h"
#include "netserver.h"
#include "network.h"
#include "deck_manager.h"
#include "data_manager.h"
#include <steam/steam_api.h>
#include <steam/isteammatchmaking.h>
#include <steam/isteamfriends.h>
#include <steam/isteamnetworkingsockets.h>
#include <steam/isteamnetworkingutils.h>
#include <algorithm>
#include <mutex>
#include <cstdlib>
#include <cstring>
#include <unordered_map>
#include <unordered_set>
#include <memory>
#include <thread>
#include <atomic>
#include <chrono>
#include <errno.h>
#ifdef _WIN32
#include <winsock2.h>
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#endif
#include <event2/util.h>

namespace ygo {
namespace steam {

void UpdateConnectString(const std::wstring& descriptor);

namespace {

struct LobbyEntry {
	CSteamID lobby_id;
	std::wstring display;
	std::wstring join_descriptor;
	std::wstring pass;
};

bool steam_initialized = false;
bool lobby_pending_create = false;
bool lobby_active = false;
CSteamID active_lobby;
HostInfo hosting_info{};
std::wstring hosting_name;
std::wstring hosting_pass;

LobbyListCallback pending_lobby_callback;
std::vector<LobbyEntry> cached_lobbies;

std::mutex callback_mutex;

HSteamListenSocket listen_socket = k_HSteamListenSocket_Invalid;
HSteamNetPollGroup poll_group = k_HSteamNetPollGroup_Invalid;

#ifdef _WIN32
inline int GetSocketErrorCode() { return WSAGetLastError(); }
inline bool IsRetryableSocketError(int err) {
    return err == WSAEWOULDBLOCK || err == WSAEINTR || err == WSAEINPROGRESS || err == WSAEALREADY;
}
const evutil_socket_t kInvalidSocket = INVALID_SOCKET;
#else
inline int GetSocketErrorCode() { return errno; }
inline bool IsRetryableSocketError(int err) {
    return err == EINTR || err == EAGAIN || err == EWOULDBLOCK;
}
const evutil_socket_t kInvalidSocket = -1;
#endif

struct SteamBridge {
	HSteamNetConnection connection = k_HSteamNetConnection_Invalid;
	bool server_side = false;
	evutil_socket_t pipe_fd = kInvalidSocket;
	bufferevent* bev = nullptr;
	std::thread worker;
	std::atomic<bool> running{false};
};

std::unordered_map<HSteamNetConnection, std::shared_ptr<SteamBridge>> bridge_by_connection;
std::unordered_map<bufferevent*, std::weak_ptr<SteamBridge>> bridge_by_bufferevent;
std::unordered_set<HSteamNetConnection> pending_client_connections;
std::mutex bridges_mutex;
HSteamNetConnection active_client_connection = k_HSteamNetConnection_Invalid;
std::wstring pending_join_descriptor;

std::wstring Utf8ToWide(const std::string& input) {
	if(input.empty())
		return {};
	std::vector<wchar_t> buffer(input.size() + 1);
	BufferIO::DecodeUTF8String(input.c_str(), buffer.data(), buffer.size());
	return std::wstring(buffer.data());
}

std::string WideToUtf8(const std::wstring& input) {
	if(input.empty())
		return {};
	std::vector<char> buffer((input.size() + 1) * 4);
	BufferIO::EncodeUTF8String(input.c_str(), buffer.data(), buffer.size());
	return std::string(buffer.data());
}

bool CreateSocketPair(evutil_socket_t fds[2]) {
#ifdef _WIN32
	return evutil_socketpair(AF_INET, SOCK_STREAM, 0, fds) == 0;
#elif defined(AF_UNIX)
	if(evutil_socketpair(AF_UNIX, SOCK_STREAM, 0, fds) == 0)
		return true;
	return evutil_socketpair(AF_INET, SOCK_STREAM, 0, fds) == 0;
#else
	return evutil_socketpair(AF_INET, SOCK_STREAM, 0, fds) == 0;
#endif
}

void CleanupBridge(const std::shared_ptr<SteamBridge>& bridge, bool closeSteam = true);
void CleanupBridge(HSteamNetConnection conn, bool closeSteam = true);
std::shared_ptr<SteamBridge> CreateServerBridge(HSteamNetConnection conn);
std::shared_ptr<SteamBridge> CreateClientBridge(HSteamNetConnection conn);
void RunBridge(std::shared_ptr<SteamBridge> bridge);
void RemoveLobbyFromUI(const std::wstring& descriptor);

void RestoreJoinControls() {
	if(!mainGame)
		return;
	mainGame->gMutex.lock();
	mainGame->btnCreateHost->setEnabled(true);
	mainGame->btnJoinHost->setEnabled(true);
	mainGame->btnJoinCancel->setEnabled(true);
	mainGame->gMutex.unlock();
}

void NotifyJoinFailure() {
	if(!mainGame)
		return;
	mainGame->gMutex.lock();
	mainGame->env->addMessageBox(L"", dataManager.GetSysString(1400));
	mainGame->gMutex.unlock();
}

void RemoveLobbyFromUI(const std::wstring& descriptor) {
	if(!mainGame || descriptor.empty())
		return;
	mainGame->gMutex.lock();
	auto& hosts = DuelClient::hosts;
	auto& passwords = DuelClient::host_passwords;
	for(size_t i = 0; i < hosts.size(); ++i) {
		if(hosts[i] != descriptor)
			continue;
		hosts.erase(hosts.begin() + static_cast<std::ptrdiff_t>(i));
		if(i < passwords.size())
			passwords.erase(passwords.begin() + static_cast<std::ptrdiff_t>(i));
		if(!DuelClient::is_srvpro) {
			irr::s32 idx = static_cast<irr::s32>(i);
			if(mainGame->lstHostList->getItemCount() > idx)
				mainGame->lstHostList->removeItem(idx);
		}
		break;
	}
	mainGame->gMutex.unlock();
}

bool SocketSendAll(evutil_socket_t fd, const char* data, size_t len) {
	size_t sent_total = 0;
	while(sent_total < len) {
		int sent = send(fd, data + sent_total, static_cast<int>(len - sent_total), 0);
		if(sent > 0) {
			sent_total += static_cast<size_t>(sent);
			continue;
		}
		if(sent == 0)
			return false;
		int err = GetSocketErrorCode();
		if(IsRetryableSocketError(err)) {
			fd_set wfds;
			FD_ZERO(&wfds);
			FD_SET(fd, &wfds);
			timeval tv{0, 20000};
			int r = select(static_cast<int>(fd) + 1, nullptr, &wfds, nullptr, &tv);
			if(r <= 0)
				return false;
			continue;
		}
		return false;
	}
	return true;
}

int SocketReceive(evutil_socket_t fd, char* buffer, size_t capacity) {
	int received = recv(fd, buffer, static_cast<int>(capacity), 0);
	if(received >= 0)
		return received;
	int err = GetSocketErrorCode();
	if(IsRetryableSocketError(err))
		return 0;
	return -1;
}

void RunBridge(std::shared_ptr<SteamBridge> bridge) {
	if(!bridge)
		return;
	ISteamNetworkingSockets* sockets = SteamNetworkingSockets();
	if(!sockets)
		return;
	std::vector<char> buffer(SIZE_NETWORK_BUFFER);
	evutil_socket_t pipe_fd = bridge->pipe_fd;
	bridge->running = true;
	while(bridge->running) {
		ISteamNetworkingMessage* msgs[8];
		int recv_count = sockets->ReceiveMessagesOnConnection(bridge->connection, msgs, 8);
		for(int i = 0; i < recv_count; ++i) {
			ISteamNetworkingMessage* msg = msgs[i];
			const char* data = static_cast<const char*>(msg->GetData());
			int length = msg->GetSize();
			if(!SocketSendAll(pipe_fd, data, static_cast<size_t>(length))) {
				bridge->running = false;
			}
			msg->Release();
		}
		if(!bridge->running)
			break;
		fd_set readfds;
		FD_ZERO(&readfds);
		FD_SET(pipe_fd, &readfds);
		timeval tv{0, 20000};
		int sel = select(static_cast<int>(pipe_fd) + 1, &readfds, nullptr, nullptr, &tv);
		if(sel > 0 && FD_ISSET(pipe_fd, &readfds)) {
			int len = SocketReceive(pipe_fd, buffer.data(), buffer.size());
			if(len > 0) {
				sockets->SendMessageToConnection(bridge->connection, buffer.data(), len, k_nSteamNetworkingSend_Reliable, nullptr);
			} else if(len < 0) {
				bridge->running = false;
			} else if(len == 0) {
				std::this_thread::sleep_for(std::chrono::milliseconds(1));
			}
		} else if(sel < 0) {
			int err = GetSocketErrorCode();
			if(!IsRetryableSocketError(err))
				bridge->running = false;
		}
	}
}

void CleanupBridge(const std::shared_ptr<SteamBridge>& bridge, bool closeSteam) {
	if(!bridge)
		return;
	if(bridge->running.exchange(false)) {
		// will exit loop
	}
	if(bridge->pipe_fd != kInvalidSocket) {
		evutil_closesocket(bridge->pipe_fd);
		bridge->pipe_fd = kInvalidSocket;
	}
	if(bridge->worker.joinable())
		bridge->worker.join();
	if(closeSteam && bridge->connection != k_HSteamNetConnection_Invalid) {
		if(ISteamNetworkingSockets* sockets = SteamNetworkingSockets())
			sockets->CloseConnection(bridge->connection, 0, nullptr, false);
	}
	bridge->connection = k_HSteamNetConnection_Invalid;
	bridge->bev = nullptr;
}

void CleanupBridge(HSteamNetConnection conn, bool closeSteam) {
	std::shared_ptr<SteamBridge> bridge;
	{
		std::lock_guard<std::mutex> lock(bridges_mutex);
		pending_client_connections.erase(conn);
		auto it = bridge_by_connection.find(conn);
		if(it != bridge_by_connection.end()) {
			bridge = it->second;
			if(bridge && bridge->bev)
				bridge_by_bufferevent.erase(bridge->bev);
			bridge_by_connection.erase(it);
		}
	}
	if(!bridge)
		return;
	CleanupBridge(bridge, closeSteam);
	if(!bridge->server_side) {
		DuelClient::OnSteamTransportClosed();
		active_client_connection = k_HSteamNetConnection_Invalid;
	}
}

std::shared_ptr<SteamBridge> CreateServerBridge(HSteamNetConnection conn) {
	evutil_socket_t fds[2];
	if(!CreateSocketPair(fds))
		return nullptr;
	evutil_make_socket_nonblocking(fds[0]);
	evutil_make_socket_nonblocking(fds[1]);
	bufferevent* bev = NetServer::AttachSteamConnection(fds[0]);
	if(!bev) {
		evutil_closesocket(fds[0]);
		evutil_closesocket(fds[1]);
		return nullptr;
	}
	auto bridge = std::make_shared<SteamBridge>();
	bridge->connection = conn;
	bridge->server_side = true;
	bridge->pipe_fd = fds[1];
	bridge->bev = bev;
	{
		std::lock_guard<std::mutex> lock(bridges_mutex);
		bridge_by_connection[conn] = bridge;
		bridge_by_bufferevent[bev] = bridge;
	}
	bridge->worker = std::thread(RunBridge, bridge);
	return bridge;
}

std::shared_ptr<SteamBridge> CreateClientBridge(HSteamNetConnection conn) {
	evutil_socket_t fds[2];
	if(!CreateSocketPair(fds))
		return nullptr;
	evutil_make_socket_nonblocking(fds[0]);
	evutil_make_socket_nonblocking(fds[1]);
	if(!DuelClient::StartSteamClient(fds[0])) {
		evutil_closesocket(fds[0]);
		evutil_closesocket(fds[1]);
		return nullptr;
	}
	auto bridge = std::make_shared<SteamBridge>();
	bridge->connection = conn;
	bridge->server_side = false;
	bridge->pipe_fd = fds[1];
	{
		std::lock_guard<std::mutex> lock(bridges_mutex);
		bridge_by_connection[conn] = bridge;
		active_client_connection = conn;
	}
	bridge->worker = std::thread(RunBridge, bridge);
	return bridge;
}

void HandleServerConnectionClosed(bufferevent* bev) {
	if(!bev)
		return;
	std::shared_ptr<SteamBridge> bridge;
	{
		std::lock_guard<std::mutex> lock(bridges_mutex);
		auto it = bridge_by_bufferevent.find(bev);
		if(it != bridge_by_bufferevent.end()) {
			bridge = it->second.lock();
			bridge_by_bufferevent.erase(it);
			if(bridge)
				bridge_by_connection.erase(bridge->connection);
		}
	}
	if(bridge)
		CleanupBridge(bridge);
}

class SteamSessionCallbacks {
public:
	SteamSessionCallbacks() :
		lobbyEnter(this, &SteamSessionCallbacks::OnLobbyEntered),
		lobbyJoinRequested(this, &SteamSessionCallbacks::OnLobbyJoinRequested),
		connectionStatusChanged(this, &SteamSessionCallbacks::OnConnectionStatusChanged)
	{
	}

	CCallResult<SteamSessionCallbacks, LobbyMatchList_t> lobbyMatchListResult;
	CCallResult<SteamSessionCallbacks, LobbyCreated_t> lobbyCreatedResult;
	CCallback<SteamSessionCallbacks, LobbyEnter_t> lobbyEnter;
	CCallback<SteamSessionCallbacks, GameLobbyJoinRequested_t> lobbyJoinRequested;
	CCallback<SteamSessionCallbacks, SteamNetConnectionStatusChangedCallback_t> connectionStatusChanged;

	void OnLobbyCreated(LobbyCreated_t* pCallback, bool bIOFailure) {
		std::lock_guard<std::mutex> lock(callback_mutex);
		lobby_pending_create = false;
		if(bIOFailure || pCallback->m_eResult != k_EResultOK) {
			lobby_active = false;
			active_lobby.Clear();
			return;
		}
		active_lobby = pCallback->m_ulSteamIDLobby;
		lobby_active = true;

		ISteamMatchmaking* matchmaking = SteamMatchmaking();
		if(!matchmaking)
			return;

		std::string name_utf8 = WideToUtf8(hosting_name);
		if(!name_utf8.empty())
			matchmaking->SetLobbyData(active_lobby, "name", name_utf8.c_str());
		matchmaking->SetLobbyData(active_lobby, "version", std::to_string(PRO_VERSION).c_str());
		matchmaking->SetLobbyData(active_lobby, "mode", std::to_string(hosting_info.mode).c_str());
		matchmaking->SetLobbyData(active_lobby, "rule", std::to_string(hosting_info.rule).c_str());
		matchmaking->SetLobbyData(active_lobby, "duel_rule", std::to_string(hosting_info.duel_rule).c_str());
		matchmaking->SetLobbyData(active_lobby, "status", "waiting");
		matchmaking->SetLobbyData(active_lobby, "lflist", std::to_string(hosting_info.lflist).c_str());
		matchmaking->SetLobbyData(active_lobby, "start_lp", std::to_string(hosting_info.start_lp).c_str());
		matchmaking->SetLobbyData(active_lobby, "start_hand", std::to_string(hosting_info.start_hand).c_str());
		matchmaking->SetLobbyData(active_lobby, "draw_count", std::to_string(hosting_info.draw_count).c_str());
		matchmaking->SetLobbyData(active_lobby, "time_limit", std::to_string(hosting_info.time_limit).c_str());
		matchmaking->SetLobbyData(active_lobby, "has_pass", hosting_pass.empty() ? "0" : "1");
		matchmaking->SetLobbyJoinable(active_lobby, true);
		uint16_t listen_port = mainGame ? static_cast<uint16_t>(mainGame->gameConf.serverport) : 0;
		matchmaking->SetLobbyGameServer(active_lobby, 0, listen_port, SteamUser()->GetSteamID());
			if(ISteamUser* steam_user = SteamUser())
				steam_user->AdvertiseGame(steam_user->GetSteamID(), 0, listen_port);
		std::wstring descriptor = L"steam:lobby:";
		descriptor += Utf8ToWide(std::to_string(active_lobby.ConvertToUint64()));
		UpdateConnectString(descriptor);
	}

	void OnLobbyEntered(LobbyEnter_t* pCallback) {
		if(pCallback->m_EChatRoomEnterResponse != k_EChatRoomEnterResponseSuccess)
			return;
		ISteamMatchmaking* matchmaking = SteamMatchmaking();
		ISteamUser* user = SteamUser();
		if(!matchmaking || !user)
			return;
		CSteamID lobby(pCallback->m_ulSteamIDLobby);
		CSteamID owner = matchmaking->GetLobbyOwner(lobby);
		if(!owner.IsValid())
			return;
		CSteamID self = user->GetSteamID();
			if(owner == self)
				return;
			SteamNetworkingIdentity identity{};
			identity.SetSteamID(owner);
			if(ISteamNetworkingSockets* sockets = SteamNetworkingSockets()) {
				HSteamNetConnection conn = sockets->ConnectP2P(identity, 0, 0, nullptr);
				if(conn != k_HSteamNetConnection_Invalid) {
					std::lock_guard<std::mutex> lock(bridges_mutex);
					pending_client_connections.insert(conn);
				} else {
					RestoreJoinControls();
					NotifyJoinFailure();
				}
			}
		}

	void OnLobbyJoinRequested(GameLobbyJoinRequested_t* pCallback) {
		if(!pCallback)
			return;
		CSteamID lobby = pCallback->m_steamIDLobby;
		if(!lobby.IsValid())
			return;
		pending_join_descriptor = L"steam:lobby:";
		pending_join_descriptor += Utf8ToWide(std::to_string(lobby.ConvertToUint64()));
		SteamMatchmaking()->JoinLobby(lobby);
	}

	void OnConnectionStatusChanged(SteamNetConnectionStatusChangedCallback_t* pCallback) {
		if(!pCallback)
			return;
		HSteamNetConnection conn = pCallback->m_hConn;
		switch(pCallback->m_info.m_eState) {
		case k_ESteamNetworkingConnectionState_Connecting: {
			if(pCallback->m_info.m_hListenSocket == listen_socket) {
				if(ISteamNetworkingSockets* sockets = SteamNetworkingSockets()) {
					EResult res = sockets->AcceptConnection(conn);
					if(res != k_EResultOK && res != k_EResultDuplicateRequest && res != k_EResultPending) {
						sockets->CloseConnection(conn, 0, nullptr, false);
						break;
					}
					if(poll_group != k_HSteamNetPollGroup_Invalid)
						sockets->SetConnectionPollGroup(conn, poll_group);
				}
				if(!CreateServerBridge(conn)) {
					if(ISteamNetworkingSockets* sockets = SteamNetworkingSockets())
						sockets->CloseConnection(conn, 0, nullptr, false);
				}
			}
			break;
		}
		case k_ESteamNetworkingConnectionState_Connected: {
			bool created = false;
				{
					std::lock_guard<std::mutex> lock(bridges_mutex);
					if(pending_client_connections.erase(conn) > 0)
						created = true;
				}
				if(created) {
					if(!CreateClientBridge(conn)) {
						if(ISteamNetworkingSockets* sockets = SteamNetworkingSockets())
							sockets->CloseConnection(conn, 0, nullptr, false);
						RestoreJoinControls();
						NotifyJoinFailure();
					} else {
						pending_join_descriptor.clear();
					}
				}
				break;
			}
			case k_ESteamNetworkingConnectionState_ClosedByPeer:
		case k_ESteamNetworkingConnectionState_ProblemDetectedLocally:
		case k_ESteamNetworkingConnectionState_None:
		case k_ESteamNetworkingConnectionState_FinWait:
		case k_ESteamNetworkingConnectionState_Linger:
		case k_ESteamNetworkingConnectionState_Dead: {
			bool had_pending = false;
			{
				std::lock_guard<std::mutex> lock(bridges_mutex);
				if(pending_client_connections.erase(conn) > 0)
					had_pending = true;
			}
				CleanupBridge(conn, false);
				if(had_pending) {
					RestoreJoinControls();
					NotifyJoinFailure();
				}
				break;
			}
		default:
			break;
		}
	}

	void OnLobbyMatchList(LobbyMatchList_t* pCallback, bool bIOFailure) {
		LobbyListCallback callbackCopy;
		std::vector<LobbyEntry> entries;
		{
			std::lock_guard<std::mutex> lock(callback_mutex);
			if(!pending_lobby_callback)
				return;
			if(bIOFailure) {
				callbackCopy = std::move(pending_lobby_callback);
				pending_lobby_callback = nullptr;
			} else {
				for(int i = 0; i < pCallback->m_nLobbiesMatching; ++i) {
				CSteamID lobbyID = SteamMatchmaking()->GetLobbyByIndex(i);
				if(!lobbyID.IsValid())
					continue;
				const char* ver = SteamMatchmaking()->GetLobbyData(lobbyID, "version");
				if(!ver || std::atoi(ver) != PRO_VERSION)
					continue;
				LobbyEntry entry{};
				entry.lobby_id = lobbyID;
				const char* name = SteamMatchmaking()->GetLobbyData(lobbyID, "name");
				entry.display = name ? Utf8ToWide(name) : L"Steam Lobby";
				const char* lflist = SteamMatchmaking()->GetLobbyData(lobbyID, "lflist");
				uint32_t lflist_hash = lflist ? static_cast<uint32_t>(std::strtoul(lflist, nullptr, 10)) : 0;
				const wchar_t* lflist_name = deckManager.GetLFListName(lflist_hash);
				if(!lflist_name)
					lflist_name = L"";
				const char* rule_str = SteamMatchmaking()->GetLobbyData(lobbyID, "rule");
				int rule_index = rule_str ? std::strtol(rule_str, nullptr, 10) : 0;
				const char* mode_str = SteamMatchmaking()->GetLobbyData(lobbyID, "mode");
				int mode_index = mode_str ? std::strtol(mode_str, nullptr, 10) : MODE_SINGLE;
				std::wstring formatted;
				formatted.append(L"[Steam][");
				formatted.append(lflist_name);
				formatted.append(L"][");
				formatted.append(dataManager.GetSysString(rule_index + 1481));
				formatted.append(L"][");
				int mode_string = (mode_index == MODE_SINGLE) ? 1244 : (mode_index == MODE_TAG) ? 1246 : 1244;
				formatted.append(dataManager.GetSysString(mode_string));
				formatted.append(L"] ");
				formatted.append(entry.display);
				entry.display = std::move(formatted);
				entry.join_descriptor = L"steam:lobby:";
				entry.join_descriptor += Utf8ToWide(std::to_string(lobbyID.ConvertToUint64()));
				const char* has_pass = SteamMatchmaking()->GetLobbyData(lobbyID, "has_pass");
				if(has_pass && std::strcmp(has_pass, "1") == 0)
					entry.pass = L"*";
					entries.push_back(std::move(entry));
				}
				cached_lobbies = entries;
				callbackCopy = std::move(pending_lobby_callback);
				pending_lobby_callback = nullptr;
			}
		}
		if(callbackCopy) {
			std::vector<std::wstring> display;
			std::vector<std::wstring> join;
			std::vector<std::wstring> pass;
			display.reserve(entries.size());
			join.reserve(entries.size());
			pass.reserve(entries.size());
			for(const auto& entry : entries) {
				display.emplace_back(entry.display);
				join.emplace_back(entry.join_descriptor);
				pass.emplace_back(entry.pass);
			}
			callbackCopy(display, join, pass);
		}
	}
};

SteamSessionCallbacks* callbacks = nullptr;

void EnsureCallbacks() {
	if(!callbacks)
		callbacks = new SteamSessionCallbacks();
}

} // namespace

bool IsAvailable() {
	return mainGame && mainGame->steam_sdk_available;
}

void Initialize() {
	if(steam_initialized)
		return;
	if(!mainGame || !mainGame->steam_sdk_available)
		return;
	EnsureCallbacks();
	if(ISteamNetworkingUtils* utils = SteamNetworkingUtils())
		utils->InitRelayNetworkAccess();
	steam_initialized = true;
}

void Shutdown() {
	if(!steam_initialized)
		return;
	OnGameClosed();
	delete callbacks;
	callbacks = nullptr;
	steam_initialized = false;
}

void Tick() {
	// reserved for future networking polling
}

void OnGameCreated(const HostInfo& info, const wchar_t* name, const wchar_t* pass) {
	if(!IsAvailable())
		return;
	Initialize();
	hosting_info = info;
	hosting_name = name ? name : L"";
	hosting_pass = pass ? pass : L"";
	if(lobby_active) {
		SteamMatchmaking()->LeaveLobby(active_lobby);
		lobby_active = false;
		active_lobby.Clear();
	}
	EnsureCallbacks();
	SteamAPICall_t call = SteamMatchmaking()->CreateLobby(k_ELobbyTypePublic, 4);
	callbacks->lobbyCreatedResult.Set(call, callbacks, &SteamSessionCallbacks::OnLobbyCreated);
	lobby_pending_create = true;
	if(ISteamNetworkingSockets* sockets = SteamNetworkingSockets()) {
		if(listen_socket == k_HSteamListenSocket_Invalid)
			listen_socket = sockets->CreateListenSocketP2P(0, 0, nullptr);
		if(poll_group == k_HSteamNetPollGroup_Invalid)
			poll_group = sockets->CreatePollGroup();
	}
}

void OnGameClosed() {
	if(!IsAvailable())
		return;
	CSteamID previous_lobby = active_lobby;
	if(lobby_active) {
		SteamMatchmaking()->LeaveLobby(active_lobby);
		lobby_active = false;
		active_lobby.Clear();
	}
	if(previous_lobby.IsValid()) {
		std::wstring descriptor = L"steam:lobby:";
		descriptor += Utf8ToWide(std::to_string(previous_lobby.ConvertToUint64()));
		{
			std::lock_guard<std::mutex> lock(callback_mutex);
			cached_lobbies.erase(std::remove_if(cached_lobbies.begin(), cached_lobbies.end(),
				[&](const LobbyEntry& entry) { return entry.lobby_id == previous_lobby; }),
				cached_lobbies.end());
		}
		RemoveLobbyFromUI(descriptor);
	}
	std::vector<HSteamNetConnection> connections;
	{
		std::lock_guard<std::mutex> lock(bridges_mutex);
		for(const auto& entry : bridge_by_connection)
			connections.push_back(entry.first);
	}
	for(auto conn : connections)
		CleanupBridge(conn);
	if(ISteamUser* steam_user = SteamUser())
		steam_user->AdvertiseGame(k_steamIDNil, 0, 0);
	if(ISteamNetworkingSockets* sockets = SteamNetworkingSockets()) {
		if(listen_socket != k_HSteamListenSocket_Invalid) {
			sockets->CloseListenSocket(listen_socket);
			listen_socket = k_HSteamListenSocket_Invalid;
		}
		if(poll_group != k_HSteamNetPollGroup_Invalid) {
			sockets->DestroyPollGroup(poll_group);
			poll_group = k_HSteamNetPollGroup_Invalid;
		}
	}
	if(ISteamFriends* friends = SteamFriends())
		friends->ClearRichPresence();
}

void RequestLobbyList(LobbyListCallback callback) {
	if(!IsAvailable()) {
		if(callback)
			callback({}, {}, {});
		return;
	}
	Initialize();
	EnsureCallbacks();
	{
		std::lock_guard<std::mutex> lock(callback_mutex);
		pending_lobby_callback = std::move(callback);
	}
	SteamMatchmaking()->AddRequestLobbyListStringFilter("version", std::to_string(PRO_VERSION).c_str(), k_ELobbyComparisonEqual);
	SteamAPICall_t call = SteamMatchmaking()->RequestLobbyList();
	callbacks->lobbyMatchListResult.Set(call, callbacks, &SteamSessionCallbacks::OnLobbyMatchList);
}

bool JoinByDescriptor(const std::wstring& descriptor) {
	if(!IsAvailable())
		return false;
	Initialize();
	pending_join_descriptor = descriptor;
	const std::wstring prefix = L"steam:lobby:";
	if(descriptor.compare(0, prefix.size(), prefix) != 0)
		return false;
	std::wstring idPart = descriptor.substr(prefix.size());
	if(idPart.empty())
		return false;
	uint64_t lobbyID = 0;
	for(wchar_t ch : idPart) {
		if(ch < L'0' || ch > L'9')
			return false;
		lobbyID = lobbyID * 10 + static_cast<uint64_t>(ch - L'0');
	}
	if(!lobbyID)
		return false;
	CSteamID steamLobby(lobbyID);
	if(!steamLobby.IsValid())
		return false;
	SteamMatchmaking()->JoinLobby(steamLobby);
	UpdateConnectString(descriptor);
	return true;
}

bool HandleFriendJoin(const char* connectString) {
	if(!IsAvailable())
		return false;
	Initialize();
	if(!connectString)
		return false;
	std::string connect = connectString;
	const std::string prefix = "+connect_lobby ";
	auto pos = connect.find(prefix);
	if(pos == std::string::npos)
	{
		const std::string direct_prefix = "+connect ";
		if(connect.find(direct_prefix) == std::string::npos)
			return false;
		std::string host = connect.substr(direct_prefix.size());
		if(host.empty())
			return false;
		std::wstring whost = Utf8ToWide(host);
		UpdateConnectString(whost);
		pending_join_descriptor = whost;
		mainGame->gMutex.lock();
		mainGame->ebJoinHost->setText(whost.c_str());
		mainGame->gMutex.unlock();
		BufferIO::CopyWideString(mainGame->ebJoinHost->getText(), mainGame->gameConf.lasthost);
		BufferIO::CopyWideString(L"", mainGame->gameConf.roompass);
		char hostname_tag[100];
		BufferIO::EncodeUTF8(whost.c_str(), hostname_tag);
		HostResult remote = DuelClient::ParseHost(hostname_tag);
		if(!remote.isValid())
			return false;
		return DuelClient::StartClient(remote.host, remote.port, false);
	}
	pos += prefix.size();
	std::string id = connect.substr(pos);
	if(id.empty())
		return false;
	CSteamID lobby(std::strtoull(id.c_str(), nullptr, 10));
	if(!lobby.IsValid())
		return false;
	pending_join_descriptor = L"steam:lobby:";
	pending_join_descriptor += Utf8ToWide(std::to_string(lobby.ConvertToUint64()));
	SteamMatchmaking()->JoinLobby(lobby);
	return true;
}

void OnServerConnectionClosed(bufferevent* bev) {
	HandleServerConnectionClosed(bev);
}

void OnClientConnectionClosed() {
	HSteamNetConnection conn = active_client_connection;
	if(conn != k_HSteamNetConnection_Invalid)
		CleanupBridge(conn);
	UpdateConnectString(L"");
	pending_join_descriptor.clear();
}

void UpdateConnectString(const std::wstring& descriptor) {
	if(!IsAvailable())
		return;
	Initialize();
	if(ISteamFriends* friends = SteamFriends()) {
		if(descriptor.empty()) {
			friends->SetRichPresence("connect", "");
			friends->SetRichPresence("steam_player_group", "");
			friends->SetRichPresence("steam_player_group_size", "");
		} else {
			std::string utf8 = WideToUtf8(descriptor);
			std::string connect;
			if(utf8.rfind("steam:lobby:", 0) == 0) {
				std::string lobbyId = utf8.substr(std::string("steam:lobby:").size());
				connect = "+connect_lobby " + lobbyId;
				friends->SetRichPresence("steam_player_group", lobbyId.c_str());
				friends->SetRichPresence("steam_player_group_size", "1");
			} else {
				connect = "+connect " + utf8;
			}
			friends->SetRichPresence("connect", connect.c_str());
		}
	}
}

} // namespace steam
} // namespace ygo

#else // YGOPRO_USE_STEAM_SDK

namespace ygo {
namespace steam {

bool IsAvailable() { return false; }
void Initialize() {}
void Shutdown() {}
void Tick() {}
void OnGameCreated(const HostInfo&, const wchar_t*, const wchar_t*) {}
void OnGameClosed() {}
void RequestLobbyList(LobbyListCallback callback) {
	if(callback)
		callback({}, {}, {});
}
bool JoinByDescriptor(const std::wstring&) { return false; }
bool HandleFriendJoin(const char*) { return false; }
void OnServerConnectionClosed(bufferevent*) {}
void OnClientConnectionClosed() {}

}
}

#endif
