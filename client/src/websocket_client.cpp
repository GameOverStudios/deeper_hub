#include "websocket_client.hpp"
#include <iostream>
#include <random>
#include <sstream>
#include <iomanip>
#include <fstream>

namespace deeper_hub {

WebSocketClient::WebSocketClient(const std::string& url, const std::string& auth_token, bool use_tls)
    : url_(url)
    , auth_token_(auth_token)
    , use_tls_(use_tls)
    , connected_(false)
    , authenticated_(false)
    , reconnecting_(false)
    , response_received_(false)
    , heartbeat_running_(false)
{
    // Inicializa o cliente WebSocket apropriado (TLS ou não)
    if (use_tls_) {
        wss_client_ = std::make_unique<websocket_client_tls>();
        
        // Configuração do cliente TLS
        wss_client_->set_access_channels(websocketpp::log::alevel::all);
        wss_client_->clear_access_channels(websocketpp::log::alevel::frame_payload);
        wss_client_->set_error_channels(websocketpp::log::elevel::all);
        
        // Inicializa ASIO
        wss_client_->init_asio();
        
        // Registra handlers
        wss_client_->set_open_handler([this](connection_hdl hdl) { this->on_open(hdl); });
        wss_client_->set_message_handler([this](connection_hdl hdl, message_ptr msg) { this->on_message(hdl, msg); });
        wss_client_->set_close_handler([this](connection_hdl hdl) { this->on_close(hdl); });
        wss_client_->set_fail_handler([this](connection_hdl hdl) { this->on_fail(hdl); });
        
        // Desativa verificação de certificado para desenvolvimento (remover em produção)
        wss_client_->set_tls_init_handler([](connection_hdl) {
            return websocketpp::lib::make_shared<boost::asio::ssl::context>(boost::asio::ssl::context::tlsv12);
        });
    } else {
        ws_client_ = std::make_unique<websocket_client>();
        
        // Configuração do cliente não-TLS
        ws_client_->set_access_channels(websocketpp::log::alevel::all);
        ws_client_->clear_access_channels(websocketpp::log::alevel::frame_payload);
        ws_client_->set_error_channels(websocketpp::log::elevel::all);
        
        // Inicializa ASIO
        ws_client_->init_asio();
        
        // Registra handlers
        ws_client_->set_open_handler([this](connection_hdl hdl) { this->on_open(hdl); });
        ws_client_->set_message_handler([this](connection_hdl hdl, message_ptr msg) { this->on_message(hdl, msg); });
        ws_client_->set_close_handler([this](connection_hdl hdl) { this->on_close(hdl); });
        ws_client_->set_fail_handler([this](connection_hdl hdl) { this->on_fail(hdl); });
    }
}

WebSocketClient::~WebSocketClient() {
    // Para o heartbeat
    stop_heartbeat();
    
    // Desconecta do servidor
    disconnect();
    
    // Limpa recursos
    if (use_tls_) {
        wss_client_->stop_perpetual();
    } else {
        ws_client_->stop_perpetual();
    }
}

bool WebSocketClient::connect() {
    if (connected_) {
        std::cout << "Cliente já está conectado" << std::endl;
        return true;
    }
    
    try {
        websocketpp::lib::error_code ec;
        
        if (use_tls_) {
            // Conecta usando TLS
            connection_ = wss_client_->get_connection(url_, ec);
            if (ec) {
                std::cerr << "Erro ao criar conexão: " << ec.message() << std::endl;
                return false;
            }
            
            wss_client_->connect(connection_);
            wss_client_->run();
        } else {
            // Conecta sem TLS
            connection_ = ws_client_->get_connection(url_, ec);
            if (ec) {
                std::cerr << "Erro ao criar conexão: " << ec.message() << std::endl;
                return false;
            }
            
            ws_client_->connect(connection_);
            ws_client_->run();
        }
        
        // Aguarda até que a conexão seja estabelecida
        auto start_time = std::chrono::steady_clock::now();
        while (!connected_ && 
               std::chrono::duration_cast<std::chrono::seconds>(
                   std::chrono::steady_clock::now() - start_time).count() < 10) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
        
        // Verifica se a conexão foi estabelecida
        if (!connected_) {
            std::cerr << "Timeout ao conectar ao servidor" << std::endl;
            return false;
        }
        
        // Aguarda até que a autenticação seja concluída
        start_time = std::chrono::steady_clock::now();
        while (!authenticated_ && 
               std::chrono::duration_cast<std::chrono::seconds>(
                   std::chrono::steady_clock::now() - start_time).count() < 10) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
        
        // Verifica se a autenticação foi concluída
        if (!authenticated_) {
            std::cerr << "Timeout na autenticação" << std::endl;
            disconnect();
            return false;
        }
        
        std::cout << "Conectado e autenticado com sucesso" << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exceção ao conectar: " << e.what() << std::endl;
        return false;
    }
}

void WebSocketClient::disconnect() {
    if (!connected_) {
        return;
    }
    
    try {
        websocketpp::lib::error_code ec;
        
        if (use_tls_) {
            wss_client_->close(connection_, websocketpp::close::status::normal, "Desconexão normal", ec);
        } else {
            ws_client_->close(connection_, websocketpp::close::status::normal, "Desconexão normal", ec);
        }
        
        if (ec) {
            std::cerr << "Erro ao fechar conexão: " << ec.message() << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "Exceção ao desconectar: " << e.what() << std::endl;
    }
    
    connected_ = false;
    authenticated_ = false;
}

bool WebSocketClient::is_connected() const {
    return connected_;
}

bool WebSocketClient::is_authenticated() const {
    return authenticated_;
}

bool WebSocketClient::send_message(const json& message) {
    if (!connected_ || !authenticated_) {
        std::cerr << "Tentativa de enviar mensagem sem conexão ou autenticação" << std::endl;
        return false;
    }
    
    try {
        std::string message_str = message.dump();
        websocketpp::lib::error_code ec;
        
        if (use_tls_) {
            wss_client_->send(connection_, message_str, websocketpp::frame::opcode::text, ec);
        } else {
            ws_client_->send(connection_, message_str, websocketpp::frame::opcode::text, ec);
        }
        
        if (ec) {
            std::cerr << "Erro ao enviar mensagem: " << ec.message() << std::endl;
            return false;
        }
        
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exceção ao enviar mensagem: " << e.what() << std::endl;
        return false;
    }
}

json WebSocketClient::wait_for_response(int timeout_ms) {
    std::unique_lock<std::mutex> lock(response_mutex_);
    
    // Reseta o estado de resposta
    response_received_ = false;
    last_response_ = json();
    
    // Aguarda pela resposta com timeout
    if (response_cv_.wait_for(lock, std::chrono::milliseconds(timeout_ms),
                             [this] { return response_received_; })) {
        return last_response_;
    } else {
        std::cerr << "Timeout ao aguardar resposta" << std::endl;
        return json();
    }
}

void WebSocketClient::set_message_callback(std::function<void(const json&)> callback) {
    message_callback_ = callback;
}

void WebSocketClient::set_connection_callback(std::function<void(bool)> callback) {
    connection_callback_ = callback;
}

void WebSocketClient::start_heartbeat(int interval_ms) {
    // Para o heartbeat atual se estiver rodando
    stop_heartbeat();
    
    // Inicia um novo thread de heartbeat
    heartbeat_running_ = true;
    heartbeat_thread_ = std::thread(&WebSocketClient::heartbeat_loop, this, interval_ms);
}

void WebSocketClient::stop_heartbeat() {
    // Para o thread de heartbeat se estiver rodando
    if (heartbeat_running_) {
        heartbeat_running_ = false;
        if (heartbeat_thread_.joinable()) {
            heartbeat_thread_.join();
        }
    }
}

void WebSocketClient::on_open(connection_hdl hdl) {
    std::cout << "Conexão estabelecida" << std::endl;
    connected_ = true;
    
    // Notifica o callback de conexão
    if (connection_callback_) {
        connection_callback_(true);
    }
    
    // Envia mensagem de join com autenticação
    join_channel();
}

void WebSocketClient::on_message(connection_hdl hdl, message_ptr msg) {
    try {
        // Converte a mensagem para JSON
        std::string payload = msg->get_payload();
        json data = json::parse(payload);
        
        std::cout << "Mensagem recebida: " << payload << std::endl;
        
        // Processa diferentes tipos de mensagens
        if (data.contains("event")) {
            std::string event_type = data["event"];
            
            if (event_type == "phx_reply" && data.value("ref", "") == "1") {
                // Resposta de autenticação
                if (data.contains("payload") && data["payload"].contains("status") && 
                    data["payload"]["status"] == "ok") {
                    std::cout << "Autenticação bem-sucedida" << std::endl;
                    authenticated_ = true;
                } else {
                    std::cerr << "Erro na autenticação: " << data.dump() << std::endl;
                }
            } else if (event_type == "heartbeat") {
                // Heartbeat recebido
                std::cout << "Heartbeat recebido" << std::endl;
            } else if (event_type == "phx_reply") {
                // Extrai a resposta do formato Phoenix
                json response_data = data.value("payload", json::object());
                
                // Se for uma resposta de operação de banco de dados
                if (response_data.is_object()) {
                    if (response_data.contains("response") && response_data["response"].is_object()) {
                        json response = response_data["response"];
                        if (response.contains("type") && response["type"] == "database_response") {
                            std::cout << "Resposta de operação de banco de dados recebida" << std::endl;
                            
                            // Notifica que uma resposta foi recebida
                            {
                                std::lock_guard<std::mutex> lock(response_mutex_);
                                last_response_ = response;
                                response_received_ = true;
                            }
                            response_cv_.notify_one();
                            
                            // Notifica o callback de mensagem
                            if (message_callback_) {
                                message_callback_(response);
                            }
                        } else if (response.contains("status")) {
                            std::cout << "Resposta recebida: " << response.dump() << std::endl;
                            
                            // Notifica que uma resposta foi recebida
                            {
                                std::lock_guard<std::mutex> lock(response_mutex_);
                                last_response_ = response;
                                response_received_ = true;
                            }
                            response_cv_.notify_one();
                            
                            // Notifica o callback de mensagem
                            if (message_callback_) {
                                message_callback_(response);
                            }
                        }
                    } else if (response_data.contains("status")) {
                        std::cout << "Resposta direta recebida: " << response_data.dump() << std::endl;
                        
                        // Notifica que uma resposta foi recebida
                        {
                            std::lock_guard<std::mutex> lock(response_mutex_);
                            last_response_ = response_data;
                            response_received_ = true;
                        }
                        response_cv_.notify_one();
                        
                        // Notifica o callback de mensagem
                        if (message_callback_) {
                            message_callback_(response_data);
                        }
                    }
                }
            }
        } else if (data.is_object() && data.contains("type") && data["type"] == "database_response") {
            // Formato antigo de resposta de banco de dados (compatibilidade)
            std::cout << "Resposta de operação de banco de dados recebida (formato antigo): " 
                     << data["operation"] << " - " << data["schema"] << std::endl;
            
            // Notifica que uma resposta foi recebida
            {
                std::lock_guard<std::mutex> lock(response_mutex_);
                last_response_ = data;
                response_received_ = true;
            }
            response_cv_.notify_one();
            
            // Notifica o callback de mensagem
            if (message_callback_) {
                message_callback_(data);
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar mensagem: " << e.what() << std::endl;
    }
}

void WebSocketClient::on_close(connection_hdl hdl) {
    std::cout << "Conexão fechada" << std::endl;
    connected_ = false;
    authenticated_ = false;
    
    // Notifica o callback de conexão
    if (connection_callback_) {
        connection_callback_(false);
    }
}

void WebSocketClient::on_fail(connection_hdl hdl) {
    std::cerr << "Falha na conexão" << std::endl;
    connected_ = false;
    authenticated_ = false;
    
    // Notifica o callback de conexão
    if (connection_callback_) {
        connection_callback_(false);
    }
}

void WebSocketClient::join_channel() {
    // Cria mensagem de join no formato Phoenix WebSocket
    json join_message = {
        {"topic", "websocket"},
        {"event", "phx_join"},
        {"payload", {{"auth_token", auth_token_}}},
        {"ref", "1"}
    };
    
    // Envia a mensagem
    std::string message_str = join_message.dump();
    websocketpp::lib::error_code ec;
    
    if (use_tls_) {
        wss_client_->send(connection_, message_str, websocketpp::frame::opcode::text, ec);
    } else {
        ws_client_->send(connection_, message_str, websocketpp::frame::opcode::text, ec);
    }
    
    if (ec) {
        std::cerr << "Erro ao enviar mensagem de join: " << ec.message() << std::endl;
    } else {
        std::cout << "Mensagem de join enviada" << std::endl;
    }
}

void WebSocketClient::heartbeat_loop(int interval_ms) {
    while (heartbeat_running_ && connected_) {
        // Aguarda pelo intervalo
        std::this_thread::sleep_for(std::chrono::milliseconds(interval_ms));
        
        if (!heartbeat_running_ || !connected_) {
            break;
        }
        
        // Cria mensagem de heartbeat
        json heartbeat_message = {
            {"topic", "websocket"},
            {"event", "heartbeat"},
            {"payload", json::object()},
            {"ref", generate_uuid()}
        };
        
        // Envia a mensagem
        send_message(heartbeat_message);
    }
}

std::string WebSocketClient::generate_uuid() {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    static std::uniform_int_distribution<> dis(0, 15);
    static std::uniform_int_distribution<> dis2(8, 11);
    
    std::stringstream ss;
    ss << std::hex;
    
    for (int i = 0; i < 8; i++) {
        ss << dis(gen);
    }
    ss << "-";
    
    for (int i = 0; i < 4; i++) {
        ss << dis(gen);
    }
    ss << "-4";
    
    for (int i = 0; i < 3; i++) {
        ss << dis(gen);
    }
    ss << "-";
    
    ss << dis2(gen);
    
    for (int i = 0; i < 3; i++) {
        ss << dis(gen);
    }
    ss << "-";
    
    for (int i = 0; i < 12; i++) {
        ss << dis(gen);
    }
    
    return ss.str();
}

} // namespace deeper_hub
