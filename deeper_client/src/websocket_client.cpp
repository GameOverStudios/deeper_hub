#include "../include/websocket_client.h"
#include <iostream>
#include <codecvt>
#include <locale>
#include <regex>

WebsocketClient::WebsocketClient() : 
    m_session(NULL),
    m_connection(NULL),
    m_request(NULL),
    m_websocket(NULL),
    m_connected(false),
    m_closing(false),
    m_message_callback(nullptr) {
    // Inicializa a sessão WinHTTP
    m_session = WinHttpOpen(
        L"Deeper_Hub WebSocket Client/1.0",
        WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME,
        WINHTTP_NO_PROXY_BYPASS,
        0);
    
    if (!m_session) {
        std::cerr << "Erro ao inicializar a sessão WinHTTP: " << GetLastError() << std::endl;
    }
}

WebsocketClient::~WebsocketClient() {
    close();
    
    // Limpa os recursos
    if (m_thread.joinable()) {
        m_thread.join();
    }
    
    if (m_websocket) {
        WinHttpWebSocketClose(m_websocket, WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS, NULL, 0);
        WinHttpCloseHandle(m_websocket);
        m_websocket = NULL;
    }
    
    if (m_request) {
        WinHttpCloseHandle(m_request);
        m_request = NULL;
    }
    
    if (m_connection) {
        WinHttpCloseHandle(m_connection);
        m_connection = NULL;
    }
    
    if (m_session) {
        WinHttpCloseHandle(m_session);
        m_session = NULL;
    }
}

std::wstring WebsocketClient::string_to_wstring(const std::string& str) {
    if (str.empty()) return std::wstring();
    
    // Determina o tamanho necessário
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstr(size_needed, 0);
    
    // Converte a string
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstr[0], size_needed);
    return wstr;
}

std::string WebsocketClient::wstring_to_string(const std::wstring& wstr) {
    if (wstr.empty()) return std::string();
    
    // Determina o tamanho necessário
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string str(size_needed, 0);
    
    // Converte a wstring
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &str[0], size_needed, NULL, NULL);
    return str;
}

bool WebsocketClient::parse_uri(const std::string& uri, std::wstring& host, std::wstring& path, INTERNET_PORT& port, bool& secure) {
    // Regex para validar e extrair componentes da URI
    std::regex uri_regex("(ws|wss)://([^:/]+)(:([0-9]+))?(/.*)?");
    std::smatch matches;
    
    if (!std::regex_match(uri, matches, uri_regex)) {
        std::cerr << "URI inválida: " << uri << std::endl;
        return false;
    }
    
    // Protocolo (ws ou wss)
    std::string protocol = matches[1].str();
    secure = (protocol == "wss");
    
    // Host
    host = string_to_wstring(matches[2].str());
    
    // Porta (padrão: 80 para ws, 443 para wss)
    if (matches[4].matched) {
        port = std::stoi(matches[4].str());
    } else {
        port = secure ? 443 : 80;
    }
    
    // Caminho (padrão: "/")
    if (matches[5].matched) {
        path = string_to_wstring(matches[5].str());
    } else {
        path = L"/";
    }
    
    return true;
}

