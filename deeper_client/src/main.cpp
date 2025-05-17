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

#pragma comment(lib, "winhttp.lib")

using json = nlohmann::json;

// Função para testar a conexão e envio de mensagens WebSocket
void testWebSocketConnection() {
    WebSocketClient client;
    
    std::cout << "\n===== TESTE DE CONEXÃO WEBSOCKET =====\n";
    std::cout << "Conectando ao servidor WebSocket localhost:8080...\n";
    
    if (client.connect("localhost", 8080)) {
        std::cout << "Conexão estabelecida com sucesso!\n";
        
        // Teste 1: Enviar mensagem de echo
        std::cout << "\n----- Teste 1: Enviar mensagem de echo -----\n";
        json echoMessage = {
            {"topic", "phoenix"}, // Tópico Phoenix
            {"event", "echo"}, // Evento
            {"payload", {
                {"message", "Olá, servidor!"}
            }},
            {"ref", "1"} // Referência para correlacionar respostas
        };
        
        if (client.sendTextMessage(echoMessage)) {
            std::string response;
            if (client.receiveMessage(response)) {
                std::cout << "Resposta recebida: " << response << "\n";
            }
        }
        
        // Pequena pausa para garantir que a mensagem seja processada
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        
        // Teste 2: Enviar mensagem para criar um usuário
        std::cout << "\n----- Teste 2: Criar um novo usuário -----\n";
        json createUserMessage = {
            {"topic", "user"}, // Tópico para operações de usuário
            {"event", "create"}, // Evento de criação
            {"payload", {
                {"username", "testuser"},
                {"email", "test@example.com"},
                {"password", "password123"}
            }},
            {"ref", "2"} // Referência para correlacionar respostas
        };
        
        if (client.sendTextMessage(createUserMessage)) {
            std::string response;
            if (client.receiveMessage(response)) {
                std::cout << "Resposta recebida: " << response << "\n";
            }
        }
        
        // Pequena pausa para garantir que a mensagem seja processada
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        
        // Teste 3: Enviar mensagem para autenticar um usuário
        std::cout << "\n----- Teste 3: Autenticar usuário -----\n";
        json authUserMessage = {
            {"topic", "user"},
            {"event", "authenticate"},
            {"payload", {
                {"username", "testuser"},
                {"password", "password123"}
            }},
            {"ref", "3"}
        };
        
        if (client.sendTextMessage(authUserMessage)) {
            std::string response;
            if (client.receiveMessage(response)) {
                std::cout << "Resposta recebida: " << response << "\n";
            }
        }
        
        // Pequena pausa para garantir que a mensagem seja processada
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        
        // Teste 4: Enviar mensagem para atualizar um usuário
        std::cout << "\n----- Teste 4: Atualizar usuário -----\n";
        json updateUserMessage = {
            {"topic", "user"},
            {"event", "update"},
            {"payload", {
                {"username", "testuser"},
                {"email", "updated@example.com"}
            }},
            {"ref", "4"}
        };
        
        if (client.sendTextMessage(updateUserMessage)) {
            std::string response;
            if (client.receiveMessage(response)) {
                std::cout << "Resposta recebida: " << response << "\n";
            }
        }
        
        // Pequena pausa para garantir que a mensagem seja processada
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        
        // Teste 5: Enviar mensagem para buscar um usuário
        std::cout << "\n----- Teste 5: Buscar usuário -----\n";
        json getUserMessage = {
            {"topic", "user"},
            {"event", "get"},
            {"payload", {
                {"username", "testuser"}
            }},
            {"ref", "5"}
        };
        
        if (client.sendTextMessage(getUserMessage)) {
            std::string response;
            if (client.receiveMessage(response)) {
                std::cout << "Resposta recebida: " << response << "\n";
            }
        }
        
        // Pequena pausa para garantir que a mensagem seja processada
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        
        // Teste 6: Enviar mensagem para excluir um usuário
        std::cout << "\n----- Teste 6: Excluir usuário -----\n";
        json deleteUserMessage = {
            {"topic", "user"},
            {"event", "delete"},
            {"payload", {
                {"username", "testuser"}
            }},
            {"ref", "6"}
        };
        
        if (client.sendTextMessage(deleteUserMessage)) {
            std::string response;
            if (client.receiveMessage(response)) {
                std::cout << "Resposta recebida: " << response << "\n";
            }
        }
        
        // Fechando a conexão
        std::cout << "\nFechando conexão...\n";
        client.close();
    } else {
        std::cerr << "Falha ao conectar ao servidor WebSocket.\n";
    }
}

int main(int argc, char* argv[]) {
    std::cout << "Iniciando cliente Deeper_Hub...\n";
    
    // Inicializa o COM (necessário para algumas versões do Windows)
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    
    // Inicializa o WinSock (necessário para WinHTTP)
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        std::cerr << "Falha ao inicializar o WinSock.\n";
        return 1;
    }
    
    try {
        // Testar a conexão WebSocket
        testWebSocketConnection();
    } catch (const std::exception& e) {
        std::cerr << "Erro: " << e.what() << std::endl;
        WSACleanup();
        CoUninitialize();
        return 1;
    }
    
    // Limpeza
    WSACleanup();
    CoUninitialize();
    
    std::cout << "Pressione Enter para sair...";
    std::cin.ignore();
    
    return 0;
}
