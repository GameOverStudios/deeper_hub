#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from modules.client_base import DeeperHubClient

class AuthClient(DeeperHubClient):
    """
    Implementa as funcionalidades de autenticação JWT para o cliente DeeperHub.
    """
    
    async def login(self, username, password, remember_me=False):
        """Realiza login no sistema usando o fluxo de autenticação JWT."""
        payload = {
            "action": "login",
            "username": username,
            "password": password,
            "remember_me": remember_me
        }
        
        response = await self.send_message("auth", payload)
        
        if response["type"] == "auth.login.success":
            self.access_token = response["payload"]["access_token"]
            self.refresh_token = response["payload"]["refresh_token"]
            self.user_id = response["payload"]["user_id"]
            self.username = response["payload"]["username"]
            print(f"✅ Login bem-sucedido como {username}")
            print(f"🔑 User ID: {self.user_id}")
            print(f"🔒 Token expira em: {response['payload']['expires_in']} segundos")
            return True
        else:
            print(f"❌ Falha no login: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    async def logout(self):
        """Realiza logout do sistema."""
        if not self.access_token or not self.refresh_token:
            print("❌ Não está autenticado")
            return False
            
        payload = {
            "action": "logout",
            "access_token": self.access_token,
            "refresh_token": self.refresh_token,
            "user_agent": "DeeperHubPythonClient"  # Adicionado para evitar o erro de badkey
        }
        
        response = await self.send_message("auth", payload)
        
        if response["type"] == "auth.logout.success":
            self.access_token = None
            self.refresh_token = None
            self.user_id = None
            self.username = None
            print("✅ Logout realizado com sucesso")
            return True
        else:
            print(f"❌ Falha no logout: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    async def refresh_tokens(self):
        """Atualiza os tokens de acesso usando o refresh token."""
        if not self.refresh_token:
            print("❌ Não possui refresh token")
            return False
            
        payload = {
            "action": "refresh",
            "refresh_token": self.refresh_token
        }
        
        response = await self.send_message("auth", payload)
        
        if response["type"] == "auth.refresh.success":
            self.access_token = response["payload"]["access_token"]
            self.refresh_token = response["payload"]["refresh_token"]
            print("✅ Tokens atualizados com sucesso")
            print(f"🔒 Novo token expira em: {response['payload'].get('expires_in', 'N/A')} segundos")
            return True
        else:
            print(f"❌ Falha ao atualizar tokens: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
            
    async def request_password_reset(self, email):
        """Solicita a recuperação de senha para um email."""
        payload = {
            "action": "request_password_reset",
            "email": email
        }
        
        response = await self.send_message("auth", payload)
        
        if response["type"] == "auth.password_reset.requested":
            print("✅ Solicitação de recuperação de senha enviada")
            # Em ambiente de desenvolvimento, o token é retornado diretamente
            # Em produção, isso não aconteceria - o token seria enviado por email
            if "token" in response["payload"]:
                print(f"🔑 Token de recuperação: {response['payload']['token']}")
                print(f"⏰ Expira em: {response['payload']['expires_at']}")
            return True, response["payload"].get("token")
        else:
            print(f"❌ Falha na solicitação: {response['payload'].get('message', 'Erro desconhecido')}")
            return False, None
            
    async def reset_password(self, token, new_password):
        """Redefine a senha usando um token de recuperação."""
        payload = {
            "action": "reset_password",
            "token": token,
            "password": new_password
        }
        
        response = await self.send_message("auth", payload)
        
        if response["type"] == "auth.password_reset.success":
            print("✅ Senha redefinida com sucesso")
            if "username" in response["payload"]:
                print(f"👤 Usuário: {response['payload']['username']}")
            return True
        else:
            print(f"❌ Falha ao redefinir senha: {response['payload'].get('message', 'Erro desconhecido')}")
            return False