void WebsocketClient::connect(const std::string& uri) {
    if (!m_session) {
        std::cerr << "Sessão WinHTTP não inicializada" << std::endl;
        return;
    }
    
    // Fecha qualquer conexão existente
    close();
    
    // Extrai componentes da URI
    std::wstring host, path;
    INTERNET_PORT port;
    bool secure;
    
    if (!parse_uri(uri, host, path, port, secure)) {
        return;
    }
    
    // Modifica o path para incluir o endpoint do Phoenix WebSocket
    std::wstring socket_path = path + L"/socket/websocket";
    std::cout << "Conectando ao path: " << wstring_to_string(socket_path) << std::endl;
    
    // Cria a conexão HTTP
    m_connection = WinHttpConnect(m_session, host.c_str(), port, 0);
    if (!m_connection) {
        std::cerr << "Erro ao conectar ao servidor: " << GetLastError() << std::endl;
        return;
    }
    
    // Cria a requisição HTTP
    DWORD flags = secure ? WINHTTP_FLAG_SECURE : 0;
    m_request = WinHttpOpenRequest(
        m_connection,
        L"GET",
        socket_path.c_str(),
        NULL,
        WINHTTP_NO_REFERER,
        WINHTTP_DEFAULT_ACCEPT_TYPES,
        flags);
    
    if (!m_request) {
        std::cerr << "Erro ao criar requisição HTTP: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_connection);
        m_connection = NULL;
        return;
    }
    
    // Adiciona cabeçalhos para upgrade para WebSocket
    // Phoenix WebSocket requer cabeçalhos específicos
    LPCWSTR additionalHeaders = L"Sec-WebSocket-Protocol: phoenix-v1.x.x\r\n"
                               L"Sec-WebSocket-Version: 13\r\n"
                               L"Connection: Upgrade\r\n"
                               L"Upgrade: websocket\r\n";
    
    if (!WinHttpSetOption(m_request, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, NULL, 0)) {
        std::cerr << "Erro ao configurar opção de upgrade para WebSocket: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_request);
        WinHttpCloseHandle(m_connection);
        m_request = NULL;
        m_connection = NULL;
        return;
    }
    
    // Envia a requisição com os cabeçalhos adicionais
    if (!WinHttpSendRequest(
            m_request,
            additionalHeaders,
            -1L,  // Comprimento automático dos cabeçalhos
            WINHTTP_NO_REQUEST_DATA,
            0,
            0,
            0)) {
        std::cerr << "Erro ao enviar requisição HTTP: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_request);
        WinHttpCloseHandle(m_connection);
        m_request = NULL;
        m_connection = NULL;
        return;
    }
    
    // Recebe a resposta
    if (!WinHttpReceiveResponse(m_request, NULL)) {
        std::cerr << "Erro ao receber resposta HTTP: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_request);
        WinHttpCloseHandle(m_connection);
        m_request = NULL;
        m_connection = NULL;
        return;
    }
    
    // Completa o handshake WebSocket
    m_websocket = WinHttpWebSocketCompleteUpgrade(m_request, 0);
    if (!m_websocket) {
        std::cerr << "Erro ao completar upgrade para WebSocket: " << GetLastError() << std::endl;
        WinHttpCloseHandle(m_request);
        WinHttpCloseHandle(m_connection);
        m_request = NULL;
        m_connection = NULL;
        return;
    }
    
    // A requisição não é mais necessária
    WinHttpCloseHandle(m_request);
    m_request = NULL;
    
    // Conexão estabelecida com sucesso
    m_connected = true;
    m_closing = false;
    
    std::cout << "Conexão WebSocket estabelecida com sucesso." << std::endl;
    
    // Enviar mensagem de join para o canal Phoenix
    join_phoenix_channel();
    
    // Inicia a thread de recebimento
    m_thread = std::thread(&WebsocketClient::receive_thread, this);
}

