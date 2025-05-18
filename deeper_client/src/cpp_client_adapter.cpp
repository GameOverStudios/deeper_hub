#include "../include/cpp_client_adapter.h"
#include <iostream>
#include <string>
#include <sstream>
#include <chrono>
#include <thread>
#include <functional>

CppClientAdapter::CppClientAdapter() : m_authenticated(false) {
    std::cout << "Inicializando CppClientAdapter..." << std::endl;
}

CppClientAdapter::~CppClientAdapter() {
    disconnect();
}

bool CppClientAdapter::connect(const std::string& host, int port) {
    std::cout << "Conectando ao servidor WebSocket em " << host << ":" << port << std::endl;
    
    // Tenta conectar ao servidor WebSocket
    if (!m_client.connect(host, port)) {
        std::cerr << "Falha ao conectar ao servidor WebSocket" << std::endl;
        return false;
    }
    
    std::cout << "Conexão WebSocket estabelecida com sucesso!" << std::endl;
    return true;
}

void CppClientAdapter::disconnect() {
    if (m_client.isConnected()) {
        std::cout << "Desconectando do servidor WebSocket..." << std::endl;
        m_client.close();
    }
}

bool CppClientAdapter::isConnected() const {
    return m_client.isConnected();
}

bool CppClientAdapter::authenticate(const std::string& userId) {
    if (!m_client.isConnected()) {
        std::cerr << "Erro: não está conectado ao servidor WebSocket" << std::endl;
        return false;
    }
    
    std::cout << "Autenticando com ID de usuário: " << userId << std::endl;
    
    // Cria a mensagem de autenticação no formato esperado pelo servidor
    nlohmann::json authMessage = {
        {"type", "auth"},
        {"payload", {
            {"user_id", userId}
        }}
    };
    
    // Envia a mensagem de autenticação
    if (!m_client.sendTextMessage(authMessage)) {
        std::cerr << "Erro ao enviar mensagem de autenticação" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de autenticação" << std::endl;
        return false;
    }
    
    // Verifica se a autenticação foi bem-sucedida
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("type") && responseJson["type"] == "auth.success") {
            std::cout << "Autenticação bem-sucedida!" << std::endl;
            m_authenticated = true;
            m_userId = userId;
            return true;
        } else {
            std::cerr << "Erro na autenticação: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta de autenticação: " << e.what() << std::endl;
        return false;
    }
}

