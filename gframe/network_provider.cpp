#include "network_provider.h"
#include <algorithm>

namespace ygo {

NetworkProviderManager& NetworkProviderManager::GetInstance() {
    static NetworkProviderManager instance;
    return instance;
}

void NetworkProviderManager::RegisterProvider(NetworkProvider* provider) {
    if (!provider) return;

    // 检查是否已经注册
    auto it = std::find(providers.begin(), providers.end(), provider);
    if (it == providers.end()) {
        providers.push_back(provider);
    }
}

void NetworkProviderManager::UnregisterProvider(NetworkProvider* provider) {
    if (!provider) return;

    // 如果是当前提供者，清除当前提供者
    if (current_provider == provider) {
        current_provider = nullptr;
    }

    // 从列表中移除
    providers.erase(std::remove(providers.begin(), providers.end(), provider), providers.end());
}

std::vector<NetworkProvider*> NetworkProviderManager::GetAvailableProviders() const {
    std::vector<NetworkProvider*> available;
    for (auto* provider : providers) {
        if (provider && provider->IsAvailable()) {
            available.push_back(provider);
        }
    }
    return available;
}

bool NetworkProviderManager::SetCurrentProvider(NetworkProviderType type) {
    NetworkProvider* target = GetProvider(type);
    return SetCurrentProvider(target);
}

bool NetworkProviderManager::SetCurrentProvider(NetworkProvider* provider) {
    if (!provider || !provider->IsAvailable()) {
        return false;
    }

    // 如果有当前提供者且正在使用中，先断开
    if (current_provider) {
        if (current_provider->IsHosting()) {
            current_provider->StopHosting();
        }
        if (current_provider->GetConnectionState() != NetworkConnectionState::DISCONNECTED) {
            current_provider->Disconnect();
        }
    }

    current_provider = provider;
    return true;
}

NetworkProvider* NetworkProviderManager::GetCurrentProvider() const {
    return current_provider;
}

NetworkProvider* NetworkProviderManager::GetProvider(NetworkProviderType type) const {
    for (auto* provider : providers) {
        if (provider && provider->GetType() == type) {
            return provider;
        }
    }
    return nullptr;
}

NetworkProvider* NetworkProviderManager::GetBestAvailableProvider() const {
    auto available = GetAvailableProviders();
    if (available.empty()) {
        return nullptr;
    }

    // 优先级排序：Steam > Default
    for (auto* provider : available) {
        if (provider->GetType() == NetworkProviderType::STEAM_NETWORK) {
            return provider;
        }
    }

    // 如果没有Steam，返回默认提供者
    for (auto* provider : available) {
        if (provider->GetType() == NetworkProviderType::DEFAULT_NETWORK) {
            return provider;
        }
    }

    // 返回第一个可用的
    return available[0];
}

}