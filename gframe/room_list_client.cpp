#include "room_list_client.h"

#include "bufferio.h"
#include "game.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <utility>
#include <cstring>
#include <cstdlib>
#include <sstream>
#include <vector>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

namespace ygo {

namespace {
constexpr std::chrono::seconds kHeartbeatInterval{45};
}

RoomListClient::RoomListClient() = default;

RoomListClient::~RoomListClient() {
    UnregisterRoom();
}

void RoomListClient::Configure(const std::wstring& server, bool enabled) {
	UnregisterRoom();
	std::lock_guard<std::mutex> guard(mutex_);
    enabled_ = enabled;
    serverHost_.clear();
    serverPort_.clear();
    hostHeader_.clear();

    std::string serverUtf8 = TrimCopy(WideToUtf8(server));
    if (!enabled_ || serverUtf8.empty()) {
        enabled_ = false;
        return;
    }

    std::string hostPart = serverUtf8;
    std::string portPart = "80";

    auto bracketPos = hostPart.find(']');
    if (!hostPart.empty() && hostPart.front() == '[' && bracketPos != std::string::npos) {
        std::string addrPart = hostPart.substr(1, bracketPos - 1);
        std::string rest = hostPart.substr(bracketPos + 1);
        if (!rest.empty() && rest.front() == ':') {
            portPart = rest.substr(1);
        }
        hostPart = addrPart;
    } else {
        auto colonPos = hostPart.rfind(':');
        if (colonPos != std::string::npos && colonPos != hostPart.size() - 1 && hostPart.find(':') == colonPos) {
            portPart = hostPart.substr(colonPos + 1);
            hostPart = hostPart.substr(0, colonPos);
        }
    }

    if (hostPart.empty()) {
        enabled_ = false;
        return;
    }

    if (portPart.empty()) {
        portPart = "80";
    }

    serverHost_ = hostPart;
    serverPort_ = portPart;
    if (portPart == "80") {
        hostHeader_ = hostPart;
    } else {
        hostHeader_ = hostPart + ":" + portPart;
    }
}

void RoomListClient::UpdatePublicHost(const std::wstring& hostText) {
    std::lock_guard<std::mutex> guard(mutex_);
    publicHost_ = TrimCopy(WideToUtf8(hostText));
}

bool RoomListClient::FetchRooms(std::vector<RoomListEntry>& outList, std::wstring& errMsg) {
    std::string response;
    int status = 0;

    if (!SendRequest("GET", "/rooms/list", {}, status, response)) {
        errMsg = L"无法连接房间列表服务器";
        return false;
    }
    if (status != 200) {
        errMsg = L"房间列表服务器返回错误";
        return false;
    }

    outList.clear();
    std::stringstream ss(response);
    std::string line;
    while (std::getline(ss, line)) {
        if (line.empty())
            continue;
        std::string name;
        std::string host;
        std::string port;
        std::string note;

        size_t first = line.find('|');
        size_t second = (first == std::string::npos) ? std::string::npos : line.find('|', first + 1);
        size_t third = (second == std::string::npos) ? std::string::npos : line.find('|', second + 1);

        if (first == std::string::npos || second == std::string::npos) {
            continue;
        }
        name = line.substr(0, first);
        host = line.substr(first + 1, second - first - 1);
        if (third == std::string::npos) {
            port = line.substr(second + 1);
        } else {
            port = line.substr(second + 1, third - second - 1);
            note = line.substr(third + 1);
        }

        std::wstring wName = Utf8ToWide(name);
        std::wstring wNote = Utf8ToWide(note);
        std::wstring endpoint = Utf8ToWide(host);
        if (!port.empty()) {
            endpoint += L":";
            endpoint += Utf8ToWide(port);
        }

        RoomListEntry entry{};
        entry.name = std::move(wName);
        entry.note = std::move(wNote);
        entry.endpoint = std::move(endpoint);
        outList.push_back(std::move(entry));
    }
    return true;
}

void RoomListClient::RegisterRoom(const std::wstring& roomName, uint16_t port, const std::wstring& note) {
    UnregisterRoom();

    std::string idCandidate;
    {
        std::lock_guard<std::mutex> guard(mutex_);
        if (!enabled_ || serverHost_.empty() || publicHost_.empty()) {
            return;
        }
    }

    std::string body = "name=" + UrlEncode(WideToUtf8(roomName));
    {
        std::lock_guard<std::mutex> guard(mutex_);
        body += "&host=" + UrlEncode(publicHost_);
    }
    body += "&port=" + UrlEncode(std::to_string(port));
    body += "&note=" + UrlEncode(WideToUtf8(note));

    int status = 0;
    std::string response;
    if (!SendRequest("POST", "/rooms/register", body, status, response)) {
        if (mainGame) {
            mainGame->ErrorLog("[room-list] failed to contact server on register");
        }
        return;
    }
    if (status != 200) {
        if (mainGame) {
            mainGame->ErrorLog("[room-list] server returned non-200 on register");
        }
        return;
    }
	std::string trimmed = response;
	if (trimmed.rfind("OK", 0) != 0) {
		if (mainGame) {
			mainGame->ErrorLog("[room-list] register error response");
		}
		return;
	}
	trimmed.erase(0, 2);
	while (!trimmed.empty() && std::isspace(static_cast<unsigned char>(trimmed.front()))) {
		trimmed.erase(trimmed.begin());
	}
	while (!trimmed.empty() && (trimmed.back() == '\n' || trimmed.back() == '\r')) {
		trimmed.pop_back();
	}
	if (trimmed.empty()) {
		if (mainGame) {
			mainGame->ErrorLog("[room-list] register missing id");
		}
		return;
	}

	{
		std::lock_guard<std::mutex> guard(mutex_);
		registeredId_ = std::move(trimmed);
	}
	StartHeartbeat();
}

void RoomListClient::UnregisterRoom() {
    std::string id;
    {
        std::lock_guard<std::mutex> guard(mutex_);
        id = registeredId_;
        registeredId_.clear();
    }

    StopHeartbeat();

    if (id.empty())
        return;

    std::string body = "id=" + UrlEncode(id);
    if (!SendPlainPost("/rooms/unregister", body)) {
        if (mainGame) {
            mainGame->ErrorLog("[room-list] failed to unregister room");
        }
    }
}

bool RoomListClient::SendPlainPost(const std::string& path, const std::string& body) {
    int status = 0;
    std::string response;
    if (!SendRequest("POST", path, body, status, response)) {
        return false;
    }
    return status == 200;
}

void RoomListClient::StartHeartbeat() {
    StopHeartbeat();
    heartbeatRunning_.store(true);
    heartbeatThread_ = std::thread(&RoomListClient::HeartbeatLoop, this);
}

void RoomListClient::StopHeartbeat() {
    bool expected = true;
    if (heartbeatRunning_.compare_exchange_strong(expected, false)) {
        if (heartbeatThread_.joinable()) {
            heartbeatThread_.join();
        }
    } else {
        heartbeatRunning_.store(false);
        if (heartbeatThread_.joinable()) {
            heartbeatThread_.join();
        }
    }
}

void RoomListClient::HeartbeatLoop() {
    while (heartbeatRunning_.load()) {
        std::this_thread::sleep_for(kHeartbeatInterval);
        if (!heartbeatRunning_.load())
            break;
        std::string id;
        {
            std::lock_guard<std::mutex> guard(mutex_);
            id = registeredId_;
        }
        if (id.empty())
            continue;
        std::string body = "id=" + UrlEncode(id);
        int status = 0;
        std::string response;
        if (!SendRequest("POST", "/rooms/heartbeat", body, status, response) || status != 200) {
            if (mainGame) {
                mainGame->ErrorLog("[room-list] heartbeat failed");
            }
        }
    }
}

bool RoomListClient::SendRequest(const std::string& method,
                                 const std::string& path,
                                 const std::string& body,
                                 int& statusCode,
                                 std::string& responseBody) {
    statusCode = 0;
    responseBody.clear();

    std::string host;
    std::string port;
    std::string hostHeader;
    {
        std::lock_guard<std::mutex> guard(mutex_);
        if (!enabled_ || serverHost_.empty()) {
            return false;
        }
        host = serverHost_;
        port = serverPort_;
        hostHeader = hostHeader_;
    }

    addrinfo hints{};
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    addrinfo* result = nullptr;
    int error = getaddrinfo(host.c_str(), port.c_str(), &hints, &result);
    if (error != 0 || !result) {
        return false;
    }

    int sockfd = -1;
    for (addrinfo* ptr = result; ptr != nullptr; ptr = ptr->ai_next) {
        sockfd = static_cast<int>(socket(ptr->ai_family, ptr->ai_socktype, ptr->ai_protocol));
        if (sockfd < 0)
            continue;
        if (connect(sockfd, ptr->ai_addr, static_cast<int>(ptr->ai_addrlen)) == 0) {
            break;
        }
#ifdef _WIN32
        closesocket(sockfd);
#else
        close(sockfd);
#endif
        sockfd = -1;
    }
    freeaddrinfo(result);
    if (sockfd < 0) {
        return false;
    }

    std::string request;
    request.reserve(256 + body.size());
    request.append(method);
    request.append(" ");
    request.append(path);
    request.append(" HTTP/1.1\r\n");
    request.append("Host: ");
    request.append(hostHeader);
    request.append("\r\n");
    request.append("Connection: close\r\n");
    if (!body.empty()) {
        request.append("Content-Type: application/x-www-form-urlencoded\r\n");
        request.append("Content-Length: ");
        request.append(std::to_string(body.size()));
        request.append("\r\n");
    }
    request.append("\r\n");
    request.append(body);

    size_t sent = 0;
    while (sent < request.size()) {
        int chunk = send(sockfd, request.data() + sent, static_cast<int>(request.size() - sent), 0);
        if (chunk <= 0) {
#ifdef _WIN32
            closesocket(sockfd);
#else
            close(sockfd);
#endif
            return false;
        }
        sent += static_cast<size_t>(chunk);
    }

    std::string raw;
    char buffer[1024];
    int received = 0;
    while ((received = recv(sockfd, buffer, sizeof(buffer), 0)) > 0) {
        raw.append(buffer, buffer + received);
    }

#ifdef _WIN32
    closesocket(sockfd);
#else
    close(sockfd);
#endif

    if (raw.empty()) {
        return false;
    }
    auto headerEnd = raw.find("\r\n\r\n");
    size_t bodyPos = std::string::npos;
    if (headerEnd != std::string::npos) {
        bodyPos = headerEnd + 4;
    } else {
        headerEnd = raw.find("\n\n");
        if (headerEnd != std::string::npos) {
            bodyPos = headerEnd + 2;
        }
    }
    if (bodyPos == std::string::npos) {
        return false;
    }

    std::string statusLine;
    auto lineEnd = raw.find("\r\n");
    if (lineEnd == std::string::npos)
        return false;
    statusLine = raw.substr(0, lineEnd);

    auto spacePos = statusLine.find(' ');
    if (spacePos == std::string::npos)
        return false;
    auto nextSpace = statusLine.find(' ', spacePos + 1);
    std::string codeStr;
    if (nextSpace == std::string::npos) {
        codeStr = statusLine.substr(spacePos + 1);
    } else {
        codeStr = statusLine.substr(spacePos + 1, nextSpace - spacePos - 1);
    }
    statusCode = std::atoi(codeStr.c_str());
    responseBody = raw.substr(bodyPos);
    return true;
}

std::string RoomListClient::WideToUtf8(const std::wstring& value) {
    if (value.empty())
        return {};
    std::vector<char> buffer(value.size() * 4 + 1);
    int written = BufferIO::EncodeUTF8String(value.c_str(), buffer.data(), buffer.size());
    if (written < 0)
        written = 0;
    return std::string(buffer.data(), static_cast<size_t>(written));
}

std::wstring RoomListClient::Utf8ToWide(const std::string& value) {
    if (value.empty())
        return {};
    std::vector<wchar_t> buffer(value.size() + 1);
    int written = BufferIO::DecodeUTF8String(value.c_str(), buffer.data(), buffer.size());
    if (written < 0)
        written = 0;
    return std::wstring(buffer.data(), static_cast<size_t>(written));
}

std::string RoomListClient::UrlEncode(const std::string& value) {
    std::string encoded;
    for (unsigned char c : value) {
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~') {
            encoded.push_back(static_cast<char>(c));
        } else if (c == ' ') {
            encoded.push_back('+');
        } else {
            constexpr char hex[] = "0123456789ABCDEF";
            encoded.push_back('%');
            encoded.push_back(hex[c >> 4]);
            encoded.push_back(hex[c & 0x0F]);
        }
    }
    return encoded;
}

std::string RoomListClient::TrimCopy(const std::string& value) {
    auto begin = value.begin();
    auto end = value.end();
    while (begin != end && std::isspace(static_cast<unsigned char>(*begin))) {
        ++begin;
    }
    while (end != begin && std::isspace(static_cast<unsigned char>(*(end - 1)))) {
        --end;
    }
    return std::string(begin, end);
}

} // namespace ygo
