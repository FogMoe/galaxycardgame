#include "network_manager.h"
#include <algorithm>
#include <iostream>

namespace ygo {

GameNetworkManager::~GameNetworkManager() {
    Shutdown();
}

GameNetworkManager& GameNetworkManager::GetInstance() {
    static GameNetworkManager instance;
    return instance;
}

bool GameNetworkManager::Initialize() {
    if (initialized) {
        return true;
    }

    // 初始化网络提供者
    InitializeProviders();

    // 选择默认提供者
#ifdef YGOPRO_ENABLE_STEAM_SUPPORT
    // 如果Steam可用，优先使用Steam
    if (steam_provider && steam_provider->IsAvailable()) {
        preferred_provider_type = NetworkProviderType::STEAM_NETWORK;
        provider_manager.SetCurrentProvider(steam_provider.get());
    } else {
        provider_manager.SetCurrentProvider(default_provider.get());
    }
#else
    provider_manager.SetCurrentProvider(default_provider.get());
#endif

    initialized = true;
    return true;
}

void GameNetworkManager::Shutdown() {
    if (!initialized) {
        return;
    }

    // 断开所有连接
    if (IsHosting()) {
        StopHosting();
    }
    if (GetConnectionState() != NetworkConnectionState::DISCONNECTED) {
        Disconnect();
    }

    // 关闭所有提供者
    ShutdownProviders();

    initialized = false;
}

bool GameNetworkManager::IsInitialized() const {
    return initialized;
}

NetworkProvider* GameNetworkManager::GetCurrentProvider() const {
    if (!initialized) {
        return nullptr;
    }
    return provider_manager.GetCurrentProvider();
}

bool GameNetworkManager::SetNetworkProvider(NetworkProviderType type) {
    if (!initialized) {
        return false;
    }

    NetworkProvider* provider = provider_manager.GetProvider(type);
    if (!provider || !provider->IsAvailable()) {
        return false;
    }

    return provider_manager.SetCurrentProvider(provider);
}

std::vector<NetworkProvider*> GameNetworkManager::GetAvailableProviders() const {
    if (!initialized) {
        return {};
    }
    return provider_manager.GetAvailableProviders();
}

bool GameNetworkManager::IsProviderAvailable(NetworkProviderType type) const {
    if (!initialized) {
        return false;
    }

    NetworkProvider* provider = provider_manager.GetProvider(type);
    return provider && provider->IsAvailable();
}

// 统一网络接口实现（委托给当前提供者）

bool GameNetworkManager::StartHosting(const HostInfo& host_info, const std::wstring& host_name,
                                     const std::wstring& password, uint16_t port) {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->StartHosting(host_info, host_name, password, port) : false;
}

void GameNetworkManager::StopHosting() {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->StopHosting();
    }
}

bool GameNetworkManager::IsHosting() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->IsHosting() : false;
}

bool GameNetworkManager::ConnectToHost(const std::string& host_address, uint16_t port,
                                      const std::wstring& password) {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->ConnectToHost(host_address, port, password) : false;
}

bool GameNetworkManager::ConnectToHost(uint32_t host_id, const std::wstring& password) {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->ConnectToHost(host_id, password) : false;
}

void GameNetworkManager::Disconnect() {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->Disconnect();
    }
}

NetworkConnectionState GameNetworkManager::GetConnectionState() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->GetConnectionState() : NetworkConnectionState::DISCONNECTED;
}

void GameNetworkManager::RefreshHostList() {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->RefreshHostList();
    }
}

std::vector<NetworkHostInfo> GameNetworkManager::GetHostList() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->GetHostList() : std::vector<NetworkHostInfo>{};
}

void GameNetworkManager::ClearHostList() {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->ClearHostList();
    }
}

bool GameNetworkManager::SendToServer(const void* data, size_t len) {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->SendToServer(data, len) : false;
}

bool GameNetworkManager::SendToClient(DuelPlayer* player, const void* data, size_t len) {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->SendToClient(player, data, len) : false;
}

bool GameNetworkManager::SendToAllClients(const void* data, size_t len) {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->SendToAllClients(data, len) : false;
}

