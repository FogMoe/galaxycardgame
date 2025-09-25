#include "simple_http.h"
#include <sstream>
#include <algorithm>
#include <cstring>

namespace ygo {

// ========== HTTP 客户端实现 ==========

SimpleHttpClient::HttpResponse SimpleHttpClient::Get(const std::string& url) {
    HttpResponse response;

    UrlParts parts = ParseUrl(url);
    if (parts.host.empty()) {
        return response;
    }

    SOCKET sock = ConnectToHost(parts.host, parts.port);
    if (sock == INVALID_SOCKET) {
        return response;
    }

    std::string request = BuildHttpRequest("GET", parts.path, parts.host);
    std::string response_data = SendRequest(sock, request);

    closesocket(sock);

    if (!response_data.empty()) {
        response = ParseHttpResponse(response_data);
    }

    return response;
}

SimpleHttpClient::HttpResponse SimpleHttpClient::Post(const std::string& url, const std::string& data,
                                                      const std::map<std::string, std::string>& headers) {
    HttpResponse response;

    UrlParts parts = ParseUrl(url);
    if (parts.host.empty()) {
        return response;
    }

    SOCKET sock = ConnectToHost(parts.host, parts.port);
    if (sock == INVALID_SOCKET) {
        return response;
    }

    std::string request = BuildHttpRequest("POST", parts.path, parts.host, data, headers);
    std::string response_data = SendRequest(sock, request);

    closesocket(sock);

    if (!response_data.empty()) {
        response = ParseHttpResponse(response_data);
    }

    return response;
}

SimpleHttpClient::UrlParts SimpleHttpClient::ParseUrl(const std::string& url) {
    UrlParts parts;

    // 简单的URL解析
    size_t pos = 0;

    // 协议
    size_t protocol_end = url.find("://", pos);
    if (protocol_end == std::string::npos) {
        return parts; // 无效URL
    }

    parts.protocol = url.substr(pos, protocol_end);
    pos = protocol_end + 3;

    // 主机和端口
    size_t path_start = url.find('/', pos);
    if (path_start == std::string::npos) {
        path_start = url.length();
    }

    std::string host_port = url.substr(pos, path_start - pos);
    size_t port_pos = host_port.find(':');

    if (port_pos != std::string::npos) {
        parts.host = host_port.substr(0, port_pos);
        parts.port = std::stoi(host_port.substr(port_pos + 1));
    } else {
        parts.host = host_port;
        parts.port = (parts.protocol == "https") ? 443 : 80;
    }

    // 路径
    if (path_start < url.length()) {
        parts.path = url.substr(path_start);
    } else {
        parts.path = "/";
    }

    return parts;
}

SOCKET SimpleHttpClient::ConnectToHost(const std::string& host, int port) {
    SOCKET sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock == INVALID_SOCKET) {
        return INVALID_SOCKET;
    }

    // 设置超时
    struct timeval timeout;
    timeout.tv_sec = 10;
    timeout.tv_usec = 0;

#ifdef _WIN32
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char*)&timeout, sizeof(timeout));
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (const char*)&timeout, sizeof(timeout));
#else
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
#endif

    // 解析主机名
    struct hostent* host_entry = gethostbyname(host.c_str());
    if (!host_entry) {
        closesocket(sock);
        return INVALID_SOCKET;
    }

    // 连接
    sockaddr_in server_addr;
    std::memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    std::memcpy(&server_addr.sin_addr, host_entry->h_addr, host_entry->h_length);

    if (connect(sock, (sockaddr*)&server_addr, sizeof(server_addr)) == SOCKET_ERROR) {
        closesocket(sock);
        return INVALID_SOCKET;
    }

    return sock;
}

std::string SimpleHttpClient::BuildHttpRequest(const std::string& method, const std::string& path,
                                               const std::string& host, const std::string& data,
                                               const std::map<std::string, std::string>& headers) {
    std::ostringstream request;

    request << method << " " << path << " HTTP/1.1\r\n";
    request << "Host: " << host << "\r\n";
    request << "User-Agent: Galaxy-Card-Game/1.0\r\n";
    request << "Connection: close\r\n";

    if (!data.empty()) {
        request << "Content-Length: " << data.length() << "\r\n";
        if (headers.find("Content-Type") == headers.end()) {
            request << "Content-Type: application/json\r\n";
        }
    }

    for (const auto& header : headers) {
        request << header.first << ": " << header.second << "\r\n";
    }

    request << "\r\n";

    if (!data.empty()) {
        request << data;
    }

    return request.str();
}

