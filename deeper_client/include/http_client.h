#ifndef DEEPER_CLIENT_HTTP_CLIENT_H
#define DEEPER_CLIENT_HTTP_CLIENT_H

#include <string>
#include <nlohmann/json.hpp>

bool fetchAndParseJson(const std::string& url, nlohmann::json& result);

#endif // DEEPER_CLIENT_HTTP_CLIENT_H 