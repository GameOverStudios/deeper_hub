@echo off
echo === Instalando Meson e dependencias para o projeto Deeper_Hub ===
echo.

REM Verificar se Python está instalado
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Erro: Python nao encontrado. Por favor, instale o Python 3.6 ou superior.
    echo Visite: https://www.python.org/downloads/
    exit /b 1
)

REM Verificar se pip está instalado
where pip >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Erro: pip nao encontrado. Instalando pip...
    python -m ensurepip --upgrade
    if %ERRORLEVEL% neq 0 (
        echo Falha ao instalar pip.
        exit /b 1
    )
)

REM Verificar se MinGW está instalado
where gcc >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo MinGW-w64 nao encontrado. Instalando MinGW-w64...
    
    REM Baixar instalador do MinGW-w64
    echo Baixando MinGW-w64...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/niXman/mingw-builds-binaries/releases/download/15.1.0-rt_v12-rev0/x86_64-15.1.0-release-posix-seh-msvcrt-rt_v12-rev0.7z' -OutFile 'mingw64.7z'"
    
    REM Extrair usando 7-Zip
    echo Extraindo MinGW-w64...
    "C:\Program Files\7-Zip\7z.exe" x mingw64.7z -oc:\ -y
    
    REM Adicionar MinGW ao PATH
    echo Adicionando MinGW ao PATH...
    setx PATH "%PATH%;C:\mingw64\bin"
    set "PATH=%PATH%;C:\mingw64\bin"
    
    echo MinGW-w64 instalado com sucesso.
) else (
    echo MinGW-w64 já está instalado.
)

REM Verificar se Ninja está instalado
where ninja >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Ninja build system nao encontrado. Instalando Ninja...
    
    REM Baixar Ninja
    echo Baixando Ninja...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-win.zip' -OutFile 'ninja-build.zip'"
    
    REM Extrair Ninja para o diretório bin do MinGW
    echo Extraindo Ninja...
    "C:\Program Files\7-Zip\7z.exe" x ninja-build.zip -oC:\mingw64\bin -y
    
    echo Ninja instalado com sucesso.
) else (
    echo Ninja já está instalado.
)

REM Instalar ou atualizar Meson
echo Instalando/atualizando Meson...
pip install --upgrade meson

REM Verificar se Meson foi instalado corretamente
where meson >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Erro: Meson nao foi instalado corretamente. Verifique se o diretório de scripts do Python está no PATH.
    exit /b 1
) else (
    echo Meson instalado com sucesso.
)

REM Verificar se o vcpkg está configurado
if "%VCPKG_ROOT%"=="" (
    echo AVISO: Variável de ambiente VCPKG_ROOT não definida.
    
    if exist "C:\vcpkg" (
        set "VCPKG_ROOT=C:\vcpkg"
        echo Usando vcpkg encontrado em: %VCPKG_ROOT%
    ) else (
        echo vcpkg não encontrado.
        echo Execute o script setup_vcpkg.bat no diretório vcpkg para instalar o vcpkg.
        echo Comando: %~dp0..\vcpkg\setup_vcpkg.bat
    )
)

REM Configurar o projeto com Meson
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
echo === Instalação concluída com sucesso! ===
echo.
echo Para compilar o projeto, execute:
echo cd build
echo meson compile
echo.
echo Para executar o projeto após a compilação:
echo .\deeper_client.exe

pause