#!/usr/bin/env python3
"""
Cliente WebSocket para testar operações CRUD e joins com o servidor Deeper_Hub.

Este cliente implementa todos os testes equivalentes aos do arquivo testes.ex,
incluindo operações CRUD e diferentes tipos de joins.
"""

import json
import time
import uuid
import random
import string
import logging
import websocket
import threading
import os
import sys

# Adiciona os arquivos de partes ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger('crud_test')

class CrudTestClient:
    """Cliente WebSocket para testar operações CRUD e joins."""
    
    def __init__(self, url="ws://localhost:4000/socket/websocket", auth_token="test_token"):
        """
        Inicializa o cliente de teste.
        
        Args:
            url: URL do servidor WebSocket
            auth_token: Token de autenticação
        """
        self.url = url
        self.auth_token = auth_token
        self.ws = None
        self.connected = False
        self.authenticated = False
        self.last_response = None
        self.response_received = False
        self.created_user_id = None
        self.created_profile_id = None
        self.test_results = {}
        
    def connect(self):
        """Conecta ao servidor WebSocket."""
        try:
            # Configuração do WebSocket
            websocket.enableTrace(False)  # Desativa o trace para reduzir o ruído
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
                        self.authenticated = True
                    else:
                        logger.error(f"Erro na autenticação: {data}")
                elif event_type == 'heartbeat':
                    logger.debug("Heartbeat recebido")
                elif event_type == 'phx_reply':
                    # Extrai a resposta do formato Phoenix
                    response_data = data.get('payload', {})
                    
                    # Se for uma resposta de operação de banco de dados
                    if isinstance(response_data, dict):
                        if 'response' in response_data and isinstance(response_data['response'], dict):
                            response = response_data['response']
                            if 'type' in response and response['type'] == 'database_response':
                                logger.info(f"Resposta de operação de banco de dados recebida: {response}")
                                self.last_response = response
                                self.response_received = True
                            elif 'status' in response:
                                logger.info(f"Resposta recebida: {response}")
                                self.last_response = response
                                self.response_received = True
                        elif 'status' in response_data:
                            logger.info(f"Resposta direta recebida: {response_data}")
                            self.last_response = response_data
                            self.response_received = True
            
            # Processa respostas de operações de banco de dados no formato antigo (compatibilidade)
            elif isinstance(data, dict) and data.get('type') == 'database_response':
                logger.info(f"Resposta de operação de banco de dados recebida: {data['operation']} - {data['schema']}")
                self.last_response = data
                self.response_received = True
                
        except Exception as e:
            logger.error(f"Erro ao processar mensagem: {e}")
    
    def on_error(self, ws, error):
        """Callback quando ocorre um erro."""
        logger.error(f"Erro na conexão: {error}")
    
    def on_close(self, ws, close_status_code, close_msg):
        """Callback quando a conexão é fechada."""
        logger.info(f"Conexão fechada: {close_status_code} - {close_msg}")
        self.connected = False
    
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
    
    def generate_random_string(self, length=8):
        """Gera uma string aleatória."""
        return ''.join(random.choice(string.ascii_lowercase) for _ in range(length))
    
    def create_user(self):
        """
        Cria um novo usuário com dados aleatórios.
        Equivalente à operação 'teste_usuarios' no arquivo testes.ex.
        
        Returns:
            A resposta do servidor e o ID do usuário criado
        """
        if not self.connected or not self.authenticated:
            logger.warning("Tentativa de criar usuário sem conexão ou autenticação")
            return None, None
        
        # Gera dados aleatórios para o usuário
        username = f"user_{self.generate_random_string()}"
        email = f"{self.generate_random_string()}@example.com"
        password = self.generate_random_string(12)
        
        # Prepara os dados do usuário
        user_data = {
            "username": username,
            "email": email,
            "password": password,
            "is_active": True
        }
        
        # Converte para JSON string
        user_data_json = json.dumps(user_data)
        
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        # Cria a mensagem no formato que o servidor espera
        # Importante: o payload deve ser uma string JSON, não um dict
        payload = json.dumps({
            "database_operation": {
                "operation": "create",
                "schema": "user",
                "data": user_data_json,  # Já é uma string JSON
                "request_id": request_id,
                "timestamp": int(time.time() * 1000)
            }
        })
        
        message = {
            "topic": "websocket",
            "event": "message",  # Usa o evento message que o servidor espera
            "payload": payload,  # Envia o payload como string JSON
            "ref": str(uuid.uuid4())
        }
        
        # Envia a mensagem
        logger.info(f"Criando usuário: {username} / {email}")
        self.send_message(message)
        
        # Aguarda a resposta
        response = self.wait_for_response()
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info(f"✅ Usuário criado com sucesso: {username}")
            self.test_results["create_user"] = True
            
            # Extrai o ID do usuário criado
            if 'data' in response:
                try:
                    data = response['data']
                    if isinstance(data, dict) and 'id' in data:
                        self.created_user_id = data['id']
                        logger.info(f"ID do usuário criado: {self.created_user_id}")
                    elif isinstance(data, str):
                        # Tenta decodificar se for uma string JSON
                        try:
                            data_dict = json.loads(data)
                            if isinstance(data_dict, dict) and 'id' in data_dict:
                                self.created_user_id = data_dict['id']
                                logger.info(f"ID do usuário criado: {self.created_user_id}")
                        except:
                            logger.warning("Não foi possível decodificar os dados como JSON")
                except Exception as e:
                    logger.error(f"Erro ao extrair ID do usuário: {e}")
        else:
            logger.error(f"❌ Falha ao criar usuário: {response}")
            self.test_results["create_user"] = False
        
        return response, self.created_user_id
    
    def get_user(self, user_id):
        """
        Obtém um usuário pelo ID.
        Equivalente à operação de busca por ID no arquivo testes.ex.
        
        Args:
            user_id: ID do usuário
            
        Returns:
            A resposta do servidor
        """
        if not self.connected or not self.authenticated:
            logger.warning("Tentativa de obter usuário sem conexão ou autenticação")
            return None
        
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        # Cria a mensagem no formato que o servidor espera
        database_operation = {
            "operation": "read",
            "schema": "user",
            "id": user_id,
            "request_id": request_id,
            "timestamp": int(time.time() * 1000)
        }
        
        # Serializa a operação de banco de dados como string JSON
        payload = json.dumps({
            "database_operation": database_operation
        })
        
        message = {
            "topic": "websocket",
            "event": "message",
            "payload": payload,
            "ref": str(uuid.uuid4())
        }
        
        # Envia a mensagem
        logger.info(f"Obtendo usuário com ID: {user_id}")
        self.send_message(message)
        
        # Aguarda a resposta
        response = self.wait_for_response()
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info("✅ Usuário obtido com sucesso")
    def get_user(self, user_id):
        """
        Obtém um usuário pelo ID.
        Equivalente à operação de busca por ID no arquivo testes.ex.
        
        Args:
            user_id: ID do usuário
                
        Returns:
            A resposta do servidor
        """
        if not self.connected or not self.authenticated:
            logger.warning("Tentativa de obter usuário sem conexão ou autenticação")
            return None
            
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
            
        # Cria a mensagem no formato que o servidor espera
        database_operation = {
            "operation": "read",
            "schema": "user",
            "id": user_id,
            "request_id": request_id,
            "timestamp": int(time.time() * 1000)
        }
            
        # Serializa a operação de banco de dados como string JSON
        payload = json.dumps({
            "database_operation": database_operation
        })
            
        message = {
            "topic": "websocket",
            "event": "message",
            "payload": payload,
            "ref": str(uuid.uuid4())
        }
        
        # Envia a mensagem
        logger.info(f"Obtendo usuário com ID: {user_id}")
        self.send_message(message)
        
        # Aguarda a resposta
        response = self.wait_for_response()
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info("✅ Usuário obtido com sucesso")
            self.test_results["get_user"] = True
        else:
            logger.error(f"❌ Falha ao obter usuário: {response}")
            self.test_results["get_user"] = False
        
        return response
    
    def find_active_users(self):
        """
        Busca usuários ativos.
        Equivalente à operação 'find_active_users' no arquivo testes.ex.
        
        Returns:
            A resposta do servidor
        """
        if not self.connected or not self.authenticated:
            logger.warning("Tentativa de buscar usuários sem conexão ou autenticação")
            return None
        
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        # Condições para a busca em formato JSON
        conditions = {
            "where": {"is_active": True},
            "order_by": {"username": "asc"},
            "limit": 10
        }
        
        # Serializa as condições como string JSON
        conditions_json = json.dumps(conditions)
        
        # Cria a mensagem no formato que o servidor espera
        database_operation = {
            "operation": "find",
            "schema": "user",
            "conditions": conditions_json,
            "request_id": request_id,
            "timestamp": int(time.time() * 1000)
        }
        
        # Serializa a operação de banco de dados como string JSON
        payload = json.dumps({
            "database_operation": database_operation
        })
        
        message = {
            "topic": "websocket",
            "event": "message",
            "payload": payload,
            "ref": str(uuid.uuid4())
        }
        
        # Envia a mensagem
        logger.info("Buscando usuários ativos")
        self.send_message(message)
        
        # Aguarda a resposta
        response = self.wait_for_response()
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info(f"✅ Busca de usuários ativos bem-sucedida: {len(response.get('data', []))} usuários encontrados")
            self.test_results["find_active_users"] = True
        else:
            logger.error(f"❌ Falha na busca de usuários ativos: {response}")
            self.test_results["find_active_users"] = False
        
        return response

