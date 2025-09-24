# Steam联机功能集成使用指南

## 概述

本项目现已成功集成Steam联机功能，同时保持GPL-v2许可证兼容性。Steam功能通过动态加载实现，不会影响主程序的开源性质。

## 编译配置

### 默认编译（不含Steam支持）
```bash
premake5 vs2022
# 或
premake5 gmake2
make
```

### 启用Steam支持的编译
```bash
# 启用Steam支持
premake5 --enable-steam-support --steam-app-id=YOUR_STEAM_APP_ID vs2022

# Linux/Mac
premake5 --enable-steam-support --steam-app-id=YOUR_STEAM_APP_ID gmake2
make
```

## 文件结构

```
gframe/
├── network_provider.h/cpp              # 网络提供者抽象接口
├── default_network_provider.h/cpp      # 默认网络实现（libevent）
├── network_manager.h/cpp               # 统一网络管理器
└── steam/                              # Steam相关文件
    ├── steam_api_loader.h/cpp          # Steam API动态加载器
    ├── steam_network_provider.h/cpp    # Steam网络实现
    └── steam_lobby.h/cpp               # Steam大厅功能
```

## 使用方法

### 1. 初始化网络管理器

```cpp
#include "network_manager.h"

// 在游戏初始化时
GameNetworkManager& network = GameNetworkManager::GetInstance();
if (!network.Initialize()) {
    // 处理初始化失败
}
```

### 2. 检查可用的网络提供者

```cpp
auto providers = network.GetAvailableProviders();
for (auto* provider : providers) {
    printf("Available: %s\n", provider->GetTypeName());
}

// 检查Steam是否可用
if (network.IsProviderAvailable(NetworkProviderType::STEAM_NETWORK)) {
    printf("Steam networking is available!\n");
}
```

### 3. 切换网络提供者

```cpp
// 尝试切换到Steam网络
if (network.SetNetworkProvider(NetworkProviderType::STEAM_NETWORK)) {
    printf("Switched to Steam networking\n");
} else {
    printf("Steam not available, using default networking\n");
}
```

### 4. 创建房间

```cpp
HostInfo host_info;
host_info.rule = 5;
host_info.mode = 0;
host_info.start_lp = 8000;
// ... 设置其他参数

if (network.StartHosting(host_info, L"My Game Room", L"password123")) {
    printf("Room created successfully\n");
}
```

### 5. 搜索和加入房间

```cpp
// 搜索房间
network.RefreshHostList();

// 设置房间列表更新回调
network.SetOnHostListUpdated([]() {
    auto hosts = network.GetHostList();
    for (const auto& host : hosts) {
        wprintf(L"Found room: %ls\n", host.host_name.c_str());
    }
});

// 加入房间
if (!hosts.empty()) {
    if (network.ConnectToHost(hosts[0].host_id, L"password123")) {
        printf("Connecting to room...\n");
    }
}
```

### 6. Steam特有功能（条件编译）

```cpp
#ifdef YGOPRO_ENABLE_STEAM_SUPPORT
if (network.IsSteamSupported()) {
    // 获取Steam用户信息
    std::wstring player_name = network.GetLocalPlayerName();
    uint64_t steam_id = network.GetLocalPlayerId();

    // 邀请Steam好友
    if (network.SupportsFriendInvite()) {
        network.InviteFriend(friend_steam_id);
    }

    // 使用Steam大厅
    auto& lobby = network.GetSteamLobbyManager();
    lobby.CreateLobby(host_info, L"Steam Lobby");
}
#endif
```

### 7. 网络事件处理

```cpp
// 设置事件回调
network.SetOnClientConnected([](DuelPlayer* player) {
    printf("Player connected\n");
});

network.SetOnClientDisconnected([](DuelPlayer* player) {
    printf("Player disconnected\n");
});

network.SetOnDataReceived([](DuelPlayer* player, const void* data, size_t len) {
    // 处理接收到的数据
});

// 在主循环中处理网络事件
while (game_running) {
    network.ProcessNetworkEvents();
    // ... 其他游戏逻辑
}
```

## Steam应用配置

### 1. 注册Steam应用

1. 在Steamworks开发者门户注册应用
2. 获取Steam应用ID
3. 配置应用权限和网络设置

### 2. 配置steam_appid.txt

在游戏可执行文件同目录创建`steam_appid.txt`文件：
```
YOUR_STEAM_APP_ID
```

### 3. 部署要求

- 用户必须安装Steam客户端
- 游戏必须通过Steam启动（或Steam客户端正在运行）
- 应用必须在Steam上发布才能使用完整的联机功能

## 兼容性说明

### GPL-v2 兼容性
- 主程序代码完全开源，符合GPL-v2
- Steam SDK通过动态加载，不包含在二进制文件中
- 用户可以选择编译不含Steam功能的版本

### 向后兼容性
- 现有的局域网功能完全保留
- 网络协议和数据包格式不变
- 无需修改现有游戏逻辑代码

### 平台支持
- Windows: 完整支持
- Linux: 支持（需要Steam客户端）
- macOS: 支持（需要Steam客户端）

## 故障排除

### Steam API加载失败
1. 检查Steam客户端是否正在运行
2. 确认steam_api.dll/libsteam_api.so在系统PATH中
3. 验证Steam应用ID配置正确

### 连接问题
1. 检查防火墙设置
2. 确认网络端口未被占用
3. 验证Steam网络状态

### 编译错误
1. 确保使用了正确的编译选项
2. 检查条件编译宏定义
3. 验证文件包含路径

## 开发建议

### 1. 测试流程
1. 先测试默认网络功能
2. 再测试Steam功能（需要Steam环境）
3. 测试网络提供者切换

### 2. 错误处理
- 始终检查网络操作返回值
- 实现合理的重连机制
- 提供用户友好的错误信息

### 3. 性能优化
- 定期调用ProcessNetworkEvents()
- 合理设置网络超时时间
- 监控网络连接质量

## 更新日志

- 2025.09: 完成Steam网络提供者架构设计
- 2025.09: 实现动态加载Steam SDK
- 2025.09: 添加Steam大厅功能支持
- 2025.09: 完成GPL兼容性验证