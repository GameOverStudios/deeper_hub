import logging
import time
import json
import uuid
logger = logging.getLogger('crud_test')

def update_profile(self, profile_id):
    """
    Atualiza um perfil existente.
    Equivalente à operação de atualização de perfil no arquivo testes.ex.
    
    Args:
        profile_id: ID do perfil
        
    Returns:
        A resposta do servidor
    """
    if not self.connected or not self.authenticated:
        logger.warning("Tentativa de atualizar perfil sem conexão ou autenticação")
        return None
    
    # Dados para atualização
    update_data = {
        "bio": f"Desenvolvedor de software e entusiasta de Elixir - Atualizado em {time.strftime('%Y-%m-%d %H:%M:%S')}",
        "website": "https://exemplo-atualizado.com"
    }
    
    # Converte para JSON string
    update_data_json = json.dumps(update_data)
    
    # Cria um ID de requisição único
    request_id = str(uuid.uuid4())
    
    # Cria a mensagem no formato que o servidor espera
    database_operation = {
        "operation": "update",
        "schema": "profile",
        "id": profile_id,
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
    logger.info(f"Atualizando perfil {profile_id}")
    self.send_message(message)
    
    # Aguarda a resposta
    response = self.wait_for_response()
    
    # Verifica o resultado
    if response and response.get('status') == 'success':
        logger.info(f"✅ Perfil atualizado com sucesso")
        self.test_results["update_profile"] = True
    else:
        logger.error(f"❌ Falha ao atualizar perfil: {response}")
        self.test_results["update_profile"] = False
    
    return response

def inner_join_users_profiles(self):
    """
    Realiza um inner join entre usuários e perfis.
    Equivalente à operação 'inner_join_results' no arquivo testes.ex.
    
    Returns:
        A resposta do servidor
    """
    if not self.connected or not self.authenticated:
        logger.warning("Tentativa de realizar join sem conexão ou autenticação")
        return None
    
    # Cria um ID de requisição único
    request_id = str(uuid.uuid4())
    
    # Condições para o inner join em formato JSON
    conditions = {
        "join": {
            "schema": "profile",
            "type": "inner",
            "on": {"user_id": "id"}
        },
        "select": ["username", "email", "profile.bio", "profile.website"],
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
    logger.info("Realizando inner join entre usuários e perfis")
    self.send_message(message)
    
    # Aguarda a resposta
    response = self.wait_for_response()
    
    # Verifica o resultado
    if response and response.get('status') == 'success':
        logger.info(f"✅ Inner join realizado com sucesso: {len(response.get('data', []))} resultados")
        self.test_results["inner_join"] = True
    else:
        logger.error(f"❌ Falha ao realizar inner join: {response}")
        self.test_results["inner_join"] = False
    
    return response
