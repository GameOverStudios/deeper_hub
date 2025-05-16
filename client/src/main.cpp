#include "websocket_client.hpp"
#include "database_operations.hpp"
#include <iostream>
#include <fstream>
#include <thread>
#include <chrono>
#include <memory>
#include <nlohmann/json.hpp>

using json = nlohmann::json;
using namespace deeper_hub;

// Função para carregar a configuração do arquivo
json load_config(const std::string& config_path) {
    try {
        std::ifstream file(config_path);
        if (!file.is_open()) {
            std::cerr << "Erro ao abrir arquivo de configuração: " << config_path << std::endl;
            return json::object();
        }
        
        json config;
        file >> config;
        return config;
    } catch (const std::exception& e) {
        std::cerr << "Erro ao carregar configuração: " << e.what() << std::endl;
        return json::object();
    }
}

// Função para exibir o menu principal
void display_menu() {
    std::cout << "\n=== Cliente Deeper_Hub ===\n";
    std::cout << "1. Criar usuário\n";
    std::cout << "2. Obter usuário por ID\n";
    std::cout << "3. Buscar usuários ativos\n";
    std::cout << "4. Criar perfil\n";
    std::cout << "5. Inner join usuários e perfis\n";
    std::cout << "6. Left join usuários e perfis\n";
    std::cout << "7. Right join usuários e perfis\n";
    std::cout << "0. Sair\n";
    std::cout << "Escolha uma opção: ";
}

