# Cliente C++ para Deeper_Hub

Este é um cliente C++ para o projeto Deeper_Hub que implementa comunicação WebSocket com o servidor Elixir, permitindo operações de banco de dados e joins através de uma interface simples e robusta.

## Características

- Comunicação WebSocket com o servidor Deeper_Hub
- Suporte a autenticação via token
- Operações CRUD completas para usuários e perfis
- Suporte a diferentes tipos de joins (inner, left, right)
- Serialização/deserialização JSON
- Heartbeat automático para manter a conexão ativa
- Tratamento de reconexão
- Configuração via arquivo JSON

## Requisitos

- CMake 3.20+
- Compilador C++ com suporte a C++17 (MSVC, GCC, Clang)
- vcpkg (para gerenciamento de dependências)
- Dependências:
  - websocketpp (0.8.2+)
  - OpenSSL
  - Boost (system, thread)
  - nlohmann_json

## Instalação das Dependências no Windows

### 1. Instalar vcpkg

```batch
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg integrate install
```

### 2. Instalar as dependências via vcpkg

```batch
.\vcpkg install websocketpp:x64-windows
.\vcpkg install openssl:x64-windows
.\vcpkg install boost:x64-windows
.\vcpkg install nlohmann-json:x64-windows
```

## Compilação

### Usando CMake com vcpkg

```batch
mkdir build
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/caminho/para/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build . --config Release
```

### Usando Visual Studio

1. Abra o Visual Studio
2. Selecione "Abrir um projeto ou solução local"
3. Navegue até a pasta do cliente e selecione o arquivo CMakeLists.txt
4. Configure o projeto para usar vcpkg
5. Compile o projeto

## Configuração

O cliente usa um arquivo de configuração `config.json` que deve estar no mesmo diretório do executável. Exemplo de configuração:

```json
{
    "server": {
        "url": "ws://localhost:4000/socket/websocket",
        "auth_token": "test_token"
    },
    "connection": {
        "reconnect_attempts": 5,
        "reconnect_delay_ms": 3000,
        "heartbeat_interval_ms": 30000
    },
    "logging": {
        "level": "info",
        "console_output": true,
        "file_output": true,
        "file_path": "logs/client.log"
    }
}
```

## Uso

Após compilar o projeto, execute o binário gerado:

```batch
.\build\Release\deeper_hub_client.exe
```

O programa apresentará um menu interativo com as seguintes opções:

1. Criar usuário
2. Obter usuário por ID
3. Buscar usuários ativos
4. Criar perfil
5. Inner join usuários e perfis
6. Left join usuários e perfis
7. Right join usuários e perfis
0. Sair

## Formato das Mensagens WebSocket

O cliente segue o formato de mensagens Phoenix WebSocket, com a seguinte estrutura:

```json
{
    "topic": "websocket",
    "event": "message",
    "payload": "...", // String JSON serializada
    "ref": "uuid-v4"
}
```

O payload para operações de banco de dados segue o formato:

```json
{
    "database_operation": {
        "operation": "create|read|update|delete|find|join",
        "schema": "user|profile",
        "data": "...", // String JSON serializada
        "id": "record-id", // Para operações que requerem ID
        "conditions": "...", // String JSON serializada para operações find
        "request_id": "uuid-v4",
        "timestamp": 1621234567890
    }
}
```

## Integração com Aplicações Existentes

Para integrar este cliente em uma aplicação C++ existente:

1. Inclua os arquivos de cabeçalho em seu projeto
2. Crie uma instância de `WebSocketClient` e conecte ao servidor
3. Use a classe `DatabaseOperations` para realizar operações de banco de dados

Exemplo:

```cpp
#include "websocket_client.hpp"
#include "database_operations.hpp"

// Criar e conectar o cliente WebSocket
auto ws_client = std::make_shared<deeper_hub::WebSocketClient>(
    "ws://localhost:4000/socket/websocket", 
    "test_token"
);
ws_client->connect();

// Criar o cliente de operações de banco de dados
deeper_hub::DatabaseOperations db_ops(ws_client);

// Criar um usuário
auto [success, user_id] = db_ops.create_user(
    "username", 
    "email@example.com", 
    "password123"
);

// Obter um usuário
auto user = db_ops.get_user(user_id);

// Desconectar
ws_client->disconnect();
```

## Licença

Este projeto é parte do Deeper_Hub e segue a mesma licença do projeto principal.

## Contribuição

Para contribuir com este projeto, siga as diretrizes de codificação do Deeper_Hub e certifique-se de que todas as alterações sejam testadas adequadamente.
