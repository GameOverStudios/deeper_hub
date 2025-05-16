#ifndef DEEPER_CLIENT_WEBSOCKET_CLIENT_H
#define DEEPER_CLIENT_WEBSOCKET_CLIENT_H

#include <string>
#include <windows.h>
#include <winhttp.h>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <functional>
#include <nlohmann/json.hpp>

// Callback para receber mensagens WebSocket
typedef std::function<void(const std::string&)> MessageCallback;

class WebsocketClient {
public:
    WebsocketClient();
    ~WebsocketClient();

    // Conecta ao servidor WebSocket
    void connect(const std::string& uri);
    
    // Envia uma mensagem para o servidor
    void send_message(const std::string& message);
    
    // Fecha a conexão
    void close();
    
    // Verifica se está conectado
    bool is_connected() const { return m_connected; }
    
    // Define um callback para receber mensagens
    void set_message_callback(MessageCallback callback) { m_message_callback = callback; }
    
    // Formata uma mensagem para o protocolo Phoenix
    std::string format_phoenix_message(const std::string& event, const std::string& topic, const nlohmann::json& payload, const std::string& ref = "");

private:
    // Thread para processar mensagens recebidas
    void receive_thread();
    
    // Envia mensagem de join para o canal Phoenix
    void join_phoenix_channel();
    
    // Envia um heartbeat para o servidor
    void send_heartbeat();
    
    // Converte string para wstring
    std::wstring string_to_wstring(const std::string& str);
    
    // Converte wstring para string
    std::string wstring_to_string(const std::wstring& wstr);
    
    // Processa a URL para extrair host, path e porta
    bool parse_uri(const std::string& uri, std::wstring& host, std::wstring& path, INTERNET_PORT& port, bool& secure);

    // Handles do WinHTTP
    HINTERNET m_session;
    HINTERNET m_connection;
    HINTERNET m_request;
    HINTERNET m_websocket;
    
    // Estado da conexão
    bool m_connected;
    bool m_closing;
    
    // Thread e sincronização
    std::thread m_thread;
    std::mutex m_mutex;
    std::condition_variable m_condition;
    
    // Fila de mensagens para envio
    std::queue<std::string> m_message_queue;
    
    // Callback para receber mensagens
    MessageCallback m_message_callback;
};

#endif // DEEPER_CLIENT_WEBSOCKET_CLIENT_H 