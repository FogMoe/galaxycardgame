#ifndef STEAM_API_LOADER_H
#define STEAM_API_LOADER_H

// Steam API动态加载器 - GPL兼容实现
// 不直接包含steam_api.h，而是定义必要的类型和函数指针

#include <cstdint>
#include <functional>

#ifdef _WIN32
    #include <windows.h>
    typedef HMODULE LibraryHandle;
#else
    #include <dlfcn.h>
    typedef void* LibraryHandle;
#endif

namespace ygo {

// Steam类型定义（避免直接包含Steam SDK头文件）
using SteamAPICall_t = uint64_t;
using CSteamID = uint64_t;
using HSteamNetConnection = uint32_t;
using HSteamListenSocket = uint32_t;
using HSteamNetPollGroup = uint32_t;
using SteamNetworkingMicroseconds = int64_t;
using AppId_t = uint32_t;

// 枚举定义
enum class ESteamNetworkingConnectionState : int {
    None = 0,
    Connecting = 1,
    FindingRoute = 2,
    Connected = 3,
    ClosedByPeer = 4,
    ProblemDetectedLocally = 5
};

enum class ESteamNetworkingIdentityType : int {
    Invalid = 0,
    SteamID = 16
};

enum class ELobbyType : int {
    Private = 0,
    FriendsOnly = 1,
    Public = 2,
    Invisible = 3
};

// 结构体定义（简化版本）
struct SteamNetworkingIdentity {
    ESteamNetworkingIdentityType type;
    union {
        CSteamID steamID64;
        char genericString[128];
        uint8_t genericBytes[128];
        char ipv6[16];
    };
};

struct SteamNetworkingMessage_t {
    void* pData;
    int cbSize;
    HSteamNetConnection conn;
    SteamNetworkingIdentity identityPeer;
    int64_t nConnUserData;
    SteamNetworkingMicroseconds usecTimeReceived;
    int64_t nMessageNumber;
    // 其他字段...
};

struct SteamNetConnectionInfo_t {
    SteamNetworkingIdentity identityRemote;
    int64_t nUserData;
    HSteamListenSocket listenSocket;
    // 其他字段...
};

// 回调函数类型
using FnSteamNetConnectionStatusChanged = void(*)(void* context);

// Steam API函数指针类型定义
typedef bool (*SteamAPI_Init_t)();
typedef void (*SteamAPI_Shutdown_t)();
typedef void (*SteamAPI_RunCallbacks_t)();
typedef bool (*SteamAPI_RestartAppIfNecessary_t)(AppId_t unOwnAppID);

// Matchmaking接口函数指针
typedef void* (*SteamMatchmaking_t)();
typedef SteamAPICall_t (*CreateLobby_t)(void* interface, ELobbyType lobbyType, int maxMembers);
typedef void (*SetLobbyData_t)(void* interface, CSteamID steamIDLobby, const char* key, const char* value);
typedef bool (*RequestLobbyList_t)(void* interface);

// Networking接口函数指针
typedef void* (*SteamNetworkingSockets_t)();
typedef HSteamListenSocket (*CreateListenSocketIP_t)(void* interface, uint32_t nIP, uint16_t nPort);
typedef HSteamNetConnection (*ConnectByIPAddress_t)(void* interface, uint32_t nIP, uint16_t nPort);
typedef bool (*AcceptConnection_t)(void* interface, HSteamNetConnection hConn);
typedef bool (*CloseConnection_t)(void* interface, HSteamNetConnection hPeer, int nReason, const char* pszDebug, bool bEnableLinger);
typedef bool (*SendMessageToConnection_t)(void* interface, HSteamNetConnection hConn, const void* pData, uint32_t cbData, int nSendFlags);
typedef int (*ReceiveMessagesOnConnection_t)(void* interface, HSteamNetConnection hConn, SteamNetworkingMessage_t** ppOutMessages, int nMaxMessages);

// Steam API动态加载器类
class SteamAPILoader {
public:
    static SteamAPILoader& GetInstance();