SimpleHttpClient::HttpResponse SimpleHttpClient::ParseHttpResponse(const std::string& response_data) {
    HttpResponse response;

    size_t header_end = response_data.find("\r\n\r\n");
    if (header_end == std::string::npos) {
        return response;
    }

    std::string header_part = response_data.substr(0, header_end);
    std::string body_part = response_data.substr(header_end + 4);

    // 解析状态行
    std::istringstream header_stream(header_part);
    std::string line;
    if (std::getline(header_stream, line)) {
        std::istringstream status_stream(line);
        std::string http_version;
        status_stream >> http_version >> response.status_code;
    }

    // 解析头部
    while (std::getline(header_stream, line)) {
        if (line.empty() || line == "\r") break;

        size_t colon_pos = line.find(':');
        if (colon_pos != std::string::npos) {
            std::string key = line.substr(0, colon_pos);
            std::string value = line.substr(colon_pos + 1);

            // 去除前后空格
            key.erase(0, key.find_first_not_of(" \t\r"));
            key.erase(key.find_last_not_of(" \t\r") + 1);
            value.erase(0, value.find_first_not_of(" \t\r"));
            value.erase(value.find_last_not_of(" \t\r") + 1);

            response.headers[key] = value;
        }
    }

    response.body = body_part;
    response.success = (response.status_code >= 200 && response.status_code < 300);

    return response;
}

std::string SimpleHttpClient::SendRequest(SOCKET sock, const std::string& request) {
    // 发送请求
    int total_sent = 0;
    const char* data = request.c_str();
    int data_len = request.length();

    while (total_sent < data_len) {
        int sent = send(sock, data + total_sent, data_len - total_sent, 0);
        if (sent == SOCKET_ERROR) {
            return "";
        }
        total_sent += sent;
    }

    // 接收响应
    std::string response;
    char buffer[4096];

    while (true) {
        int received = recv(sock, buffer, sizeof(buffer) - 1, 0);
        if (received <= 0) {
            break;
        }

        buffer[received] = '\0';
        response.append(buffer, received);

        // 简单检查是否收到完整响应
        if (response.find("\r\n\r\n") != std::string::npos) {
            // 检查Content-Length
            size_t content_length_pos = response.find("Content-Length:");
            if (content_length_pos != std::string::npos) {
                std::string length_line = response.substr(content_length_pos);
                size_t line_end = length_line.find("\r\n");
                if (line_end != std::string::npos) {
                    length_line = length_line.substr(15, line_end - 15); // 15 = length of "Content-Length:"
                    length_line.erase(0, length_line.find_first_not_of(" \t"));

                    int content_length = std::stoi(length_line);
                    size_t header_end = response.find("\r\n\r\n");
                    if (response.length() >= header_end + 4 + content_length) {
                        break;
                    }
                }
            } else {
                // 没有Content-Length，继续读取直到连接关闭
            }
        }
    }

    return response;
}

// ========== JSON 解析器实现 ==========

SimpleJson SimpleJson::Parse(const std::string& json_str) {
    size_t pos = 0;
    return ParseValue(json_str, pos);
}

std::string SimpleJson::Stringify() const {
    std::ostringstream ss;

    switch (type_) {
        case JSON_NULL:
            ss << "null";
            break;
        case JSON_BOOL:
            ss << (bool_value_ ? "true" : "false");
            break;
        case JSON_NUMBER:
            ss << number_value_;
            break;
        case JSON_STRING:
            ss << "\"" << string_value_ << "\"";
            break;
        case JSON_ARRAY:
            ss << "[";
            for (size_t i = 0; i < array_value_.size(); ++i) {
                if (i > 0) ss << ",";
                ss << array_value_[i].Stringify();
            }
            ss << "]";
            break;
        case JSON_OBJECT:
            ss << "{";
            bool first = true;
            for (const auto& pair : object_value_) {
                if (!first) ss << ",";
                ss << "\"" << pair.first << "\":" << pair.second.Stringify();
                first = false;
            }
            ss << "}";
            break;
    }

    return ss.str();
}

SimpleJson& SimpleJson::operator[](const std::string& key) {
    if (type_ != JSON_OBJECT) {
        type_ = JSON_OBJECT;
        object_value_.clear();
    }
    return object_value_[key];
}

const SimpleJson& SimpleJson::operator[](const std::string& key) const {
    static SimpleJson null_json;
    if (type_ != JSON_OBJECT) return null_json;
    auto it = object_value_.find(key);
    return (it != object_value_.end()) ? it->second : null_json;
}

bool SimpleJson::HasKey(const std::string& key) const {
    if (type_ != JSON_OBJECT) return false;
    return object_value_.find(key) != object_value_.end();
}

void SimpleJson::PushBack(const SimpleJson& value) {
    if (type_ != JSON_ARRAY) {
        type_ = JSON_ARRAY;
        array_value_.clear();
    }
    array_value_.push_back(value);
}

size_t SimpleJson::Size() const {
    if (type_ == JSON_ARRAY) return array_value_.size();
    if (type_ == JSON_OBJECT) return object_value_.size();
    return 0;
}

