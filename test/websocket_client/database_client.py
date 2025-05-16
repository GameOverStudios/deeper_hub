#!/usr/bin/env python3
"""
Cliente WebSocket para testar operações de banco de dados com o servidor Deeper_Hub.

Este script:
- Estende o cliente WebSocket básico
- Adiciona suporte para operações CRUD
- Permite manipular usuários e perfis via WebSocket
"""

import json
import time
import uuid
import logging
from websocket_client import DeeperHubClient

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger('database_client')

class DatabaseClient(DeeperHubClient):
    """Cliente WebSocket para operações de banco de dados no Deeper_Hub."""
    
    def __init__(self, url="ws://localhost:4000/socket/websocket", auth_token="test_token"):
        """
        Inicializa o cliente de banco de dados.
        
        Args:
            url: URL do servidor WebSocket
            auth_token: Token de autenticação
        """
        super().__init__(url, auth_token)
        self.last_response = None
        self.response_received = False
        
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
                elif event_type == 'heartbeat':
                    logger.info("Heartbeat recebido")
                else:
                    logger.info(f"Evento recebido: {event_type}")
                    
                # Armazena resposta para operações de banco de dados
                if event_type == 'data_response' and data.get('payload', {}).get('resource_type') == 'database':
                    self.last_response = data
                    self.response_received = True
                    
        except Exception as e:
            logger.error(f"Erro ao processar mensagem: {e}")
    
    def wait_for_response(self, timeout=5):
        """
        Aguarda por uma resposta do servidor.
        
        Args:
            timeout: Tempo máximo de espera em segundos
            
        Returns:
            A resposta recebida ou None se ocorrer timeout
        """
        start_time = time.time()
        self.response_received = False
        self.last_response = None
        
        while not self.response_received and time.time() - start_time < timeout:
            time.sleep(0.1)
            
        return self.last_response
    
    def create_user(self, username, email, password):
        """
        Cria um novo usuário.
        
        Args:
            username: Nome de usuário
            email: Email do usuário
            password: Senha do usuário
            
        Returns:
            A resposta do servidor
        """
        if not self.connected:
            logger.warning("Tentativa de enviar mensagem sem conexão")
            return None
            
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        # Prepara os dados do usuário
        user_data = {
            "username": username,
            "email": email,
            "password": password,
            "is_active": True
        }
        
        # Cria a mensagem de operação de banco de dados
        message = {
            "topic": "websocket",
            "event": "message",
            "payload": json.dumps({
                "database_operation": {
                    "operation": "create",
                    "schema": "user",
                    "data": json.dumps(user_data),
                    "request_id": request_id,
                    "timestamp": int(time.time() * 1000)
                }
            }),
            "ref": request_id
        }
        
        # Envia a mensagem
        self.ws.send(json.dumps(message))
        logger.info(f"Solicitação de criação de usuário enviada: {username}")
        
        # Aguarda a resposta
        return self.wait_for_response()
    
    def get_user(self, user_id):
        """
        Obtém um usuário pelo ID.
        
        Args:
            user_id: ID do usuário
            
        Returns:
            A resposta do servidor
        """
        if not self.connected:
            logger.warning("Tentativa de enviar mensagem sem conexão")
            return None
            
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        # Cria a mensagem de operação de banco de dados
        message = {
            "topic": "websocket",
            "event": "message",
            "payload": json.dumps({
                "database_operation": {
                    "operation": "read",
                    "schema": "user",
                    "id": user_id,
                    "request_id": request_id,
                    "timestamp": int(time.time() * 1000)
                }
            }),
            "ref": request_id
        }
        
        # Envia a mensagem
        self.ws.send(json.dumps(message))
        logger.info(f"Solicitação de leitura de usuário enviada: {user_id}")
        
        # Aguarda a resposta
        return self.wait_for_response()
    
    def update_user(self, user_id, data):
        """
        Atualiza um usuário existente.
        
        Args:
            user_id: ID do usuário
            data: Dados a serem atualizados
            
        Returns:
            A resposta do servidor
        """
        if not self.connected:
            logger.warning("Tentativa de enviar mensagem sem conexão")
            return None
            
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        # Cria a mensagem de operação de banco de dados
        message = {
            "topic": "websocket",
            "event": "message",
            "payload": json.dumps({
                "database_operation": {
                    "operation": "update",
                    "schema": "user",
                    "id": user_id,
                    "data": json.dumps(data),
                    "request_id": request_id,
                    "timestamp": int(time.time() * 1000)
                }
            }),
            "ref": request_id
        }
        
        # Envia a mensagem
        self.ws.send(json.dumps(message))
        logger.info(f"Solicitação de atualização de usuário enviada: {user_id}")
        
        # Aguarda a resposta
        return self.wait_for_response()
    
    def delete_user(self, user_id):
        """
        Exclui um usuário pelo ID.
        
        Args:
            user_id: ID do usuário
            
        Returns:
            A resposta do servidor
        """
        if not self.connected:
            logger.warning("Tentativa de enviar mensagem sem conexão")
            return None
            
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        # Cria a mensagem de operação de banco de dados
        message = {
            "topic": "websocket",
            "event": "message",
            "payload": json.dumps({
                "database_operation": {
                    "operation": "delete",
                    "schema": "user",
                    "id": user_id,
                    "request_id": request_id,
                    "timestamp": int(time.time() * 1000)
                }
            }),
            "ref": request_id
        }
        
        # Envia a mensagem
        self.ws.send(json.dumps(message))
        logger.info(f"Solicitação de exclusão de usuário enviada: {user_id}")
        
        # Aguarda a resposta
        return self.wait_for_response()
    
    def find_users(self, conditions):
        """
        Busca usuários por condições.
        
        Args:
            conditions: Condições de busca (dicionário)
            
        Returns:
            A resposta do servidor
        """
        if not self.connected:
            logger.warning("Tentativa de enviar mensagem sem conexão")
            return None
            
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        self.logger.info(f"Buscando usuários com condições: {conditions}")
        
        # Cria a mensagem de operação de banco de dados
        message = {
            "topic": "websocket",
            "event": "message",
            "payload": json.dumps({
                "database_operation": {
                    "operation": "find",
                    "schema": "user",
                    "data": json.dumps(conditions),
                    "request_id": request_id,
                    "timestamp": int(time.time() * 1000)
                }
            }),
            "ref": request_id
        }
        
        # Envia a mensagem
        self.ws.send(json.dumps(message))
        logger.info(f"Solicitação de busca de usuários enviada: {conditions}")
        
        # Aguarda a resposta
        return self.wait_for_response()
    
    def list_users(self):
        """
        Lista todos os usuários.
        
        Returns:
            A resposta do servidor
        """
        if not self.connected:
            logger.warning("Tentativa de enviar mensagem sem conexão")
            return None
            
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        # Cria a mensagem de operação de banco de dados
        message = {
            "topic": "websocket",
            "event": "message",
            "payload": json.dumps({
                "database_operation": {
                    "operation": "list",
                    "schema": "user",
                    "request_id": request_id,
                    "timestamp": int(time.time() * 1000)
                }
            }),
            "ref": request_id
        }
        
        # Envia a mensagem
        self.ws.send(json.dumps(message))
        logger.info("Solicitação de listagem de usuários enviada")
        
        # Aguarda a resposta
        return self.wait_for_response()

