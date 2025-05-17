#ifndef DEEPER_CLIENT_WEBSOCKET_CLIENT_H
#define DEEPER_CLIENT_WEBSOCKET_CLIENT_H

#include <string>
#include <functional>
#include <nlohmann/json.hpp>
#include <windows.h>
#include <winhttp.h>

class WebSocketClient {
public:
    WebSocketClient();
    ~WebSocketClient();

    // Conectar ao servidor WebSocket
    bool connect(const std::string& host, int port);

    // Enviar mensagem de texto
    bool sendTextMessage(const nlohmann::json& jsonMessage);

    // Enviar mensagem binária
    bool sendBinaryMessage(const std::vector<uint8_t>& data);

    // Receber mensagens (bloqueante)
    bool receiveMessage(std::string& message);

    // Fechar conexão
    void close();

    // Verificar se está conectado
    bool isConnected() const;

private:
    // Sessão HTTP
    HINTERNET m_hSession;
    // Conexão HTTP
    HINTERNET m_hConnection;
    // Requisição HTTP
    HINTERNET m_hRequest;
    // WebSocket
    HINTERNET m_hWebSocket;
    // Status da conexão
    bool m_connected;

    // Converter string para wstring
    std::wstring stringToWideString(const std::string& str);
};

#endif // DEEPER_CLIENT_WEBSOCKET_CLIENT_H
