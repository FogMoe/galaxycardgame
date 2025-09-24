#ifndef NETWORK_MANAGER_H
#define NETWORK_MANAGER_H

#include "network_provider.h"
#include "default_network_provider.h"

#ifdef YGOPRO_ENABLE_STEAM_SUPPORT
#include "steam/steam_network_provider.h"
#include "steam/steam_lobby.h"
#endif

namespace ygo {

// 游戏网络管理器 - 统一管理所有网络提供者
class GameNetworkManager {
public:
    static GameNetworkManager& GetInstance();

    // 初始化和清理
    bool Initialize();
    void Shutdown();
    bool IsInitialized() const;

    // 网络提供者管理
    NetworkProvider* GetCurrentProvider() const;
    bool SetNetworkProvider(NetworkProviderType type);
    std::vector<NetworkProvider*> GetAvailableProviders() const;
    bool IsProviderAvailable(NetworkProviderType type) const;

    // 统一网络接口（委托给当前提供者）
    bool StartHosting(const HostInfo& host_info, const std::wstring& host_name,
                     const std::wstring& password = L"", uint16_t port = 0);
    void StopHosting();
    bool IsHosting() const;

    bool ConnectToHost(const std::string& host_address, uint16_t port,
                      const std::wstring& password = L"");
    bool ConnectToHost(uint32_t host_id, const std::wstring& password = L"");
    void Disconnect();
    NetworkConnectionState GetConnectionState() const;

    void RefreshHostList();
    std::vector<NetworkHostInfo> GetHostList() const;
    void ClearHostList();

    bool SendToServer(const void* data, size_t len);
    bool SendToClient(DuelPlayer* player, const void* data, size_t len);
    bool SendToAllClients(const void* data, size_t len);

    std::vector<DuelPlayer*> GetConnectedPlayers() const;
    void KickPlayer(DuelPlayer* player);

    // 事件处理
    void ProcessNetworkEvents();

    // 网络状态信息
    const char* GetCurrentProviderName() const;
    bool SupportsFriendInvite() const;
    bool InviteFriend(uint64_t friend_id);
    std::wstring GetLocalPlayerName() const;
    uint64_t GetLocalPlayerId() const;
    int GetPing() const;
    std::string GetConnectionQualityString() const;

    // 回调设置
    void SetOnClientConnected(std::function<void(DuelPlayer*)> callback);
    void SetOnClientDisconnected(std::function<void(DuelPlayer*)> callback);
    void SetOnDataReceived(std::function<void(DuelPlayer*, const void*, size_t)> callback);
    void SetOnHostListUpdated(std::function<void()> callback);
    void SetOnConnectionStateChanged(std::function<void(NetworkConnectionState)> callback);

#ifdef YGOPRO_ENABLE_STEAM_SUPPORT
    // Steam特有功能
    SteamLobbyManager& GetSteamLobbyManager();
    bool IsSteamSupported() const;
#endif

private:
    GameNetworkManager() = default;
    ~GameNetworkManager();

    // 禁用拷贝
    GameNetworkManager(const GameNetworkManager&) = delete;
    GameNetworkManager& operator=(const GameNetworkManager&) = delete;

    // 初始化各种网络提供者
    void InitializeProviders();
    void ShutdownProviders();

    // 成员变量
    bool initialized = false;
    NetworkProviderManager& provider_manager;

    // 网络提供者实例
    std::unique_ptr<DefaultNetworkProvider> default_provider;

#ifdef YGOPRO_ENABLE_STEAM_SUPPORT
    std::unique_ptr<SteamNetworkProvider> steam_provider;
#endif

    // 用户偏好
    NetworkProviderType preferred_provider_type = NetworkProviderType::DEFAULT_NETWORK;
};

}

#endif // NETWORK_MANAGER_H