void WebsocketClient::send_message(const std::string& message) {
    if (!m_connected || !m_websocket) {
        std::cerr << "Não conectado ao servidor WebSocket" << std::endl;
        return;
    }
    
    // Tenta analisar a mensagem como JSON
    try {
        nlohmann::json json_message = nlohmann::json::parse(message);
        
        // Verifica se é uma mensagem formatada para o Phoenix ou se precisamos formatá-la
        if (!json_message.contains("topic") || !json_message.contains("event")) {
            // Verifica se é uma operação de banco de dados
            if (json_message.contains("database_operation")) {
                // O canal espera operações de banco de dados no evento "message"
                // Formata a mensagem para o protocolo Phoenix
                std::string formatted_message = format_phoenix_message("message", "websocket", json_message);
                
                // Envia a mensagem formatada
                DWORD result = WinHttpWebSocketSend(
                    m_websocket,
                    WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
                    (PVOID)formatted_message.c_str(),
                    (DWORD)formatted_message.length());
                
                if (result != ERROR_SUCCESS) {
                    std::cerr << "Erro ao enviar operação de banco de dados: " << result << std::endl;
                } else {
                    std::cout << "Operação de banco de dados enviada: " << formatted_message << std::endl;
                }
            } else {
                // Formata a mensagem para o protocolo Phoenix
                std::string formatted_message = format_phoenix_message("message", "websocket", json_message);
                
                // Envia a mensagem formatada
                DWORD result = WinHttpWebSocketSend(
                    m_websocket,
                    WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
                    (PVOID)formatted_message.c_str(),
                    (DWORD)formatted_message.length());
                
                if (result != ERROR_SUCCESS) {
                    std::cerr << "Erro ao enviar mensagem WebSocket: " << result << std::endl;
                } else {
                    std::cout << "Mensagem enviada: " << formatted_message << std::endl;
                }
            }
        } else {
            // A mensagem já está formatada para o Phoenix, envia diretamente
            DWORD result = WinHttpWebSocketSend(
                m_websocket,
                WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
                (PVOID)message.c_str(),
                (DWORD)message.length());
            
            if (result != ERROR_SUCCESS) {
                std::cerr << "Erro ao enviar mensagem WebSocket: " << result << std::endl;
            } else {
                std::cout << "Mensagem enviada: " << message << std::endl;
            }
        }
    } catch (const nlohmann::json::exception& e) {
        // Se não for JSON válido, envia a mensagem como está
        DWORD result = WinHttpWebSocketSend(
            m_websocket,
            WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
            (PVOID)message.c_str(),
            (DWORD)message.length());
        
        if (result != ERROR_SUCCESS) {
            std::cerr << "Erro ao enviar mensagem WebSocket: " << result << std::endl;
        } else {
            std::cout << "Mensagem enviada (não-JSON): " << message << std::endl;
        }
    }
}

void WebsocketClient::close() {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    if (m_connected && m_websocket && !m_closing) {
        m_closing = true;
        
        // Fecha a conexão WebSocket
        DWORD result = WinHttpWebSocketClose(
            m_websocket,
            WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS,
            NULL,
            0);
        
        if (result != ERROR_SUCCESS) {
            std::cerr << "Erro ao fechar conexão WebSocket: " << result << std::endl;
        }
        
        m_connected = false;
    }
}

std::string WebsocketClient::format_phoenix_message(const std::string& event, const std::string& topic, const nlohmann::json& payload, const std::string& ref) {
    // Gera um ID de referência único se não for fornecido
    std::string message_ref = ref;
    if (message_ref.empty()) {
        // Gera um ID aleatório para a mensagem
        message_ref = std::to_string(std::rand());
    }
    
    // Cria a mensagem no formato do Phoenix
    nlohmann::json phoenix_message = {
        {"topic", topic},
        {"event", event},
        {"payload", payload},
        {"ref", message_ref}
    };
    
    return phoenix_message.dump();
}

void WebsocketClient::join_phoenix_channel() {
    if (!m_connected || !m_websocket) {
        std::cerr << "Não conectado ao servidor WebSocket" << std::endl;
        return;
    }
    
    // Cria a mensagem de join para o canal Phoenix
    nlohmann::json join_payload = {}; // Payload vazio para join simples
    std::string join_message = format_phoenix_message("phx_join", "websocket", join_payload);
    
    // Envia a mensagem de join
    DWORD result = WinHttpWebSocketSend(
        m_websocket,
        WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
        (PVOID)join_message.c_str(),
        (DWORD)join_message.length());
    
    if (result != ERROR_SUCCESS) {
        std::cerr << "Erro ao enviar mensagem de join: " << result << std::endl;
    } else {
        std::cout << "Mensagem de join enviada: " << join_message << std::endl;
    }
}

