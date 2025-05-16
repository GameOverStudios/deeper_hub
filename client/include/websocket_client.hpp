#pragma once

#include <string>
#include <functional>
#include <memory>
#include <mutex>
#include <condition_variable>
#include <chrono>
#include <thread>
#include <atomic>
#include <queue>
#include <nlohmann/json.hpp>

// Definições do websocketpp
#define ASIO_STANDALONE
#include <websocketpp/config/asio_client.hpp>
#include <websocketpp/client.hpp>

using json = nlohmann::json;
using websocket_client_tls = websocketpp::client<websocketpp::config::asio_tls_client>;
using websocket_client = websocketpp::client<websocketpp::config::asio_client>;
using message_ptr = websocketpp::config::asio_client::message_type::ptr;
using connection_hdl = websocketpp::connection_hdl;

namespace deeper_hub {

/**
 * @brief Cliente WebSocket para comunicação com o servidor Deeper_Hub
 * 
 * Esta classe implementa um cliente WebSocket que se comunica com o servidor Deeper_Hub,
 * seguindo o protocolo Phoenix WebSocket e suportando operações de banco de dados.
 */
class WebSocketClient {
public:
    /**
     * @brief Construtor
     * 
     * @param url URL do servidor WebSocket (ex: ws://localhost:4000/socket/websocket)
     * @param auth_token Token de autenticação
     * @param use_tls Indica se deve usar TLS (wss://)
     */
    WebSocketClient(const std::string& url, const std::string& auth_token, bool use_tls = false);
    
    /**
     * @brief Destrutor
     */
    ~WebSocketClient();
    
    /**
     * @brief Conecta ao servidor WebSocket
     * 
     * @return true se a conexão foi estabelecida com sucesso, false caso contrário
     */
    bool connect();
    
    /**
     * @brief Desconecta do servidor WebSocket
     */
    void disconnect();
    
    /**
     * @brief Verifica se o cliente está conectado
     * 
     * @return true se o cliente está conectado, false caso contrário
     */
    bool is_connected() const;
    
    /**
     * @brief Verifica se o cliente está autenticado
     * 
     * @return true se o cliente está autenticado, false caso contrário
     */
    bool is_authenticated() const;
    
    /**
     * @brief Envia uma mensagem para o servidor
     * 
     * @param message Mensagem a ser enviada
     * @return true se a mensagem foi enviada com sucesso, false caso contrário
     */
    bool send_message(const json& message);
    
    /**
     * @brief Aguarda por uma resposta do servidor
     * 
     * @param timeout_ms Tempo máximo de espera em milissegundos
     * @return json Resposta recebida ou json nulo se ocorrer timeout
     */
    json wait_for_response(int timeout_ms = 5000);
    
    /**
     * @brief Define um callback para receber mensagens
     * 
     * @param callback Função de callback que recebe uma mensagem JSON
     */
    void set_message_callback(std::function<void(const json&)> callback);
    
    /**
     * @brief Define um callback para eventos de conexão
     * 
     * @param callback Função de callback que recebe um booleano indicando se está conectado
     */
    void set_connection_callback(std::function<void(bool)> callback);
    
    /**
     * @brief Inicia o envio periódico de heartbeats
     * 
     * @param interval_ms Intervalo em milissegundos entre heartbeats
     */
    void start_heartbeat(int interval_ms = 30000);
    
    /**
     * @brief Para o envio de heartbeats
     */
    void stop_heartbeat();

private:
    // Configuração do cliente
    std::string url_;
    std::string auth_token_;
    bool use_tls_;
    
    // Estado da conexão
    std::atomic<bool> connected_;
    std::atomic<bool> authenticated_;
    std::atomic<bool> reconnecting_;
    
    // Mutex e variável de condição para espera de respostas
    std::mutex response_mutex_;
    std::condition_variable response_cv_;
    bool response_received_;
    json last_response_;
    
    // Callbacks
    std::function<void(const json&)> message_callback_;
    std::function<void(bool)> connection_callback_;
    
    // Cliente WebSocket
    std::unique_ptr<websocket_client> ws_client_;
    std::unique_ptr<websocket_client_tls> wss_client_;
    connection_hdl connection_;
    
    // Thread de heartbeat
    std::thread heartbeat_thread_;
    std::atomic<bool> heartbeat_running_;
    
    // Métodos privados
    void on_open(connection_hdl hdl);
    void on_message(connection_hdl hdl, message_ptr msg);
    void on_close(connection_hdl hdl);
    void on_fail(connection_hdl hdl);
    
    void join_channel();
    void heartbeat_loop(int interval_ms);
    
    // Gera um UUID v4 para referências de mensagens
    std::string generate_uuid();
};

} // namespace deeper_hub
