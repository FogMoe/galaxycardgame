#ifndef STEAM_SESSION_H
#define STEAM_SESSION_H

#include "config.h"
#include "network.h"
#include <string>
#include <vector>
#include <functional>

namespace ygo {
namespace steam {

using LobbyListCallback = std::function<void(const std::vector<std::wstring>& display,
                                            const std::vector<std::wstring>& join,
                                            const std::vector<std::wstring>& pass)>;

bool IsAvailable();
void Initialize();
void Shutdown();
void Tick();

void OnGameCreated(const HostInfo& info, const wchar_t* name, const wchar_t* pass);
void OnGameClosed();

void RequestLobbyList(LobbyListCallback callback);
bool JoinByDescriptor(const std::wstring& descriptor);
bool HandleFriendJoin(const char* connectString);
void OnServerConnectionClosed(bufferevent* bev);
void OnClientConnectionClosed();
void UpdateConnectString(const std::wstring& descriptor);

}
}

#endif // STEAM_SESSION_H
