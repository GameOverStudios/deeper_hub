#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import asyncio
import json
import websockets
import uuid
import os
import sys
from datetime import datetime

# Adiciona o diretório pai ao path para importar o logger
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from modules.logger import get_logger

class DeeperHubClient:
    """
    Cliente WebSocket para testar a comunicação com o DeeperHub.
    Implementa a funcionalidade base de conexão e envio de mensagens.
    """
    
    # Referência aos níveis de log do DeeperHubLogger
    
    def __init__(self, host="localhost", port=4000, log_level="info"):
        """Inicializa o cliente com o endereço do servidor."""
        self.server_url = f"ws://{host}:{port}/ws"
        self.websocket = None
        self.access_token = None
        self.refresh_token = None
        self.user_id = None
        self.username = None
        
        # Configuração do logger
        from modules.logger import DeeperHubLogger
        level = DeeperHubLogger.LOG_LEVELS.get(log_level.lower(), 20)  # Default para INFO
        self.logger = get_logger("DeeperHubClient", level)
        
    async def connect(self):
        """Estabelece conexão com o servidor WebSocket."""
        try:
            self.logger.info(f"Tentando conectar a {self.server_url}")
            
            # Obtém configurações de segurança
            security_config = self.config["security"]
            origin = f"http://{self.server_url.split('://')[1].split('/')[0]}"
            
            # Verifica se a origem é permitida
            if origin not in security_config["allowed_origins"]:
                self.logger.warning(f"Origem {origin} não está na lista de origens permitidas")
            
            # Headers de segurança
            headers = {
                "Origin": origin,
                "User-Agent": security_config["user_agent"],
                "Sec-WebSocket-Protocol": security_config["websocket_protocol"]
            }
            
            self.websocket = await websockets.connect(
                self.server_url,
                extra_headers=headers,
                subprotocols=[security_config["websocket_protocol"]]
            )
            self.logger.info(f"Conexão estabelecida com {self.server_url}")
            return True
        except Exception as e:
            self.logger.error(f"Erro ao conectar: {e}")
            self.logger.log_exception(e, "connect")
            return False
            
    async def close(self):
        """Fecha a conexão com o servidor."""
        if self.websocket:
            try:
                await self.websocket.close()
                self.logger.info("Conexão fechada com sucesso")
            except Exception as e:
                self.logger.error(f"Erro ao fechar conexão: {e}")
                self.logger.log_exception(e, "close")
            
    async def send_message(self, message_type, payload):
        """Envia uma mensagem formatada para o servidor."""
        try:
            message = {
                "type": message_type,
                "payload": payload
            }
            
            # Gera um ID único para rastrear a requisição nos logs
            request_id = str(uuid.uuid4())[:8]
            
            message_json = json.dumps(message)
            self.logger.debug(f"Enviando mensagem [{request_id}]: {message_type}", payload=payload)
            
            # Envia a mensagem
            await self.websocket.send(message_json)
            
            # Aguarda e processa a resposta
            response = await self.websocket.recv()
            response_data = json.loads(response)
            
            # Registra a resposta recebida
            self.logger.log_response(response_data)
            
            return response_data
        except websockets.exceptions.ConnectionClosed as e:
            self.logger.critical(f"Conexão fechada durante o envio da mensagem: {e}")
            self.logger.log_exception(e, "send_message")
            raise
        except Exception as e:
            self.logger.error(f"Erro ao enviar mensagem: {e}")
            self.logger.log_exception(e, "send_message")
            raise
