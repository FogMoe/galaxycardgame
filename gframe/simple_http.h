#ifndef SIMPLE_HTTP_H
#define SIMPLE_HTTP_H

#include "config.h"
#include <string>
#include <map>
#include <sstream>

namespace ygo {

// 简单的HTTP客户端，使用系统socket实现
class SimpleHttpClient {
public:
    struct HttpResponse {
        int status_code;
        std::map<std::string, std::string> headers;
        std::string body;
        bool success;

        HttpResponse() : status_code(0), success(false) {}
    };

    static HttpResponse Get(const std::string& url);
    static HttpResponse Post(const std::string& url, const std::string& data,
                            const std::map<std::string, std::string>& headers = {});

private:
    struct UrlParts {
        std::string protocol;
        std::string host;
        int port;
        std::string path;
    };

    static UrlParts ParseUrl(const std::string& url);
    static SOCKET ConnectToHost(const std::string& host, int port);
    static std::string BuildHttpRequest(const std::string& method, const std::string& path,
                                       const std::string& host, const std::string& data = "",
                                       const std::map<std::string, std::string>& headers = {});
    static HttpResponse ParseHttpResponse(const std::string& response_data);
    static std::string SendRequest(SOCKET sock, const std::string& request);
};

// JSON 简单解析器（仅支持基本功能）
class SimpleJson {
public:
    enum JsonType {
        JSON_NULL = 0,
        JSON_BOOL = 1,
        JSON_NUMBER = 2,
        JSON_STRING = 3,
        JSON_ARRAY = 4,
        JSON_OBJECT = 5
    };

    SimpleJson() : type_(JSON_NULL) {}
    SimpleJson(bool value) : type_(JSON_BOOL), bool_value_(value) {}
    SimpleJson(double value) : type_(JSON_NUMBER), number_value_(value) {}
    SimpleJson(const std::string& value) : type_(JSON_STRING), string_value_(value) {}

    static SimpleJson Parse(const std::string& json_str);
    std::string Stringify() const;

    JsonType GetType() const { return type_; }
    bool AsBool() const { return bool_value_; }
    double AsNumber() const { return number_value_; }
    std::string AsString() const { return string_value_; }

    // 对象操作
    SimpleJson& operator[](const std::string& key);
    const SimpleJson& operator[](const std::string& key) const;
    bool HasKey(const std::string& key) const;

    // 数组操作
    void PushBack(const SimpleJson& value);
    size_t Size() const;
    SimpleJson& operator[](size_t index);
    const SimpleJson& operator[](size_t index) const;

private:
    JsonType type_;
    bool bool_value_ = false;
    double number_value_ = 0.0;
    std::string string_value_;
    std::map<std::string, SimpleJson> object_value_;
    std::vector<SimpleJson> array_value_;

    static SimpleJson ParseValue(const std::string& str, size_t& pos);
    static SimpleJson ParseObject(const std::string& str, size_t& pos);
    static SimpleJson ParseArray(const std::string& str, size_t& pos);
    static SimpleJson ParseString(const std::string& str, size_t& pos);
    static SimpleJson ParseNumber(const std::string& str, size_t& pos);
    static void SkipWhitespace(const std::string& str, size_t& pos);
};

} // namespace ygo

#endif // SIMPLE_HTTP_H