void WebsocketClient::send_heartbeat() {
    if (!m_connected || !m_websocket) {
        std::cerr << "Não conectado ao servidor WebSocket" << std::endl;
        return;
    }
    
    // Cria a mensagem de heartbeat para o Phoenix
    nlohmann::json heartbeat_payload = {
        {"timestamp", std::time(nullptr)}
    };
    
    std::string heartbeat_message = format_phoenix_message("heartbeat", "websocket", heartbeat_payload);
    
    // Envia a mensagem de heartbeat
    DWORD result = WinHttpWebSocketSend(
        m_websocket,
        WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
        (PVOID)heartbeat_message.c_str(),
        (DWORD)heartbeat_message.length());
    
    if (result != ERROR_SUCCESS) {
        std::cerr << "Erro ao enviar heartbeat: " << result << std::endl;
    } else {
        std::cout << "Heartbeat enviado: " << heartbeat_message << std::endl;
    }
}

void WebsocketClient::receive_thread() {
    if (!m_websocket) return;
    
    const DWORD buffer_size = 8192; // 8KB buffer
    char buffer[buffer_size];
    DWORD bytes_read = 0;
    WINHTTP_WEB_SOCKET_BUFFER_TYPE buffer_type;
    
    // Contador para enviar heartbeats periodicamente
    int heartbeat_counter = 0;
    
    while (m_connected && !m_closing) {
        // Recebe dados do WebSocket
        DWORD result = WinHttpWebSocketReceive(
            m_websocket,
            buffer,
            buffer_size - 1, // Deixa espaço para o terminador nulo
            &bytes_read,
            &buffer_type);
        
        if (result != ERROR_SUCCESS) {
            if (result != ERROR_WINHTTP_OPERATION_CANCELLED) {
                std::cerr << "Erro ao receber dados WebSocket: " << result << std::endl;
            }
            break;
        }
        
        // Processa a mensagem recebida
        if (bytes_read > 0) {
            // Adiciona terminador nulo
            buffer[bytes_read] = '\0';
            
            // Verifica se é uma mensagem completa ou fragmentada
            if (buffer_type == WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE ||
                buffer_type == WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE) {
                
                std::string message(buffer, bytes_read);
                
                // Tenta analisar a mensagem como JSON
                try {
                    nlohmann::json json_message = nlohmann::json::parse(message);
                    
                    // Verifica se é uma resposta de heartbeat ou phx_reply
                    if (json_message.contains("event")) {
                        std::string event = json_message["event"];
                        
                        // Se for uma resposta de join bem-sucedida
                        if (event == "phx_reply" && json_message.contains("payload")) {
                            auto payload = json_message["payload"];
                            if (payload.contains("status") && payload["status"] == "ok") {
                                std::cout << "Join ao canal Phoenix bem-sucedido!" << std::endl;
                            }
                        }
                        // Se for um heartbeat, responde com outro heartbeat
                        else if (event == "heartbeat") {
                            std::cout << "Heartbeat recebido, respondendo..." << std::endl;
                            send_heartbeat();
                        }
                    }
                } catch (const nlohmann::json::exception& e) {
                    // Não é JSON válido, apenas registra
                    std::cout << "Mensagem não-JSON recebida: " << message << std::endl;
                }
                
                // Notifica através do callback, se definido
                if (m_message_callback) {
                    m_message_callback(message);
                }
                
                std::cout << "Mensagem recebida: " << message << std::endl;
            }
            // Mensagem de fechamento
            else if (buffer_type == WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE) {
                std::cout << "Conexão WebSocket fechada pelo servidor." << std::endl;
                m_connected = false;
                break;
            }
        }
        
        // Envia heartbeat periodicamente (a cada 30 segundos aproximadamente)
        heartbeat_counter++;
        if (heartbeat_counter >= 300) { // Aproximadamente 30 segundos (assumindo que o loop leva ~100ms)
            send_heartbeat();
            heartbeat_counter = 0;
        }
        
        // Pequena pausa para evitar uso excessivo de CPU
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    // Marca como desconectado
    m_connected = false;
}