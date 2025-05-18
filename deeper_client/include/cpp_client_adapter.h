#ifndef DEEPER_CLIENT_CPP_CLIENT_ADAPTER_H
#define DEEPER_CLIENT_CPP_CLIENT_ADAPTER_H

#include "websocket_client.h"
#include <string>

/**
 * @class CppClientAdapter
 * @brief Adaptador para testar os handlers WebSocket do Elixir a partir do cliente C++
 * 
 * Esta classe fornece uma interface simplificada para testar todos os handlers
 * WebSocket implementados no servidor Elixir.
 */
class CppClientAdapter {
public:
    /**
     * @brief Construtor
     */
    CppClientAdapter();
    
    /**
     * @brief Destrutor
     */
    ~CppClientAdapter();
    
    /**
     * @brief Conecta ao servidor WebSocket
     * @param host Endereço do servidor
     * @param port Porta do servidor
     * @return true se a conexão foi estabelecida com sucesso, false caso contrário
     */
    bool connect(const std::string& host, int port);
    
    /**
     * @brief Desconecta do servidor WebSocket
     */
    void disconnect();
    
    /**
     * @brief Verifica se está conectado ao servidor
     * @return true se está conectado, false caso contrário
     */
    bool isConnected() const;
    
    /**
     * @brief Autentica o cliente com um ID de usuário
     * @param userId ID do usuário para autenticação
     * @return true se a autenticação foi bem-sucedida, false caso contrário
     */
    bool authenticate(const std::string& userId);
    
    // Métodos para testar o EchoHandler
    
    /**
     * @brief Testa o EchoHandler
     * @param message Mensagem a ser ecoada
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testEchoHandler(const std::string& message);
    
    // Métodos para testar o UserHandler
    
    /**
     * @brief Testa a criação de usuário
     * @param username Nome de usuário
     * @param email Email do usuário
     * @param password Senha do usuário
     * @param userId Referência para armazenar o ID do usuário criado
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testUserCreate(const std::string& username, const std::string& email, const std::string& password, std::string& userId);
    
    /**
     * @brief Testa a obtenção de usuário
     * @param userId ID do usuário
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testUserGet(const std::string& userId);
    
    /**
     * @brief Testa a atualização de usuário
     * @param userId ID do usuário
     * @param username Novo nome de usuário
     * @param email Novo email
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testUserUpdate(const std::string& userId, const std::string& username, const std::string& email);
    
    /**
     * @brief Testa a exclusão de usuário
     * @param userId ID do usuário
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testUserDelete(const std::string& userId);
    
    // Métodos para testar o ChannelHandler
    
    /**
     * @brief Testa a criação de canal
     * @param channelName Nome do canal
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testChannelCreate(const std::string& channelName);
    
    /**
     * @brief Testa a inscrição em um canal
     * @param channelName Nome do canal
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testChannelSubscribe(const std::string& channelName);
    
    /**
     * @brief Testa a publicação de mensagem em um canal
     * @param channelName Nome do canal
     * @param content Conteúdo da mensagem
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testChannelPublish(const std::string& channelName, const std::string& content);
    
    // Métodos para testar o MessageHandler
    
    /**
     * @brief Testa o envio de mensagem direta
     * @param recipientId ID do destinatário
     * @param content Conteúdo da mensagem
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testMessageSend(const std::string& recipientId, const std::string& content);
    
    /**
     * @brief Testa a obtenção de histórico de mensagens
     * @param otherUserId ID do outro usuário
     * @param limit Limite de mensagens
     * @param offset Deslocamento
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testMessageHistory(const std::string& otherUserId, int limit = 50, int offset = 0);
    
    /**
     * @brief Testa a marcação de mensagem como lida
     * @param messageId ID da mensagem
     * @return true se o teste foi bem-sucedido, false caso contrário
     */
    bool testMessageMarkRead(const std::string& messageId);
    
private:
    WebSocketClient m_client;
    bool m_authenticated;
    std::string m_userId;
    
    /**
     * @brief Verifica se está conectado ao servidor
     * @return true se está conectado, false caso contrário
     */
    bool ensureConnected();
    
    /**
     * @brief Verifica se está autenticado
     * @return true se está autenticado, false caso contrário
     */
    bool ensureAuthenticated();
    
    /**
     * @brief Obtém o timestamp atual em milissegundos
     * @return Timestamp como int64_t
     */
    int64_t getCurrentTimestamp();
};

#endif // DEEPER_CLIENT_CPP_CLIENT_ADAPTER_H
