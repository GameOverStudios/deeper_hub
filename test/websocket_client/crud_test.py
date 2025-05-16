#!/usr/bin/env python3
"""
Cliente WebSocket simplificado para testar operações CRUD com o servidor Deeper_Hub.

Este script executa automaticamente todas as operações CRUD sem interação do usuário.
"""

import json
import time
import uuid
import random
import string
import logging
import websocket
import threading

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger('crud_test')

class CrudTestClient:
    """Cliente WebSocket para testar operações CRUD."""
    
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
        
        Returns:
            A resposta do servidor
        """
        if not self.connected or not self.authenticated:
            logger.warning("Tentativa de criar usuário sem conexão ou autenticação")
            return None
        
        # Gera dados aleatórios para o usuário
        username = f"user_{self.generate_random_string()}"
        email = f"{self.generate_random_string()}@example.com"
        password = self.generate_random_string(12)
        
        # Prepara os dados do usuário como um dicionário simples
        user_data = {
            "username": username,
            "email": email,
            "password": password,
            "is_active": True
        }
        
        # Converte para JSON string - o servidor espera uma string JSON
        user_data_json = json.dumps(user_data)
        
        # Cria um ID de requisição único
        request_id = str(uuid.uuid4())
        
        # Cria a mensagem de operação de banco de dados no formato exato esperado pelo servidor
        # Envia a mensagem diretamente para o canal
        message = {
            "topic": "websocket",
            "event": "database_operation",  # Usa o evento database_operation diretamente
            "payload": {
                "operation": "create",
                "schema": "user",
                "data": user_data_json,
                "request_id": request_id,
                "timestamp": int(time.time() * 1000)
            },
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
        
        return response
    
    def get_user(self, user_id):
        """
        Obtém um usuário pelo ID.
        
        Args:
            user_id: ID do usuário
            
        Returns:
            A resposta do servidor
        """
        if not self.connected or not self.authenticated:
            logger.warning("Tentativa de obter usuário sem conexão ou autenticação")
            return None
    
    # Cria a mensagem de operação de banco de dados
    # Envia a mensagem diretamente para o canal
    message = {
        "topic": "websocket",
        "event": "database_operation",  # Usa o evento database_operation diretamente
        "payload": {
            "operation": "read",
            "schema": "user",
            "id": user_id,
            "request_id": request_id,
            "timestamp": int(time.time() * 1000)
        },
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

def update_user(self, user_id):
    """
    Atualiza um usuário existente.
        
        # Aguarda a resposta
        response = self.wait_for_response()
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info("✅ Usuário excluído com sucesso")
            self.test_results["delete_user"] = True
        else:
            logger.error(f"❌ Falha ao excluir usuário: {response}")
            self.test_results["delete_user"] = False
        
        return response
    
    def run_all_tests(self):
        """Executa todos os testes automaticamente."""
        logger.info("Iniciando testes automatizados...")
        
        # Teste 1: Criar usuário
        user_response = self.create_user()
        
        # Se o usuário foi criado com sucesso, continua com os outros testes
        if self.created_user_id:
            # Teste 2: Obter usuário pelo ID
            self.get_user(self.created_user_id)
            
            # Teste 3: Atualizar usuário
            self.update_user(self.created_user_id)
            
            # Teste 4: Buscar usuários por condição
            self.find_users()
            
            # Teste 5: Listar todos os usuários
            self.list_users()
            
            # Teste 6: Criar perfil para o usuário
            self.create_profile(self.created_user_id)
            
            # Teste 7: Excluir usuário (último teste para não afetar os outros)
            self.delete_user(self.created_user_id)
        else:
            logger.error("Não foi possível criar um usuário, pulando os outros testes")
        
        # Exibe o resumo dos resultados
        self.print_test_summary()
    
    def print_test_summary(self):
        """Imprime um resumo dos resultados dos testes."""
        logger.info("\n===== RESUMO DOS TESTES =====")
        
        all_passed = True
        for test_name, result in self.test_results.items():
            status = "✅ PASSOU" if result else "❌ FALHOU" if result is False else "⚠️ NÃO EXECUTADO"
            logger.info(f"{test_name}: {status}")
            if result is not True:
                all_passed = False
        
        if all_passed:
            logger.info("\n✅✅✅ TODOS OS TESTES PASSARAM! ✅✅✅")
        else:
            logger.info("\n⚠️ ALGUNS TESTES FALHARAM OU NÃO FORAM EXECUTADOS ⚠️")

def main():
    """Função principal."""
    logger.info("Iniciando cliente de teste CRUD")
    
    # Cria o cliente
    client = CrudTestClient()
    
    # Conecta ao servidor
    if not client.connect():
        logger.error("Falha ao conectar ao servidor")
        return
    
    # Aguarda a conexão ser estabelecida e a autenticação ser concluída
    max_wait_time = 10  # segundos
    wait_interval = 0.5  # segundos
    total_waited = 0
    
    logger.info("Aguardando estabelecimento da conexão e autenticação...")
    while not client.authenticated and total_waited < max_wait_time:
        time.sleep(wait_interval)
        total_waited += wait_interval
    
    if not client.authenticated:
        logger.error(f"Timeout esperando a autenticação ser concluída após {max_wait_time} segundos")
        return
    
    logger.info("Conexão e autenticação concluídas com sucesso, aguardando mais 2 segundos para estabilização...")
    time.sleep(2)  # Aguarda mais um pouco para garantir que tudo está estável
    
    # Executa todos os testes
    client.run_all_tests()
    
    # Fecha a conexão
    time.sleep(1)  # Aguarda um pouco para garantir que as últimas mensagens sejam processadas
    client.ws.close()
    logger.info("Testes concluídos, conexão fechada")

if __name__ == "__main__":
    main()
