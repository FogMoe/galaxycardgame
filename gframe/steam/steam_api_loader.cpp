#include "steam_api_loader.h"
#include <cstring>
#include <cstdio>

#ifdef _WIN32
    #include <windows.h>
    #define STEAM_LIBRARY_NAME "steam_api64.dll"
#elif defined(__APPLE__)
    #include <dlfcn.h>
    #define STEAM_LIBRARY_NAME "libsteam_api.dylib"
#else
    #include <dlfcn.h>
    #define STEAM_LIBRARY_NAME "libsteam_api.so"
#endif

namespace ygo {

SteamAPILoader::~SteamAPILoader() {
    UnloadSteamAPI();
}

SteamAPILoader& SteamAPILoader::GetInstance() {
    static SteamAPILoader instance;
    return instance;
}

bool SteamAPILoader::LoadSteamAPI() {
    if (loaded) {
        return true;
    }

    // 检查Steam客户端是否正在运行
    if (!IsSteamRunning()) {
        snprintf(error_buffer, sizeof(error_buffer), "Steam client is not running");
        return false;
    }

    // 加载Steam库
    if (!LoadLibrary()) {
        return false;
    }

    // 加载函数指针
    if (!LoadFunctions()) {
        UnloadLibrary();
        return false;
    }

    loaded = true;
    return true;
}

void SteamAPILoader::UnloadSteamAPI() {
    if (loaded) {
        if (steamapi_shutdown) {
            steamapi_shutdown();
        }
        UnloadLibrary();
        loaded = false;
    }
}

bool SteamAPILoader::IsLoaded() const {
    return loaded;
}

bool SteamAPILoader::IsSteamRunning() const {
#ifdef _WIN32
    // 在Windows上检查Steam进程或注册表
    HKEY hKey;
    if (RegOpenKeyExA(HKEY_CURRENT_USER, "Software\\Valve\\Steam", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        DWORD runningValue;
        DWORD dataSize = sizeof(runningValue);
        DWORD dataType;

        if (RegQueryValueExA(hKey, "RunningAppID", NULL, &dataType, (LPBYTE)&runningValue, &dataSize) == ERROR_SUCCESS) {
            RegCloseKey(hKey);
            return true;
        }
        RegCloseKey(hKey);
    }

    // 尝试查找Steam窗口
    return FindWindowA("vguiPopupWindow", "Steam") != NULL;
#else
    // 在Unix系统上检查Steam进程
    FILE* fp = popen("pgrep steam", "r");
    if (fp) {
        char buffer[64];
        bool found = fgets(buffer, sizeof(buffer), fp) != NULL;
        pclose(fp);
        return found;
    }
    return false;
#endif
}

bool SteamAPILoader::LoadLibrary() {
#ifdef _WIN32
    steam_library = LoadLibraryA(STEAM_LIBRARY_NAME);
    if (!steam_library) {
        snprintf(error_buffer, sizeof(error_buffer), "Failed to load %s (Error: %lu)",
                STEAM_LIBRARY_NAME, GetLastError());
        return false;
    }
#else
    steam_library = dlopen(STEAM_LIBRARY_NAME, RTLD_LAZY);
    if (!steam_library) {
        snprintf(error_buffer, sizeof(error_buffer), "Failed to load %s: %s",
                STEAM_LIBRARY_NAME, dlerror());
        return false;
    }
#endif
    return true;
}

void SteamAPILoader::UnloadLibrary() {
    if (steam_library) {
#ifdef _WIN32
        FreeLibrary(steam_library);
#else
        dlclose(steam_library);
#endif
        steam_library = nullptr;
    }
}

bool SteamAPILoader::LoadFunctions() {
    // 基础API函数
    steamapi_init = (SteamAPI_Init_t)GetProcAddress("SteamAPI_Init");
    steamapi_shutdown = (SteamAPI_Shutdown_t)GetProcAddress("SteamAPI_Shutdown");
    steamapi_runcallbacks = (SteamAPI_RunCallbacks_t)GetProcAddress("SteamAPI_RunCallbacks");
    steamapi_restart = (SteamAPI_RestartAppIfNecessary_t)GetProcAddress("SteamAPI_RestartAppIfNecessary");

    if (!steamapi_init || !steamapi_shutdown || !steamapi_runcallbacks) {
        snprintf(error_buffer, sizeof(error_buffer), "Failed to load required Steam API functions");
        return false;
    }

    // Matchmaking函数（可选）
    get_steam_matchmaking = (SteamMatchmaking_t)GetProcAddress("SteamAPI_SteamMatchmaking_v009");
    create_lobby = (CreateLobby_t)GetProcAddress("SteamAPI_ISteamMatchmaking_CreateLobby");
    set_lobby_data = (SetLobbyData_t)GetProcAddress("SteamAPI_ISteamMatchmaking_SetLobbyData");
    request_lobby_list = (RequestLobbyList_t)GetProcAddress("SteamAPI_ISteamMatchmaking_RequestLobbyList");

    // Networking函数（可选）
    get_steam_networking = (SteamNetworkingSockets_t)GetProcAddress("SteamAPI_SteamNetworkingSockets_v012");
    create_listen_socket = (CreateListenSocketIP_t)GetProcAddress("SteamAPI_ISteamNetworkingSockets_CreateListenSocketIP");
    connect_by_ip = (ConnectByIPAddress_t)GetProcAddress("SteamAPI_ISteamNetworkingSockets_ConnectByIPAddress");
    accept_connection = (AcceptConnection_t)GetProcAddress("SteamAPI_ISteamNetworkingSockets_AcceptConnection");
    close_connection = (CloseConnection_t)GetProcAddress("SteamAPI_ISteamNetworkingSockets_CloseConnection");
    send_message = (SendMessageToConnection_t)GetProcAddress("SteamAPI_ISteamNetworkingSockets_SendMessageToConnection");
    receive_messages = (ReceiveMessagesOnConnection_t)GetProcAddress("SteamAPI_ISteamNetworkingSockets_ReceiveMessagesOnConnection");

    return true;
}

void* SteamAPILoader::GetProcAddress(const char* name) {
    if (!steam_library) {
        return nullptr;
    }

#ifdef _WIN32
    return (void*)::GetProcAddress(steam_library, name);
#else
    return dlsym(steam_library, name);
#endif
}

// Steam API基础函数实现
bool SteamAPILoader::SteamAPI_Init() {
    if (!loaded || !steamapi_init) {
        return false;
    }
    return steamapi_init();
}

void SteamAPILoader::SteamAPI_Shutdown() {
    if (loaded && steamapi_shutdown) {
        steamapi_shutdown();
    }
}

void SteamAPILoader::SteamAPI_RunCallbacks() {
    if (loaded && steamapi_runcallbacks) {
        steamapi_runcallbacks();
    }
}

bool SteamAPILoader::SteamAPI_RestartAppIfNecessary(AppId_t unOwnAppID) {
    if (!loaded || !steamapi_restart) {
        return false;
    }
    return steamapi_restart(unOwnAppID);
}

// Matchmaking接口实现
void* SteamAPILoader::GetSteamMatchmaking() {
    if (!loaded || !get_steam_matchmaking) {
        return nullptr;
    }

    if (!steam_matchmaking) {
        steam_matchmaking = get_steam_matchmaking();
    }
    return steam_matchmaking;
}

SteamAPICall_t SteamAPILoader::CreateLobby(ELobbyType lobbyType, int maxMembers) {
    void* matchmaking = GetSteamMatchmaking();
    if (!matchmaking || !create_lobby) {
        return 0;
    }
    return create_lobby(matchmaking, lobbyType, maxMembers);
}

void SteamAPILoader::SetLobbyData(CSteamID steamIDLobby, const char* key, const char* value) {
    void* matchmaking = GetSteamMatchmaking();
    if (matchmaking && set_lobby_data) {
        set_lobby_data(matchmaking, steamIDLobby, key, value);
    }
}

bool SteamAPILoader::RequestLobbyList() {
    void* matchmaking = GetSteamMatchmaking();
    if (!matchmaking || !request_lobby_list) {
        return false;
    }
    return request_lobby_list(matchmaking);
}

// Networking接口实现
void* SteamAPILoader::GetSteamNetworkingSockets() {
    if (!loaded || !get_steam_networking) {
        return nullptr;
    }

    if (!steam_networking_sockets) {
        steam_networking_sockets = get_steam_networking();
    }
    return steam_networking_sockets;
}

HSteamListenSocket SteamAPILoader::CreateListenSocketIP(uint32_t nIP, uint16_t nPort) {
    void* networking = GetSteamNetworkingSockets();
    if (!networking || !create_listen_socket) {
        return 0;
    }
    return create_listen_socket(networking, nIP, nPort);
}

HSteamNetConnection SteamAPILoader::ConnectByIPAddress(uint32_t nIP, uint16_t nPort) {
    void* networking = GetSteamNetworkingSockets();
    if (!networking || !connect_by_ip) {
        return 0;
    }
    return connect_by_ip(networking, nIP, nPort);
}

bool SteamAPILoader::AcceptConnection(HSteamNetConnection hConn) {
    void* networking = GetSteamNetworkingSockets();
    if (!networking || !accept_connection) {
        return false;
    }
    return accept_connection(networking, hConn);
}

bool SteamAPILoader::CloseConnection(HSteamNetConnection hPeer, int nReason, const char* pszDebug, bool bEnableLinger) {
    void* networking = GetSteamNetworkingSockets();
    if (!networking || !close_connection) {
        return false;
    }
    return close_connection(networking, hPeer, nReason, pszDebug, bEnableLinger);
}

bool SteamAPILoader::SendMessageToConnection(HSteamNetConnection hConn, const void* pData, uint32_t cbData, int nSendFlags) {
    void* networking = GetSteamNetworkingSockets();
    if (!networking || !send_message) {
        return false;
    }
    return send_message(networking, hConn, pData, cbData, nSendFlags);
}

int SteamAPILoader::ReceiveMessagesOnConnection(HSteamNetConnection hConn, SteamNetworkingMessage_t** ppOutMessages, int nMaxMessages) {
    void* networking = GetSteamNetworkingSockets();
    if (!networking || !receive_messages) {
        return 0;
    }
    return receive_messages(networking, hConn, ppOutMessages, nMaxMessages);
}

// 用户信息（简化实现）
CSteamID SteamAPILoader::GetSteamID() {
    // 这里需要从Steam API获取用户ID
    // 简化实现，返回一个假的ID
    return 0;
}

const char* SteamAPILoader::GetPersonaName() {
    // 这里需要从Steam API获取用户名
    // 简化实现
    return "SteamPlayer";
}

const char* SteamAPILoader::GetLastError() const {
    return error_buffer;
}

}