# Importa os métodos adicionais dos arquivos de partes
from crud_test_complete_part2 import update_user, create_profile
from crud_test_complete_part3 import update_profile, inner_join_users_profiles
from crud_test_complete_part4 import left_join_users_profiles, right_join_users_profiles
from crud_test_complete_part5 import conditional_join_users_profiles, run_all_tests

# Adiciona os métodos importados à classe CrudTestClient
CrudTestClient.update_user = update_user
CrudTestClient.create_profile = create_profile
CrudTestClient.update_profile = update_profile
CrudTestClient.inner_join_users_profiles = inner_join_users_profiles
CrudTestClient.left_join_users_profiles = left_join_users_profiles
CrudTestClient.right_join_users_profiles = right_join_users_profiles
CrudTestClient.conditional_join_users_profiles = conditional_join_users_profiles
CrudTestClient.run_all_tests = run_all_tests

def main():
    """Função principal."""
    logger.info("Iniciando cliente de teste CRUD completo")
    
    # Cria o cliente
    client = CrudTestClient()
    
    # Conecta ao servidor
    if not client.connect():
        logger.error("Falha ao conectar ao servidor")
        return
    
    # Aguarda a conexão e autenticação
    logger.info("Aguardando estabelecimento da conexão e autenticação...")
    start_time = time.time()
    while (not client.connected or not client.authenticated) and time.time() - start_time < 10:
        time.sleep(0.1)
    
    # Verifica se a conexão e autenticação foram bem-sucedidas
    if not client.connected:
        logger.error("Falha ao conectar ao servidor")
        return
    
    if not client.authenticated:
        logger.error("Falha ao autenticar no servidor")
        return
    
    # Aguarda mais alguns segundos para estabilização
    logger.info("Conexão e autenticação concluídas com sucesso, aguardando mais 2 segundos para estabilização...")
    time.sleep(2)
    
    # Executa todos os testes
    client.run_all_tests()
    
    # Fecha a conexão
    if client.ws:
        client.ws.close()
    
    # Aguarda o fechamento da conexão
    time.sleep(1)
    logger.info("Testes concluídos, conexão fechada")

if __name__ == "__main__":
    main()
