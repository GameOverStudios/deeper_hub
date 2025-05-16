#!/usr/bin/env python3
"""
Cliente WebSocket simplificado para testar operações CRUD com o servidor Deeper_Hub.

Esta versão usa uma abordagem mais direta, enviando mensagens no formato exato esperado pelo servidor.
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
        
        # Envia a mensagem no formato esperado pelo servidor
        # Certifica-se de que user_data_json é uma string JSON válida
        # O servidor espera que o campo data seja uma string JSON
        if isinstance(user_data, dict):
            user_data_json = json.dumps(user_data)
        
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
        
        return response
    
    def run_tests(self):
        """Executa todos os testes automatizados."""
        logger.info("Iniciando testes automatizados...")
        
        # Cria um usuário
        user_response = self.create_user()
        
        # Se não conseguiu criar um usuário, não continua os testes
        if not user_response or not self.created_user_id:
            logger.error("Não foi possível criar um usuário, pulando os outros testes")
            return
        
        # Exibe um resumo dos testes
        logger.info("\n===== RESUMO DOS TESTES =====")
        for test_name, result in self.test_results.items():
            status = "✅ PASSOU" if result else "❌ FALHOU"
            logger.info(f"{test_name}: {status}")
        
        # Verifica se algum teste falhou
        if not all(self.test_results.values()):
            logger.info("\n⚠️ ALGUNS TESTES FALHARAM OU NÃO FORAM EXECUTADOS ⚠️")
        else:
            logger.info("\n🎉 TODOS OS TESTES PASSARAM! 🎉")

def main():
    """Função principal."""
    logger.info("Iniciando cliente de teste CRUD")
    
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
    
    # Executa os testes
    client.run_tests()
    
    # Fecha a conexão
    if client.ws:
        client.ws.close()
    
    # Aguarda o fechamento da conexão
    time.sleep(1)
    logger.info("Testes concluídos, conexão fechada")

if __name__ == "__main__":
    main()
