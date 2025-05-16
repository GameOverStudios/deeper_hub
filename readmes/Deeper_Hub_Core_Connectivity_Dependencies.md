# Deeper_Hub - Dependências para Comunicação com Protocol Buffers

## 1. Protocol Buffers (protobuf)

### Dependências:

1. **Protocol Buffers Compiler (protoc)**
   - Versão recomendada: 3.21.12 ou superior
   - Baixar do site oficial: https://github.com/protocolbuffers/protobuf/releases
   - Instalação no Windows:
     ```bash
     # Baixar o instalador Windows
     wget https://github.com/protocolbuffers/protobuf/releases/download/v3.21.12/protoc-3.21.12-win64.zip
     # Extrair para pasta do projeto
     unzip protoc-3.21.12-win64.zip -d ./protobuf
     # Adicionar ao PATH
     set PATH=%PATH%;./protobuf/bin
     ```

2. **Biblioteca C++ do Protocol Buffers**
   - Versão recomendada: 3.21.12 ou superior
   - Instalação via vcpkg (recomendado para Windows):
     ```bash
     # Instalar vcpkg se ainda não tiver
     git clone https://github.com/Microsoft/vcpkg.git
     cd vcpkg
     bootstrap-vcpkg.bat
     
     # Instalar protobuf
     vcpkg install protobuf:x64-windows
     ```

   - Ou via CMake:
     ```bash
     # Baixar o código fonte
     git clone https://github.com/protocolbuffers/protobuf.git
     cd protobuf
     git submodule update --init --recursive
     
     # Compilar
     mkdir build && cd build
     cmake -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local ..
     cmake --build . --target install
     ```

## 2. WebSocket (websocketpp)

### Dependências:

1. **websocketpp**
   - Versão recomendada: 0.8.2 ou superior
   - Instalação via vcpkg:
     ```bash
     vcpkg install websocketpp:x64-windows
     ```

   - Ou via CMake:
     ```bash
     # Baixar o código fonte
     git clone https://github.com/zaphoyd/websocketpp.git
     cd websocketpp
     
     # Compilar
     mkdir build && cd build
     cmake ..
     cmake --build .
     ```

2. **Boost (dependência do websocketpp)**
   - Versão recomendada: 1.78.0 ou superior
   - Instalação via vcpkg:
     ```bash
     vcpkg install boost:x64-windows
     ```

## 3. ZeroMQ (opcional)

### Dependências:

1. **ZeroMQ**
   - Versão recomendada: 4.3.4 ou superior
   - Instalação via vcpkg:
     ```bash
     vcpkg install zeromq:x64-windows
     ```

   - Ou via CMake:
     ```bash
     # Baixar o código fonte
     git clone https://github.com/zeromq/libzmq.git
     cd libzmq
     
     # Compilar
     mkdir build && cd build
     cmake ..
     cmake --build .
     ```

## 4. ImGui

### Dependências:

1. **ImGui**
   - Versão recomendada: 1.89 ou superior
   - Instalação via vcpkg:
     ```bash
     vcpkg install imgui:x64-windows
     ```

   - Ou manualmente:
     ```bash
     # Baixar o código fonte
     git clone https://github.com/ocornut/imgui.git
     ```

## 5. Dependências Comuns

1. **CMake**
   - Versão recomendada: 3.20 ou superior
   - Baixar do site oficial: https://cmake.org/download/

2. **Visual Studio** (para Windows)
   - Versão recomendada: 2019 ou superior
   - Componentes necessários:
     - C++ development workload
     - Windows 10 SDK
     - C++ CMake tools

## 6. Configuração do Projeto

### CMakeLists.txt exemplo:
```cmake
project(ImGuiClient)

# Versão mínima do CMake
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Adicionar vcpkg
set(CMAKE_TOOLCHAIN_FILE "C:/vcpkg/scripts/buildsystems/vcpkg.cmake")

# Adicionar bibliotecas
find_package(Protobuf REQUIRED)
find_package(websocketpp REQUIRED)
find_package(Boost REQUIRED)

# Incluir diretórios
include_directories(
    ${Protobuf_INCLUDE_DIRS}
    ${websocketpp_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
)

# Adicionar fontes
file(GLOB SOURCES "src/*.cpp" "src/*.h")

# Criar executável
add_executable(ImGuiClient ${SOURCES})

# Linkar bibliotecas
target_link_libraries(
    ImGuiClient
    PRIVATE
    protobuf::libprotobuf
    websocketpp
    Boost::system
    Boost::thread
)
```

## 7. Estrutura de Arquivos Recomendada
```
ImGuiClient/
├── CMakeLists.txt
├── src/
│   ├── main.cpp
│   ├── network/
│   │   ├── websocket_client.cpp
│   │   ├── protobuf_handler.cpp
│   │   └── message_types.proto
│   └── ui/
│       ├── imgui_window.cpp
│       └── imgui_renderer.cpp
└── include/
    └── ImGuiClient/
        ├── network.hpp
        └── ui.hpp
```

## 8. Passos de Instalação

1. **Instalar vcpkg** (se ainda não tiver):
   ```bash
   git clone https://github.com/Microsoft/vcpkg.git
   cd vcpkg
   bootstrap-vcpkg.bat
   vcpkg integrate install
   ```

2. **Instalar dependências**:
   ```bash
   vcpkg install protobuf:x64-windows
   vcpkg install websocketpp:x64-windows
   vcpkg install boost:x64-windows
   vcpkg install imgui:x64-windows
   ```

3. **Compilar o projeto**:
   ```bash
   mkdir build
   cd build
   cmake ..
   cmake --build .
   ```

## 9. Considerações Finais

1. **Performance**:
   - Use o máximo de dependências estáticas possíveis
   - Compile em release mode
   - Use optimization flags (-O3)

2. **Depuração**:
   - Mantenha logs detalhados
   - Use assert em desenvolvimento
   - Implemente tratamento de erros robusto

3. **Manutenção**:
   - Mantenha dependências atualizadas
   - Documente configurações
   - Use submodules para bibliotecas externas