// Testa o EchoHandler
bool CppClientAdapter::testEchoHandler(const std::string& message) {
    if (!ensureConnected()) return false;
    
    std::cout << "Testando EchoHandler com mensagem: " << message << std::endl;
    
    // Cria a mensagem de eco
    nlohmann::json echoMessage = {
        {"type", "echo"},
        {"payload", {
            {"message", message},
            {"timestamp", getCurrentTimestamp()}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(echoMessage)) {
        std::cerr << "Erro ao enviar mensagem de eco" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de eco" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("type") && responseJson["type"] == "echo.response") {
            std::cout << "Resposta de eco recebida: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o UserHandler - Criar usuário
bool CppClientAdapter::testUserCreate(const std::string& username, const std::string& email, const std::string& password) {
    if (!ensureConnected()) return false;
    
    std::cout << "Testando UserHandler - Criar usuário: " << username << std::endl;
    
    // Cria a mensagem para criar usuário
    nlohmann::json createUserMessage = {
        {"type", "user"},
        {"payload", {
            {"action", "create"},
            {"username", username},
            {"email", email},
            {"password", password}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(createUserMessage)) {
        std::cerr << "Erro ao enviar mensagem de criação de usuário" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de criação de usuário" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("type") && responseJson["type"] == "user.create.response") {
            std::cout << "Usuário criado com sucesso: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o UserHandler - Obter usuário
bool CppClientAdapter::testUserGet(const std::string& userId) {
    if (!ensureConnected()) return false;
    
    std::cout << "Testando UserHandler - Obter usuário: " << userId << std::endl;
    
    // Cria a mensagem para obter usuário
    nlohmann::json getUserMessage = {
        {"type", "user"},
        {"payload", {
            {"action", "get"},
            {"id", userId}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(getUserMessage)) {
        std::cerr << "Erro ao enviar mensagem de obtenção de usuário" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de obtenção de usuário" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("type") && responseJson["type"] == "user.get.response") {
            std::cout << "Usuário obtido com sucesso: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o UserHandler - Atualizar usuário
bool CppClientAdapter::testUserUpdate(const std::string& userId, const std::string& username, const std::string& email) {
    if (!ensureConnected()) return false;
    
    std::cout << "Testando UserHandler - Atualizar usuário: " << userId << std::endl;
    
    // Cria a mensagem para atualizar usuário
    nlohmann::json updateUserMessage = {
        {"type", "user"},
        {"payload", {
            {"action", "update"},
            {"id", userId},
            {"username", username},
            {"email", email}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(updateUserMessage)) {
        std::cerr << "Erro ao enviar mensagem de atualização de usuário" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de atualização de usuário" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("type") && responseJson["type"] == "user.update.response") {
            std::cout << "Usuário atualizado com sucesso: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o UserHandler - Excluir usuário
bool CppClientAdapter::testUserDelete(const std::string& userId) {
    if (!ensureConnected()) return false;
    
    std::cout << "Testando UserHandler - Excluir usuário: " << userId << std::endl;
    
    // Cria a mensagem para excluir usuário
    nlohmann::json deleteUserMessage = {
        {"type", "user"},
        {"payload", {
            {"action", "delete"},
            {"id", userId}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(deleteUserMessage)) {
        std::cerr << "Erro ao enviar mensagem de exclusão de usuário" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de exclusão de usuário" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("type") && responseJson["type"] == "user.delete.response") {
            std::cout << "Usuário excluído com sucesso: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o ChannelHandler - Criar canal
bool CppClientAdapter::testChannelCreate(const std::string& channelName) {
    if (!ensureAuthenticated()) return false;
    
    std::cout << "Testando ChannelHandler - Criar canal: " << channelName << std::endl;
    
    // Cria a mensagem para criar canal
    nlohmann::json createChannelMessage = {
        {"type", "channel"},
        {"payload", {
            {"action", "create"},
            {"name", channelName},
            {"metadata", {
                {"description", "Canal de teste criado pelo cliente C++"},
                {"created_at", getCurrentTimestamp()}
            }}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(createChannelMessage)) {
        std::cerr << "Erro ao enviar mensagem de criação de canal" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de criação de canal" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("channel_id")) {
            std::cout << "Canal criado com sucesso: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o ChannelHandler - Inscrever-se em um canal
bool CppClientAdapter::testChannelSubscribe(const std::string& channelName) {
    if (!ensureAuthenticated()) return false;
    
    std::cout << "Testando ChannelHandler - Inscrever-se no canal: " << channelName << std::endl;
    
    // Cria a mensagem para inscrever-se no canal
    nlohmann::json subscribeMessage = {
        {"type", "channel"},
        {"payload", {
            {"action", "subscribe"},
            {"name", channelName}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(subscribeMessage)) {
        std::cerr << "Erro ao enviar mensagem de inscrição no canal" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de inscrição no canal" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("channel_name")) {
            std::cout << "Inscrito no canal com sucesso: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o ChannelHandler - Publicar mensagem em um canal
bool CppClientAdapter::testChannelPublish(const std::string& channelName, const std::string& content) {
    if (!ensureAuthenticated()) return false;
    
    std::cout << "Testando ChannelHandler - Publicar mensagem no canal: " << channelName << std::endl;
    
    // Cria a mensagem para publicar no canal
    nlohmann::json publishMessage = {
        {"type", "channel"},
        {"payload", {
            {"action", "publish"},
            {"channel_name", channelName},
            {"content", content},
            {"metadata", {
                {"sent_at", getCurrentTimestamp()},
                {"client", "cpp_client"}
            }}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(publishMessage)) {
        std::cerr << "Erro ao enviar mensagem para o canal" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de publicação no canal" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("message_id")) {
            std::cout << "Mensagem publicada com sucesso: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o MessageHandler - Enviar mensagem direta
bool CppClientAdapter::testMessageSend(const std::string& recipientId, const std::string& content) {
    if (!ensureAuthenticated()) return false;
    
    std::cout << "Testando MessageHandler - Enviar mensagem para: " << recipientId << std::endl;
    
    // Cria a mensagem direta
    nlohmann::json directMessage = {
        {"type", "message"},
        {"payload", {
            {"action", "send"},
            {"recipient_id", recipientId},
            {"content", content},
            {"metadata", {
                {"sent_at", getCurrentTimestamp()},
                {"client", "cpp_client"}
            }}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(directMessage)) {
        std::cerr << "Erro ao enviar mensagem direta" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de envio de mensagem" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("message_id")) {
            std::cout << "Mensagem enviada com sucesso: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o MessageHandler - Obter histórico de mensagens
bool CppClientAdapter::testMessageHistory(const std::string& otherUserId, int limit, int offset) {
    if (!ensureAuthenticated()) return false;
    
    std::cout << "Testando MessageHandler - Obter histórico de mensagens com: " << otherUserId << std::endl;
    
    // Cria a mensagem para obter histórico
    nlohmann::json historyMessage = {
        {"type", "message"},
        {"payload", {
            {"action", "history"},
            {"user_id", otherUserId},
            {"limit", limit},
            {"offset", offset}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(historyMessage)) {
        std::cerr << "Erro ao enviar solicitação de histórico" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de histórico" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("messages")) {
            std::cout << "Histórico de mensagens recebido: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Testa o MessageHandler - Marcar mensagem como lida
bool CppClientAdapter::testMessageMarkRead(const std::string& messageId) {
    if (!ensureAuthenticated()) return false;
    
    std::cout << "Testando MessageHandler - Marcar mensagem como lida: " << messageId << std::endl;
    
    // Cria a mensagem para marcar como lida
    nlohmann::json markReadMessage = {
        {"type", "message"},
        {"payload", {
            {"action", "mark_read"},
            {"message_id", messageId}
        }}
    };
    
    // Envia a mensagem
    if (!m_client.sendTextMessage(markReadMessage)) {
        std::cerr << "Erro ao enviar solicitação para marcar mensagem como lida" << std::endl;
        return false;
    }
    
    // Aguarda a resposta
    std::string response;
    if (!m_client.receiveMessage(response)) {
        std::cerr << "Erro ao receber resposta de marcação de mensagem" << std::endl;
        return false;
    }
    
    // Verifica a resposta
    try {
        nlohmann::json responseJson = nlohmann::json::parse(response);
        if (responseJson.contains("message_id")) {
            std::cout << "Mensagem marcada como lida: " << response << std::endl;
            return true;
        } else {
            std::cerr << "Resposta inesperada: " << response << std::endl;
            return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Erro ao processar resposta: " << e.what() << std::endl;
        return false;
    }
}

// Métodos auxiliares
bool CppClientAdapter::ensureConnected() {
    if (!m_client.isConnected()) {
        std::cerr << "Erro: não está conectado ao servidor WebSocket" << std::endl;
        return false;
    }
    return true;
}

bool CppClientAdapter::ensureAuthenticated() {
    if (!ensureConnected()) return false;
    
    if (!m_authenticated) {
        std::cerr << "Erro: não está autenticado. Autentique-se primeiro." << std::endl;
        return false;
    }
    return true;
}

std::string CppClientAdapter::getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto now_ms = std::chrono::time_point_cast<std::chrono::milliseconds>(now);
    auto epoch = now_ms.time_since_epoch();
    auto value = std::chrono::duration_cast<std::chrono::milliseconds>(epoch);
    return std::to_string(value.count());
}
