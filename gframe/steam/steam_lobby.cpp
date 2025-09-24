#include "steam_lobby.h"
#include <algorithm>
#include <sstream>
#include <chrono>
#include <codecvt>
#include <locale>

namespace ygo {

SteamLobbyManager::SteamLobbyManager()
    : steam_api(SteamAPILoader::GetInstance()) {
}

SteamLobbyManager::~SteamLobbyManager() {
    Shutdown();
}

SteamLobbyManager& SteamLobbyManager::GetInstance() {
    static SteamLobbyManager instance;
    return instance;
}

bool SteamLobbyManager::Initialize() {
    if (initialized.load()) {
        return true;
    }

    if (!steam_api.IsLoaded()) {
        return false;
    }

    initialized.store(true);
    return true;
}

void SteamLobbyManager::Shutdown() {
    if (!initialized.load()) {
        return;
    }

    if (in_lobby.load()) {
        LeaveLobby();
    }

    ClearLobbyList();
    initialized.store(false);
}

bool SteamLobbyManager::IsInitialized() const {
    return initialized.load();
}

bool SteamLobbyManager::CreateLobby(const HostInfo& game_info, const std::wstring& lobby_name,
                                   const std::wstring& password, ELobbyType type) {
    if (!initialized.load()) {
        return false;
    }

    if (in_lobby.load()) {
        LeaveLobby();
    }

    // 创建大厅
    int max_members = 4; // 根据游戏模式调整
    SteamAPICall_t call_handle = steam_api.CreateLobby(type, max_members);

    if (call_handle == 0) {
        return false;
    }

    // 添加待处理的回调
    {
        std::lock_guard<std::mutex> lock(pending_callbacks_mutex);
        PendingCallback pending;
        pending.call_handle = call_handle;
        pending.callback = [this, game_info, lobby_name, password]() {
            // 大厅创建成功后设置数据
            SetLobbyGameInfo(game_info);
            SetLobbyData(KEY_LOBBY_NAME, WStringToUTF8(lobby_name));
            SetLobbyData(KEY_PASSWORD_PROTECTED, password.empty() ? "0" : "1");
            SetLobbyData(KEY_GAME_VERSION, "1.0"); // 设置游戏版本

            if (callbacks.on_lobby_created) {
                callbacks.on_lobby_created(current_lobby_id, true);
            }
        };
        pending.timeout = std::chrono::steady_clock::now() +
                         std::chrono::seconds(CALLBACK_TIMEOUT_SECONDS);
        pending_callbacks.push_back(pending);
    }

    return true;
}

bool SteamLobbyManager::JoinLobby(CSteamID lobby_id, const std::wstring& password) {
    if (!initialized.load() || lobby_id == 0) {
        return false;
    }

    if (in_lobby.load()) {
        LeaveLobby();
    }

    // 检查密码保护
    // 这里简化实现，实际中应该通过Steam API检查大厅信息

    // 尝试加入大厅
    // 注意：实际的Steam API中，加入大厅的函数名可能不同
    // 这里使用伪代码表示
    // SteamAPICall_t call_handle = steam_api.JoinLobby(lobby_id);

    current_lobby_id = lobby_id;
    in_lobby.store(true);

    if (callbacks.on_lobby_joined) {
        callbacks.on_lobby_joined(lobby_id, true, "");
    }

    return true;
}

bool SteamLobbyManager::LeaveLobby() {
    if (!in_lobby.load()) {
        return false;
    }

    CSteamID old_lobby = current_lobby_id;

    // 离开大厅的Steam API调用
    // steam_api.LeaveLobby(current_lobby_id);

    current_lobby_id = 0;
    in_lobby.store(false);

    if (callbacks.on_lobby_left) {
        callbacks.on_lobby_left(old_lobby);
    }

    return true;
}

bool SteamLobbyManager::IsInLobby() const {
    return in_lobby.load();
}

CSteamID SteamLobbyManager::GetCurrentLobby() const {
    return current_lobby_id;
}

bool SteamLobbyManager::SetLobbyData(const std::string& key, const std::string& value) {
    if (!in_lobby.load()) {
        return false;
    }

    steam_api.SetLobbyData(current_lobby_id, key.c_str(), value.c_str());
    return true;
}

std::string SteamLobbyManager::GetLobbyData(const std::string& key) const {
    if (!in_lobby.load()) {
        return "";
    }

    // 这里需要Steam API来获取大厅数据
    // const char* data = steam_api.GetLobbyData(current_lobby_id, key.c_str());
    // return data ? std::string(data) : std::string();

    return ""; // 简化实现
}

bool SteamLobbyManager::SetLobbyGameInfo(const HostInfo& game_info) {
    if (!in_lobby.load()) {
        return false;
    }

    std::string encoded_info = EncodeHostInfo(game_info);
    return SetLobbyData(KEY_GAME_INFO, encoded_info);
}

bool SteamLobbyManager::GetLobbyGameInfo(HostInfo& game_info) const {
    if (!in_lobby.load()) {
        return false;
    }

    std::string encoded_info = GetLobbyData(KEY_GAME_INFO);
    if (encoded_info.empty()) {
        return false;
    }

    return DecodeHostInfo(encoded_info, game_info);
}

bool SteamLobbyManager::RequestLobbyList() {
    if (!initialized.load()) {
        return false;
    }

    // 设置搜索过滤器（如果需要）
    // steam_api.AddRequestLobbyListStringFilter("game_version", "1.0", k_ELobbyComparisonEqual);

    bool success = steam_api.RequestLobbyList();
    if (success) {
        // 添加回调处理
        // 实际实现中应该通过Steam回调系统处理
    }

    return success;
}

std::vector<SteamLobbyInfo> SteamLobbyManager::GetLobbyList() const {
    std::lock_guard<std::mutex> lock(lobby_list_mutex);
    return lobby_list;
}

void SteamLobbyManager::ClearLobbyList() {
    std::lock_guard<std::mutex> lock(lobby_list_mutex);
    lobby_list.clear();
}

std::vector<CSteamID> SteamLobbyManager::GetLobbyMembers() const {
    std::vector<CSteamID> members;

    if (!in_lobby.load()) {
        return members;
    }

    // 这里需要Steam API来获取大厅成员
    // int member_count = steam_api.GetNumLobbyMembers(current_lobby_id);
    // for (int i = 0; i < member_count; i++) {
    //     CSteamID member_id = steam_api.GetLobbyMemberByIndex(current_lobby_id, i);
    //     members.push_back(member_id);
    // }

    return members;
}

int SteamLobbyManager::GetLobbyMemberCount() const {
    if (!in_lobby.load()) {
        return 0;
    }

    // return steam_api.GetNumLobbyMembers(current_lobby_id);
    return 0; // 简化实现
}

int SteamLobbyManager::GetLobbyMemberLimit() const {
    if (!in_lobby.load()) {
        return 0;
    }

    // return steam_api.GetLobbyMemberLimit(current_lobby_id);
    return 4; // 简化实现
}

bool SteamLobbyManager::SetLobbyMemberLimit(int max_members) {
    if (!in_lobby.load()) {
        return false;
    }

    // return steam_api.SetLobbyMemberLimit(current_lobby_id, max_members);
    return true; // 简化实现
}

bool SteamLobbyManager::InviteFriend(CSteamID friend_id) {
    if (!in_lobby.load() || friend_id == 0) {
        return false;
    }

    // steam_api.InviteUserToLobby(current_lobby_id, friend_id);

    if (callbacks.on_friend_invited) {
        callbacks.on_friend_invited(friend_id, current_lobby_id);
    }

    return true;
}

std::vector<CSteamID> SteamLobbyManager::GetFriendsList() const {
    std::vector<CSteamID> friends;

    // 这里需要Steam好友API
    // int friend_count = steam_api.GetFriendCount(k_EFriendFlagImmediate);
    // for (int i = 0; i < friend_count; i++) {
    //     CSteamID friend_id = steam_api.GetFriendByIndex(i, k_EFriendFlagImmediate);
    //     friends.push_back(friend_id);
    // }

    return friends;
}

bool SteamLobbyManager::CanInviteFriend(CSteamID friend_id) const {
    if (!in_lobby.load() || friend_id == 0) {
        return false;
    }

    // 检查好友是否在线、是否已经在大厅等
    // 这里需要Steam API支持
    return true; // 简化实现
}

bool SteamLobbyManager::StartHostingFromLobby(const HostInfo& game_info, uint16_t port) {
    if (!in_lobby.load()) {
        return false;
    }

    // 获取本机IP（简化实现）
    std::string local_ip = "127.0.0.1"; // 实际应该获取真实IP
    if (port == 0) {
        port = 7911; // 默认端口
    }

    // 更新大厅数据
    SetLobbyData(KEY_HOST_IP, local_ip);
    SetLobbyData(KEY_HOST_PORT, std::to_string(port));
    SetLobbyGameInfo(game_info);

    return true;
}

bool SteamLobbyManager::ConnectToLobbyHost() {
    if (!in_lobby.load()) {
        return false;
    }

    std::string host_ip = GetLobbyData(KEY_HOST_IP);
    std::string port_str = GetLobbyData(KEY_HOST_PORT);

    if (host_ip.empty() || port_str.empty()) {
        return false;
    }

    uint16_t port = static_cast<uint16_t>(std::stoul(port_str));

    // 这里应该通知网络提供者连接到指定地址
    // 实际实现中需要与NetworkProvider集成

    return true;
}

std::string SteamLobbyManager::GetLobbyHostIP() const {
    return GetLobbyData(KEY_HOST_IP);
}

uint16_t SteamLobbyManager::GetLobbyHostPort() const {
    std::string port_str = GetLobbyData(KEY_HOST_PORT);
    return port_str.empty() ? 0 : static_cast<uint16_t>(std::stoul(port_str));
}

void SteamLobbyManager::SetCallbacks(const SteamLobbyCallbacks& new_callbacks) {
    std::lock_guard<std::mutex> lock(callbacks_mutex);
    callbacks = new_callbacks;
}

void SteamLobbyManager::ProcessCallbacks() {
    if (!initialized.load()) {
        return;
    }

    // 处理待处理的回调
    {
        std::lock_guard<std::mutex> lock(pending_callbacks_mutex);
        auto now = std::chrono::steady_clock::now();

        for (auto it = pending_callbacks.begin(); it != pending_callbacks.end();) {
            if (now > it->timeout) {
                // 回调超时
                it = pending_callbacks.erase(it);
            } else {
                // 检查回调是否完成（这里简化处理）
                // 实际中需要检查Steam API调用是否完成
                ++it;
            }
        }
    }

    // 处理Steam API回调
    steam_api.SteamAPI_RunCallbacks();
}

NetworkHostInfo SteamLobbyManager::ConvertToNetworkHostInfo(const SteamLobbyInfo& lobby_info) const {
    NetworkHostInfo network_info;

    network_info.host_name = lobby_info.lobby_name;
    network_info.info = lobby_info.game_info;
    network_info.host_id = static_cast<uint32_t>(lobby_info.lobby_id & 0xFFFFFFFF);
    network_info.ip_address = lobby_info.ip_address;
    network_info.port = lobby_info.port;
    network_info.player_count = lobby_info.current_players;
    network_info.max_players = lobby_info.max_players;
    network_info.password_protected = lobby_info.password_protected;

    return network_info;
}

std::vector<NetworkHostInfo> SteamLobbyManager::ConvertToNetworkHostList() const {
    std::lock_guard<std::mutex> lock(lobby_list_mutex);
    std::vector<NetworkHostInfo> network_list;

    for (const auto& lobby : lobby_list) {
        if (IsLobbyDataValid(lobby)) {
            network_list.push_back(ConvertToNetworkHostInfo(lobby));
        }
    }

    return network_list;
}

// 私有方法实现

bool SteamLobbyManager::IsLobbyDataValid(const SteamLobbyInfo& info) const {
    return info.lobby_id != 0 &&
           !info.lobby_name.empty() &&
           info.current_players >= 0 &&
           info.max_players > 0 &&
           info.current_players <= info.max_players;
}

void SteamLobbyManager::ParseLobbyData(CSteamID lobby_id, SteamLobbyInfo& info) {
    info.lobby_id = lobby_id;

    // 解析大厅元数据（简化实现）
    // 实际中需要通过Steam API获取大厅数据
    info.lobby_name = L"Steam Lobby";
    info.host_name = L"Steam Host";
    info.current_players = 1;
    info.max_players = 4;
    info.password_protected = false;
    info.joinable = true;
}

void SteamLobbyManager::UpdateLobbyList() {
    std::lock_guard<std::mutex> lock(lobby_list_mutex);
    lobby_list.clear();

    // 这里需要Steam API来获取搜索到的大厅列表
    // int lobby_count = steam_api.GetLobbyListSize();
    // for (int i = 0; i < lobby_count; i++) {
    //     CSteamID lobby_id = steam_api.GetLobbyByIndex(i);
    //     SteamLobbyInfo info;
    //     ParseLobbyData(lobby_id, info);
    //     lobby_list.push_back(info);
    // }
}

std::string SteamLobbyManager::EncodeHostInfo(const HostInfo& info) const {
    std::stringstream ss;
    ss << info.lflist << "," << static_cast<int>(info.rule) << ","
       << static_cast<int>(info.mode) << "," << static_cast<int>(info.duel_rule) << ","
       << static_cast<int>(info.no_check_deck) << "," << static_cast<int>(info.no_shuffle_deck) << ","
       << info.start_lp << "," << static_cast<int>(info.start_hand) << ","
       << static_cast<int>(info.draw_count) << "," << info.time_limit;
    return ss.str();
}

bool SteamLobbyManager::DecodeHostInfo(const std::string& data, HostInfo& info) const {
    std::stringstream ss(data);
    std::string item;
    std::vector<std::string> tokens;

    while (std::getline(ss, item, ',')) {
        tokens.push_back(item);
    }

    if (tokens.size() != 10) {
        return false;
    }

    try {
        info.lflist = std::stoul(tokens[0]);
        info.rule = static_cast<uint8_t>(std::stoul(tokens[1]));
        info.mode = static_cast<uint8_t>(std::stoul(tokens[2]));
        info.duel_rule = static_cast<uint8_t>(std::stoul(tokens[3]));
        info.no_check_deck = static_cast<uint8_t>(std::stoul(tokens[4]));
        info.no_shuffle_deck = static_cast<uint8_t>(std::stoul(tokens[5]));
        info.start_lp = std::stol(tokens[6]);
        info.start_hand = static_cast<uint8_t>(std::stoul(tokens[7]));
        info.draw_count = static_cast<uint8_t>(std::stoul(tokens[8]));
        info.time_limit = static_cast<uint16_t>(std::stoul(tokens[9]));
        return true;
    } catch (const std::exception&) {
        return false;
    }
}

std::wstring SteamLobbyManager::UTF8ToWString(const std::string& utf8) const {
    std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
    try {
        return converter.from_bytes(utf8);
    } catch (const std::exception&) {
        return L"";
    }
}

std::string SteamLobbyManager::WStringToUTF8(const std::wstring& wstr) const {
    std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
    try {
        return converter.to_bytes(wstr);
    } catch (const std::exception&) {
        return "";
    }
}

}