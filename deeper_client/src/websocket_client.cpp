#include "../include/websocket_client.h"
#include <iostream>
#include <sstream>
#include <vector>
#include <algorithm>
#include <ctime>
#include <wincrypt.h>

#pragma comment(lib, "winhttp.lib")
#pragma comment(lib, "crypt32.lib")

WebSocketClient::WebSocketClient() 
    : m_hSession(NULL), m_hConnection(NULL), m_hRequest(NULL), m_hWebSocket(NULL), m_connected(false) {
    // Inicializa a semente para geração de números aleatórios
    srand(static_cast<unsigned int>(time(nullptr)));
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

    // Usamos o caminho definido no servidor Elixir (websocket_supervisor.ex)
    std::wstring path = L"/ws";
    
    std::cout << "Conectando ao caminho: " << std::string(path.begin(), path.end()) << std::endl;
    
    // Abre a requisição para upgrade para WebSocket
    // IMPORTANTE: Usamos HTTP/1.1 explicitamente, pois o protocolo WebSocket requer HTTP/1.1
    m_hRequest = WinHttpOpenRequest(
        m_hConnection,
        L"GET",
        path.c_str(),
        L"HTTP/1.1",  // Especificamos explicitamente HTTP/1.1 para o protocolo WebSocket
        WINHTTP_NO_REFERER,
        WINHTTP_DEFAULT_ACCEPT_TYPES,
        0);  // Sem WINHTTP_FLAG_SECURE para conexão local

    if (!m_hRequest) {
        DWORD error = GetLastError();
        std::cerr << "Erro ao criar requisição: " << error << std::endl;
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }
    
    // Gera 16 bytes aleatórios para o Sec-WebSocket-Key
    BYTE randomBytes[16];
    for (int i = 0; i < 16; i++) {
        randomBytes[i] = static_cast<BYTE>(rand() % 256);
    }
    
    // Converte para base64
    DWORD base64Length = 0;
    CryptBinaryToStringW(randomBytes, 16, CRYPT_STRING_BASE64, NULL, &base64Length);
    std::vector<wchar_t> base64Buffer(base64Length);
    CryptBinaryToStringW(randomBytes, 16, CRYPT_STRING_BASE64, base64Buffer.data(), &base64Length);
    
    // Remove quebras de linha e espaços da string base64
    std::wstring key(base64Buffer.data());
    key.erase(std::remove_if(key.begin(), key.end(), [](wchar_t c) { return c == '\r' || c == '\n' || c == ' '; }), key.end());
    
    // Usamos a API nativa do WinHTTP para WebSockets
    // Indicamos que queremos fazer um upgrade para WebSocket
    BOOL bResult = WinHttpSetOption(
        m_hRequest,
        WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET,
        NULL,
        0);
    
    if (!bResult) {
        DWORD error = GetLastError();
        std::cerr << "Erro ao configurar opção de upgrade para WebSocket: " << error << std::endl;
        WinHttpCloseHandle(m_hRequest);
        WinHttpCloseHandle(m_hConnection);
        WinHttpCloseHandle(m_hSession);
        m_hRequest = NULL;
        m_hConnection = NULL;
        m_hSession = NULL;
        return false;
    }
    
    // Adicionamos o cabeçalho Sec-WebSocket-Key manualmente
    std::wstring keyHeader = L"Sec-WebSocket-Key: " + key;
    if (!WinHttpAddRequestHeaders(m_hRequest, keyHeader.c_str(), -1, WINHTTP_ADDREQ_FLAG_ADD)) {
        std::cerr << "Erro ao adicionar cabeçalho Sec-WebSocket-Key: " << GetLastError() << std::endl;
    }
    
    // Envia a requisição sem cabeçalhos adicionais, pois o WinHTTP adicionará os cabeçalhos necessários
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
    
    // Recebe a resposta do servidor
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
    DWORD statusCodeSize = sizeof(statusCode);
    WinHttpQueryHeaders(
        m_hRequest,
        WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
        WINHTTP_HEADER_NAME_BY_INDEX,
        &statusCode,
        &statusCodeSize,
        WINHTTP_NO_HEADER_INDEX);

    std::cout << "Status da resposta: " << statusCode << std::endl;

    // Exibe os cabeçalhos da resposta para diagnóstico
    DWORD headersSize = 0;
    WinHttpQueryHeaders(
        m_hRequest,
        WINHTTP_QUERY_RAW_HEADERS_CRLF,
        WINHTTP_HEADER_NAME_BY_INDEX,
        NULL,
        &headersSize,
        WINHTTP_NO_HEADER_INDEX);

    if (headersSize > 0) {
        std::vector<wchar_t> headersBuffer(headersSize / sizeof(wchar_t));
        WinHttpQueryHeaders(
            m_hRequest,
            WINHTTP_QUERY_RAW_HEADERS_CRLF,
            WINHTTP_HEADER_NAME_BY_INDEX,
            headersBuffer.data(),
            &headersSize,
            WINHTTP_NO_HEADER_INDEX);

        std::wcout << L"Cabeçalhos da resposta:" << std::endl;
        std::wcout << headersBuffer.data() << std::endl;
    }

    // Esperamos o código 101 (Switching Protocols) para WebSocket
    if (statusCode != 101) {
        std::cerr << "Resposta inesperada do servidor: " << statusCode << std::endl;
        
        DWORD error = GetLastError();
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
    
    // Completa o upgrade para WebSocket
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
        std::wcerr << L"Mensagem de erro: Falha ao conectar ao servidor WebSocket" << std::endl;
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
    
    // Aguarda um pouco antes de enviar a mensagem para garantir que a conexão esteja estável
    Sleep(500);
    
    // Envia uma mensagem de teste para o servidor no formato esperado pelo router.ex
    try {
        nlohmann::json testMessage = {
            {"type", "echo"},  // Usando 'type' em vez de 'event' conforme esperado pelo servidor
            {"payload", {
                {"message", "Hello from C++ client!"},
                {"timestamp", static_cast<long long>(time(nullptr))}
            }}
        };
        
        std::string messageStr = testMessage.dump();
        std::cout << "Enviando mensagem de teste: " << messageStr << std::endl;
        
        DWORD result = WinHttpWebSocketSend(
            m_hWebSocket,
            WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
            (PVOID)messageStr.c_str(),
            messageStr.length());

        if (result != ERROR_SUCCESS) {
            std::cerr << "Erro ao enviar mensagem de teste: " << result << std::endl;
        } else {
            std::cout << "Mensagem de teste enviada com sucesso!" << std::endl;
            
            // Aguarda pela resposta
            std::string response;
            if (receiveMessage(response)) {
                std::cout << "Resposta recebida: " << response << std::endl;
            } else {
                std::cerr << "Erro ao receber resposta" << std::endl;
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao criar mensagem de teste: " << e.what() << std::endl;
    }
    
    return true;
}


bool WebSocketClient::sendTextMessage(const nlohmann::json& jsonMessage) {
    if (!m_connected) {
        std::cerr << "Erro: não está conectado ao servidor WebSocket" << std::endl;
        return false;
    }

    // Formata a mensagem JSON
    std::string message;
    try {
        message = jsonMessage.dump();
    } catch (const std::exception& e) {
        std::cerr << "Erro ao serializar mensagem JSON: " << e.what() << std::endl;
        return false;
    }
    
    // Configura timeout para envio
    DWORD timeout = 5000; // 5 segundos
    WinHttpSetOption(m_hWebSocket, WINHTTP_OPTION_SEND_TIMEOUT, &timeout, sizeof(timeout));
    
    // Tenta enviar a mensagem com retry
    int retryCount = 3;
    DWORD result = ERROR_SUCCESS;
    
    while (retryCount > 0) {
        result = WinHttpWebSocketSend(
            m_hWebSocket,
            WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
            (PVOID)message.c_str(),
            message.length());

        if (result == ERROR_SUCCESS) {
            break; // Enviou com sucesso
        } else if (result == ERROR_WINHTTP_TIMEOUT) {
            std::cerr << "Timeout ao enviar mensagem, tentando novamente... " << retryCount-1 << " tentativas restantes" << std::endl;
            retryCount--;
            Sleep(500); // Aguarda 500ms antes de tentar novamente
        } else {
            std::cerr << "Erro ao enviar mensagem WebSocket: " << result << std::endl;
            return false;
        }
    }
    
    if (result != ERROR_SUCCESS) {
        std::cerr << "Falha após várias tentativas de enviar mensagem" << std::endl;
        return false;
    }

    std::cout << "Mensagem enviada com sucesso: " << message << std::endl;
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

    const int bufferSize = 8192; // Aumentamos o tamanho do buffer para mensagens maiores
    char buffer[bufferSize];
    BYTE* pbBuffer = (BYTE*)buffer;
    DWORD dwBufferLength = bufferSize - 1;
    DWORD dwBytesTransferred = 0;
    WINHTTP_WEB_SOCKET_BUFFER_TYPE eBufferType;
    
    // Configura um timeout para a operação de recebimento
    DWORD timeout = 5000; // 5 segundos
    WinHttpSetOption(m_hWebSocket, WINHTTP_OPTION_RECEIVE_TIMEOUT, &timeout, sizeof(timeout));

    // Tenta receber a mensagem com retry
    int retryCount = 3;
    DWORD result = ERROR_SUCCESS;
    
    while (retryCount > 0) {
        result = WinHttpWebSocketReceive(
            m_hWebSocket,
            pbBuffer,
            dwBufferLength,
            &dwBytesTransferred,
            &eBufferType);

        if (result == ERROR_SUCCESS) {
            break; // Recebeu com sucesso
        } else if (result == ERROR_WINHTTP_TIMEOUT) {
            std::cerr << "Timeout ao receber mensagem, tentando novamente... " << retryCount-1 << " tentativas restantes" << std::endl;
            retryCount--;
            Sleep(500); // Aguarda 500ms antes de tentar novamente
        } else {
            std::cerr << "Erro ao receber mensagem WebSocket: " << result << std::endl;
            return false;
        }
    }
    
    if (result != ERROR_SUCCESS) {
        std::cerr << "Falha após várias tentativas de receber mensagem" << std::endl;
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
