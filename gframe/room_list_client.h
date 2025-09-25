#ifndef ROOM_LIST_CLIENT_H
#define ROOM_LIST_CLIENT_H

#include <atomic>
#include <cstdint>
#include <mutex>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace ygo {

struct RoomListEntry {
    std::wstring name;
    std::wstring endpoint;
    std::wstring note;
};

class RoomListClient {
public:
    RoomListClient();
    ~RoomListClient();

    void Configure(const std::wstring& server, bool enabled);
    void UpdatePublicHost(const std::wstring& hostText);

    bool FetchRooms(std::vector<RoomListEntry>& outList, std::wstring& errMsg);

    void RegisterRoom(const std::wstring& roomName, uint16_t port, const std::wstring& note = L"");
    void UnregisterRoom();

private:
    bool SendRequest(const std::string& method,
                     const std::string& path,
                     const std::string& body,
                     int& statusCode,
                     std::string& responseBody);
    bool SendPlainPost(const std::string& path, const std::string& body);
    void StartHeartbeat();
    void StopHeartbeat();
    void HeartbeatLoop();
    static std::string WideToUtf8(const std::wstring& value);
    static std::wstring Utf8ToWide(const std::string& value);
    static std::string UrlEncode(const std::string& value);
    static std::string TrimCopy(const std::string& value);

    std::mutex mutex_;
    std::string serverHost_;
    std::string serverPort_;
    std::string hostHeader_;
    bool enabled_{ false };

    std::string publicHost_;
    std::string registeredId_;

    std::atomic<bool> heartbeatRunning_{ false };
    std::thread heartbeatThread_;
};

} // namespace ygo

#endif // ROOM_LIST_CLIENT_H
