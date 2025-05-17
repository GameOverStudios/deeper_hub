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
                    std::string status = payload["status"];
                    std::cout << "Status da resposta: " << status << std::endl;
                    
                    if (status == "ok") {
                        // Resposta de sucesso
                        if (payload.contains("response")) {
                            auto response = payload["response"];
                            
                            // Verifica o tipo de operação pela resposta
                            if (response.contains("status") && response["status"] == "success") {
                                // Operação bem-sucedida
                                
                                // Verifica se é uma resposta de criação de usuário
                                if (response.contains("message") && response["message"] == "Usuário criado com sucesso") {
                                    std::cout << "\n✅ SUCESSO: " << response["message"] << std::endl;
                                }
                                // Verifica se é uma resposta de listagem de usuários
                                else if (response.contains("users")) {
                                    auto users = response["users"];
                                    std::cout << "\n✅ SUCESSO: Encontrados " << users.size() << " usuários" << std::endl;
                                    
                                    if (users.size() > 0) {
                                        std::cout << "Lista de usuários:" << std::endl;
                                        for (const auto& user : users) {
                                            std::cout << "  - Username: " << user["username"] << std::endl;
                                            std::cout << "    Email: " << user["email"] << std::endl;
                                            std::cout << "    ID: " << user["id"] << std::endl;
                                            std::cout << "    Ativo: " << (user["is_active"].get<bool>() ? "Sim" : "Não") << std::endl;
                                            std::cout << "    ---" << std::endl;
                                        }
                                    }
                                }
                                // Verifica se é uma resposta de atualização de usuário
                                else if (response.contains("message") && response["message"] == "Usuário atualizado com sucesso") {
                                    std::cout << "\n✅ SUCESSO: " << response["message"] << std::endl;
                                    if (response.contains("user")) {
                                        auto user = response["user"];
                                        std::cout << "Dados atualizados:" << std::endl;
                                        std::cout << "  - Username: " << user["username"] << std::endl;
                                        std::cout << "    Email: " << user["email"] << std::endl;
                                        std::cout << "    ID: " << user["id"] << std::endl;
                                        std::cout << "    Ativo: " << (user["is_active"].get<bool>() ? "Sim" : "Não") << std::endl;
                                    }
                                }
                                // Verifica se é uma resposta de exclusão de usuário
                                else if (response.contains("message") && response["message"] == "Usuário excluído com sucesso") {
                                    std::cout << "\n✅ SUCESSO: " << response["message"] << std::endl;
                                }
                                // Resposta genérica de sucesso
                                else {
                                    std::cout << "\n✅ SUCESSO: Operação realizada com sucesso" << std::endl;
                                    std::cout << "Resposta: " << response.dump(2) << std::endl;
                                }
                            }
                            else {
                                // Resposta genérica
                                std::cout << "Resposta: " << response.dump(2) << std::endl;
                            }
                        }
                    }
                    else if (status == "error") {
                        // Resposta de erro
                        if (payload.contains("response") && payload["response"].contains("reason")) {
                            std::string reason = payload["response"]["reason"];
                            std::cout << "\n❌ ERRO: " << reason << std::endl;
                        }
                        else {
                            std::cout << "\n❌ ERRO: Erro desconhecido" << std::endl;
                        }
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

// Função para atualizar um usuário existente
void atualizar_usuario(WebsocketClient& client) {
    std::cout << "\nAtualizando usuário..." << std::endl;
    
    // Solicita o ID do usuário a ser atualizado
    std::string user_id;
    std::cout << "Digite o ID do usuário a ser atualizado: ";
    std::getline(std::cin, user_id);
    
    if (user_id.empty()) {
        std::cout << "ID do usuário não pode ser vazio." << std::endl;
        return;
    }
    
    // Solicita o novo email
    std::string new_email;
    std::cout << "Digite o novo email: ";
    std::getline(std::cin, new_email);
    
    if (new_email.empty()) {
        std::cout << "Email não pode ser vazio." << std::endl;
        return;
    }
    
    // Cria a mensagem no formato simplificado
    std::string request_id = std::to_string(std::rand() % 100000);
    nlohmann::json payload = {
        {"action", "update_user"},
        {"user_id", user_id},
        {"email", new_email},
        {"request_id", request_id}
    };
    
    // Envia a mensagem para o servidor
    std::cout << "Enviando operação de atualização de usuário..." << std::endl;
    std::string message = client.format_phoenix_message("message", "websocket", payload, std::to_string(std::rand() % 100000));
    std::cout << "Enviando mensagem: " << message << std::endl;
    client.send_message(message);
    
    // Aguarda um pouco para a operação ser processada
    std::this_thread::sleep_for(std::chrono::seconds(2));
}

// Função para desativar um usuário
void desativar_usuario(WebsocketClient& client) {
    std::cout << "\nDesativando usuário..." << std::endl;
    
    // Solicita o ID do usuário a ser desativado
    std::string user_id;
    std::cout << "Digite o ID do usuário a ser desativado: ";
    std::getline(std::cin, user_id);
    
    if (user_id.empty()) {
        std::cout << "ID do usuário não pode ser vazio." << std::endl;
        return;
    }
    
    // Cria a mensagem no formato simplificado
    std::string request_id = std::to_string(std::rand() % 100000);
    nlohmann::json payload = {
        {"action", "deactivate_user"},
        {"user_id", user_id},
        {"request_id", request_id}
    };
    
    // Envia a mensagem para o servidor
    std::cout << "Enviando operação de desativação de usuário..." << std::endl;
    std::string message = client.format_phoenix_message("message", "websocket", payload, std::to_string(std::rand() % 100000));
    std::cout << "Enviando mensagem: " << message << std::endl;
    client.send_message(message);
    
    // Aguarda um pouco para a operação ser processada
    std::this_thread::sleep_for(std::chrono::seconds(2));
}

// Função para reativar um usuário
void reativar_usuario(WebsocketClient& client) {
    std::cout << "\nReativando usuário..." << std::endl;
    
    // Solicita o ID do usuário a ser reativado
    std::string user_id;
    std::cout << "Digite o ID do usuário a ser reativado: ";
    std::getline(std::cin, user_id);
    
    if (user_id.empty()) {
        std::cout << "ID do usuário não pode ser vazio." << std::endl;
        return;
    }
    
    // Cria a mensagem no formato simplificado
    std::string request_id = std::to_string(std::rand() % 100000);
    nlohmann::json payload = {
        {"action", "reactivate_user"},
        {"user_id", user_id},
        {"request_id", request_id}
    };
    
    // Envia a mensagem para o servidor
    std::cout << "Enviando operação de reativação de usuário..." << std::endl;
    std::string message = client.format_phoenix_message("message", "websocket", payload, std::to_string(std::rand() % 100000));
    std::cout << "Enviando mensagem: " << message << std::endl;
    client.send_message(message);
    
    // Aguarda um pouco para a operação ser processada
    std::this_thread::sleep_for(std::chrono::seconds(2));
}

// Função para excluir um usuário
void excluir_usuario(WebsocketClient& client) {
    std::cout << "\nExcluindo usuário..." << std::endl;
    
    // Solicita o ID do usuário a ser excluído
    std::string user_id;
    std::cout << "Digite o ID do usuário a ser excluído: ";
    std::getline(std::cin, user_id);
    
    if (user_id.empty()) {
        std::cout << "ID do usuário não pode ser vazio." << std::endl;
        return;
    }
    
    // Confirmação de exclusão
    std::string confirmation;
    std::cout << "Esta operação não pode ser desfeita. Digite 'confirmar' para continuar: ";
    std::getline(std::cin, confirmation);
    
    if (confirmation != "confirmar") {
        std::cout << "Operação cancelada." << std::endl;
        return;
    }
    
    // Cria a mensagem no formato simplificado
    std::string request_id = std::to_string(std::rand() % 100000);
    nlohmann::json payload = {
        {"action", "delete_user"},
        {"user_id", user_id},
        {"request_id", request_id}
    };
    
    // Envia a mensagem para o servidor
    std::cout << "Enviando operação de exclusão de usuário..." << std::endl;
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
            std::cout << "\n===== MENU PRINCIPAL =====" << std::endl;
            std::cout << "1. Gerenciar Usuários" << std::endl;
            std::cout << "2. Enviar mensagem personalizada" << std::endl;
            std::cout << "0. Sair" << std::endl;
            std::cout << "Escolha uma opção: ";
            std::getline(std::cin, input);
            
            if (input == "0" || input == "sair") {
                break;
            }
            else if (input == "1") {
                // Submenu de gerenciamento de usuários
                bool voltar_menu_principal = false;
                while (!voltar_menu_principal && client.is_connected()) {
                    std::cout << "\n===== GERENCIAMENTO DE USUÁRIOS =====" << std::endl;
                    std::cout << "1. Criar novo usuário" << std::endl;
                    std::cout << "2. Listar todos os usuários" << std::endl;
                    std::cout << "3. Atualizar usuário" << std::endl;
                    std::cout << "4. Desativar usuário" << std::endl;
                    std::cout << "5. Reativar usuário" << std::endl;
                    std::cout << "6. Excluir usuário" << std::endl;
                    std::cout << "0. Voltar ao menu principal" << std::endl;
                    std::cout << "Escolha uma opção: ";
                    std::getline(std::cin, input);
                    
                    if (input == "0") {
                        voltar_menu_principal = true;
                    }
                    else if (input == "1") {
                        teste_usuarios(client);
                    }
                    else if (input == "2") {
                        listar_usuarios(client);
                    }
                    else if (input == "3") {
                        atualizar_usuario(client);
                    }
                    else if (input == "4") {
                        desativar_usuario(client);
                    }
                    else if (input == "5") {
                        reativar_usuario(client);
                    }
                    else if (input == "6") {
                        excluir_usuario(client);
                    }
                    else {
                        std::cout << "Opção inválida!" << std::endl;
                    }
                }
            }
            else if (input == "2") {
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
