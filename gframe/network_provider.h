#ifndef NETWORK_PROVIDER_H
#define NETWORK_PROVIDER_H

#include <vector>
#include <string>
#include <functional>
#include <cstdint>
#include "config.h"
#include "network.h"

namespace ygo {

struct NetworkHostInfo {
    std::wstring host_name;
    std::wstring password;
    HostInfo info;
    uint32_t host_id;
    std::string ip_address;
    uint16_t port;
    int player_count;
    int max_players;
    bool password_protected;
};

enum class NetworkProviderType {
    DEFAULT_NETWORK,  // 原有的libevent网络
    STEAM_NETWORK     // Steam网络
};

enum class NetworkConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    FAILED,
    TIMEOUT
};

class NetworkProvider {
public:
    virtual ~NetworkProvider() = default;

    // 基础连接管理
    virtual bool Initialize() = 0;
    virtual void Shutdown() = 0;
    virtual bool IsAvailable() const = 0;
    virtual NetworkProviderType GetType() const = 0;
    virtual const char* GetTypeName() const = 0;

    // 服务器功能
    virtual bool StartHosting(const HostInfo& host_info, const std::wstring& host_name,
                             const std::wstring& password, uint16_t port = 0) = 0;
    virtual void StopHosting() = 0;
    virtual bool IsHosting() const = 0;

    // 客户端功能
    virtual bool ConnectToHost(const std::string& host_address, uint16_t port,
                              const std::wstring& password = L"") = 0;
    virtual bool ConnectToHost(uint32_t host_id, const std::wstring& password = L"") = 0;
    virtual void Disconnect() = 0;
    virtual NetworkConnectionState GetConnectionState() const = 0;

    // 房间列表和发现
    virtual void RefreshHostList() = 0;
    virtual std::vector<NetworkHostInfo> GetHostList() const = 0;
    virtual void ClearHostList() = 0;

    // 数据传输 - 兼容现有协议
    virtual bool SendToServer(const void* data, size_t len) = 0;
    virtual bool SendToClient(DuelPlayer* player, const void* data, size_t len) = 0;
    virtual bool SendToAllClients(const void* data, size_t len) = 0;

    // 玩家管理
    virtual std::vector<DuelPlayer*> GetConnectedPlayers() const = 0;
    virtual void KickPlayer(DuelPlayer* player) = 0;

    // 事件回调设置
    virtual void SetOnClientConnected(std::function<void(DuelPlayer*)> callback) = 0;
    virtual void SetOnClientDisconnected(std::function<void(DuelPlayer*)> callback) = 0;
    virtual void SetOnDataReceived(std::function<void(DuelPlayer*, const void*, size_t)> callback) = 0;
    virtual void SetOnHostListUpdated(std::function<void()> callback) = 0;
    virtual void SetOnConnectionStateChanged(std::function<void(NetworkConnectionState)> callback) = 0;

    // 处理网络事件
    virtual void ProcessNetworkEvents() = 0;

    // 附加功能
    virtual bool SupportsFriendInvite() const { return false; }
    virtual bool InviteFriend(uint64_t friend_id) { return false; }
    virtual std::wstring GetLocalPlayerName() const { return L"Player"; }
    virtual uint64_t GetLocalPlayerId() const { return 0; }

    // 网络质量信息
    virtual int GetPing() const { return -1; }
    virtual float GetPacketLoss() const { return 0.0f; }
    virtual std::string GetConnectionQualityString() const { return "Unknown"; }

protected:
    // 事件回调函数
    std::function<void(DuelPlayer*)> on_client_connected;
    std::function<void(DuelPlayer*)> on_client_disconnected;
    std::function<void(DuelPlayer*, const void*, size_t)> on_data_received;
    std::function<void()> on_host_list_updated;
    std::function<void(NetworkConnectionState)> on_connection_state_changed;
};

// 网络提供者管理器
class NetworkProviderManager {
public:
    static NetworkProviderManager& GetInstance();

    // 提供者管理
    void RegisterProvider(NetworkProvider* provider);
    void UnregisterProvider(NetworkProvider* provider);
    std::vector<NetworkProvider*> GetAvailableProviders() const;

    // 当前提供者选择
    bool SetCurrentProvider(NetworkProviderType type);
    bool SetCurrentProvider(NetworkProvider* provider);
    NetworkProvider* GetCurrentProvider() const;
    NetworkProvider* GetProvider(NetworkProviderType type) const;

    // 自动选择最佳提供者
    NetworkProvider* GetBestAvailableProvider() const;

private:
    NetworkProviderManager() = default;
    std::vector<NetworkProvider*> providers;
    NetworkProvider* current_provider = nullptr;
};

}

#endif // NETWORK_PROVIDER_H