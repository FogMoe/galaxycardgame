#ifndef DEFAULT_NETWORK_PROVIDER_H
#define DEFAULT_NETWORK_PROVIDER_H

#include "network_provider.h"
#include "netserver.h"
#include "duelclient.h"
#include <atomic>
#include <thread>
#include <mutex>

namespace ygo {

// 默认网络提供者 - 包装现有的libevent实现
class DefaultNetworkProvider : public NetworkProvider {
public:
    DefaultNetworkProvider();
    virtual ~DefaultNetworkProvider();

    // NetworkProvider interface implementation
    bool Initialize() override;
    void Shutdown() override;
    bool IsAvailable() const override;
    NetworkProviderType GetType() const override;
    const char* GetTypeName() const override;

    // 服务器功能
    bool StartHosting(const HostInfo& host_info, const std::wstring& host_name,
                     const std::wstring& password, uint16_t port = 0) override;
    void StopHosting() override;
    bool IsHosting() const override;

    // 客户端功能
    bool ConnectToHost(const std::string& host_address, uint16_t port,
                      const std::wstring& password = L"") override;
    bool ConnectToHost(uint32_t host_id, const std::wstring& password = L"") override;
    void Disconnect() override;
    NetworkConnectionState GetConnectionState() const override;

    // 房间列表和发现
    void RefreshHostList() override;
    std::vector<NetworkHostInfo> GetHostList() const override;
    void ClearHostList() override;

    // 数据传输
    bool SendToServer(const void* data, size_t len) override;
    bool SendToClient(DuelPlayer* player, const void* data, size_t len) override;
    bool SendToAllClients(const void* data, size_t len) override;

    // 玩家管理
    std::vector<DuelPlayer*> GetConnectedPlayers() const override;
    void KickPlayer(DuelPlayer* player) override;

    // 事件回调设置
    void SetOnClientConnected(std::function<void(DuelPlayer*)> callback) override;
    void SetOnClientDisconnected(std::function<void(DuelPlayer*)> callback) override;
    void SetOnDataReceived(std::function<void(DuelPlayer*, const void*, size_t)> callback) override;
    void SetOnHostListUpdated(std::function<void()> callback) override;
    void SetOnConnectionStateChanged(std::function<void(NetworkConnectionState)> callback) override;

    // 处理网络事件
    void ProcessNetworkEvents() override;

    // 网络质量信息
    int GetPing() const override;
    std::string GetConnectionQualityString() const override;

private:
    // 内部状态管理
    void UpdateConnectionState(NetworkConnectionState new_state);
    void ProcessBroadcastPackets();
    void ConvertHostPacketToInfo(const HostPacket& packet, NetworkHostInfo& info);
    NetworkConnectionState DuelClientStateToNetworkState() const;

    // 成员变量
    std::atomic<bool> initialized{false};
    std::atomic<bool> is_hosting{false};
    std::atomic<NetworkConnectionState> connection_state{NetworkConnectionState::DISCONNECTED};

    std::vector<NetworkHostInfo> host_list;
    mutable std::mutex host_list_mutex;

    std::thread* broadcast_thread = nullptr;
    std::atomic<bool> should_stop_broadcast{false};

    HostInfo current_host_info{};
    std::wstring current_host_name;
    std::wstring current_password;
    uint16_t hosting_port = 0;

    // 计时器和统计
    std::chrono::steady_clock::time_point last_ping_time;
    int current_ping = -1;

    // 静态回调适配器函数（用于与现有NetServer/DuelClient集成）
    static void OnDuelClientDataReceived(const void* data, size_t len);
    static void OnNetServerClientConnected(DuelPlayer* player);
    static void OnNetServerClientDisconnected(DuelPlayer* player);

    static DefaultNetworkProvider* current_instance;
};

}

#endif // DEFAULT_NETWORK_PROVIDER_H