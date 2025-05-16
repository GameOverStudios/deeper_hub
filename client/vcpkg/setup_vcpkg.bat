@echo off
echo === Instalacao do vcpkg para o Deeper_Hub ===
echo.
echo Este script vai instalar o vcpkg em C:\vcpkg e configurar as variaveis de ambiente necessarias.
echo.
echo.
echo Executando script de instalacao do vcpkg...
powershell -ExecutionPolicy Bypass -File "%~dp0vcpkg.ps1"