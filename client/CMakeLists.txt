cmake_minimum_required(VERSION 3.20)
project(deeper_hub_client VERSION 0.1.0 LANGUAGES CXX)

# Definir C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Opções de compilação
option(BUILD_TESTS "Build tests" OFF)

# Configuração do vcpkg (gerenciador de pacotes C++)
if(DEFINED ENV{VCPKG_ROOT} AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
        CACHE STRING "Vcpkg toolchain file")
endif()

# Dependências
find_package(websocketpp CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(Boost REQUIRED COMPONENTS system thread)
find_package(nlohmann_json CONFIG REQUIRED)

# Incluir diretórios
include_directories(
    ${PROJECT_SOURCE_DIR}/include
    ${Boost_INCLUDE_DIRS}
)

# Arquivos fonte
set(SOURCES
    src/main.cpp
    src/websocket_client.cpp
    src/database_operations.cpp
)

# Arquivos de cabeçalho
set(HEADERS
    include/websocket_client.hpp
    include/database_operations.hpp
)

# Executável principal
add_executable(deeper_hub_client ${SOURCES} ${HEADERS})

# Vincular bibliotecas
target_link_libraries(deeper_hub_client PRIVATE
    OpenSSL::SSL
    OpenSSL::Crypto
    ${Boost_LIBRARIES}
    nlohmann_json::nlohmann_json
)

# Configuração para testes (opcional)
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# Copiar arquivos de configuração para o diretório de build
configure_file(${PROJECT_SOURCE_DIR}/config/config.json
               ${CMAKE_BINARY_DIR}/config.json COPYONLY)

# Instalação
install(TARGETS deeper_hub_client DESTINATION bin)
install(FILES ${CMAKE_BINARY_DIR}/config.json DESTINATION bin)
