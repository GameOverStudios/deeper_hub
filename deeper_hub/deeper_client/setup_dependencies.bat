@echo off
echo === Configurando dependencias para o Deeper_Hub Client ===
echo.

REM Criar diretórios para bibliotecas externas se não existirem
if not exist external mkdir external
if not exist external\websocketpp mkdir external\websocketpp
if not exist external\boost mkdir external\boost
if not exist external\openssl mkdir external\openssl
if not exist external\openssl\include mkdir external\openssl\include

echo Baixando bibliotecas externas...

REM Baixar WebSocketPP (header-only)
echo Baixando WebSocketPP...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/zaphoyd/websocketpp/archive/refs/tags/0.8.2.zip' -OutFile 'websocketpp.zip' }"
"C:\Program Files\7-Zip\7z.exe" x websocketpp.zip -oexternal\temp -y
xcopy /E /Y external\temp\websocketpp-0.8.2\* external\websocketpp\
rmdir /S /Q external\temp
del websocketpp.zip

REM Baixar apenas os headers do Boost necessários (system, asio)
echo Baixando Boost headers necessários...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/boostorg/boost/archive/refs/tags/boost-1.83.0.zip' -OutFile 'boost.zip' }"
"C:\Program Files\7-Zip\7z.exe" x boost.zip -oexternal\temp -y
xcopy /E /Y external\temp\boost-boost-1.83.0\boost external\boost\boost\
rmdir /S /Q external\temp
del boost.zip

REM Baixar OpenSSL (apenas headers)
echo Baixando OpenSSL headers...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/openssl/openssl/archive/refs/tags/openssl-3.1.4.zip' -OutFile 'openssl.zip' }"
"C:\Program Files\7-Zip\7z.exe" x openssl.zip -oexternal\temp -y
xcopy /E /Y external\temp\openssl-openssl-3.1.4\include\* external\openssl\include\
rmdir /S /Q external\temp
del openssl.zip

echo.
echo Configurando o projeto com Meson...
if exist build (
    echo Removendo diretório build existente...
    rmdir /s /q build
)

echo Criando nova configuração de build...
meson setup build --buildtype=release

if %ERRORLEVEL% neq 0 (
    echo Erro ao configurar o projeto com Meson.
    exit /b 1
)

echo.
echo === Configuração concluída com sucesso! ===
echo.
echo Para compilar o projeto, execute:
echo cd build
echo meson compile
echo.

pause
