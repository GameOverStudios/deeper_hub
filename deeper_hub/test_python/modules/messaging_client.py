#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from modules.user_client import UserClient
from modules.logger import get_logger

class MessagingClient(UserClient):
    """
    Implementa as funcionalidades de mensagens e canais para o cliente DeeperHub.
    """
    
    def __init__(self, host="localhost", port=4000, log_level="info"):
        """Inicializa o cliente com o endereço do servidor."""
        super().__init__(host, port, log_level)
        from modules.logger import DeeperHubLogger
        self.logger = get_logger("MessagingClient", DeeperHubLogger.LOG_LEVELS.get(log_level.lower(), 20))
    
    async def create_channel(self, channel_name, metadata=None):
        """Cria um novo canal."""
        if not self.access_token:
            self.Logger.warn("Tentativa de criar canal sem autenticação")
            return False
            
        payload = {
            "action": "create",  # Ação correta conforme implementado no servidor
            "name": channel_name,  # Nome do parâmetro correto
            "metadata": metadata or {}
        }
        
        self.logger.info(f"Criando canal: {channel_name}")
        response = await self.send_message("channel", payload)
        
        if response.get("type") == "channel.create.success":
            channel_id = response['payload'].get('id', 'N/A')
            self.logger.info(f"Canal {channel_name} criado com sucesso, ID: {channel_id}")
            print(f"✅ Canal {channel_name} criado com sucesso")
            print(f"🔢 ID do canal: {channel_id}")
            return True
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            self.logger.error(f"Falha ao criar canal: {error_msg}", response=response)
            print(f"❌ Falha ao criar canal: {error_msg}")
            return False
    
    async def subscribe_channel(self, channel_name):
        """Inscreve o usuário em um canal."""
        if not self.access_token:
            self.Logger.warn("Tentativa de inscrição em canal sem autenticação")
            return False
            
        payload = {
            "action": "subscribe",  # Ação correta conforme implementado no servidor
            "name": channel_name  # Servidor espera 'name' em vez de 'channel_name'
        }
        
        self.logger.info(f"Inscrevendo no canal: {channel_name}")
        response = await self.send_message("channel", payload)
        
        if response.get("type") == "channel.subscribe.success":
            self.logger.info(f"Inscrito no canal {channel_name} com sucesso")
            print(f"✅ Inscrito no canal {channel_name} com sucesso")
            return True
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            self.logger.error(f"Falha ao se inscrever no canal: {error_msg}", response=response)
            print(f"❌ Falha ao se inscrever no canal: {error_msg}")
            return False
    
    async def publish_message(self, channel_name, content, metadata=None):
        """Publica uma mensagem em um canal."""
        if not self.access_token:
            self.Logger.warn("Tentativa de publicar mensagem sem autenticação")
            return False
        
        # Enviar para o tipo 'channel' com ação 'message'
        payload = {
            "action": "message",
            "channel_name": channel_name,
            "content": content,
            "metadata": metadata or {}
        }
        
        self.logger.info(f"Publicando mensagem no canal: {channel_name}")
        self.logger.debug("Conteúdo da mensagem", content=content[:50] + "..." if len(content) > 50 else content)
        response = await self.send_message("channel", payload)
        
        if response.get("type") == "channel.message.success":
            message_id = response['payload'].get('id', 'N/A')
            self.logger.info(f"Mensagem publicada no canal {channel_name}, ID: {message_id}")
            print(f"✅ Mensagem publicada no canal {channel_name}")
            print(f"🆔 ID da mensagem: {message_id}")
            return True
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            self.logger.error(f"Falha ao publicar mensagem: {error_msg}", response=response)
            print(f"❌ Falha ao publicar mensagem: {error_msg}")
            return False
    
    async def send_direct_message(self, recipient_id, content, metadata=None):
        """Envia uma mensagem direta para outro usuário."""
        if not self.access_token:
            self.Logger.warn("Tentativa de enviar mensagem direta sem autenticação")
            return False
        
        # Enviar para o tipo 'user' com ação 'message'
        payload = {
            "action": "message",
            "recipient_id": recipient_id,
            "content": content,
            "metadata": metadata or {}
        }
        
        self.logger.info(f"Enviando mensagem direta para usuário ID: {recipient_id}")
        self.logger.debug("Conteúdo da mensagem direta", content=content[:50] + "..." if len(content) > 50 else content)
        response = await self.send_message("user", payload)
        
        if response.get("type") == "user.message.success":
            message_id = response['payload'].get('id', 'N/A')
            self.logger.info(f"Mensagem direta enviada para usuário {recipient_id}, ID: {message_id}")
            print(f"✅ Mensagem enviada para o usuário {recipient_id}")
            print(f"🆔 ID da mensagem: {message_id}")
            return True
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            self.logger.error(f"Falha ao enviar mensagem direta: {error_msg}", response=response)
            print(f"❌ Falha ao enviar mensagem: {error_msg}")
            return False
    
    async def get_message_history(self, other_user_id, limit=20):
        """Obtém o histórico de mensagens com outro usuário."""
        if not self.access_token:
            self.Logger.warn("Tentativa de acessar histórico de mensagens sem autenticação")
            return False
            
        payload = {
            "action": "get_history",  # Corrigido para a ação esperada pelo servidor
            "other_user_id": other_user_id,
            "limit": limit
        }
        
        self.logger.info(f"Obtendo histórico de mensagens com usuário ID: {other_user_id}, limite: {limit}")
        response = await self.send_message("message", payload)
        
        if response.get("type") == "message.history.success":
            messages = response["payload"].get("messages", [])
            self.logger.info(f"Histórico recuperado: {len(messages)} mensagens encontradas")
            print(f"✅ {len(messages)} mensagens encontradas:")
            
            for i, msg in enumerate(messages, 1):
                sender = "Você" if msg.get("sender_id") == self.user_id else f"Usuário {msg.get('sender_id')}"
                print(f"{i}. [{msg.get('timestamp')}] {sender}: {msg.get('content')}")
                self.logger.debug(f"Mensagem {i}", sender=sender, timestamp=msg.get('timestamp'), content=msg.get('content')[:30] + "..." if len(msg.get('content', '')) > 30 else msg.get('content', ''))
                
            return messages
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            self.logger.error(f"Falha ao obter histórico: {error_msg}", response=response)
            print(f"❌ Falha ao obter histórico: {error_msg}")
            return []
            
    async def list_channels(self):
        """Lista todos os canais disponíveis."""
        if not self.access_token:
            self.Logger.warn("Tentativa de listar canais sem autenticação")
            return False
            
        payload = {
            "action": "list"  # Ação correta conforme implementado no servidor
        }
        
        self.logger.info("Listando todos os canais disponíveis")
        response = await self.send_message("channel", payload)
        
        if response.get("type") == "channel.list.success":
            channels = response["payload"].get("channels", [])
            self.logger.info(f"{len(channels)} canais encontrados")
            print(f"✅ {len(channels)} canais encontrados:")
            
            for i, channel in enumerate(channels, 1):
                channel_name = channel.get('name')
                channel_id = channel.get('id')
                self.logger.debug(f"Canal {i}", name=channel_name, id=channel_id)
                print(f"{i}. {channel_name} (ID: {channel_id})")
                if channel.get('description'):
                    print(f"   Descrição: {channel.get('description')}")
                
            return channels
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            self.logger.error(f"Falha ao listar canais: {error_msg}", response=response)
            print(f"❌ Falha ao listar canais: {error_msg}")
            return []
            
    async def get_channel(self, channel_id):
        """Obtém detalhes de um canal específico."""
        if not self.access_token:
            self.Logger.warn("Tentativa de obter detalhes de canal sem autenticação")
            return False
            
        payload = {
            "action": "get",  # Ação correta conforme implementado no servidor
            "channel_id": channel_id
        }
        
        self.logger.info(f"Obtendo detalhes do canal ID: {channel_id}")
        response = await self.send_message("channel", payload)
        
        if response.get("type") == "channel.get.success":
            channel = response["payload"]
            channel_name = channel.get('name')
            channel_id = channel.get('id')
            members_count = len(channel.get('members', []))
            
            self.logger.info(f"Canal encontrado: {channel_name} (ID: {channel_id}), {members_count} membros")
            print(f"✅ Canal encontrado:")
            print(f"ID: {channel_id}")
            print(f"Nome: {channel_name}")
            if channel.get('description'):
                print(f"Descrição: {channel.get('description')}")
            print(f"Membros: {members_count}")
            return channel
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            self.logger.error(f"Falha ao obter detalhes do canal: {error_msg}", response=response)
            print(f"❌ Falha ao obter detalhes do canal: {error_msg}")
            return None
