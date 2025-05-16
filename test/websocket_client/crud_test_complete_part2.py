import logging
import json
import time
import uuid
logger = logging.getLogger('crud_test')

def update_user(self, user_id):
    """
    Atualiza um usuário existente.
    Equivalente à operação de atualização no arquivo testes.ex.
    
    Args:
        user_id: ID do usuário
        
    Returns:
        A resposta do servidor
    """
    if not self.connected or not self.authenticated:
        logger.warning("Tentativa de atualizar usuário sem conexão ou autenticação")
        return None
    
    # Gera novos dados aleatórios
    new_username = f"updated_{self.generate_random_string()}"
    
    # Dados para atualização
    update_data = {
        "username": new_username
    }
    
    # Converte para JSON string
    update_data_json = json.dumps(update_data)
    
    # Cria um ID de requisição único
    request_id = str(uuid.uuid4())
    
    # Cria a mensagem no formato que o servidor espera
    database_operation = {
        "operation": "update",
        "schema": "user",
        "id": user_id,
        "data": update_data_json,
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
    logger.info(f"Atualizando usuário {user_id} para {new_username}")
    self.send_message(message)
    
    # Aguarda a resposta
    response = self.wait_for_response()
    
    # Verifica o resultado
    if response and response.get('status') == 'success':
        logger.info(f"✅ Usuário atualizado com sucesso: {new_username}")
        self.test_results["update_user"] = True
    else:
        logger.error(f"❌ Falha ao atualizar usuário: {response}")
        self.test_results["update_user"] = False
    
    return response

def create_profile(self, user_id):
    """
    Cria um perfil para o usuário.
    Equivalente à operação 'teste_perfis' no arquivo testes.ex.
    
    Args:
        user_id: ID do usuário
        
    Returns:
        A resposta do servidor e o ID do perfil criado
    """
    if not self.connected or not self.authenticated:
        logger.warning("Tentativa de criar perfil sem conexão ou autenticação")
        return None
    
    # Dados do perfil
    profile_data = {
        "user_id": user_id,
        "profile_picture": "https://exemplo.com/perfil.jpg",
        "bio": "Desenvolvedor de software",
        "website": "https://exemplo.com"
    }
    
    # Converte para JSON string
    profile_data_json = json.dumps(profile_data)
    
    # Cria um ID de requisição único
    request_id = str(uuid.uuid4())
    
    # Cria a mensagem no formato que o servidor espera
    payload = json.dumps({
        "database_operation": {
            "operation": "create",
            "schema": "profile",
            "data": profile_data_json,
            "request_id": request_id,
            "timestamp": int(time.time() * 1000)
        }
    })
    
    message = {
        "topic": "websocket",
        "event": "message",
        "payload": payload,
        "ref": str(uuid.uuid4())
    }
    
    # Envia a mensagem
    logger.info(f"Criando perfil para usuário: {user_id}")
    self.send_message(message)
    
    # Aguarda a resposta
    response = self.wait_for_response()
    
    # Verifica o resultado
    if response and response.get('status') == 'success':
        logger.info("✅ Perfil criado com sucesso")
        self.test_results["create_profile"] = True
        
        # Extrai o ID do perfil criado
        if 'data' in response:
            try:
                data = response['data']
                if isinstance(data, dict) and 'id' in data:
                    self.created_profile_id = data['id']
                    logger.info(f"ID do perfil criado: {self.created_profile_id}")
                elif isinstance(data, str):
                    # Tenta decodificar se for uma string JSON
                    try:
                        data_dict = json.loads(data)
                        if isinstance(data_dict, dict) and 'id' in data_dict:
                            self.created_profile_id = data_dict['id']
                            logger.info(f"ID do perfil criado: {self.created_profile_id}")
                    except:
                        logger.warning("Não foi possível decodificar os dados como JSON")
            except Exception as e:
                logger.error(f"Erro ao extrair ID do perfil: {e}")
    else:
        logger.error(f"❌ Falha ao criar perfil: {response}")
        self.test_results["create_profile"] = False
    
    return response, self.created_profile_id