SimpleJson& SimpleJson::operator[](size_t index) {
    if (type_ != JSON_ARRAY) {
        type_ = JSON_ARRAY;
        array_value_.clear();
    }
    if (index >= array_value_.size()) {
        array_value_.resize(index + 1);
    }
    return array_value_[index];
}

const SimpleJson& SimpleJson::operator[](size_t index) const {
    static SimpleJson null_json;
    if (type_ != JSON_ARRAY || index >= array_value_.size()) {
        return null_json;
    }
    return array_value_[index];
}

SimpleJson SimpleJson::ParseValue(const std::string& str, size_t& pos) {
    SkipWhitespace(str, pos);

    if (pos >= str.length()) return SimpleJson();

    char c = str[pos];

    if (c == '{') {
        return ParseObject(str, pos);
    } else if (c == '[') {
        return ParseArray(str, pos);
    } else if (c == '"') {
        return ParseString(str, pos);
    } else if (c == 't' || c == 'f') {
        // Boolean
        if (str.substr(pos, 4) == "true") {
            pos += 4;
            return SimpleJson(true);
        } else if (str.substr(pos, 5) == "false") {
            pos += 5;
            return SimpleJson(false);
        }
    } else if (c == 'n') {
        // Null
        if (str.substr(pos, 4) == "null") {
            pos += 4;
            return SimpleJson();
        }
    } else if (c == '-' || (c >= '0' && c <= '9')) {
        return ParseNumber(str, pos);
    }

    return SimpleJson();
}

SimpleJson SimpleJson::ParseObject(const std::string& str, size_t& pos) {
    SimpleJson obj;
    obj.type_ = JSON_OBJECT;

    ++pos; // skip '{'
    SkipWhitespace(str, pos);

    if (pos < str.length() && str[pos] == '}') {
        ++pos;
        return obj;
    }

    while (pos < str.length()) {
        SkipWhitespace(str, pos);

        if (str[pos] != '"') break;

        SimpleJson key = ParseString(str, pos);
        SkipWhitespace(str, pos);

        if (pos >= str.length() || str[pos] != ':') break;
        ++pos; // skip ':'

        SimpleJson value = ParseValue(str, pos);
        obj.object_value_[key.AsString()] = value;

        SkipWhitespace(str, pos);
        if (pos >= str.length()) break;

        if (str[pos] == '}') {
            ++pos;
            break;
        } else if (str[pos] == ',') {
            ++pos;
        } else {
            break;
        }
    }

    return obj;
}

SimpleJson SimpleJson::ParseArray(const std::string& str, size_t& pos) {
    SimpleJson arr;
    arr.type_ = JSON_ARRAY;

    ++pos; // skip '['
    SkipWhitespace(str, pos);

    if (pos < str.length() && str[pos] == ']') {
        ++pos;
        return arr;
    }

    while (pos < str.length()) {
        SimpleJson value = ParseValue(str, pos);
        arr.array_value_.push_back(value);

        SkipWhitespace(str, pos);
        if (pos >= str.length()) break;

        if (str[pos] == ']') {
            ++pos;
            break;
        } else if (str[pos] == ',') {
            ++pos;
            SkipWhitespace(str, pos);
        } else {
            break;
        }
    }

    return arr;
}

SimpleJson SimpleJson::ParseString(const std::string& str, size_t& pos) {
    ++pos; // skip opening '"'

    std::string result;
    while (pos < str.length() && str[pos] != '"') {
        if (str[pos] == '\\' && pos + 1 < str.length()) {
            ++pos;
            switch (str[pos]) {
                case '"': result += '"'; break;
                case '\\': result += '\\'; break;
                case '/': result += '/'; break;
                case 'b': result += '\b'; break;
                case 'f': result += '\f'; break;
                case 'n': result += '\n'; break;
                case 'r': result += '\r'; break;
                case 't': result += '\t'; break;
                default: result += str[pos]; break;
            }
        } else {
            result += str[pos];
        }
        ++pos;
    }

    if (pos < str.length()) ++pos; // skip closing '"'

    return SimpleJson(result);
}

SimpleJson SimpleJson::ParseNumber(const std::string& str, size_t& pos) {
    size_t start = pos;

    if (str[pos] == '-') ++pos;

    while (pos < str.length() && str[pos] >= '0' && str[pos] <= '9') {
        ++pos;
    }

    if (pos < str.length() && str[pos] == '.') {
        ++pos;
        while (pos < str.length() && str[pos] >= '0' && str[pos] <= '9') {
            ++pos;
        }
    }

    std::string number_str = str.substr(start, pos - start);
    double value = std::stod(number_str);

    return SimpleJson(value);
}

void SimpleJson::SkipWhitespace(const std::string& str, size_t& pos) {
    while (pos < str.length() && (str[pos] == ' ' || str[pos] == '\t' ||
                                  str[pos] == '\n' || str[pos] == '\r')) {
        ++pos;
    }
}

} // namespace ygo