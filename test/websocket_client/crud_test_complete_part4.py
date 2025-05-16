import logging
import json
import uuid
import time
logger = logging.getLogger('crud_test')

def left_join_users_profiles(self):
    """
    Realiza um left join entre usuários e perfis.
    Equivalente à operação 'left_join_results' no arquivo testes.ex.
    
    Returns:
        A resposta do servidor
    """
    if not self.connected or not self.authenticated:
        logger.warning("Tentativa de realizar join sem conexão ou autenticação")
        return None
    
    # Cria um ID de requisição único
    request_id = str(uuid.uuid4())
    
    # Condições para o left join em formato JSON
    conditions = {
        "join": {
            "schema": "profile",
            "type": "left",
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
    logger.info("Realizando left join entre usuários e perfis")
    self.send_message(message)
    
    # Aguarda a resposta
    response = self.wait_for_response()
    
    # Verifica o resultado
    if response and response.get('status') == 'success':
        logger.info(f"✅ Left join realizado com sucesso: {len(response.get('data', []))} resultados")
        self.test_results["left_join"] = True
    else:
        logger.error(f"❌ Falha ao realizar left join: {response}")
        self.test_results["left_join"] = False
    
    return response

def right_join_users_profiles(self):
    """
    Realiza um right join entre usuários e perfis.
    Equivalente à operação 'right_join_results' no arquivo testes.ex.
    
    Returns:
        A resposta do servidor
    """
    if not self.connected or not self.authenticated:
        logger.warning("Tentativa de realizar join sem conexão ou autenticação")
        return None
    
    # Cria um ID de requisição único
    request_id = str(uuid.uuid4())
    
    # Condições para o right join em formato JSON
    conditions = {
        "join": {
            "schema": "profile",
            "type": "right",
            "on": {"user_id": "id"}
        },
        "select": ["username", "email", "profile.bio", "profile.website"],
        "order_by": {"profile.website": "asc"},
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
    logger.info("Realizando right join entre usuários e perfis")
    self.send_message(message)
    
    # Aguarda a resposta
    response = self.wait_for_response()
    
    # Verifica o resultado
    if response and response.get('status') == 'success':
        logger.info(f"✅ Right join realizado com sucesso: {len(response.get('data', []))} resultados")
        self.test_results["right_join"] = True
    else:
        logger.error(f"❌ Falha ao realizar right join: {response}")
        self.test_results["right_join"] = False
    
    return response
