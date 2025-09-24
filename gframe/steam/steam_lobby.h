#ifndef STEAM_LOBBY_H
#define STEAM_LOBBY_H

#include "steam_api_loader.h"
#include "../network_provider.h"
#include <vector>
#include <string>
#include <unordered_map>
#include <functional>
#include <mutex>
#include <atomic>

namespace ygo {

// Steam大厅信息
struct SteamLobbyInfo {
    CSteamID lobby_id = 0;
    std::wstring lobby_name;
    std::wstring host_name;
    std::string ip_address;
    uint16_t port = 0;
    int current_players = 0;
    int max_players = 4;
    bool password_protected = false;
    bool joinable = true;
    HostInfo game_info;

    // Steam特有信息
    CSteamID owner_id = 0;
    ELobbyType lobby_type = ELobbyType::Public;
    std::unordered_map<std::string, std::string> metadata;
};

// Steam大厅回调处理
class SteamLobbyCallbacks {
public:
    // 大厅创建完成回调
    std::function<void(CSteamID lobby_id, bool success)> on_lobby_created;

    // 大厅列表更新回调
    std::function<void(const std::vector<SteamLobbyInfo>&)> on_lobby_list_updated;

    // 加入大厅回调
    std::function<void(CSteamID lobby_id, bool success, const std::string& error)> on_lobby_joined;

    // 离开大厅回调
    std::function<void(CSteamID lobby_id)> on_lobby_left;

    // 大厅数据更新回调
    std::function<void(CSteamID lobby_id, CSteamID member_id)> on_lobby_data_updated;

    // 玩家加入大厅回调
    std::function<void(CSteamID lobby_id, CSteamID user_id)> on_player_entered_lobby;

    // 玩家离开大厅回调
    std::function<void(CSteamID lobby_id, CSteamID user_id)> on_player_left_lobby;

    // 好友邀请回调
    std::function<void(CSteamID friend_id, CSteamID lobby_id)> on_friend_invited;
};

// Steam大厅管理器
class SteamLobbyManager {
public:
    static SteamLobbyManager& GetInstance();

    // 初始化和清理
    bool Initialize();
    void Shutdown();
    bool IsInitialized() const;

    // 大厅创建和管理
    bool CreateLobby(const HostInfo& game_info, const std::wstring& lobby_name,
                    const std::wstring& password = L"", ELobbyType type = ELobbyType::Public);
    bool JoinLobby(CSteamID lobby_id, const std::wstring& password = L"");
    bool LeaveLobby();
    bool IsInLobby() const;
    CSteamID GetCurrentLobby() const;

    // 大厅信息管理
    bool SetLobbyData(const std::string& key, const std::string& value);
    std::string GetLobbyData(const std::string& key) const;
    bool SetLobbyGameInfo(const HostInfo& game_info);
    bool GetLobbyGameInfo(HostInfo& game_info) const;

    // 大厅搜索和列表
    bool RequestLobbyList();
    std::vector<SteamLobbyInfo> GetLobbyList() const;
    void ClearLobbyList();

    // 玩家管理
    std::vector<CSteamID> GetLobbyMembers() const;
    int GetLobbyMemberCount() const;
    int GetLobbyMemberLimit() const;
    bool SetLobbyMemberLimit(int max_members);

    // 好友和邀请
    bool InviteFriend(CSteamID friend_id);
    std::vector<CSteamID> GetFriendsList() const;
    bool CanInviteFriend(CSteamID friend_id) const;

    // 网络连接集成
    bool StartHostingFromLobby(const HostInfo& game_info, uint16_t port = 0);
    bool ConnectToLobbyHost();
    std::string GetLobbyHostIP() const;
    uint16_t GetLobbyHostPort() const;

    // 回调设置
    void SetCallbacks(const SteamLobbyCallbacks& callbacks);

    // 事件处理（需要定期调用）
    void ProcessCallbacks();

    // 转换函数
    NetworkHostInfo ConvertToNetworkHostInfo(const SteamLobbyInfo& lobby_info) const;
    std::vector<NetworkHostInfo> ConvertToNetworkHostList() const;

private:
    SteamLobbyManager();
    ~SteamLobbyManager();

    // 禁用拷贝和赋值
    SteamLobbyManager(const SteamLobbyManager&) = delete;
    SteamLobbyManager& operator=(const SteamLobbyManager&) = delete;

    // Steam回调处理（模拟回调系统）
    void OnLobbyCreated(SteamAPICall_t call_result, bool io_failure);
    void OnLobbyEntered(CSteamID lobby_id, bool success);
    void OnLobbyListReceived();
    void OnLobbyDataUpdated(CSteamID lobby_id, CSteamID member_id);

    // 内部辅助函数
    bool IsLobbyDataValid(const SteamLobbyInfo& info) const;
    void ParseLobbyData(CSteamID lobby_id, SteamLobbyInfo& info);
    void UpdateLobbyList();
    std::string EncodeHostInfo(const HostInfo& info) const;
    bool DecodeHostInfo(const std::string& data, HostInfo& info) const;
    std::wstring UTF8ToWString(const std::string& utf8) const;
    std::string WStringToUTF8(const std::wstring& wstr) const;

    // 成员变量
    SteamAPILoader& steam_api;
    std::atomic<bool> initialized{false};
    std::atomic<bool> in_lobby{false};
    CSteamID current_lobby_id = 0;

    // 大厅列表
    std::vector<SteamLobbyInfo> lobby_list;
    mutable std::mutex lobby_list_mutex;

    // 回调处理
    SteamLobbyCallbacks callbacks;
    std::mutex callbacks_mutex;

    // 待处理的Steam回调
    struct PendingCallback {
        SteamAPICall_t call_handle;
        std::function<void()> callback;
        std::chrono::steady_clock::time_point timeout;
    };
    std::vector<PendingCallback> pending_callbacks;
    std::mutex pending_callbacks_mutex;

    // 大厅元数据键
    static constexpr const char* KEY_GAME_INFO = "game_info";
    static constexpr const char* KEY_HOST_NAME = "host_name";
    static constexpr const char* KEY_LOBBY_NAME = "lobby_name";
    static constexpr const char* KEY_PASSWORD_PROTECTED = "password_protected";
    static constexpr const char* KEY_HOST_IP = "host_ip";
    static constexpr const char* KEY_HOST_PORT = "host_port";
    static constexpr const char* KEY_CURRENT_PLAYERS = "current_players";
    static constexpr const char* KEY_MAX_PLAYERS = "max_players";
    static constexpr const char* KEY_GAME_VERSION = "game_version";

    // 配置常量
    static constexpr int MAX_LOBBIES_TO_REQUEST = 50;
    static constexpr int CALLBACK_TIMEOUT_SECONDS = 30;
};

}

#endif // STEAM_LOBBY_H