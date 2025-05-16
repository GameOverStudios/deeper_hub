#include <iostream>
#include <string>
#include "websocket_client.h" // Include the WebSocket client header
#include <thread>
#include <nlohmann/json.hpp>

// Callback para processar mensagens recebidas
void on_message(const std::string& message) {
    std::cout << "Mensagem recebida (callback): " << message << std::endl;
    
    // Tenta analisar a mensagem como JSON
    try {
        nlohmann::json json_message = nlohmann::json::parse(message);
        
        // Verifica se é uma mensagem Phoenix
        if (json_message.contains("event") && json_message.contains("payload")) {
            std::string event = json_message["event"];
            auto payload = json_message["payload"];
            
            std::cout << "Evento recebido: " << event << std::endl;
            std::cout << "Payload: " << payload.dump(2) << std::endl;
            
            // Processa diferentes tipos de eventos
            if (event == "phx_reply") {
                // Resposta a uma mensagem enviada anteriormente
                if (payload.contains("status")) {
                    std::cout << "Status da resposta: " << payload["status"] << std::endl;
                    
                    // Se for uma resposta de sucesso a uma operação de banco de dados
                    if (payload.contains("response") && 
                        payload["response"].contains("data") && 
                        payload["status"] == "success") {
                        std::cout << "Dados recebidos: " << payload["response"]["data"].dump(2) << std::endl;
                    }
                }
            }
        }
    } catch (const nlohmann::json::exception& e) {
        std::cerr << "Erro ao analisar mensagem JSON: " << e.what() << std::endl;
    }
}

// Função para criar uma mensagem simples para o servidor
nlohmann::json create_database_operation(const std::string& operation, const std::string& schema, 
                                        const std::string& id, const nlohmann::json& data) {
    // Cria uma mensagem simples para o servidor
    nlohmann::json message = {
        {"type", "database_operation"},
        {"operation", operation},
        {"schema", schema},
        {"id", id},
        {"request_id", std::to_string(std::rand())}
    };
    
    // Adiciona os dados apenas se não estiverem vazios
    if (!data.empty()) {
        message["user_data"] = data;
    }
    
    return message;
}

// Função para executar os testes de usuários
void teste_usuarios(WebsocketClient& client) {
    std::cout << "\nExecutando teste de usuários..." << std::endl;
    
    std::string username = "user_" + std::to_string(std::rand() % 10000);
    std::string email = username + "@example.com";
    std::string password = "senha123";
    std::string request_id = std::to_string(std::rand() % 100000);
    
    // Cria a mensagem no formato simplificado
    nlohmann::json payload = {
        {"action", "create_user"},
        {"username", username},
        {"email", email},
        {"password", password},
        {"request_id", request_id}
    };
    
    // Envia a mensagem para o servidor
    std::string message = client.format_phoenix_message("message", "websocket", payload, std::to_string(std::rand() % 100000));
    
    std::cout << "Enviando mensagem: " << message << std::endl;
    client.send_message(message);
    std::this_thread::sleep_for(std::chrono::seconds(2));
}

// Função para listar todos os usuários
void listar_usuarios(WebsocketClient& client) {
    std::cout << "\nListando todos os usuários..." << std::endl;
    
    // Cria a mensagem no formato simplificado
    std::string request_id = std::to_string(std::rand() % 100000);
    nlohmann::json payload = {
        {"action", "list_users"},
        {"request_id", request_id}
    };
    
    // Envia a mensagem para o servidor
    std::cout << "Enviando operação de listagem de usuários..." << std::endl;
    std::string message = client.format_phoenix_message("message", "websocket", payload, std::to_string(std::rand() % 100000));
    std::cout << "Enviando mensagem: " << message << std::endl;
    client.send_message(message);
    
    // Aguarda um pouco para a operação ser processada
    std::this_thread::sleep_for(std::chrono::seconds(2));
}

int main(int argc, char* argv[]) {
    std::cout << "Iniciando cliente Deeper_Hub...\n";
    
    // Inicializa o gerador de números aleatórios para IDs de mensagens
    std::srand(static_cast<unsigned int>(std::time(nullptr)));
    
    WebsocketClient client;
    
    // Configura o callback para receber mensagens
    client.set_message_callback(on_message);
    
    std::string uri = "ws://localhost:4000"; // Endereço do servidor WebSocket
    std::cout << "Conectando a " << uri << "...\n";
    
    client.connect(uri);
    
    // Aguardar um pouco para a conexão ser estabelecida
    std::this_thread::sleep_for(std::chrono::seconds(3)); 
    
    if (client.is_connected()) {
        std::cout << "Conexão WebSocket estabelecida com sucesso.\n";
        
        // Aguarda mais um pouco para garantir que o join ao canal foi processado
        std::this_thread::sleep_for(std::chrono::seconds(1));
        
        // Menu de opções
        std::string input;
        while (client.is_connected()) {
            std::cout << "\n===== MENU =====" << std::endl;
            std::cout << "1. Executar teste de usuários" << std::endl;
            std::cout << "2. Listar todos os usuários" << std::endl;
            std::cout << "3. Enviar mensagem personalizada" << std::endl;
            std::cout << "0. Sair" << std::endl;
            std::cout << "Escolha uma opção: ";
            std::getline(std::cin, input);
            
            if (input == "0" || input == "sair") {
                break;
            }
            else if (input == "1") {
                teste_usuarios(client);
            }
            else if (input == "2") {
                listar_usuarios(client);
            }
            else if (input == "3") {
                std::cout << "Digite sua mensagem: ";
                std::getline(std::cin, input);
                
                if (!input.empty()) {
                    // Cria uma mensagem personalizada
                    nlohmann::json custom_message = {
                        {"content", input},
                        {"message_type", "custom"},
                        {"timestamp", std::time(nullptr)}
                    };
                    
                    client.send_message(custom_message.dump());
                }
            }
            else {
                std::cout << "Opção inválida!" << std::endl;
            }
        }
        
        client.close();
    } else {
        std::cerr << "Falha ao conectar ao servidor WebSocket.\n";
    }
    
    return 0;
}
