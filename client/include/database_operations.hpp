#pragma once

#include "websocket_client.hpp"
#include <string>
#include <vector>
#include <optional>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

namespace deeper_hub {

/**
 * @brief Cliente para operações de banco de dados via WebSocket
 * 
 * Esta classe implementa operações CRUD e joins para comunicação
 * com o servidor Deeper_Hub via WebSocket.
 */
class DatabaseOperations {
public:
    /**
     * @brief Construtor
     * 
     * @param client Cliente WebSocket já conectado e autenticado
     */
    explicit DatabaseOperations(std::shared_ptr<WebSocketClient> client);
    
    /**
     * @brief Cria um novo usuário
     * 
     * @param username Nome de usuário
     * @param email Email do usuário
     * @param password Senha do usuário
     * @param is_active Indica se o usuário está ativo
     * @return std::pair<bool, std::string> Par com sucesso/falha e ID do usuário criado (ou mensagem de erro)
     */
    std::pair<bool, std::string> create_user(
        const std::string& username,
        const std::string& email,
        const std::string& password,
        bool is_active = true
    );
    
    /**
     * @brief Obtém um usuário pelo ID
     * 
     * @param user_id ID do usuário
     * @return std::optional<json> Dados do usuário ou std::nullopt se não encontrado
     */
    std::optional<json> get_user(const std::string& user_id);
    
    /**
     * @brief Atualiza um usuário existente
     * 
     * @param user_id ID do usuário
     * @param user_data Dados do usuário a serem atualizados
     * @return bool true se a atualização foi bem-sucedida, false caso contrário
     */
    bool update_user(const std::string& user_id, const json& user_data);
    
    /**
     * @brief Busca usuários com base em condições
     * 
     * @param conditions Condições de busca (ex: {"is_active": true})
     * @return std::vector<json> Lista de usuários encontrados
     */
    std::vector<json> find_users(const json& conditions);
    
    /**
     * @brief Cria um novo perfil
     * 
     * @param user_id ID do usuário associado ao perfil
     * @param display_name Nome de exibição
     * @param bio Biografia
     * @param avatar_url URL do avatar
     * @return std::pair<bool, std::string> Par com sucesso/falha e ID do perfil criado (ou mensagem de erro)
     */
    std::pair<bool, std::string> create_profile(
        const std::string& user_id,
        const std::string& display_name,
        const std::string& bio,
        const std::string& avatar_url
    );
    
    /**
     * @brief Atualiza um perfil existente
     * 
     * @param profile_id ID do perfil
     * @param profile_data Dados do perfil a serem atualizados
     * @return bool true se a atualização foi bem-sucedida, false caso contrário
     */
    bool update_profile(const std::string& profile_id, const json& profile_data);
    
    /**
     * @brief Realiza um inner join entre usuários e perfis
     * 
     * @param conditions Condições para o join (opcional)
     * @return std::vector<json> Resultados do join
     */
    std::vector<json> inner_join_users_profiles(const json& conditions = json::object());
    
    /**
     * @brief Realiza um left join entre usuários e perfis
     * 
     * @param conditions Condições para o join (opcional)
     * @return std::vector<json> Resultados do join
     */
    std::vector<json> left_join_users_profiles(const json& conditions = json::object());
    
    /**
     * @brief Realiza um right join entre usuários e perfis
     * 
     * @param conditions Condições para o join (opcional)
     * @return std::vector<json> Resultados do join
     */
    std::vector<json> right_join_users_profiles(const json& conditions = json::object());

private:
    std::shared_ptr<WebSocketClient> client_;
    
    /**
     * @brief Envia uma operação de banco de dados e aguarda a resposta
     * 
     * @param operation Tipo de operação (create, read, update, delete, find)
     * @param schema Nome do schema (user, profile)
     * @param data Dados da operação (opcional)
     * @param id ID do registro (opcional)
     * @param conditions Condições para find (opcional)
     * @return json Resposta do servidor
     */
    json send_database_operation(
        const std::string& operation,
        const std::string& schema,
        const json& data = json::object(),
        const std::string& id = "",
        const json& conditions = json::object()
    );
    
    /**
     * @brief Envia uma operação de join e aguarda a resposta
     * 
     * @param join_type Tipo de join (inner, left, right)
     * @param schemas Schemas a serem unidos
     * @param on Condições de junção
     * @param conditions Condições adicionais (opcional)
     * @return json Resposta do servidor
     */
    json send_join_operation(
        const std::string& join_type,
        const std::vector<std::string>& schemas,
        const json& on,
        const json& conditions = json::object()
    );
    
    /**
     * @brief Gera um timestamp em milissegundos
     * 
     * @return int64_t Timestamp atual em milissegundos
     */
    int64_t get_timestamp_ms();
    
    /**
     * @brief Gera um ID de requisição único
     * 
     * @return std::string UUID v4
     */
    std::string generate_request_id();
};

} // namespace deeper_hub