def main():
    """Função principal."""
    # Cria o cliente
    client = DatabaseClient()
    
    # Conecta ao servidor
    if not client.connect():
        logger.error("Falha ao conectar ao servidor")
        return
    
    # Aguarda a conexão ser estabelecida
    time.sleep(2)
    
    # Menu interativo
    while True:
        print("\nComandos disponíveis:")
        print("1. Criar usuário")
        print("2. Buscar usuário por ID")
        print("3. Atualizar usuário")
        print("4. Excluir usuário")
        print("5. Buscar usuários por condição")
        print("6. Listar todos os usuários")
        print("7. Sair")
        
        choice = input("Digite o número do comando: ")
        
        if choice == "1":
            username = input("Nome de usuário: ")
            email = input("Email: ")
            password = input("Senha: ")
            response = client.create_user(username, email, password)
            print(f"Resposta: {response}")
            
        elif choice == "2":
            user_id = input("ID do usuário: ")
            response = client.get_user(user_id)
            print(f"Resposta: {response}")
            
        elif choice == "3":
            user_id = input("ID do usuário: ")
            username = input("Novo nome de usuário (deixe em branco para manter): ")
            email = input("Novo email (deixe em branco para manter): ")
            
            data = {}
            if username:
                data["username"] = username
            if email:
                data["email"] = email
                
            response = client.update_user(user_id, data)
            print(f"Resposta: {response}")
            
        elif choice == "4":
            user_id = input("ID do usuário: ")
            response = client.delete_user(user_id)
            print(f"Resposta: {response}")
            
        elif choice == "5":
            field = input("Campo (ex: username): ")
            value = input("Valor: ")
            response = client.find_users({field: value})
            print(f"Resposta: {response}")
            
        elif choice == "6":
            response = client.list_users()
            print(f"Resposta: {response}")
            
        elif choice == "7":
            break
            
        else:
            print("Comando inválido")
    
    # Fecha a conexão
    client.ws.close()
    print("Conexão fechada")

if __name__ == "__main__":
    main()
