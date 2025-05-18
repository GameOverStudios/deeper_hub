#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import asyncio
import uuid
import time
from datetime import datetime

class TestSuite:
    """
    Suite de testes automatizados para o cliente DeeperHub.
    Implementa testes para todas as funcionalidades em uma ordem eficiente.
    """
    
    def __init__(self, client):
        """Inicializa a suite de testes com o cliente DeeperHub."""
        self.client = client
        self.test_id = uuid.uuid4().hex[:8]
        self.test_results = {
            "total": 0,
            "passed": 0,
            "failed": 0,
            "skipped": 0
        }
        self.test_data = {}
        
    async def run_all_tests(self):
        """Executa todos os testes em uma ordem eficiente."""
        print("\n" + "="*70)
        print(f"INICIANDO SUITE DE TESTES AUTOMATIZADOS - {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
        print("="*70)
        
        # Gera dados de teste únicos
        self.test_data = {
            "username": f"test_user_{self.test_id}",
            "email": f"test_{self.test_id}@example.com",
            "password": f"password_{self.test_id}",
            "new_password": f"new_password_{self.test_id}",
            "channel_name": f"test_channel_{self.test_id}",
            "message_content": f"Mensagem de teste {self.test_id}"
        }
        
        # Ordem eficiente de testes
        test_sequence = [
            # 1. Testes de usuário (não requerem autenticação)
            self.test_create_user,
            self.test_list_users,
            
            # 2. Testes de autenticação básica
            self.test_login,
            self.test_refresh_tokens,
            
            # 3. Testes de canais e mensagens (requerem autenticação)
            self.test_create_channel,
            self.test_subscribe_channel,
            self.test_publish_message,
            
            # 4. Testes de mensagens diretas (se houver outro usuário)
            self.test_direct_messaging,
            
            # 5. Testes de logout e recuperação de senha
            self.test_logout,
            self.test_password_reset_flow,
            
            # 6. Testes finais de limpeza
            self.test_delete_user
        ]
        
        # Executa a sequência de testes
        for test_func in test_sequence:
            await self._run_test(test_func)
            
        # Exibe o resumo dos resultados
        print("\n" + "="*70)
        print(f"RESUMO DOS TESTES - {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
        print("="*70)
        print(f"Total de testes: {self.test_results['total']}")
        print(f"✅ Testes bem-sucedidos: {self.test_results['passed']}")
        print(f"❌ Testes falhos: {self.test_results['failed']}")
        print(f"⏭️ Testes ignorados: {self.test_results['skipped']}")
        print("="*70)
        
        return self.test_results
        
    async def _run_test(self, test_func):
        """Executa um teste individual e registra o resultado."""
        test_name = test_func.__name__.replace('test_', '').replace('_', ' ').title()
        
        print(f"\n📋 Executando teste: {test_name}")
        print("-" * 50)
        
        self.test_results["total"] += 1
        
        try:
            result = await test_func()
            if result is True:
                print(f"✅ Teste '{test_name}' concluído com sucesso")
                self.test_results["passed"] += 1
            elif result is False:
                print(f"❌ Teste '{test_name}' falhou")
                self.test_results["failed"] += 1
            else:  # None ou outro valor indica que o teste foi ignorado
                print(f"⏭️ Teste '{test_name}' ignorado")
                self.test_results["skipped"] += 1
        except Exception as e:
            print(f"❌ Erro durante o teste '{test_name}': {e}")
            self.test_results["failed"] += 1
            
        print("-" * 50)
        
    async def test_create_user(self):
        """Testa a criação de um novo usuário."""
        print(f"🔍 Criando usuário de teste: {self.test_data['username']}")
        try:
            return await self.client.create_user(
                self.test_data["username"],
                self.test_data["email"],
                self.test_data["password"]
            )
        except Exception as e:
            print(f"\n❌ Erro durante o teste de criação de usuário: {e}")
            return False
        
    async def test_list_users(self):
        """Testa a listagem de usuários e verifica se o usuário de teste foi criado."""
        print("\n🔍 Listando usuários para verificar se o novo usuário foi criado")
        try:
            users = await self.client.list_users()
            
            # Verifica se o usuário foi criado
            user_found = any(user.get("username") == self.test_data["username"] for user in users)
            if not user_found:
                print(f"\n❌ Usuário {self.test_data['username']} não encontrado na listagem")
                return False
                
            print(f"\n✅ Usuário {self.test_data['username']} encontrado na listagem")
            return True
        except Exception as e:
            print(f"\n❌ Erro durante o teste de listagem de usuários: {e}")
            return False
        
    async def test_login(self):
        """Testa o login com o usuário criado."""
        print(f"\n🔍 Fazendo login com o usuário: {self.test_data['username']}")
        try:
            return await self.client.login(
                self.test_data["username"],
                self.test_data["password"]
            )
        except Exception as e:
            print(f"\n❌ Erro durante o teste de login: {e}")
            return False
        
    async def test_refresh_tokens(self):
        """Testa a atualização de tokens."""
        if not self.client.refresh_token:
            print("\n⏭️ Ignorando teste de refresh de tokens - cliente não está autenticado")
            return None
            
        print("\n🔍 Atualizando tokens (refresh)")
        try:
            return await self.client.refresh_tokens()
        except Exception as e:
            print(f"\n❌ Erro durante o teste de refresh de tokens: {e}")
            return False
        
    async def test_create_channel(self):
        """Testa a criação de um canal."""
        if not self.client.access_token:
            print("\n⏭️ Ignorando teste de criação de canal - cliente não está autenticado")
            return None
            
        print(f"\n🔍 Criando canal de teste: {self.test_data['channel_name']}")
        try:
            return await self.client.create_channel(
                self.test_data["channel_name"],
                {"description": "Canal de teste automatizado"}
            )
        except Exception as e:
            print(f"\n❌ Erro durante o teste de criação de canal: {e}")
            return False
        
    async def test_subscribe_channel(self):
        """Testa a inscrição em um canal."""
        if not self.client.access_token:
            print("\n⏭️ Ignorando teste de inscrição em canal - cliente não está autenticado")
            return None
            
        print(f"\n🔍 Inscrevendo-se no canal: {self.test_data['channel_name']}")
        try:
            return await self.client.subscribe_channel(self.test_data["channel_name"])
        except Exception as e:
            print(f"\n❌ Erro durante o teste de inscrição em canal: {e}")
            return False
        
    async def test_publish_message(self):
        """Testa a publicação de mensagem em um canal."""
        if not self.client.access_token:
            print("\n⏭️ Ignorando teste de publicação de mensagem - cliente não está autenticado")
            return None
            
        print(f"\n🔍 Publicando mensagem no canal: {self.test_data['channel_name']}")
        try:
            return await self.client.publish_message(
                self.test_data["channel_name"],
                self.test_data["message_content"]
            )
        except Exception as e:
            print(f"\n❌ Erro durante o teste de publicação de mensagem: {e}")
            return False
        
    async def test_direct_messaging(self):
        """Testa o envio de mensagens diretas e obtenção de histórico."""
        if not self.client.access_token:
            print("\n⏭️ Ignorando teste de mensagens diretas - cliente não está autenticado")
            return None
            
        try:
            # Este teste requer outro usuário no sistema
            print("\n🔍 Listando usuários para encontrar um destinatário para mensagem direta")
            users = await self.client.list_users()
            
            # Encontra um usuário diferente do atual para enviar mensagem
            other_user = next((user for user in users if user.get("id") != self.client.user_id), None)
            
            if not other_user:
                print("\n⏭️ Ignorando teste de mensagens diretas - não há outros usuários no sistema")
                return None
                
            # Envia mensagem direta
            print(f"\n🔍 Enviando mensagem direta para: {other_user.get('username')}")
            send_success = await self.client.send_direct_message(
                other_user.get("id"),
                f"Mensagem de teste para {other_user.get('username')} - {self.test_id}"
            )
            
            if not send_success:
                return False
                
            # Obtém histórico de mensagens
            print(f"\n🔍 Obtendo histórico de mensagens com: {other_user.get('username')}")
            messages = await self.client.get_message_history(other_user.get("id"))
            
            if not messages:
                print("\n❌ Histórico de mensagens vazio")
                return False
                
            return True
        except Exception as e:
            print(f"\n❌ Erro durante o teste de mensagens diretas: {e}")
            return False
        
    async def test_logout(self):
        """Testa o logout."""
        if not self.client.access_token:
            print("\n⏭️ Ignorando teste de logout - cliente não está autenticado")
            return None
            
        print("\n🔍 Fazendo logout")
        try:
            return await self.client.logout()
        except Exception as e:
            print(f"\n❌ Erro durante o teste de logout: {e}")
            return False
        
    async def test_password_reset_flow(self):
        """Testa o fluxo completo de recuperação e redefinição de senha."""
        try:
            print(f"\n🔍 Solicitando recuperação de senha para: {self.test_data['email']}")
            success, reset_token = await self.client.request_password_reset(self.test_data["email"])
            
            if not success or not reset_token:
                print("\n❌ Falha na solicitação de recuperação de senha")
                return False
                
            print(f"\n🔍 Redefinindo senha com o token recebido")
            reset_success = await self.client.reset_password(reset_token, self.test_data["new_password"])
            
            if not reset_success:
                print("\n❌ Falha na redefinição de senha")
                return False
                
            print(f"\n🔍 Testando login com a nova senha")
            login_success = await self.client.login(
                self.test_data["username"],
                self.test_data["new_password"]
            )
            
            if not login_success:
                print("\n❌ Falha no login após redefinição de senha")
                return False
                
            # Faz logout para preparar para o próximo teste
            await self.client.logout()
            return True
        except Exception as e:
            print(f"\n❌ Erro durante o teste de recuperação de senha: {e}")
            return False
        
    async def test_delete_user(self):
        """Testa a exclusão do usuário de teste."""
        try:
            # Primeiro precisa fazer login novamente
            login_success = await self.client.login(
                self.test_data["username"],
                self.test_data["new_password"]
            )
            
            if not login_success:
                print("\n⏭️ Ignorando teste de exclusão - não foi possível autenticar")
                return None
                
            # Agora pode excluir o usuário
            print(f"\n🔍 Excluindo usuário de teste: {self.test_data['username']}")
            delete_success = await self.client.delete_user(self.client.user_id)
            
            if delete_success:
                # Verifica se o usuário foi realmente excluído
                await asyncio.sleep(1)  # Pequena pausa para garantir que a exclusão foi processada
                users = await self.client.list_users()
                user_still_exists = any(user.get("username") == self.test_data["username"] for user in users)
                
                if user_still_exists:
                    print(f"\n❌ Usuário {self.test_data['username']} ainda existe após exclusão")
                    return False
                    
            return delete_success
        except Exception as e:
            print(f"\n❌ Erro durante o teste de exclusão de usuário: {e}")
            return False
