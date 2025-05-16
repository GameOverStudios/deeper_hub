#!/usr/bin/env python3
"""
Cliente WebSocket para testar a comunicação com o servidor Deeper_Hub.

Este script:
- Conecta-se ao servidor WebSocket
- Envia mensagens de autenticação
- Envia heartbeats periódicos
- Processa mensagens recebidas
"""

import json
import time
import threading
import websocket
import logging

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger('websocket_client')

class DeeperHubClient:
    """Cliente WebSocket para o Deeper_Hub."""
    
    def __init__(self, url="ws://localhost:4000/socket/websocket", auth_token="test_token"):
        """
        Inicializa o cliente WebSocket.
        
        Args:
            url: URL do servidor WebSocket
            auth_token: Token de autenticação
        """
        self.url = url
        self.auth_token = auth_token
        self.ws = None
        self.connected = False
        self.should_reconnect = True
        self.heartbeat_thread = None
        
    def connect(self):
        """Conecta ao servidor WebSocket."""
        try:
            # Configuração do WebSocket
            websocket.enableTrace(True)
            self.ws = websocket.WebSocketApp(
                self.url,
                on_open=self.on_open,
                on_message=self.on_message,
                on_error=self.on_error,
                on_close=self.on_close
            )
            
            # Inicia a conexão em uma thread separada
            self.ws_thread = threading.Thread(target=self.ws.run_forever)
            self.ws_thread.daemon = True
            self.ws_thread.start()
            
            logger.info(f"Conectando ao servidor: {self.url}")
            return True
        except Exception as e:
            logger.error(f"Erro ao conectar: {e}")
            return False
            
    def on_open(self, ws):
        """Callback quando a conexão é estabelecida."""
        logger.info("Conexão estabelecida")
        self.connected = True
        
        # Envia mensagem de join com autenticação
        self.join_channel()
        
        # Inicia o heartbeat
        self.start_heartbeat()
        
    def on_message(self, ws, message):
        """Callback quando uma mensagem é recebida."""
        try:
            logger.info(f"Mensagem recebida: {message}")
            data = json.loads(message)
            
            # Processa diferentes tipos de mensagens
            if 'event' in data:
                event_type = data['event']
                if event_type == 'phx_reply' and data.get('ref') == '1':
                    if data.get('payload', {}).get('status') == 'ok':
                        logger.info("Autenticação bem-sucedida")
                    else:
                        logger.error(f"Erro na autenticação: {data}")
                elif event_type == 'heartbeat_response':
                    logger.info("Heartbeat recebido")
                else:
                    logger.info(f"Evento recebido: {event_type}")
        except Exception as e:
            logger.error(f"Erro ao processar mensagem: {e}")
            
    def on_error(self, ws, error):
        """Callback quando ocorre um erro."""
        logger.error(f"Erro na conexão: {error}")
        
    def on_close(self, ws, close_status_code, close_msg):
        """Callback quando a conexão é fechada."""
        logger.info(f"Conexão fechada: {close_status_code} - {close_msg}")
        self.connected = False
        
        # Tenta reconectar se necessário
        if self.should_reconnect:
            logger.info("Tentando reconectar em 5 segundos...")
            time.sleep(5)
            self.connect()
            
    def join_channel(self):
        """Envia mensagem para entrar no canal."""
        join_message = {
            "topic": "websocket",
            "event": "phx_join",
            "payload": {"auth_token": self.auth_token},
            "ref": "1"
        }
        self.send_message(join_message)
        logger.info("Mensagem de join enviada")
        
    def send_heartbeat(self):
        """Envia mensagem de heartbeat."""
        heartbeat_message = {
            "topic": "websocket",
            "event": "heartbeat",
            "payload": {"timestamp": int(time.time())},
            "ref": str(int(time.time()))
        }
        self.send_message(heartbeat_message)
        logger.debug("Heartbeat enviado")
        
    def start_heartbeat(self):
        """Inicia o envio periódico de heartbeats."""
        def heartbeat_loop():
            while self.connected:
                self.send_heartbeat()
                time.sleep(15)  # Envia heartbeat a cada 15 segundos
                
        self.heartbeat_thread = threading.Thread(target=heartbeat_loop)
        self.heartbeat_thread.daemon = True
        self.heartbeat_thread.start()
        
    def send_message(self, message):
        """Envia uma mensagem para o servidor."""
        if self.connected:
            try:
                self.ws.send(json.dumps(message))
                return True
            except Exception as e:
                logger.error(f"Erro ao enviar mensagem: {e}")
                return False
        else:
            logger.warning("Tentativa de enviar mensagem sem conexão")
            return False
            
    def send_custom_message(self, event, payload):
        """Envia uma mensagem personalizada para o servidor."""
        message = {
            "topic": "websocket",
            "event": event,
            "payload": payload,
            "ref": str(int(time.time()))
        }
        return self.send_message(message)
        
    def disconnect(self):
        """Desconecta do servidor."""
        self.should_reconnect = False
        if self.ws:
            self.ws.close()
            logger.info("Desconectado do servidor")

def main():
    """Função principal."""
    client = DeeperHubClient()
    
    # Conecta ao servidor
    if client.connect():
        try:
            # Mantém o programa em execução
            while True:
                cmd = input("\nComandos disponíveis:\n"
                           "1. Enviar mensagem personalizada\n"
                           "2. Enviar heartbeat\n"
                           "3. Sair\n"
                           "Digite o número do comando: ")
                
                if cmd == "1":
                    event = input("Digite o tipo de evento: ")
                    payload_str = input("Digite o payload (JSON): ")
                    try:
                        payload = json.loads(payload_str)
                        client.send_custom_message(event, payload)
                    except json.JSONDecodeError:
                        logger.error("Payload inválido. Use formato JSON.")
                
                elif cmd == "2":
                    client.send_heartbeat()
                    logger.info("Heartbeat enviado manualmente")
                
                elif cmd == "3":
                    break
                
                else:
                    logger.warning("Comando inválido")
                    
        except KeyboardInterrupt:
            logger.info("Programa interrompido pelo usuário")
        finally:
            client.disconnect()
    else:
        logger.error("Não foi possível conectar ao servidor")

if __name__ == "__main__":
    main()