int main(int argc, char* argv[]) {
    std::cout << "Iniciando cliente Deeper_Hub...\n";
    
    // Carrega a configuração
    std::string config_path = "config.json";
    if (argc > 1) {
        config_path = argv[1];
    }
    
    json config = load_config(config_path);
    if (config.empty()) {
        std::cerr << "Falha ao carregar configuração. Usando valores padrão.\n";
        config = {
            {"server", {
                {"url", "ws://localhost:4000/socket/websocket"},
                {"auth_token", "test_token"}
            }}
        };
    }
    
    // Extrai configurações
    std::string server_url = config["server"]["url"];
    std::string auth_token = config["server"]["auth_token"];
    bool use_tls = server_url.substr(0, 3) == "wss";
    
    std::cout << "Conectando ao servidor: " << server_url << std::endl;
    
    // Cria e conecta o cliente WebSocket
    auto ws_client = std::make_shared<WebSocketClient>(server_url, auth_token, use_tls);
    
    // Define callbacks
    ws_client->set_connection_callback([](bool connected) {
        if (connected) {
            std::cout << "Conexão estabelecida com o servidor\n";
        } else {
            std::cout << "Desconectado do servidor\n";
        }
    });
    
    ws_client->set_message_callback([](const json& message) {
        // Este callback é chamado para todas as mensagens recebidas
        // Útil para logging ou processamento assíncrono
    });
    
    // Conecta ao servidor
    if (!ws_client->connect()) {
        std::cerr << "Falha ao conectar ao servidor. Encerrando.\n";
        return 1;
    }
    
    // Inicia o heartbeat
    int heartbeat_interval = 30000;
    if (config.contains("connection") && config["connection"].contains("heartbeat_interval_ms")) {
        heartbeat_interval = config["connection"]["heartbeat_interval_ms"];
    }
    ws_client->start_heartbeat(heartbeat_interval);
    
    // Cria o cliente de operações de banco de dados
    DatabaseOperations db_ops(ws_client);
    
    // Variáveis para armazenar IDs criados
    std::string last_user_id;
    std::string last_profile_id;
    
    // Loop principal
    bool running = true;
    while (running && ws_client->is_connected()) {
        display_menu();
        
        int choice;
        std::cin >> choice;
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        
        switch (choice) {
            case 0: {
                // Sair
                running = false;
                break;
            }
            case 1: {
                // Criar usuário
                std::string username, email, password;
                
                std::cout << "Nome de usuário: ";
                std::getline(std::cin, username);
                
                std::cout << "Email: ";
                std::getline(std::cin, email);
                
                std::cout << "Senha: ";
                std::getline(std::cin, password);
                
                std::cout << "Criando usuário...\n";
                auto [success, user_id] = db_ops.create_user(username, email, password);
                
                if (success) {
                    std::cout << "✅ Usuário criado com sucesso. ID: " << user_id << std::endl;
                    last_user_id = user_id;
                } else {
                    std::cout << "❌ Falha ao criar usuário: " << user_id << std::endl;
                }
                break;
            }
            case 2: {
                // Obter usuário por ID
                std::string user_id;
                
                if (!last_user_id.empty()) {
                    std::cout << "Último ID de usuário criado: " << last_user_id << std::endl;
                    std::cout << "Usar este ID? (s/n): ";
                    std::string use_last;
                    std::getline(std::cin, use_last);
                    
                    if (use_last == "s" || use_last == "S") {
                        user_id = last_user_id;
                    }
                }
                
                if (user_id.empty()) {
                    std::cout << "ID do usuário: ";
                    std::getline(std::cin, user_id);
                }
                
                std::cout << "Obtendo usuário...\n";
                auto user = db_ops.get_user(user_id);
                
                if (user) {
                    std::cout << "✅ Usuário encontrado:\n";
                    std::cout << user.value().dump(2) << std::endl;
                } else {
                    std::cout << "❌ Usuário não encontrado\n";
                }
                break;
            }
            case 3: {
                // Buscar usuários ativos
                std::cout << "Buscando usuários ativos...\n";
                json conditions = {{"is_active", true}};
                auto users = db_ops.find_users(conditions);
                
                if (!users.empty()) {
                    std::cout << "✅ " << users.size() << " usuários encontrados:\n";
                    for (const auto& user : users) {
                        std::cout << "ID: " << user["id"] << ", Username: " << user["username"] << std::endl;
                    }
                } else {
                    std::cout << "❌ Nenhum usuário ativo encontrado\n";
                }
                break;
            }
            case 4: {
                // Criar perfil
                std::string user_id, display_name, bio, avatar_url;
                
                if (!last_user_id.empty()) {
                    std::cout << "Último ID de usuário criado: " << last_user_id << std::endl;
                    std::cout << "Usar este ID? (s/n): ";
                    std::string use_last;
                    std::getline(std::cin, use_last);
                    
                    if (use_last == "s" || use_last == "S") {
                        user_id = last_user_id;
                    }
                }
                
                if (user_id.empty()) {
                    std::cout << "ID do usuário: ";
                    std::getline(std::cin, user_id);
                }
                
                std::cout << "Nome de exibição: ";
                std::getline(std::cin, display_name);
                
                std::cout << "Biografia: ";
                std::getline(std::cin, bio);
                
                std::cout << "URL do avatar: ";
                std::getline(std::cin, avatar_url);
                
                std::cout << "Criando perfil...\n";
                auto [success, profile_id] = db_ops.create_profile(user_id, display_name, bio, avatar_url);
                
                if (success) {
                    std::cout << "✅ Perfil criado com sucesso. ID: " << profile_id << std::endl;
                    last_profile_id = profile_id;
                } else {
                    std::cout << "❌ Falha ao criar perfil: " << profile_id << std::endl;
                }
                break;
            }
            case 5: {
                // Inner join usuários e perfis
                std::cout << "Realizando inner join entre usuários e perfis...\n";
                auto results = db_ops.inner_join_users_profiles();
                
                if (!results.empty()) {
                    std::cout << "✅ " << results.size() << " resultados encontrados:\n";
                    for (const auto& result : results) {
                        std::cout << "Usuário: " << result["user"]["username"] 
                                 << ", Perfil: " << result["profile"]["display_name"] << std::endl;
                    }
                } else {
                    std::cout << "❌ Nenhum resultado encontrado\n";
                }
                break;
            }
            case 6: {
                // Left join usuários e perfis
                std::cout << "Realizando left join entre usuários e perfis...\n";
                auto results = db_ops.left_join_users_profiles();
                
                if (!results.empty()) {
                    std::cout << "✅ " << results.size() << " resultados encontrados:\n";
                    for (const auto& result : results) {
                        std::string username = result["user"]["username"];
                        std::string display_name = "N/A";
                        
                        if (result.contains("profile") && !result["profile"].is_null() && 
                            result["profile"].contains("display_name")) {
                            display_name = result["profile"]["display_name"];
                        }
                        
                        std::cout << "Usuário: " << username << ", Perfil: " << display_name << std::endl;
                    }
                } else {
                    std::cout << "❌ Nenhum resultado encontrado\n";
                }
                break;
            }
            case 7: {
                // Right join usuários e perfis
                std::cout << "Realizando right join entre usuários e perfis...\n";
                auto results = db_ops.right_join_users_profiles();
                
                if (!results.empty()) {
                    std::cout << "✅ " << results.size() << " resultados encontrados:\n";
                    for (const auto& result : results) {
                        std::string username = "N/A";
                        std::string display_name = "N/A";
                        
                        if (result.contains("user") && !result["user"].is_null() && 
                            result["user"].contains("username")) {
                            username = result["user"]["username"];
                        }
                        
                        if (result.contains("profile") && !result["profile"].is_null() && 
                            result["profile"].contains("display_name")) {
                            display_name = result["profile"]["display_name"];
                        }
                        
                        std::cout << "Usuário: " << username << ", Perfil: " << display_name << std::endl;
                    }
                } else {
                    std::cout << "❌ Nenhum resultado encontrado\n";
                }
                break;
            }
            default: {
                std::cout << "Opção inválida. Tente novamente.\n";
                break;
            }
        }
    }
    
    // Para o heartbeat e desconecta
    ws_client->stop_heartbeat();
    ws_client->disconnect();
    
    std::cout << "Cliente encerrado.\n";
    return 0;
}
