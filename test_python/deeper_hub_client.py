#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import asyncio
import argparse
import sys
import os
import traceback
import importlib

# Adiciona o diretório atual ao path para importações relativas
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from modules.messaging_client import MessagingClient
from modules.test_suite import TestSuite
from modules.logger import get_logger, DeeperHubLogger
from modules.hot_reload import setup_hot_reload

async def run_interactive_client(host="localhost", port=4000, log_level="info"):
    """Executa o cliente em modo interativo."""
    # Configura o logger principal
    logger = get_logger("DeeperHubMain")
    logger.set_level(DeeperHubLogger.LOG_LEVELS.get(log_level.lower(), DeeperHubLogger.INFO))
    logger.info(f"Iniciando cliente interativo - Conectando a {host}:{port}")
    
    client = None
    try:
        client = MessagingClient(host, port, log_level)
        
        if not await client.connect():
            logger.error("Falha ao conectar ao servidor")
            return
        
        while True:
            print("\n" + "="*50)
            print("DEEPER HUB - CLIENTE WEBSOCKET")
            print("="*50)
            
            if client.username:
                print(f"\nLogado como: {client.username} (ID: {client.user_id})")
                print("\nOpções:")
                print("1. Criar usuário")
                print("2. Listar usuários")
                print("3. Atualizar usuário")
                print("4. Excluir usuário")
                print("5. Criar canal")
                print("6. Inscrever-se em canal")
                print("7. Publicar mensagem em canal")
                print("8. Enviar mensagem direta")
                print("9. Ver histórico de mensagens")
                print("10. Atualizar tokens (refresh)")
                print("11. Logout")
                print("12. Executar todos os testes automatizados")
                print("0. Sair")
            else:
                print("\nOpções:")
                print("1. Criar usuário")
                print("2. Listar usuários")
                print("3. Login")
                print("4. Solicitar recuperação de senha")
                print("5. Redefinir senha")
                print("12. Executar todos os testes automatizados")
                print("0. Sair")
                
            choice = input("\nEscolha uma opção: ")
            
            if choice == "0":
                print("Encerrando cliente...")
                break
                
            elif choice == "1":
                username = input("Nome de usuário: ")
                email = input("Email: ")
                password = input("Senha: ")
                await client.create_user(username, email, password)
                
            elif choice == "2":
                await client.list_users()
                
            elif choice == "3" and not client.username:
                username = input("Nome de usuário: ")
                password = input("Senha: ")
                await client.login(username, password)
                
            elif choice == "3" and client.username:
                user_id = input("ID do usuário a atualizar: ")
                print("Dados a atualizar (deixe em branco para não alterar):")
                email = input("Novo email: ")
                
                data = {}
                if email:
                    data["email"] = email
                    
                await client.update_user(user_id, data)
                
            elif choice == "4" and not client.username:
                email = input("Email para recuperação de senha: ")
                success, token = await client.request_password_reset(email)
                if success and token:
                    print(f"\nGuarde este token para redefinir sua senha: {token}")
                
            elif choice == "4" and client.username:
                user_id = input("ID do usuário a excluir: ")
                confirm = input(f"Tem certeza que deseja excluir o usuário {user_id}? (s/n): ")
                if confirm.lower() == "s":
                    await client.delete_user(user_id)
                    
            elif choice == "5" and not client.username:
                token = input("Token de recuperação: ")
                new_password = input("Nova senha: ")
                await client.reset_password(token, new_password)
                    
            elif choice == "5" and client.username:
                channel_name = input("Nome do canal: ")
                description = input("Descrição (opcional): ")
                
                metadata = {}
                if description:
                    metadata["description"] = description
                    
                await client.create_channel(channel_name, metadata)
                
            elif choice == "6" and client.username:
                channel_name = input("Nome do canal: ")
                await client.subscribe_channel(channel_name)
                
            elif choice == "7" and client.username:
                channel_name = input("Nome do canal: ")
                content = input("Mensagem: ")
                await client.publish_message(channel_name, content)
                
            elif choice == "8" and client.username:
                recipient_id = input("ID do destinatário: ")
                content = input("Mensagem: ")
                await client.send_direct_message(recipient_id, content)
                
            elif choice == "9" and client.username:
                other_user_id = input("ID do outro usuário: ")
                await client.get_message_history(other_user_id)
                
            elif choice == "10" and client.username:
                await client.refresh_tokens()
                
            elif choice == "11" and client.username:
                await client.logout()
                
            elif choice == "12":
                # Cria um novo cliente para os testes para não interferir com o cliente atual
                try:
                    test_client = MessagingClient(host, port)
                    if not await test_client.connect():
                        print("\n❌ Falha ao conectar ao servidor para testes. Verifique se o servidor está em execução.")
                        continue
                    
                    test_suite = TestSuite(test_client)
                    await test_suite.run_all_tests()
                    
                    # Fecha o cliente de teste
                    await test_client.close()
                except Exception as e:
                    print(f"\n❌ Erro durante a execução dos testes automatizados: {e}")
                
            else:
                print("Opção inválida ou não disponível no estado atual")
                
            
            
    except KeyboardInterrupt:
        logger.info("Operação interrompida pelo usuário")
    except Exception as e:
        logger.critical(f"Erro inesperado no cliente interativo: {e}")
        logger.debug(traceback.format_exc())
    finally:
        if client:
            await client.close()