std::vector<DuelPlayer*> GameNetworkManager::GetConnectedPlayers() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->GetConnectedPlayers() : std::vector<DuelPlayer*>{};
}

void GameNetworkManager::KickPlayer(DuelPlayer* player) {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->KickPlayer(player);
    }
}

void GameNetworkManager::ProcessNetworkEvents() {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->ProcessNetworkEvents();
    }

#ifdef YGOPRO_ENABLE_STEAM_SUPPORT
    // 处理Steam大厅回调
    SteamLobbyManager::GetInstance().ProcessCallbacks();
#endif
}

// 网络状态信息

const char* GameNetworkManager::GetCurrentProviderName() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->GetTypeName() : "None";
}

bool GameNetworkManager::SupportsFriendInvite() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->SupportsFriendInvite() : false;
}

bool GameNetworkManager::InviteFriend(uint64_t friend_id) {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->InviteFriend(friend_id) : false;
}

std::wstring GameNetworkManager::GetLocalPlayerName() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->GetLocalPlayerName() : L"Player";
}

uint64_t GameNetworkManager::GetLocalPlayerId() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->GetLocalPlayerId() : 0;
}

int GameNetworkManager::GetPing() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->GetPing() : -1;
}

std::string GameNetworkManager::GetConnectionQualityString() const {
    NetworkProvider* provider = GetCurrentProvider();
    return provider ? provider->GetConnectionQualityString() : "Unknown";
}

// 回调设置

void GameNetworkManager::SetOnClientConnected(std::function<void(DuelPlayer*)> callback) {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->SetOnClientConnected(callback);
    }
}

void GameNetworkManager::SetOnClientDisconnected(std::function<void(DuelPlayer*)> callback) {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->SetOnClientDisconnected(callback);
    }
}

void GameNetworkManager::SetOnDataReceived(std::function<void(DuelPlayer*, const void*, size_t)> callback) {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->SetOnDataReceived(callback);
    }
}

void GameNetworkManager::SetOnHostListUpdated(std::function<void()> callback) {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->SetOnHostListUpdated(callback);
    }
}

void GameNetworkManager::SetOnConnectionStateChanged(std::function<void(NetworkConnectionState)> callback) {
    NetworkProvider* provider = GetCurrentProvider();
    if (provider) {
        provider->SetOnConnectionStateChanged(callback);
    }
}

#ifdef YGOPRO_ENABLE_STEAM_SUPPORT
SteamLobbyManager& GameNetworkManager::GetSteamLobbyManager() {
    return SteamLobbyManager::GetInstance();
}

bool GameNetworkManager::IsSteamSupported() const {
    return steam_provider && steam_provider->IsAvailable();
}
#endif

// 私有方法实现

void GameNetworkManager::InitializeProviders() {
    // 初始化默认网络提供者
    default_provider = std::make_unique<DefaultNetworkProvider>();
    if (default_provider->Initialize()) {
        provider_manager.RegisterProvider(default_provider.get());
    }

#ifdef YGOPRO_ENABLE_STEAM_SUPPORT
    // 初始化Steam网络提供者
    steam_provider = std::make_unique<SteamNetworkProvider>();
    if (steam_provider->Initialize()) {
        provider_manager.RegisterProvider(steam_provider.get());
    }

    // 初始化Steam大厅管理器
    SteamLobbyManager::GetInstance().Initialize();
#endif
}

void GameNetworkManager::ShutdownProviders() {
#ifdef YGOPRO_ENABLE_STEAM_SUPPORT
    // 关闭Steam大厅管理器
    SteamLobbyManager::GetInstance().Shutdown();

    // 关闭Steam提供者
    if (steam_provider) {
        provider_manager.UnregisterProvider(steam_provider.get());
        steam_provider->Shutdown();
        steam_provider.reset();
    }
#endif

    // 关闭默认提供者
    if (default_provider) {
        provider_manager.UnregisterProvider(default_provider.get());
        default_provider->Shutdown();
        default_provider.reset();
    }
}

}