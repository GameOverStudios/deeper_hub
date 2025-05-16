@echo off
echo Iniciando teste do WebSocket para Deeper_Hub
echo.
echo 1. Iniciando o servidor Elixir (em uma nova janela)
start cmd /k "cd c:\deeper_hub && mix phx.server"

echo 2. Aguardando o servidor iniciar (5 segundos)...
timeout /t 5 /nobreak > nul

echo 3. Instalando dependências Python
pip install -r requirements.txt

echo 4. Iniciando o cliente WebSocket Python
python websocket_client.py

echo.
echo Teste finalizado.
pause
