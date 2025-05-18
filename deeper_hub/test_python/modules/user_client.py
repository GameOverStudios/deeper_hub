#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from modules.auth_client import AuthClient

class UserClient(AuthClient):
    """
    Implementa as funcionalidades de gerenciamento de usuários para o cliente DeeperHub.
    """
    
    async def create_user(self, username, email, password):
        """Cria um novo usuário no sistema."""
        payload = {
            "action": "create",  # Ação correta conforme implementado no servidor
            "username": username,
            "email": email,
            "password": password
        }
        
        response = await self.send_message("user", payload)
        
        if response.get("type") == "user.create.success":
            print(f"✅ Usuário {username} criado com sucesso")
            print(f"🆔 ID: {response['payload'].get('id', 'N/A')}")
            return True
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            print(f"❌ Falha ao criar usuário: {error_msg}")
            return False
    
    async def list_users(self):
        """Lista todos os usuários do sistema."""
        payload = {
            "action": "list"  # Ação correta conforme implementado no servidor
        }
        
        response = await self.send_message("user", payload)
        
        if response.get("type") == "user.list.success":
            users = response["payload"].get("users", [])
            print(f"✅ {len(users)} usuários encontrados:")
            
            for i, user in enumerate(users, 1):
                print(f"{i}. {user.get('username')} (ID: {user.get('id')}, Email: {user.get('email')})")
                
            return users
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            print(f"❌ Falha ao listar usuários: {error_msg}")
            return []
    
    async def update_user(self, user_id, data):
        """Atualiza dados de um usuário."""
        # Adiciona o user_id diretamente ao payload, não em um objeto data
        payload = {
            "action": "update",  # Ação correta conforme implementado no servidor
            "user_id": user_id
        }
        
        # Adiciona os campos a serem atualizados diretamente no payload
        for key, value in data.items():
            payload[key] = value
        
        response = await self.send_message("user", payload)
        
        if response.get("type") == "user.update.success":
            print(f"✅ Usuário {user_id} atualizado com sucesso")
            return True
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            print(f"❌ Falha ao atualizar usuário: {error_msg}")
            return False
    
    async def delete_user(self, user_id):
        """Remove um usuário do sistema."""
        payload = {
            "action": "delete",  # Ação correta conforme implementado no servidor
            "user_id": user_id
        }
        
        response = await self.send_message("user", payload)
        
        if response.get("type") == "user.delete.success":
            print(f"✅ Usuário {user_id} excluído com sucesso")
            return True
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            print(f"❌ Falha ao excluir usuário: {error_msg}")
            return False
            
    async def get_user(self, user_id):
        """Obtém detalhes de um usuário específico."""
        payload = {
            "action": "get",  # Ação correta conforme implementado no servidor
            "user_id": user_id
        }
        
        response = await self.send_message("user", payload)
        
        if response.get("type") == "user.get.success":
            user = response["payload"]
            print(f"✅ Usuário encontrado:")
            print(f"ID: {user.get('id')}")
            print(f"Nome: {user.get('username')}")
            print(f"Email: {user.get('email')}")
            print(f"Ativo: {'Sim' if user.get('is_active') else 'Não'}")
            return user
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            print(f"❌ Falha ao obter usuário: {error_msg}")
            return None
            
    async def change_password(self, username, new_password):
        """Altera a senha de um usuário."""
        payload = {
            "action": "change_password",  # Ação conforme implementado no servidor
            "username": username,
            "password": new_password
        }
        
        response = await self.send_message("user", payload)
        
        if response.get("type") == "user.change_password.success":
            print(f"✅ Senha alterada com sucesso para o usuário {username}")
            return True
        else:
            error_msg = "Erro desconhecido"
            if isinstance(response, dict) and 'message' in response:
                error_msg = response['message']
            elif isinstance(response, dict) and 'payload' in response and 'message' in response['payload']:
                error_msg = response['payload']['message']
            print(f"❌ Falha ao alterar senha: {error_msg}")
            return False
