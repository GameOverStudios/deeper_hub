#include "../include/websocket_client.h"
#include <iostream>
#include <sstream>
#include <vector>

#pragma comment(lib, "winhttp.lib")

WebSocketClient::WebSocketClient() 
    : m_hSession(NULL), m_hConnection(NULL), m_hRequest(NULL), m_hWebSocket(NULL), m_connected(false) {
}

WebSocketClient::~WebSocketClient() {
    close();
}

bool WebSocketClient::connect(const std::string& host, int port) {
    std::wstring wideHost = stringToWideString(host);
    
    // Inicializa a sessão WinHTTP
    m_hSession = WinHttpOpen(
        L"DeeperClient/1.0",
        WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME,
        WINHTTP_NO_PROXY_BYPASS, 0);

    if (!m_hSession) {
        std::cerr << "Erro ao inicializar WinHTTP: " << GetLastError() << std::endl;
        return false;
    }

    // Conecta ao servidor
    m_hConnection = WinHttpConnect(
        m_hSession,
        wideHost.c_str(),
        port,
        0);

    if (!m_hConnection) {
        std::cerr << "Erro ao conectar ao servidor: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_hSession);
        m_hSession = NULL;
        return false;
    }

    // Abre a requisição para upgrade para WebSocket
    m_hRequest = WinHttpOpenRequest(
        m_hConnection,
        L"GET",
        L"/socket/websocket",  // Caminho correto para o endpoint WebSocket do DeeperHub
        NULL,
        WINHTTP_NO_REFERER,
        WINHTTP_DEFAULT_ACCEPT_TYPES,
        0);  // Sem WINHTTP_FLAG_SECURE para conexão local

    if (!m_hRequest) {
        std::cerr << "Erro ao criar requisição: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }

    // Adiciona os cabeçalhos para upgrade para WebSocket
    // Adiciona todos os cabeçalhos necessários em uma única string para garantir a ordem correta
    std::wstring headers = L"Connection: Upgrade\r\n"
                          L"Upgrade: websocket\r\n"
                          L"Sec-WebSocket-Version: 13\r\n"
                          L"Sec-WebSocket-Protocol: phoenix-v1\r\n"; // Protocolo Phoenix usado pelo Elixir

    if (!WinHttpAddRequestHeaders(
        m_hRequest,
        headers.c_str(),
        -1,
        WINHTTP_ADDREQ_FLAG_ADD | WINHTTP_ADDREQ_FLAG_REPLACE)) {
        std::cerr << "Erro ao adicionar cabeçalhos WebSocket: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }

    // Gera uma chave aleatória para o handshake
    std::wstring key = L"dGhlIHNhbXBsZSBub25jZQ=="; // Valor fixo para simplificar

    std::wstring keyHeader = L"Sec-WebSocket-Key: " + key;
    if (!WinHttpAddRequestHeaders(
        m_hRequest,
        keyHeader.c_str(),
        -1,
        WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho Sec-WebSocket-Key: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }

    // Envia a requisição
    if (!WinHttpSendRequest(
        m_hRequest,
        WINHTTP_NO_ADDITIONAL_HEADERS, 0,
        WINHTTP_NO_REQUEST_DATA, 0, 0, 0)) {
        std::cerr << "Erro ao enviar requisição: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }

    // Recebe a resposta
    if (!WinHttpReceiveResponse(m_hRequest, NULL)) {
        std::cerr << "Erro ao receber resposta: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }

    // Verifica o código de status
    DWORD statusCode = 0;
    DWORD statusCodeSize = sizeof(statusCode);
    if (!WinHttpQueryHeaders(
        m_hRequest,
        WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
        WINHTTP_HEADER_NAME_BY_INDEX,
        &statusCode,
        &statusCodeSize,
        WINHTTP_NO_HEADER_INDEX)) {
        std::cerr << "Erro ao obter código de status: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }

    if (statusCode != 101) {
        std::cerr << "Erro: código de status não é 101 (Switching Protocols): " << statusCode << std::endl;
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }

    // Cria o WebSocket
    m_hWebSocket = WinHttpWebSocketCompleteUpgrade(m_hRequest, 0);
    if (!m_hWebSocket) {
        std::cerr << "Erro ao completar upgrade para WebSocket: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }

    // Fecha o handle da requisição, não é mais necessário
    WinHttpCloseHandle(m_hRequest);
    m_hRequest = NULL;

    m_connected = true;
    std::cout << "Conexão WebSocket estabelecida com sucesso!" << std::endl;
    return true;
}

bool WebSocketClient::sendTextMessage(const nlohmann::json& jsonMessage) {
    if (!m_connected) {
        std::cerr << "Erro: não está conectado ao servidor WebSocket" << std::endl;
        return false;
    }

    std::string message = jsonMessage.dump();
    DWORD result = WinHttpWebSocketSend(
        m_hWebSocket,
        WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
        (PVOID)message.c_str(),
        message.length());

    if (result != ERROR_SUCCESS) {
        std::cerr << "Erro ao enviar mensagem WebSocket: " << result << std::endl;
        return false;
    }

    std::cout << "Mensagem enviada: " << message << std::endl;
    return true;
}

bool WebSocketClient::sendBinaryMessage(const std::vector<uint8_t>& data) {
    if (!m_connected) {
        std::cerr << "Erro: não está conectado ao servidor WebSocket" << std::endl;
        return false;
    }

    DWORD result = WinHttpWebSocketSend(
        m_hWebSocket,
        WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE,
        (PVOID)data.data(),
        data.size());

    if (result != ERROR_SUCCESS) {
        std::cerr << "Erro ao enviar mensagem binária WebSocket: " << result << std::endl;
        return false;
    }

    std::cout << "Mensagem binária enviada: " << data.size() << " bytes" << std::endl;
    return true;
}

bool WebSocketClient::receiveMessage(std::string& message) {
    if (!m_connected) {
        std::cerr << "Erro: não está conectado ao servidor WebSocket" << std::endl;
        return false;
    }

    const int bufferSize = 4096;
    char buffer[bufferSize];
    BYTE* pbBuffer = (BYTE*)buffer;
    DWORD dwBufferLength = bufferSize - 1;
    DWORD dwBytesTransferred = 0;
    WINHTTP_WEB_SOCKET_BUFFER_TYPE eBufferType;

    DWORD result = WinHttpWebSocketReceive(
        m_hWebSocket,
        pbBuffer,
        dwBufferLength,
        &dwBytesTransferred,
        &eBufferType);

    if (result != ERROR_SUCCESS) {
        std::cerr << "Erro ao receber mensagem WebSocket: " << result << std::endl;
        return false;
    }

    // Garante que a string seja terminada em nulo
    buffer[dwBytesTransferred] = '\0';

    if (eBufferType == WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE) {
        message = std::string(buffer, dwBytesTransferred);
        std::cout << "Mensagem recebida: " << message << std::endl;
    } else if (eBufferType == WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE) {
        std::stringstream ss;
        ss << "Mensagem binária recebida: " << dwBytesTransferred << " bytes";
        message = ss.str();
        std::cout << message << std::endl;
    } else if (eBufferType == WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE) {
        std::cout << "Conexão fechada pelo servidor" << std::endl;
        m_connected = false;
        return false;
    }

    return true;
}

void WebSocketClient::close() {
    if (m_connected && m_hWebSocket) {
        WinHttpWebSocketClose(
            m_hWebSocket,
            WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS,
            NULL,
            0);
        m_connected = false;
    }

    if (m_hWebSocket) {
        WinHttpCloseHandle(m_hWebSocket);
        m_hWebSocket = NULL;
    }

    if (m_hRequest) {
        WinHttpCloseHandle(m_hRequest);
        m_hRequest = NULL;
    }

    if (m_hConnection) {
        WinHttpCloseHandle(m_hConnection);
        m_hConnection = NULL;
    }

    if (m_hSession) {
        WinHttpCloseHandle(m_hSession);
        m_hSession = NULL;
    }
}

bool WebSocketClient::isConnected() const {
    return m_connected;
}

std::wstring WebSocketClient::stringToWideString(const std::string& str) {
    if (str.empty()) return L"";
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}
