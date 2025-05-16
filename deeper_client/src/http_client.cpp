#include "../include/http_client.h"
#include <windows.h>
#include <winhttp.h>
#include <iostream>
#include <sstream>

#pragma comment(lib, "winhttp.lib")

// Função auxiliar para converter string para wstring
std::wstring stringToWideString(const std::string& str) {
    if (str.empty()) return L"";
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}

// Função para buscar JSON de uma URL usando WinHTTP
bool fetchAndParseJson(const std::string& url, nlohmann::json& result) {
    std::wstring wideUrl = stringToWideString(url);

    // Inicializa a sessão WinHTTP
    HINTERNET hSession = WinHttpOpen(
        L"DeeperClient/1.0",
        WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME,
        WINHTTP_NO_PROXY_BYPASS, 0);

    if (!hSession) {
        std::cerr << "Erro ao inicializar WinHTTP: " << GetLastError() << std::endl;
        return false;
    }

    // Configura a conexão
    URL_COMPONENTS urlComp = { 0 };
    wchar_t hostName[256] = { 0 };
    wchar_t urlPath[2048] = { 0 };

    // Inicializa a estrutura URL_COMPONENTS
    urlComp.dwStructSize = sizeof(urlComp);
    urlComp.lpszHostName = hostName;
    urlComp.dwHostNameLength = ARRAYSIZE(hostName);
    urlComp.lpszUrlPath = urlPath;
    urlComp.dwUrlPathLength = ARRAYSIZE(urlPath);
    urlComp.dwSchemeLength = 1;  // Necessário para análise correta

    // Analisa a URL
    if (!WinHttpCrackUrl(wideUrl.c_str(), 0, 0, &urlComp)) {
        std::cerr << "Erro ao analisar a URL: " << GetLastError() << std::endl;
        WinHttpCloseHandle(hSession);
        return false;
    }

    // Conecta ao servidor
    HINTERNET hConnect = WinHttpConnect(
        hSession,
        hostName,
        (urlComp.nPort == 0) ? 
            (urlComp.nScheme == INTERNET_SCHEME_HTTPS ? INTERNET_DEFAULT_HTTPS_PORT : INTERNET_DEFAULT_HTTP_PORT) :
            urlComp.nPort,
        0);

    if (!hConnect) {
        std::cerr << "Erro ao conectar ao servidor: " << GetLastError() << std::endl;
        WinHttpCloseHandle(hSession);
        return false;
    }

    // Abre a requisição
    DWORD flags = WINHTTP_FLAG_REFRESH | 
                 (urlComp.nScheme == INTERNET_SCHEME_HTTPS ? WINHTTP_FLAG_SECURE : 0);

    HINTERNET hRequest = WinHttpOpenRequest(
        hConnect,
        L"GET",
        urlPath,
        NULL,
        WINHTTP_NO_REFERER,
        WINHTTP_DEFAULT_ACCEPT_TYPES,
        flags);

    if (!hRequest) {
        std::cerr << "Erro ao criar requisição: " << GetLastError() << std::endl;
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return false;
    }

    // Envia a requisição
    if (!WinHttpSendRequest(
        hRequest,
        WINHTTP_NO_ADDITIONAL_HEADERS, 0,
        WINHTTP_NO_REQUEST_DATA, 0, 0, 0)) {
        std::cerr << "Erro ao enviar requisição: " << GetLastError() << std::endl;
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return false;
    }

    // Recebe a resposta
    if (!WinHttpReceiveResponse(hRequest, NULL)) {
        std::cerr << "Erro ao receber resposta: " << GetLastError() << std::endl;
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return false;
    }

    // Lê os dados da resposta
    std::string response;
    DWORD bytesRead = 0;
    DWORD totalBytesRead = 0;
    char buffer[4096] = { 0 };

    do {
        if (!WinHttpReadData(hRequest, buffer, sizeof(buffer) - 1, &bytesRead)) {
            std::cerr << "Erro ao ler dados da resposta: " << GetLastError() << std::endl;
            break;
        } else if (bytesRead == 0) {
            break;
        }
        buffer[bytesRead] = 0;
        response.append(buffer, bytesRead);
        totalBytesRead += bytesRead;
    } while (bytesRead > 0);

    // Limpa os recursos
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);

    // Verifica se recebemos dados
    if (response.empty()) {
        std::cerr << "Nenhum dado recebido do servidor" << std::endl;
        return false;
    }

    // Tenta fazer o parse do JSON
    try {
        result = nlohmann::json::parse(response);
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Erro ao fazer parse do JSON: " << e.what() << std::endl;
        return false;
    }
} 