async def run_automated_test(host, port, log_level="info"):
    """Executa o teste automatizado completo."""
    # Configura o logger para testes
    logger = get_logger("DeeperHubTests")
    logger.set_level(DeeperHubLogger.LOG_LEVELS.get(log_level.lower(), DeeperHubLogger.INFO))
    logger.info(f"Iniciando testes automatizados - Conectando a {host}:{port}")
    
    client = None
    try:
        client = MessagingClient(host, port, log_level)
        
        if not await client.connect():
            logger.error("Falha ao conectar ao servidor para testes")
            return
            
        try:
            test_suite = TestSuite(client)
            await test_suite.run_all_tests()
            logger.info("Testes automatizados concluídos com sucesso")
        except Exception as e:
            logger.error(f"Erro durante os testes automatizados: {e}")
            logger.debug(traceback.format_exc())
        finally:
            if client:
                await client.close()
    except Exception as e:
        logger.critical(f"Erro fatal ao iniciar os testes: {e}")
        logger.debug(traceback.format_exc())

def module_reloaded_callback(module_name):
    """Função chamada quando um módulo é recarregado."""
    logger = get_logger("HotReload")
    logger.info(f"Módulo recarregado: {module_name}")
    
    # Recarrega módulos dependentes se necessário
    if module_name == "modules.client_base":
        if "modules.auth_client" in sys.modules:
            importlib.reload(sys.modules["modules.auth_client"])
        if "modules.user_client" in sys.modules:
            importlib.reload(sys.modules["modules.user_client"])
        if "modules.messaging_client" in sys.modules:
            importlib.reload(sys.modules["modules.messaging_client"])
    elif module_name == "modules.auth_client":
        if "modules.user_client" in sys.modules:
            importlib.reload(sys.modules["modules.user_client"])
        if "modules.messaging_client" in sys.modules:
            importlib.reload(sys.modules["modules.messaging_client"])
    elif module_name == "modules.user_client":
        if "modules.messaging_client" in sys.modules:
            importlib.reload(sys.modules["modules.messaging_client"])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Cliente WebSocket para DeeperHub")
    parser.add_argument("--host", default="localhost", help="Endereço do servidor (padrão: localhost)")
    parser.add_argument("--port", type=int, default=4000, help="Porta do servidor (padrão: 4000)")
    parser.add_argument("--test", action="store_true", help="Executar teste automatizado")
    parser.add_argument("--log-level", default="info", choices=["debug", "info", "warning", "error", "critical"],
                      help="Nível de log (padrão: info)")
    parser.add_argument("--hot-reload", action="store_true", help="Ativar hot reload para desenvolvimento")
    
    args = parser.parse_args()
    
    # Cria o diretório de logs se não existir
    log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    # Configura o hot reload se solicitado
    reloader = None
    if args.hot_reload:
        modules_to_watch = [
            "modules.client_base",
            "modules.auth_client",
            "modules.user_client",
            "modules.messaging_client",
            "modules.test_suite"
        ]
        project_dir = os.path.dirname(os.path.abspath(__file__))
        reloader = setup_hot_reload(project_dir, modules_to_watch, module_reloaded_callback)
    
    try:
        if args.test:
            asyncio.run(run_automated_test(args.host, args.port, args.log_level))
        else:
            asyncio.run(run_interactive_client(args.host, args.port, args.log_level))
    except Exception as e:
        print(f"\n❌ Erro fatal na execução do cliente: {e}")
        print(traceback.format_exc())
    finally:
        # Para o hot reload se estiver ativo
        if reloader:
            reloader.stop()