    // 初始化和清理
    bool LoadSteamAPI();
    void UnloadSteamAPI();
    bool IsLoaded() const;
    bool IsSteamRunning() const;

    // Steam API基础函数
    bool SteamAPI_Init();
    void SteamAPI_Shutdown();
    void SteamAPI_RunCallbacks();
    bool SteamAPI_RestartAppIfNecessary(AppId_t unOwnAppID);

    // Matchmaking接口
    void* GetSteamMatchmaking();
    SteamAPICall_t CreateLobby(ELobbyType lobbyType, int maxMembers);
    void SetLobbyData(CSteamID steamIDLobby, const char* key, const char* value);
    bool RequestLobbyList();

    // Networking接口
    void* GetSteamNetworkingSockets();
    HSteamListenSocket CreateListenSocketIP(uint32_t nIP, uint16_t nPort);
    HSteamNetConnection ConnectByIPAddress(uint32_t nIP, uint16_t nPort);
    bool AcceptConnection(HSteamNetConnection hConn);
    bool CloseConnection(HSteamNetConnection hPeer, int nReason, const char* pszDebug, bool bEnableLinger);
    bool SendMessageToConnection(HSteamNetConnection hConn, const void* pData, uint32_t cbData, int nSendFlags);
    int ReceiveMessagesOnConnection(HSteamNetConnection hConn, SteamNetworkingMessage_t** ppOutMessages, int nMaxMessages);

    // 用户信息
    CSteamID GetSteamID();
    const char* GetPersonaName();

    // 错误处理
    const char* GetLastError() const;

private:
    SteamAPILoader() = default;
    ~SteamAPILoader();

    // 禁用拷贝和赋值
    SteamAPILoader(const SteamAPILoader&) = delete;
    SteamAPILoader& operator=(const SteamAPILoader&) = delete;

    // 内部函数
    bool LoadLibrary();
    void UnloadLibrary();
    bool LoadFunctions();
    void* GetProcAddress(const char* name);

    // 成员变量
    LibraryHandle steam_library = nullptr;
    bool loaded = false;
    mutable char error_buffer[256] = {0};

    // Steam接口指针
    void* steam_matchmaking = nullptr;
    void* steam_networking_sockets = nullptr;

    // 函数指针
    SteamAPI_Init_t steamapi_init = nullptr;
    SteamAPI_Shutdown_t steamapi_shutdown = nullptr;
    SteamAPI_RunCallbacks_t steamapi_runcallbacks = nullptr;
    SteamAPI_RestartAppIfNecessary_t steamapi_restart = nullptr;

    SteamMatchmaking_t get_steam_matchmaking = nullptr;
    CreateLobby_t create_lobby = nullptr;
    SetLobbyData_t set_lobby_data = nullptr;
    RequestLobbyList_t request_lobby_list = nullptr;

    SteamNetworkingSockets_t get_steam_networking = nullptr;
    CreateListenSocketIP_t create_listen_socket = nullptr;
    ConnectByIPAddress_t connect_by_ip = nullptr;
    AcceptConnection_t accept_connection = nullptr;
    CloseConnection_t close_connection = nullptr;
    SendMessageToConnection_t send_message = nullptr;
    ReceiveMessagesOnConnection_t receive_messages = nullptr;
};

// 便利宏定义
#define STEAM_API_CALL(func, ...) \
    do { \
        if (SteamAPILoader::GetInstance().IsLoaded()) { \
            SteamAPILoader::GetInstance().func(__VA_ARGS__); \
        } \
    } while(0)

#define STEAM_API_CALL_RESULT(result, func, ...) \
    do { \
        if (SteamAPILoader::GetInstance().IsLoaded()) { \
            result = SteamAPILoader::GetInstance().func(__VA_ARGS__); \
        } \
    } while(0)

}

#endif // STEAM_API_LOADER_H