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

    // Configura o timeout para operações WinHTTP (30 segundos)
    DWORD timeout = 30000; // 30 segundos
    WinHttpSetOption(m_hSession, WINHTTP_OPTION_CONNECT_TIMEOUT, &timeout, sizeof(timeout));
    WinHttpSetOption(m_hSession, WINHTTP_OPTION_SEND_TIMEOUT, &timeout, sizeof(timeout));
    WinHttpSetOption(m_hSession, WINHTTP_OPTION_RECEIVE_TIMEOUT, &timeout, sizeof(timeout));

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

    // Usamos o caminho específico para o Phoenix Framework
    std::wstring path = L"/socket/websocket";
    
    std::cout << "Conectando ao caminho: " << std::string(path.begin(), path.end()) << std::endl;
    
    // Abre a requisição para upgrade para WebSocket
    m_hRequest = WinHttpOpenRequest(
        m_hConnection,
        L"GET",
        path.c_str(),
        NULL,  // Usando NULL em vez de HTTP/1.1
        WINHTTP_NO_REFERER,
        WINHTTP_DEFAULT_ACCEPT_TYPES,
        0);  // Sem WINHTTP_FLAG_SECURE para conexão local
        
    // IMPORTANTE: Desativa o Keep-Alive que o WinHTTP adiciona por padrão
    // Isso é crucial porque o servidor Elixir espera "Connection: Upgrade"
    BOOL disable_keep_alive = TRUE;
    if (!WinHttpSetOption(m_hRequest, WINHTTP_OPTION_DISABLE_FEATURE, 
                         &disable_keep_alive, sizeof(disable_keep_alive))) {
        std::cerr << "Erro ao desativar Keep-Alive: " << GetLastError() << std::endl;
    }

    if (!m_hRequest) {
        DWORD error = GetLastError();
        std::cerr << "Erro ao criar requisição: " << error << std::endl;
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }
    
    // Adiciona cada cabeçalho individualmente para garantir que sejam enviados corretamente
    // IMPORTANTE: O Elixir espera os nomes dos cabeçalhos em minúsculas, mas o WinHTTP pode normalizá-los
    // Vamos tentar diferentes formatos para garantir que pelo menos um funcione
    
    // IMPORTANTE: O servidor Elixir verifica se o cabeçalho Connection contém a palavra "upgrade"
    // Vamos forçar este cabeçalho com WINHTTP_ADDREQ_FLAG_REPLACE para garantir que substitua o Keep-Alive
    if (!WinHttpAddRequestHeaders(m_hRequest, L"Connection: Upgrade", -1, WINHTTP_ADDREQ_FLAG_REPLACE)) {
        std::cerr << "Erro ao adicionar cabeçalho Connection: " << GetLastError() << std::endl;
    }
    
    // Também em minúsculas para garantir
    if (!WinHttpAddRequestHeaders(m_hRequest, L"connection: upgrade", -1, WINHTTP_ADDREQ_FLAG_REPLACE)) {
        std::cerr << "Erro ao adicionar cabeçalho connection: " << GetLastError() << std::endl;
    }
    
    // O cabeçalho Upgrade também é verificado pelo servidor
    if (!WinHttpAddRequestHeaders(m_hRequest, L"Upgrade: websocket", -1, WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho Upgrade: " << GetLastError() << std::endl;
    }
    
    // Também em minúsculas
    if (!WinHttpAddRequestHeaders(m_hRequest, L"upgrade: websocket", -1, WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho upgrade: " << GetLastError() << std::endl;
    }
    
    // Headers WebSocket específicos
    if (!WinHttpAddRequestHeaders(m_hRequest, L"Sec-WebSocket-Version: 13", -1, WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho Sec-WebSocket-Version: " << GetLastError() << std::endl;
    }
    
    // Também em minúsculas
    if (!WinHttpAddRequestHeaders(m_hRequest, L"sec-websocket-version: 13", -1, WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho sec-websocket-version: " << GetLastError() << std::endl;
    }
    
    // O protocolo deve ser exatamente como o servidor espera
    if (!WinHttpAddRequestHeaders(m_hRequest, L"Sec-WebSocket-Protocol: phoenix-v1", -1, WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho Sec-WebSocket-Protocol: " << GetLastError() << std::endl;
    }
    
    // Também em minúsculas
    if (!WinHttpAddRequestHeaders(m_hRequest, L"sec-websocket-protocol: phoenix-v1", -1, WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho sec-websocket-protocol: " << GetLastError() << std::endl;
    }
    
    // Adiciona o Host e Origin para ajudar no roteamento
    std::wstring hostHeader = L"Host: " + wideHost + L":" + std::to_wstring(port);
    if (!WinHttpAddRequestHeaders(m_hRequest, hostHeader.c_str(), -1, WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho Host: " << GetLastError() << std::endl;
    }
    
    std::wstring originHeader = L"Origin: http://" + wideHost + L":" + std::to_wstring(port);
    if (!WinHttpAddRequestHeaders(m_hRequest, originHeader.c_str(), -1, WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho Origin: " << GetLastError() << std::endl;
    }

    // Adicionamos os cabeçalhos individualmente acima

    // Usa a mesma chave que funcionou no teste com curl
    // Esta chave é válida conforme RFC 6455 (base64 de 16 bytes)
    std::wstring key = L"dGhlIHNhbXBsZSBub25jZQ=="; // "the sample nonce" em base64

    // Adiciona o cabeçalho Sec-WebSocket-Key que é OBRIGATÓRIO para o handshake
    // O servidor verifica explicitamente a presença deste cabeçalho
    // Tentamos com diferentes formatos de nome de cabeçalho para garantir que funcione
    
    // Formato 1: Padrão com primeira letra maiúscula
    std::wstring keyHeader = L"Sec-WebSocket-Key: " + key;
    if (!WinHttpAddRequestHeaders(
        m_hRequest,
        keyHeader.c_str(),
        -1,
        WINHTTP_ADDREQ_FLAG_ADD)) {
        DWORD error = GetLastError();
        std::cerr << "Erro ao adicionar cabeçalho Sec-WebSocket-Key: " << error << std::endl;
    }
    
    // Formato 2: Tudo em minúsculas (como o Elixir espera)
    std::wstring keyHeaderLower = L"sec-websocket-key: " + key;
    if (!WinHttpAddRequestHeaders(
        m_hRequest,
        keyHeaderLower.c_str(),
        -1,
        WINHTTP_ADDREQ_FLAG_ADD)) {
        DWORD error = GetLastError();
        std::cerr << "Erro ao adicionar cabeçalho sec-websocket-key: " << error << std::endl;
    }

    // Envia a requisição
    if (!WinHttpSendRequest(
        m_hRequest,
        WINHTTP_NO_ADDITIONAL_HEADERS, 0,
        WINHTTP_NO_REQUEST_DATA, 0, 0, 0)) {
        DWORD error = GetLastError();
        std::cerr << "Erro ao enviar requisição: " << error << std::endl;
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
        DWORD error = GetLastError();
        std::cerr << "Erro ao receber resposta: " << error << std::endl;
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }
    
    // Verifica o status da resposta
    DWORD statusCode = 0;
    DWORD statusCodeSize = sizeof(DWORD);
    if (WinHttpQueryHeaders(m_hRequest,
                            WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                            WINHTTP_HEADER_NAME_BY_INDEX,
                            &statusCode,
                            &statusCodeSize,
                            WINHTTP_NO_HEADER_INDEX)) {
        std::cout << "Status da resposta: " << statusCode << std::endl;
        
        // Verifica se o status é 101 (Switching Protocols)
        if (statusCode != 101) {
            std::cerr << "Resposta inesperada do servidor: " << statusCode << std::endl;
            // Continuamos mesmo com erro para depuração
        }
    }
    
    // Imprime todos os cabeçalhos da resposta para depuração
    DWORD headerSize = 0;
    WinHttpQueryHeaders(m_hRequest,
                       WINHTTP_QUERY_RAW_HEADERS_CRLF,
                       WINHTTP_HEADER_NAME_BY_INDEX,
                       NULL,
                       &headerSize,
                       WINHTTP_NO_HEADER_INDEX);
    
    if (headerSize > 0) {
        std::vector<wchar_t> headerBuffer(headerSize / sizeof(wchar_t));
        if (WinHttpQueryHeaders(m_hRequest,
                              WINHTTP_QUERY_RAW_HEADERS_CRLF,
                              WINHTTP_HEADER_NAME_BY_INDEX,
                              headerBuffer.data(),
                              &headerSize,
                              WINHTTP_NO_HEADER_INDEX)) {
            std::wcout << L"Cabeçalhos da resposta:\n" << headerBuffer.data() << std::endl;
        }
    }

    // Completa o handshake WebSocket
    m_hWebSocket = WinHttpWebSocketCompleteUpgrade(m_hRequest, 0);
    if (!m_hWebSocket) {
        DWORD error = GetLastError();
        std::cerr << "Erro ao completar upgrade para WebSocket: " << error << std::endl;
        
        // Imprime informações adicionais de erro
        LPVOID lpMsgBuf;
        FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER | 
            FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL,
            error,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPTSTR) &lpMsgBuf,
            0, NULL);
        std::wcerr << L"Mensagem de erro: " << (LPTSTR)lpMsgBuf << std::endl;
        LocalFree(lpMsgBuf);
        
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }
    
    // Fecha o handle da requisição HTTP, pois não é mais necessário
    WinHttpCloseHandle(m_hRequest);
    m_hRequest = NULL;
    
    std::cout << "Handshake WebSocket completado com sucesso!" << std::endl;
    
    // NÃO fechamos m_hConnection e m_hSession aqui, pois são necessários para manter a conexão WebSocket ativa
    // Os handles serão fechados no destrutor ou quando disconnect() for chamado
    
    // A conexão WebSocket está estabelecida e pronta para uso
    m_connected = true;
    std::cout << "Conexão WebSocket estabelecida com sucesso!" << std::endl;
    return true;
    }
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
