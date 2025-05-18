#include <nlohmann/json.hpp>
#include <iostream>
#include <string>
#include <memory>
#include <windows.h>
#include <winhttp.h>
#include <sstream>
#include <thread>
#include <chrono>
#include "../include/websocket_client.h"
#include "../include/cpp_client_adapter.h"

#pragma comment(lib, "winhttp.lib")

using json = nlohmann::json;

// Função para executar os testes de WebSocket
void runWebSocketTests(const std::string& host, int port, const std::string& userId) {
    std::cout << "\n===== TESTE DE INTEGRAÇÃO WEBSOCKET C++ COM ELIXIR =====\n";
    std::cout << "Conectando a " << host << ":" << port << " com usuário " << userId << "\n";
    
    // Cria o adaptador
    CppClientAdapter adapter;
    
    // Conecta ao servidor
    if (!adapter.connect(host, port)) {
        std::cerr << "Falha ao conectar ao servidor. Encerrando.\n";
        return;
    }
    
    // Autentica o usuário
    if (!adapter.authenticate(userId)) {
        std::cerr << "Falha na autenticação. Encerrando.\n";
        adapter.disconnect();
        return;
    }
    
    std::cout << "\n=== Testando EchoHandler ===\n";
    adapter.testEchoHandler("Olá do cliente C++!");
    
    // Pausa para visualizar resultados
    std::this_thread::sleep_for(std::chrono::seconds(1));
    
    // Testa criação de usuário
    std::cout << "\n=== Testando UserHandler - Criar usuário ===\n";
    std::string username = "user_" + std::to_string(std::chrono::system_clock::now().time_since_epoch().count() % 10000);
    std::string email = username + "@example.com";
    std::string password = "senha123";
    
    bool userCreated = adapter.testUserCreate(username, email, password);
    std::string createdUserId = ""; // Seria preenchido com o ID retornado na resposta real
    
    if (userCreated) {
        // Normalmente extraíriamos o ID do usuário da resposta
        createdUserId = "user_id_123"; // Exemplo
        
        // Testa obtenção de usuário
        std::cout << "\n=== Testando UserHandler - Obter usuário ===\n";
        adapter.testUserGet(createdUserId);
        
        // Pausa para visualizar resultados
        std::this_thread::sleep_for(std::chrono::seconds(1));
        
        // Testa atualização de usuário
        std::cout << "\n=== Testando UserHandler - Atualizar usuário ===\n";
        adapter.testUserUpdate(createdUserId, username + "_updated", email);
        
        // Pausa para visualizar resultados
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    
    // Testa criação de canal
    std::cout << "\n=== Testando ChannelHandler - Criar canal ===\n";
    std::string channelName = "channel_" + std::to_string(std::chrono::system_clock::now().time_since_epoch().count() % 10000);
    bool channelCreated = adapter.testChannelCreate(channelName);
    
    if (channelCreated) {
        // Testa inscrição no canal
        std::cout << "\n=== Testando ChannelHandler - Inscrever-se no canal ===\n";
        adapter.testChannelSubscribe(channelName);
        
        // Pausa para visualizar resultados
        std::this_thread::sleep_for(std::chrono::seconds(1));
        
        // Testa publicação no canal
        std::cout << "\n=== Testando ChannelHandler - Publicar mensagem no canal ===\n";
        adapter.testChannelPublish(channelName, "Mensagem de teste para o canal");
        
        // Pausa para visualizar resultados
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    
    // Testa envio de mensagem direta
    std::cout << "\n=== Testando MessageHandler - Enviar mensagem direta ===\n";
    std::string recipientId = "recipient_123"; // ID de destinatário de exemplo
    bool messageSent = adapter.testMessageSend(recipientId, "Mensagem direta de teste");
    std::string messageId = ""; // Seria preenchido com o ID retornado na resposta real
    
    if (messageSent) {
        // Normalmente extraíriamos o ID da mensagem da resposta
        messageId = "message_id_123"; // Exemplo
        
        // Testa marcação de mensagem como lida
        std::cout << "\n=== Testando MessageHandler - Marcar mensagem como lida ===\n";
        adapter.testMessageMarkRead(messageId);
        
        // Pausa para visualizar resultados
        std::this_thread::sleep_for(std::chrono::seconds(1));
        
        // Testa obtenção de histórico de mensagens
        std::cout << "\n=== Testando MessageHandler - Obter histórico de mensagens ===\n";
        adapter.testMessageHistory(recipientId, 10, 0);
        
        // Pausa para visualizar resultados
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    
    // Testa exclusão de usuário, se foi criado
    if (!createdUserId.empty()) {
        std::cout << "\n=== Testando UserHandler - Excluir usuário ===\n";
        adapter.testUserDelete(createdUserId);
        
        // Pausa para visualizar resultados
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    
    // Desconecta
    std::cout << "\n=== Desconectando do servidor ===\n";
    adapter.disconnect();
    
    std::cout << "\n=== Teste concluído ===\n";
}

int main(int argc, char* argv[]) {
    std::cout << "Iniciando cliente Deeper_Hub...\n";
    
    // Parâmetros padrão
    std::string host = "localhost";
    int port = 4000;
    std::string userId = "test_user_123";
    
    // Processamento de argumentos de linha de comando
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        
        if (arg == "--host" && i + 1 < argc) {
            host = argv[++i];
        } else if (arg == "--port" && i + 1 < argc) {
            port = std::stoi(argv[++i]);
        } else if (arg == "--user" && i + 1 < argc) {
            userId = argv[++i];
        } else if (arg == "--help") {
            std::cout << "Uso: deeper_client [opções]\n"
                      << "Opções:\n"
                      << "  --host HOSTNAME    Endereço do servidor (padrão: localhost)\n"
                      << "  --port PORT        Porta do servidor (padrão: 4000)\n"
                      << "  --user USER_ID     ID do usuário para autenticação (padrão: test_user_123)\n"
                      << "  --help             Exibe esta ajuda\n";
            return 0;
        }
    }
    
    // Inicializa o COM (necessário para algumas versões do Windows)
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    
    // Inicializa o WinSock (necessário para WinHTTP)
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        std::cerr << "Falha ao inicializar o WinSock.\n";
        return 1;
    }
    
    try {
        // Executa os testes de WebSocket automaticamente
        std::cout << "Iniciando testes de WebSocket automaticamente...\n";
        runWebSocketTests(host, port, userId);
    } catch (const std::exception& e) {
        std::cerr << "Erro: " << e.what() << std::endl;
        WSACleanup();
        CoUninitialize();
        return 1;
    }
    
    // Limpeza
    WSACleanup();
    CoUninitialize();
    
    std::cout << "Saindo...";
    
    return 0;
}
