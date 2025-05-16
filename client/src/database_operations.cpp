#include "database_operations.hpp"
#include <chrono>
#include <random>
#include <sstream>
#include <iostream>

namespace deeper_hub {

DatabaseOperations::DatabaseOperations(std::shared_ptr<WebSocketClient> client)
    : client_(client)
{
    if (!client_->is_connected() || !client_->is_authenticated()) {
        throw std::runtime_error("Cliente WebSocket deve estar conectado e autenticado");
    }
}

std::pair<bool, std::string> DatabaseOperations::create_user(
    const std::string& username,
    const std::string& email,
    const std::string& password,
    bool is_active
) {
    // Prepara os dados do usuário
    json user_data = {
        {"username", username},
        {"email", email},
        {"password", password},
        {"is_active", is_active}
    };
    
    // Envia a operação de criação
    json response = send_database_operation("create", "user", user_data);
    
    // Verifica o resultado
    if (response.contains("status") && response["status"] == "success") {
        std::string user_id;
        
        // Extrai o ID do usuário criado
        if (response.contains("data")) {
            try {
                auto data = response["data"];
                if (data.is_object() && data.contains("id")) {
                    user_id = data["id"];
                } else if (data.is_string()) {
                    // Tenta decodificar se for uma string JSON
                    try {
                        json data_obj = json::parse(data.get<std::string>());
                        if (data_obj.is_object() && data_obj.contains("id")) {
                            user_id = data_obj["id"];
                        }
                    } catch (...) {
                        std::cerr << "Não foi possível decodificar os dados como JSON" << std::endl;
                    }
                }
            } catch (const std::exception& e) {
                std::cerr << "Erro ao extrair ID do usuário: " << e.what() << std::endl;
            }
        }
        
        return {true, user_id};
    } else {
        std::string error_message = "Falha ao criar usuário";
        if (response.contains("error")) {
            error_message = response["error"];
        }
        return {false, error_message};
    }
}

std::optional<json> DatabaseOperations::get_user(const std::string& user_id) {
    // Envia a operação de leitura
    json response = send_database_operation("read", "user", json::object(), user_id);
    
    // Verifica o resultado
    if (response.contains("status") && response["status"] == "success" && response.contains("data")) {
        try {
            auto data = response["data"];
            if (data.is_object()) {
                return data;
            } else if (data.is_string()) {
                // Tenta decodificar se for uma string JSON
                try {
                    return json::parse(data.get<std::string>());
                } catch (...) {
                    std::cerr << "Não foi possível decodificar os dados como JSON" << std::endl;
                }
            }
        } catch (const std::exception& e) {
            std::cerr << "Erro ao processar dados do usuário: " << e.what() << std::endl;
        }
    }
    
    return std::nullopt;
}

bool DatabaseOperations::update_user(const std::string& user_id, const json& user_data) {
    // Envia a operação de atualização
    json response = send_database_operation("update", "user", user_data, user_id);
    
    // Verifica o resultado
    return response.contains("status") && response["status"] == "success";
}

std::vector<json> DatabaseOperations::find_users(const json& conditions) {
    // Envia a operação de busca
    json response = send_database_operation("find", "user", json::object(), "", conditions);
    
    std::vector<json> results;
    
    // Verifica o resultado
    if (response.contains("status") && response["status"] == "success" && response.contains("data")) {
        try {
            auto data = response["data"];
            if (data.is_array()) {
                for (const auto& item : data) {
                    results.push_back(item);
                }
            } else if (data.is_string()) {
                // Tenta decodificar se for uma string JSON
                try {
                    json data_array = json::parse(data.get<std::string>());
                    if (data_array.is_array()) {
                        for (const auto& item : data_array) {
                            results.push_back(item);
                        }
                    }
                } catch (...) {
                    std::cerr << "Não foi possível decodificar os dados como JSON" << std::endl;
                }
            }
        } catch (const std::exception& e) {
            std::cerr << "Erro ao processar resultados da busca: " << e.what() << std::endl;
        }
    }
    
    return results;
}

std::pair<bool, std::string> DatabaseOperations::create_profile(
    const std::string& user_id,
    const std::string& display_name,
    const std::string& bio,
    const std::string& avatar_url
) {
    // Prepara os dados do perfil
    json profile_data = {
        {"user_id", user_id},
        {"display_name", display_name},
        {"bio", bio},
        {"avatar_url", avatar_url}
    };
    
    // Envia a operação de criação
    json response = send_database_operation("create", "profile", profile_data);
    
    // Verifica o resultado
    if (response.contains("status") && response["status"] == "success") {
        std::string profile_id;
        
        // Extrai o ID do perfil criado
        if (response.contains("data")) {
            try {
                auto data = response["data"];
                if (data.is_object() && data.contains("id")) {
                    profile_id = data["id"];
                } else if (data.is_string()) {
                    // Tenta decodificar se for uma string JSON
                    try {
                        json data_obj = json::parse(data.get<std::string>());
                        if (data_obj.is_object() && data_obj.contains("id")) {
                            profile_id = data_obj["id"];
                        }
                    } catch (...) {
                        std::cerr << "Não foi possível decodificar os dados como JSON" << std::endl;
                    }
                }
            } catch (const std::exception& e) {
                std::cerr << "Erro ao extrair ID do perfil: " << e.what() << std::endl;
            }
        }
        
        return {true, profile_id};
    } else {
        std::string error_message = "Falha ao criar perfil";
        if (response.contains("error")) {
            error_message = response["error"];
        }
        return {false, error_message};
    }
}

bool DatabaseOperations::update_profile(const std::string& profile_id, const json& profile_data) {
    // Envia a operação de atualização
    json response = send_database_operation("update", "profile", profile_data, profile_id);
    
    // Verifica o resultado
    return response.contains("status") && response["status"] == "success";
}

std::vector<json> DatabaseOperations::inner_join_users_profiles(const json& conditions) {
    // Condições de junção
    json on = {
        {"user.id", "profile.user_id"}
    };
    
    // Envia a operação de join
    json response = send_join_operation("inner", {"user", "profile"}, on, conditions);
    
    std::vector<json> results;
    
    // Verifica o resultado
    if (response.contains("status") && response["status"] == "success" && response.contains("data")) {
        try {
            auto data = response["data"];
            if (data.is_array()) {
                for (const auto& item : data) {
                    results.push_back(item);
                }
            } else if (data.is_string()) {
                // Tenta decodificar se for uma string JSON
                try {
                    json data_array = json::parse(data.get<std::string>());
                    if (data_array.is_array()) {
                        for (const auto& item : data_array) {
                            results.push_back(item);
                        }
                    }
                } catch (...) {
                    std::cerr << "Não foi possível decodificar os dados como JSON" << std::endl;
                }
            }
        } catch (const std::exception& e) {
            std::cerr << "Erro ao processar resultados do join: " << e.what() << std::endl;
        }
    }
    
    return results;
}

std::vector<json> DatabaseOperations::left_join_users_profiles(const json& conditions) {
    // Condições de junção
    json on = {
        {"user.id", "profile.user_id"}
    };
    
    // Envia a operação de join
    json response = send_join_operation("left", {"user", "profile"}, on, conditions);
    
    std::vector<json> results;
    
    // Verifica o resultado
    if (response.contains("status") && response["status"] == "success" && response.contains("data")) {
        try {
            auto data = response["data"];
            if (data.is_array()) {
                for (const auto& item : data) {
                    results.push_back(item);
                }
            } else if (data.is_string()) {
                // Tenta decodificar se for uma string JSON
                try {
                    json data_array = json::parse(data.get<std::string>());
                    if (data_array.is_array()) {
                        for (const auto& item : data_array) {
                            results.push_back(item);
                        }
                    }
                } catch (...) {
                    std::cerr << "Não foi possível decodificar os dados como JSON" << std::endl;
                }
            }
        } catch (const std::exception& e) {
            std::cerr << "Erro ao processar resultados do join: " << e.what() << std::endl;
        }
    }
    
    return results;
}

std::vector<json> DatabaseOperations::right_join_users_profiles(const json& conditions) {
    // Condições de junção
    json on = {
        {"user.id", "profile.user_id"}
    };
    
    // Envia a operação de join
    json response = send_join_operation("right", {"user", "profile"}, on, conditions);
    
    std::vector<json> results;
    
    // Verifica o resultado
    if (response.contains("status") && response["status"] == "success" && response.contains("data")) {
        try {
            auto data = response["data"];
            if (data.is_array()) {
                for (const auto& item : data) {
                    results.push_back(item);
                }
            } else if (data.is_string()) {
                // Tenta decodificar se for uma string JSON
                try {
                    json data_array = json::parse(data.get<std::string>());
                    if (data_array.is_array()) {
                        for (const auto& item : data_array) {
                            results.push_back(item);
                        }
                    }
                } catch (...) {
                    std::cerr << "Não foi possível decodificar os dados como JSON" << std::endl;
                }
            }
        } catch (const std::exception& e) {
            std::cerr << "Erro ao processar resultados do join: " << e.what() << std::endl;
        }
    }
    
    return results;
}

json DatabaseOperations::send_database_operation(
    const std::string& operation,
    const std::string& schema,
    const json& data,
    const std::string& id,
    const json& conditions
) {
    // Cria a mensagem no formato que o servidor espera
    json database_operation = {
        {"operation", operation},
        {"schema", schema},
        {"request_id", generate_request_id()},
        {"timestamp", get_timestamp_ms()}
    };
    
    // Adiciona campos opcionais se fornecidos
    if (!data.empty()) {
        // IMPORTANTE: o campo data deve ser uma string JSON, não um objeto JSON
        database_operation["data"] = data.dump();
    }
    
    if (!id.empty()) {
        database_operation["id"] = id;
    }
    
    if (!conditions.empty()) {
        // IMPORTANTE: o campo conditions deve ser uma string JSON, não um objeto JSON
        database_operation["conditions"] = conditions.dump();
    }
    
    // Cria o payload da mensagem
    json payload = {
        {"database_operation", database_operation}
    };
    
    // Cria a mensagem no formato Phoenix WebSocket
    json message = {
        {"topic", "websocket"},
        {"event", "message"},  // Usa o evento message que o servidor espera
        {"payload", payload.dump()},  // IMPORTANTE: o payload deve ser uma string JSON, não um objeto JSON
        {"ref", generate_request_id()}
    };
    
    // Envia a mensagem
    std::cout << "Enviando operação de banco de dados: " << operation << " - " << schema << std::endl;
    if (!client_->send_message(message)) {
        std::cerr << "Erro ao enviar mensagem" << std::endl;
        return json();
    }
    
    // Aguarda a resposta
    json response = client_->wait_for_response();
    return response;
}

json DatabaseOperations::send_join_operation(
    const std::string& join_type,
    const std::vector<std::string>& schemas,
    const json& on,
    const json& conditions
) {
    // Cria a mensagem no formato que o servidor espera
    json database_operation = {
        {"operation", "join"},
        {"join_type", join_type},
        {"schemas", schemas},
        {"on", on.dump()},  // IMPORTANTE: o campo on deve ser uma string JSON, não um objeto JSON
        {"request_id", generate_request_id()},
        {"timestamp", get_timestamp_ms()}
    };
    
    // Adiciona condições se fornecidas
    if (!conditions.empty()) {
        // IMPORTANTE: o campo conditions deve ser uma string JSON, não um objeto JSON
        database_operation["conditions"] = conditions.dump();
    }
    
    // Cria o payload da mensagem
    json payload = {
        {"database_operation", database_operation}
    };
    
    // Cria a mensagem no formato Phoenix WebSocket
    json message = {
        {"topic", "websocket"},
        {"event", "message"},  // Usa o evento message que o servidor espera
        {"payload", payload.dump()},  // IMPORTANTE: o payload deve ser uma string JSON, não um objeto JSON
        {"ref", generate_request_id()}
    };
    
    // Envia a mensagem
    std::cout << "Enviando operação de join: " << join_type << " - " 
              << schemas[0] << " e " << schemas[1] << std::endl;
    if (!client_->send_message(message)) {
        std::cerr << "Erro ao enviar mensagem" << std::endl;
        return json();
    }
    
    // Aguarda a resposta
    json response = client_->wait_for_response();
    return response;
}

int64_t DatabaseOperations::get_timestamp_ms() {
    auto now = std::chrono::system_clock::now();
    auto duration = now.time_since_epoch();
    return std::chrono::duration_cast<std::chrono::milliseconds>(duration).count();
}

std::string DatabaseOperations::generate_request_id() {
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
