import logging
import json
import time
import uuid
logger = logging.getLogger('crud_test')

def conditional_join_users_profiles(self):
    """
    Realiza um join com condições adicionais entre usuários e perfis.
    Equivalente à operação 'conditional_join_results' no arquivo testes.ex.
    
    Returns:
        A resposta do servidor
    """
    if not self.connected or not self.authenticated:
        logger.warning("Tentativa de realizar join sem conexão ou autenticação")
        return None
    
    # Cria um ID de requisição único
    request_id = str(uuid.uuid4())
    
    # Condições para o join condicional em formato JSON
    conditions = {
        "join": {
            "schema": "profile",
            "type": "inner",
            "on": {"user_id": "id"}
        },
        "where": {
            "is_active": True,
            "profile": {
                "website": {"not": None}
            }
        },
        "order_by": {"username": "desc"},
        "limit": 10,
        "offset": 0
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
    logger.info("Realizando join com condições entre usuários e perfis")
    self.send_message(message)
    
    # Aguarda a resposta
    response = self.wait_for_response()
    
    # Verifica o resultado
    if response and response.get('status') == 'success':
        logger.info(f"✅ Join condicional realizado com sucesso: {len(response.get('data', []))} resultados")
        self.test_results["conditional_join"] = True
    else:
        logger.error(f"❌ Falha ao realizar join condicional: {response}")
        self.test_results["conditional_join"] = False
    
    return response

def run_all_tests(self):
    """
    Executa todos os testes sequencialmente.
    Implementa todos os testes equivalentes aos do arquivo testes.ex,
    incluindo operações CRUD e diferentes tipos de joins.
    
    Returns:
        Um dicionário com os resultados de todos os testes
    """
    logger.info("Iniciando testes completos de CRUD e joins...")
    
    # ===== TESTES DE USUÁRIOS =====
    logger.info("\n===== TESTES DE USUÁRIOS =====")
    
    # 1. Criar um usuário
    user_response, user_id = self.create_user()
    
    # Se não conseguiu criar um usuário, não continua os testes
    if not user_response or not user_id:
        logger.error("Não foi possível criar um usuário, pulando os outros testes")
        return self.test_results
    
    logger.info(f"Usuário criado com ID: {user_id}")
    
    # 2. Obter usuário por ID
    get_user_response = self.get_user(user_id)
    if get_user_response and get_user_response.get('status') == 'success':
        logger.info("✅ Usuário recuperado com sucesso")
        self.test_results["get_user"] = True
    else:
        logger.error(f"❌ Falha ao recuperar usuário: {get_user_response}")
        self.test_results["get_user"] = False
    
    # 3. Buscar usuários ativos
    active_users_response = self.find_active_users()
    if active_users_response and active_users_response.get('status') == 'success':
        logger.info(f"✅ Usuários ativos encontrados: {len(active_users_response.get('data', []))}")
        self.test_results["find_active_users"] = True
    else:
        logger.error(f"❌ Falha ao buscar usuários ativos: {active_users_response}")
        self.test_results["find_active_users"] = False
    
    # 4. Atualizar usuário
    update_user_response = self.update_user(user_id)
    if update_user_response and update_user_response.get('status') == 'success':
        logger.info("✅ Usuário atualizado com sucesso")
        self.test_results["update_user"] = True
    else:
        logger.error(f"❌ Falha ao atualizar usuário: {update_user_response}")
        self.test_results["update_user"] = False
    
    # ===== TESTES DE PERFIS =====
    logger.info("\n===== TESTES DE PERFIS =====")
    
    # 1. Criar um perfil para o usuário
    profile_response, profile_id = self.create_profile(user_id)
    
    # Se não conseguiu criar um perfil, não continua os testes de perfil
    if not profile_response or not profile_id:
        logger.error("Não foi possível criar um perfil, pulando os testes de perfil")
    else:
        logger.info(f"Perfil criado com ID: {profile_id}")
        
        # 2. Atualizar perfil
        update_profile_response = self.update_profile(profile_id)
        if update_profile_response and update_profile_response.get('status') == 'success':
            logger.info("✅ Perfil atualizado com sucesso")
            self.test_results["update_profile"] = True
        else:
            logger.error(f"❌ Falha ao atualizar perfil: {update_profile_response}")
            self.test_results["update_profile"] = False
    
    # ===== TESTES DE JOINS =====
    logger.info("\n===== TESTES DE JOINS =====")
    
    # 1. Inner Join
    inner_join_response = self.inner_join_users_profiles()
    if inner_join_response and inner_join_response.get('status') == 'success':
        logger.info(f"✅ Inner join realizado com sucesso: {len(inner_join_response.get('data', []))} resultados")
        self.test_results["inner_join"] = True
    else:
        logger.error(f"❌ Falha ao realizar inner join: {inner_join_response}")
        self.test_results["inner_join"] = False
    
    # 2. Left Join
    left_join_response = self.left_join_users_profiles()
    if left_join_response and left_join_response.get('status') == 'success':
        logger.info(f"✅ Left join realizado com sucesso: {len(left_join_response.get('data', []))} resultados")
        self.test_results["left_join"] = True
    else:
        logger.error(f"❌ Falha ao realizar left join: {left_join_response}")
        self.test_results["left_join"] = False
    
    # 3. Right Join
    right_join_response = self.right_join_users_profiles()
    if right_join_response and right_join_response.get('status') == 'success':
        logger.info(f"✅ Right join realizado com sucesso: {len(right_join_response.get('data', []))} resultados")
        self.test_results["right_join"] = True
    else:
        logger.error(f"❌ Falha ao realizar right join: {right_join_response}")
        self.test_results["right_join"] = False
    
    # 4. Join com condições adicionais
    conditional_join_response = self.conditional_join_users_profiles()
    if conditional_join_response and conditional_join_response.get('status') == 'success':
        logger.info(f"✅ Join condicional realizado com sucesso: {len(conditional_join_response.get('data', []))} resultados")
        self.test_results["conditional_join"] = True
    else:
        logger.error(f"❌ Falha ao realizar join condicional: {conditional_join_response}")
        self.test_results["conditional_join"] = False
    
    # ===== RESUMO DOS TESTES =====
    logger.info("\n===== RESUMO DOS TESTES =====")
    for test_name, result in self.test_results.items():
        status = "✅ PASSOU" if result else "❌ FALHOU"
        logger.info(f"{test_name}: {status}")
    
    # Verifica se algum teste falhou
    if not all(self.test_results.values()):
        logger.info("\n⚠️ ALGUNS TESTES FALHARAM OU NÃO FORAM EXECUTADOS ⚠️")
    else:
        logger.info("\n🎉 TODOS OS TESTES PASSARAM! 🎉")
    
    return self.test_results
