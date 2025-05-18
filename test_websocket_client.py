#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import asyncio
import json
import websockets
import uuid
import argparse
import sys
from datetime import datetime

class DeeperHubClient:
    """
    Cliente WebSocket para testar a comunicação com o DeeperHub.
    Implementa autenticação JWT e operações de usuário, mensagens e canais.
    """
    
    def __init__(self, host="localhost", port=4000):
        """Inicializa o cliente com o endereço do servidor."""
        self.server_url = f"ws://{host}:{port}/ws"
        self.websocket = None
        self.access_token = None
        self.refresh_token = None
        self.user_id = None
        self.username = None
        
    async def connect(self):
        """Estabelece conexão com o servidor WebSocket."""
        try:
            self.websocket = await websockets.connect(self.server_url)
            print(f"✅ Conexão estabelecida com {self.server_url}")
            return True
        except Exception as e:
            print(f"❌ Erro ao conectar: {e}")
            return False
            
    async def close(self):
        """Fecha a conexão com o servidor."""
        if self.websocket:
            await self.websocket.close()
            print("✅ Conexão fechada")
            
    async def send_message(self, message_type, payload):
        """Envia uma mensagem formatada para o servidor."""
        message = {
            "type": message_type,
            "payload": payload
        }
        
        message_json = json.dumps(message)
        await self.websocket.send(message_json)
        print(f"📤 Mensagem enviada: {message_type}")
        
        # Aguarda e processa a resposta
        response = await self.websocket.recv()
        response_data = json.loads(response)
        print(f"📥 Resposta recebida: {response_data['type']}")
        return response_data
        
    async def login(self, username, password):
        """Realiza login no sistema usando o novo fluxo de autenticação JWT."""
        payload = {
            "action": "login",
            "username": username,
            "password": password
        }
        
        response = await self.send_message("auth", payload)
        
        if response["type"] == "auth.login.success":
            self.access_token = response["payload"]["access_token"]
            self.refresh_token = response["payload"]["refresh_token"]
            self.user_id = response["payload"]["user_id"]
            self.username = response["payload"]["username"]
            print(f"✅ Login bem-sucedido como {username}")
            print(f"🔑 User ID: {self.user_id}")
            print(f"🔒 Token expira em: {response['payload']['expires_in']} segundos")
            return True
        else:
            print(f"❌ Falha no login: {response['payload']['message']}")
            return False
            
    async def logout(self):
        """Realiza logout do sistema."""
        if not self.access_token or not self.refresh_token:
            print("❌ Não está autenticado")
            return False
            
        payload = {
            "action": "logout",
            "access_token": self.access_token,
            "refresh_token": self.refresh_token
        }
        
        response = await self.send_message("auth", payload)
        
        if response["type"] == "auth.logout.success":
            self.access_token = None
            self.refresh_token = None
            self.user_id = None
            self.username = None
            print("✅ Logout realizado com sucesso")
            return True
        else:
            print(f"❌ Falha no logout: {response['payload']['message']}")
            return False
            
    async def refresh_tokens(self):
        """Atualiza os tokens de acesso usando o refresh token."""
        if not self.refresh_token:
            print("❌ Não possui refresh token")
            return False
            
        payload = {
            "action": "refresh",
            "refresh_token": self.refresh_token
        }
        
        response = await self.send_message("auth", payload)
        
        if response["type"] == "auth.refresh.success":
            self.access_token = response["payload"]["access_token"]
            self.refresh_token = response["payload"]["refresh_token"]
            print("✅ Tokens atualizados com sucesso")
            print(f"🔒 Token expira em: {response['payload']['expires_in']} segundos")
            return True
        else:
            print(f"❌ Falha ao atualizar tokens: {response['payload']['message']}")
            return False
            
    # Operações de usuário
    
    async def create_user(self, username, email, password):
        """Cria um novo usuário no sistema."""
        payload = {
            "action": "create",
            "username": username,
            "email": email,
            "password": password
        }
        
        response = await self.send_message("user", payload)
        
        if "error" not in response["payload"]:
            print(f"✅ Usuário criado: {username}")
            print(f"🆔 ID: {response['payload'].get('user_id', 'N/A')}")
            return True
        else:
            print(f"❌ Falha ao criar usuário: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    async def list_users(self):
        """Lista todos os usuários do sistema."""
        payload = {
            "action": "list"
        }
        
        response = await self.send_message("user", payload)
        
        if "error" not in response["payload"]:
            users = response["payload"].get("users", [])
            print(f"👥 Total de usuários: {len(users)}")
            for user in users:
                status = "✅ Ativo" if user.get("is_active", False) else "❌ Inativo"
                print(f"  • {user.get('username', 'N/A')} ({user.get('email', 'N/A')}) - {status}")
            return users
        else:
            print(f"❌ Falha ao listar usuários: {response['payload'].get('message', 'Erro desconhecido')}")
            return []
            
    async def update_user(self, user_id, data):
        """Atualiza dados de um usuário."""
        payload = {
            "action": "update",
            "user_id": user_id,
            **data
        }
        
        response = await self.send_message("user", payload)
        
        if "error" not in response["payload"]:
            print(f"✅ Usuário atualizado: {user_id}")
            return True
        else:
            print(f"❌ Falha ao atualizar usuário: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    async def delete_user(self, user_id):
        """Remove um usuário do sistema."""
        payload = {
            "action": "delete",
            "user_id": user_id
        }
        
        response = await self.send_message("user", payload)
        
        if "error" not in response["payload"]:
            print(f"✅ Usuário removido: {user_id}")
            return True
        else:
            print(f"❌ Falha ao remover usuário: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    # Operações de canal
    
    async def create_channel(self, channel_name, metadata=None):
        """Cria um novo canal."""
        if not self.user_id:
            print("❌ Precisa estar autenticado para criar canais")
            return False
            
        payload = {
            "action": "create",
            "name": channel_name
        }
        
        if metadata:
            payload["metadata"] = metadata
            
        response = await self.send_message("channel", payload)
        
        if "error" not in response["payload"]:
            print(f"✅ Canal criado: {channel_name}")
            return True
        else:
            print(f"❌ Falha ao criar canal: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    async def subscribe_channel(self, channel_name):
        """Inscreve o usuário em um canal."""
        if not self.user_id:
            print("❌ Precisa estar autenticado para se inscrever em canais")
            return False
            
        payload = {
            "action": "subscribe",
            "name": channel_name
        }
        
        response = await self.send_message("channel", payload)
        
        if "error" not in response["payload"]:
            print(f"✅ Inscrito no canal: {channel_name}")
            return True
        else:
            print(f"❌ Falha ao se inscrever no canal: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    async def publish_message(self, channel_name, content, metadata=None):
        """Publica uma mensagem em um canal."""
        if not self.user_id:
            print("❌ Precisa estar autenticado para publicar mensagens")
            return False
            
        payload = {
            "action": "publish",
            "channel_name": channel_name,
            "content": content
        }
        
        if metadata:
            payload["metadata"] = metadata
            
        response = await self.send_message("channel", payload)
        
        if "error" not in response["payload"]:
            print(f"✅ Mensagem publicada no canal: {channel_name}")
            return True
        else:
            print(f"❌ Falha ao publicar mensagem: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    # Operações de mensagem direta
    
    async def send_direct_message(self, recipient_id, content, metadata=None):
        """Envia uma mensagem direta para outro usuário."""
        if not self.user_id:
            print("❌ Precisa estar autenticado para enviar mensagens")
            return False
            
        payload = {
            "action": "send",
            "recipient_id": recipient_id,
            "content": content
        }
        
        if metadata:
            payload["metadata"] = metadata
            
        response = await self.send_message("message", payload)
        
        if "error" not in response["payload"]:
            print(f"✅ Mensagem enviada para: {recipient_id}")
            return True
        else:
            print(f"❌ Falha ao enviar mensagem: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    async def get_message_history(self, other_user_id, limit=20):
        """Obtém o histórico de mensagens com outro usuário."""
        if not self.user_id:
            print("❌ Precisa estar autenticado para ver histórico de mensagens")
            return False
            
        payload = {
            "action": "history",
            "user_id": other_user_id,
            "limit": limit
        }
        
        response = await self.send_message("message", payload)
        
        if "error" not in response["payload"]:
            messages = response["payload"].get("messages", [])
            print(f"📝 Histórico de mensagens com {other_user_id}: {len(messages)} mensagens")
            for msg in messages:
                sender = "Você" if msg.get("sender_id") == self.user_id else "Outro"
                print(f"  • [{sender}]: {msg.get('content', 'N/A')}")
            return messages
        else:
            print(f"❌ Falha ao obter histórico: {response['payload'].get('message', 'Erro desconhecido')}")
            return []

async def run_interactive_client():
    """Executa o cliente em modo interativo."""
    client = DeeperHubClient()
    
    if not await client.connect():
        return
        
    try:
        while True:
            print("\n" + "="*50)
            print("DEEPER HUB - CLIENTE WEBSOCKET")
            print("="*50)
            
            if client.username:
                print(f"Logado como: {client.username} (ID: {client.user_id})")
            else:
                print("Não autenticado")
                
            print("\nOPÇÕES:")
            print("1. Login")
            print("2. Criar usuário")
            print("3. Listar usuários")
            
            if client.username:
                print("4. Atualizar perfil")
                print("5. Criar canal")
                print("6. Inscrever-se em canal")
                print("7. Publicar mensagem em canal")
                print("8. Enviar mensagem direta")
                print("9. Ver histórico de mensagens")
                print("10. Atualizar tokens (refresh)")
                print("11. Logout")
                
            print("0. Sair")
            
            choice = input("\nEscolha uma opção: ")
            
            if choice == "0":
                break
                
            elif choice == "1":
                username = input("Nome de usuário: ")
                password = input("Senha: ")
                await client.login(username, password)
                
            elif choice == "2":
                username = input("Nome de usuário: ")
                email = input("Email: ")
                password = input("Senha: ")
                await client.create_user(username, email, password)
                
            elif choice == "3":
                await client.list_users()
                
            elif choice == "4" and client.username:
                print("Campos disponíveis para atualização (deixe em branco para não alterar):")
                email = input("Novo email: ")
                password = input("Nova senha: ")
                
                data = {}
                if email:
                    data["email"] = email
                if password:
                    data["password"] = password
                    
                if data:
                    await client.update_user(client.user_id, data)
                else:
                    print("Nenhum dado fornecido para atualização")
                    
            elif choice == "5" and client.username:
                channel_name = input("Nome do canal: ")
                description = input("Descrição (opcional): ")
                
                metadata = {}
                if description:
                    metadata["description"] = description
                    
                await client.create_channel(channel_name, metadata if metadata else None)
                
            elif choice == "6" and client.username:
                channel_name = input("Nome do canal: ")
                await client.subscribe_channel(channel_name)
                
            elif choice == "7" and client.username:
                channel_name = input("Nome do canal: ")
                content = input("Mensagem: ")
                await client.publish_message(channel_name, content)
                
            elif choice == "8" and client.username:
                recipient_id = input("ID do destinatário: ")
                content = input("Mensagem: ")
                await client.send_direct_message(recipient_id, content)
                
            elif choice == "9" and client.username:
                other_user_id = input("ID do outro usuário: ")
                await client.get_message_history(other_user_id)
                
            elif choice == "10" and client.username:
                await client.refresh_tokens()
                
            elif choice == "11" and client.username:
                await client.logout()
                
            else:
                print("Opção inválida ou não disponível no estado atual")
                
            input("\nPressione Enter para continuar...")
            
    except KeyboardInterrupt:
        print("\nOperação interrompida pelo usuário")
    except Exception as e:
        print(f"\nErro inesperado: {e}")
    finally:
        await client.close()

async def run_automated_test(host, port):
    """Executa um teste automatizado das principais funcionalidades."""
    client = DeeperHubClient(host, port)
    
    if not await client.connect():
        return
        
    try:
        print("\n" + "="*50)
        print("TESTE AUTOMATIZADO - DEEPER HUB WEBSOCKET")
        print("="*50)
        
        # Gera nomes de usuário e senha únicos para o teste
        test_id = uuid.uuid4().hex[:8]
        username = f"test_user_{test_id}"
        email = f"test_{test_id}@example.com"
        password = f"password_{test_id}"
        
        print(f"\n🔍 Criando usuário de teste: {username}")
        if not await client.create_user(username, email, password):
            print("❌ Teste falhou na criação de usuário")
            return
            
        print("\n🔍 Listando usuários para verificar se o novo usuário foi criado")
        users = await client.list_users()
        
        # Verifica se o usuário foi criado
        user_found = any(user.get("username") == username for user in users)
        if not user_found:
            print("❌ Usuário criado não encontrado na listagem")
            
        print(f"\n🔍 Fazendo login com o usuário: {username}")
        if not await client.login(username, password):
            print("❌ Teste falhou no login")
            return
            
        print("\n🔍 Criando um canal de teste")
        channel_name = f"test_channel_{test_id}"
        if not await client.create_channel(channel_name, {"description": "Canal de teste automatizado"}):
            print("❌ Teste falhou na criação do canal")
            
        print(f"\n🔍 Inscrevendo-se no canal: {channel_name}")
        if not await client.subscribe_channel(channel_name):
            print("❌ Teste falhou na inscrição do canal")
            
        print(f"\n🔍 Publicando mensagem no canal: {channel_name}")
        if not await client.publish_message(channel_name, "Mensagem de teste automatizado"):
            print("❌ Teste falhou na publicação de mensagem")
            
        print("\n🔍 Atualizando tokens (refresh)")
        if not await client.refresh_tokens():
            print("❌ Teste falhou na atualização de tokens")
            
        print("\n🔍 Fazendo logout")
        if not await client.logout():
            print("❌ Teste falhou no logout")
            
        print("\n" + "="*50)
        print("✅ TESTE AUTOMATIZADO CONCLUÍDO")
        print("="*50)
        
    except Exception as e:
        print(f"\n❌ Erro durante o teste automatizado: {e}")
    finally:
        await client.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Cliente WebSocket para DeeperHub")
    parser.add_argument("--host", default="localhost", help="Endereço do servidor (padrão: localhost)")
    parser.add_argument("--port", type=int, default=4000, help="Porta do servidor (padrão: 4000)")
    parser.add_argument("--test", action="store_true", help="Executar teste automatizado")
    
    args = parser.parse_args()
    
    if args.test:
        asyncio.run(run_automated_test(args.host, args.port))
    else:
        asyncio.run(run_interactive_client())
