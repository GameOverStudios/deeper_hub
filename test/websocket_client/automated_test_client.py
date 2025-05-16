#!/usr/bin/env python3
"""
Cliente automatizado para testar operações CRUD via WebSocket com o servidor Deeper_Hub.

Este script:
- Conecta-se ao servidor WebSocket
- Executa automaticamente todas as operações CRUD
- Registra os resultados de cada operação
- Não requer interação do usuário
"""

import json
import time
import uuid
import random
import string
import logging
from database_client import DatabaseClient

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger('automated_test_client')

class AutomatedTestClient(DatabaseClient):
    """Cliente automatizado para testar operações CRUD."""
    
    def __init__(self, url="ws://localhost:4000/socket/websocket", auth_token="test_token"):
        """
        Inicializa o cliente de teste automatizado.
        
        Args:
            url: URL do servidor WebSocket
            auth_token: Token de autenticação
        """
        super().__init__(url, auth_token)
        self.test_results = {
            "create_user": None,
            "get_user": None,
            "update_user": None,
            "find_users": None,
            "list_users": None,
            "delete_user": None,
            "create_profile": None
        }
        self.created_user_id = None
        
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
                        self.connected = True  # Marca como conectado após autenticação bem-sucedida
                    else:
                        logger.error(f"Erro na autenticação: {data}")
                elif event_type == 'heartbeat':
                    logger.info("Heartbeat recebido")
                else:
                    logger.info(f"Evento recebido: {event_type}")
            
            # Processa respostas de operações de banco de dados (formato JSON direto)
            if isinstance(data, dict) and data.get('type') == 'database_response':
                logger.info(f"Resposta de operação de banco de dados recebida: {data['operation']} - {data['schema']}")
                self.last_response = data
                self.response_received = True
                
        except Exception as e:
            logger.error(f"Erro ao processar mensagem: {e}")
    
    def generate_random_string(self, length=8):
        """Gera uma string aleatória."""
        return ''.join(random.choice(string.ascii_lowercase) for _ in range(length))
    
    def run_all_tests(self):
        """Executa todos os testes automaticamente."""
        logger.info("Iniciando testes automatizados...")
        
        # Teste 1: Criar usuário
        self.test_create_user()
        
        # Teste 2: Obter usuário pelo ID
        if self.created_user_id:
            self.test_get_user()
        
        # Teste 3: Atualizar usuário
        if self.created_user_id:
            self.test_update_user()
        
        # Teste 4: Buscar usuários por condição
        self.test_find_users()
        
        # Teste 5: Listar todos os usuários
        self.test_list_users()
        
        # Teste 6: Criar perfil para o usuário
        if self.created_user_id:
            self.test_create_profile()
        
        # Teste 7: Excluir usuário (último teste para não afetar os outros)
        if self.created_user_id:
            self.test_delete_user()
        
        # Exibe o resumo dos resultados
        self.print_test_summary()
    
    def test_create_user(self):
        """Testa a criação de usuário."""
        logger.info("Teste: Criar usuário")
        
        # Gera dados aleatórios para o usuário
        username = f"user_{self.generate_random_string()}"
        email = f"{self.generate_random_string()}@example.com"
        password = self.generate_random_string(12)
        
        # Cria o usuário
        response = self.create_user(username, email, password)
        
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
        
        # Cria a mensagem de operação de banco de dados no formato exato esperado pelo servidor
        message = {
            "database_operation": {
                "operation": "create",
                "schema": "user",
                "data": json.dumps(user_data),
                "request_id": request_id,
                "timestamp": int(time.time() * 1000)
            }
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
        
        # Cria a mensagem de operação de banco de dados no formato exato esperado pelo servidor
        message = {
            "database_operation": {
                "operation": "read",
                "schema": "user",
                "id": user_id,
                "request_id": request_id,
                "timestamp": int(time.time() * 1000)
            }
        }
        
        # Envia a mensagem
        self.ws.send(json.dumps(message))
        logger.info(f"Solicitação de leitura de usuário enviada: {user_id}")
        
        # Aguarda a resposta
        return self.wait_for_response()
    
    def test_get_user(self):
        """Testa a obtenção de usuário pelo ID."""
        logger.info(f"Teste: Obter usuário pelo ID {self.created_user_id}")
        
        # Obtém o usuário
        response = self.get_user(self.created_user_id)
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info("✅ Usuário obtido com sucesso")
            self.test_results["get_user"] = True
        else:
            logger.error(f"❌ Falha ao obter usuário: {response}")
            self.test_results["get_user"] = False
    
    def test_update_user(self):
        """Testa a atualização de usuário."""
        logger.info(f"Teste: Atualizar usuário {self.created_user_id}")
        
        # Dados para atualização
        new_username = f"updated_{self.generate_random_string()}"
        
        # Atualiza o usuário
        response = self.update_user(self.created_user_id, {"username": new_username})
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info(f"✅ Usuário atualizado com sucesso: {new_username}")
            self.test_results["update_user"] = True
        else:
            logger.error(f"❌ Falha ao atualizar usuário: {response}")
            self.test_results["update_user"] = False
    
    def test_find_users(self):
        """Testa a busca de usuários por condição."""
        logger.info("Teste: Buscar usuários por condição")
        
        # Busca usuários ativos
        response = self.find_users({"is_active": True})
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info("✅ Busca de usuários bem-sucedida")
            self.test_results["find_users"] = True
        else:
            logger.error(f"❌ Falha na busca de usuários: {response}")
            self.test_results["find_users"] = False
    
    def test_list_users(self):
        """Testa a listagem de todos os usuários."""
        logger.info("Teste: Listar todos os usuários")
        
        # Lista todos os usuários
        response = self.list_users()
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info("✅ Listagem de usuários bem-sucedida")
            self.test_results["list_users"] = True
        else:
            logger.error(f"❌ Falha na listagem de usuários: {response}")
            self.test_results["list_users"] = False
    
    def test_create_profile(self):
        """Testa a criação de perfil para o usuário."""
        logger.info(f"Teste: Criar perfil para o usuário {self.created_user_id}")
        
        # Dados do perfil
        profile_data = {
            "user_id": self.created_user_id,
            "profile_picture": "https://example.com/avatar.jpg",
            "bio": f"Bio de teste gerada em {time.strftime('%Y-%m-%d %H:%M:%S')}",
            "website": "https://example.com"
        }
        
        # Cria o perfil
        response = self.create_profile(profile_data)
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info("✅ Perfil criado com sucesso")
            self.test_results["create_profile"] = True
        else:
            logger.error(f"❌ Falha ao criar perfil: {response}")
            self.test_results["create_profile"] = False
    
    def test_delete_user(self):
        """Testa a exclusão de usuário."""
        logger.info(f"Teste: Excluir usuário {self.created_user_id}")
        
        # Exclui o usuário
        response = self.delete_user(self.created_user_id)
        
        # Verifica o resultado
        if response and response.get('status') == 'success':
            logger.info("✅ Usuário excluído com sucesso")
            self.test_results["delete_user"] = True
        else:
            logger.error(f"❌ Falha ao excluir usuário: {response}")
            self.test_results["delete_user"] = False
    
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
    logger.info("Iniciando cliente de teste automatizado")
    
    # Cria o cliente
    client = AutomatedTestClient()
    
    # Conecta ao servidor
    if not client.connect():
        logger.error("Falha ao conectar ao servidor")
        return
    
    # Aguarda a conexão ser estabelecida e a autenticação ser concluída
    max_wait_time = 10  # segundos
    wait_interval = 0.5  # segundos
    total_waited = 0
    
    logger.info("Aguardando estabelecimento da conexão...")
    while not client.connected and total_waited < max_wait_time:
        time.sleep(wait_interval)
        total_waited += wait_interval
    
    if not client.connected:
        logger.error(f"Timeout esperando a conexão ser estabelecida após {max_wait_time} segundos")
        return
    
    logger.info("Conexão estabelecida com sucesso, aguardando mais 2 segundos para estabilização...")
    time.sleep(2)  # Aguarda mais um pouco para garantir que tudo está estável
    
    # Executa todos os testes
    client.run_all_tests()
    
    # Fecha a conexão
    time.sleep(1)  # Aguarda um pouco para garantir que as últimas mensagens sejam processadas
    client.ws.close()
    logger.info("Testes concluídos, conexão fechada")

if __name__ == "__main__":
    main()
