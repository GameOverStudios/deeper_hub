@echo off
setlocal enabledelayedexpansion

echo === Cliente C++ Deeper_Hub - Script de Compilacao ===

REM Verifica se o CMake esta instalado
where cmake >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Erro: CMake nao encontrado. Por favor, instale o CMake e adicione-o ao PATH.
    exit /b 1
)

REM Verifica se o vcpkg esta configurado
if "%VCPKG_ROOT%"=="" (
    echo AVISO: Variavel de ambiente VCPKG_ROOT nao definida.
    
    if exist "C:\vcpkg" (
        set "VCPKG_ROOT=C:\vcpkg"
        echo Usando vcpkg encontrado em: !VCPKG_ROOT!
    ) else if exist "%~dp0..\..\vcpkg" (
        set "VCPKG_ROOT=%~dp0..\..\vcpkg"
        echo Usando vcpkg encontrado em: !VCPKG_ROOT!
    ) else (
        echo vcpkg nao encontrado.
        echo Execute o script setup_vcpkg.bat no diretorio raiz do projeto para instalar o vcpkg.
        echo Comando: %~dp0..\setup_vcpkg.bat
        exit /b 1
    )
)

REM Verifica se as dependencias estao instaladas
echo Verificando dependencias...
set MISSING_DEPS=0

"%VCPKG_ROOT%\vcpkg" list | findstr "websocketpp" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo - websocketpp nao encontrado
    set /a MISSING_DEPS+=1
)

"%VCPKG_ROOT%\vcpkg" list | findstr "openssl" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo - openssl nao encontrado
    set /a MISSING_DEPS+=1
)

"%VCPKG_ROOT%\vcpkg" list | findstr "boost" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo - boost nao encontrado
    set /a MISSING_DEPS+=1
)

"%VCPKG_ROOT%\vcpkg" list | findstr "nlohmann-json" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo - nlohmann-json nao encontrado
    set /a MISSING_DEPS+=1
)

if %MISSING_DEPS% gtr 0 (
    echo.
    echo Dependencias ausentes detectadas. Deseja instalar automaticamente? (S/N)
    set /p INSTALL_DEPS=
    
    if /i "!INSTALL_DEPS!"=="S" (
        echo Instalando dependencias...
        "%VCPKG_ROOT%\vcpkg" install websocketpp:x64-windows openssl:x64-windows boost:x64-windows nlohmann-json:x64-windows
        if %ERRORLEVEL% neq 0 (
            echo Falha ao instalar dependencias.
            exit /b 1
        )
    ) else (
        echo.
        echo Para instalar manualmente, execute:
        echo "%VCPKG_ROOT%\vcpkg" install websocketpp:x64-windows openssl:x64-windows boost:x64-windows nlohmann-json:x64-windows
        exit /b 1
    )
)

REM Cria diretorio de build se nao existir
if not exist build mkdir build

REM Configura o projeto com CMake
echo.
echo Configurando projeto com CMake...
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake" -DCMAKE_BUILD_TYPE=Release

if %ERRORLEVEL% neq 0 (
    echo Falha na configuracao do CMake.
    exit /b 1
)

REM Compila o projeto
echo.
echo Compilando projeto...
cmake --build . --config Release

if %ERRORLEVEL% neq 0 (
    echo Falha na compilacao.
    exit /b 1
)

REM Copia o arquivo de configuracao para o diretorio de build
if not exist Release\config.json (
    echo Copiando arquivo de configuracao...
    copy ..\config\config.json Release\
)

echo.
echo Compilacao concluida com sucesso!
echo O executavel esta em: %~dp0build\Release\deeper_hub_client.exe

REM Pergunta se deseja executar o cliente
echo.
echo Deseja executar o cliente agora? (S/N)
set /p RUN_CLIENT=

if /i "%RUN_CLIENT%"=="S" (
    echo Executando cliente...
    cd Release
    deeper_hub_client.exe
)

endlocal
