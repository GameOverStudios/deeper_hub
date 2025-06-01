#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Cliente Python para terminal interativo Elixir.
Este script permite conectar ao servidor DeeperHub e executar comandos Elixir remotamente.
"""

import requests
import json
import os
import sys
import colorama
from colorama import Fore, Style

# Tenta importar readline (Linux/Mac) ou pyreadline (Windows)
try:
    import readline
except ImportError:
    try:
        import pyreadline as readline
    except ImportError:
        # Se não conseguir importar readline, continue sem suporte a histórico
        pass

# Configuração do servidor
SERVER_URL = "http://localhost:4000"
API_PATH = "/api/terminal"

# Inicializa o colorama para formatação de cores
colorama.init()

class TerminalClient:
    """Cliente para interação com o terminal remoto Elixir."""
    
    def __init__(self, server_url=SERVER_URL):
        """Inicializa o cliente com a URL do servidor."""
        self.server_url = server_url
        self.api_url = f"{server_url}{API_PATH}"
        self.session_id = None
        self.history = []
    
    def create_session(self):
        """Cria uma nova sessão de terminal no servidor."""
        try:
            response = requests.post(f"{self.api_url}/sessions")
            if response.status_code == 201:
                data = response.json()
                self.session_id = data.get("session_id")
                print(f"{Fore.GREEN}✓ Sessão criada com sucesso. ID: {self.session_id}{Style.RESET_ALL}")
                return True
            else:
                print(f"{Fore.RED}✗ Erro ao criar sessão: {response.text}{Style.RESET_ALL}")
                return False
        except Exception as e:
            print(f"{Fore.RED}✗ Erro de conexão: {str(e)}{Style.RESET_ALL}")
            return False
    
    def list_sessions(self):
        """Lista todas as sessões ativas no servidor."""
        try:
            response = requests.get(f"{self.api_url}/sessions")
            if response.status_code == 200:
                data = response.json()
                sessions = data.get("sessions", [])
                
                if not sessions:
                    print(f"{Fore.YELLOW}Nenhuma sessão ativa encontrada.{Style.RESET_ALL}")
                    return
                
                print(f"{Fore.CYAN}Sessões ativas:{Style.RESET_ALL}")
                for session in sessions:
                    created_at = session.get("created_at", "N/A")
                    session_id = session.get("id", "N/A")
                    last_command = session.get("last_command", {})
                    
                    print(f"{Fore.CYAN}ID: {session_id}{Style.RESET_ALL}")
                    print(f"  Criada em: {created_at}")
                    if last_command:
                        command = last_command.get("command", "N/A")
                        executed_at = last_command.get("executed_at", "N/A")
                        print(f"  Último comando: {command}")
                        print(f"  Executado em: {executed_at}")
                    print("")
            else:
                print(f"{Fore.RED}✗ Erro ao listar sessões: {response.text}{Style.RESET_ALL}")
        except Exception as e:
            print(f"{Fore.RED}✗ Erro de conexão: {str(e)}{Style.RESET_ALL}")
    
    def execute_command(self, command):
        """Executa um comando na sessão atual."""
        if not self.session_id:
            print(f"{Fore.RED}✗ Nenhuma sessão ativa. Use 'new' para criar uma sessão.{Style.RESET_ALL}")
            return None
        
        try:
            # Aumentar o timeout para 30 segundos para comandos que podem demorar mais
            timeout = 30
            print(f"Executando comando... (timeout: {timeout}s)")
            
            response = requests.post(
                f"{self.api_url}/sessions/{self.session_id}/execute",
                json={"command": command},
                headers={"Content-Type": "application/json"},
                timeout=timeout
            )
            
            # Tentamos extrair a mensagem JSON, mesmo com código de erro
            try:
                data = response.json()
            except ValueError:
                data = {"message": response.text}
            
            # Processamos a resposta com base no status code
            if response.status_code == 200:
                result = data.get("result", "")
                
                # Verificamos se a resposta contém mensagens de erro formatadas do servidor
                if result.startswith("ERRO:") or result.startswith("ERRO DETECTADO:"):
                    # Dividimos a mensagem para exibir o tipo de erro em destaque
                    error_parts = result.split("\n\n", 1)
                    if len(error_parts) > 1:
                        error_type, error_details = error_parts
                        print(f"{Fore.RED}\n⚠️ {error_type}{Style.RESET_ALL}")
                        # Retornamos apenas os detalhes do erro sem o cabeçalho
                        result = error_details
                    else:
                        # Se não conseguirmos dividir, exibimos o erro completo
                        print(f"{Fore.RED}\n⚠️ Erro no código Elixir{Style.RESET_ALL}")
                # Verificações adicionais para mensagens de erro antigas
                elif "UndefinedFunctionError" in result:
                    print(f"{Fore.RED}\n⚠️ Erro: Função não definida{Style.RESET_ALL}")
                    print(f"{Fore.YELLOW}Dica: Verifique se o nome da função está correto. Por exemplo, use IO.puts/1 em vez de IO.put/1{Style.RESET_ALL}")
                elif "CompileError" in result:
                    print(f"{Fore.RED}\n⚠️ Erro: Erro de compilação{Style.RESET_ALL}")
                    print(f"{Fore.YELLOW}Dica: Verifique a sintaxe do seu código Elixir{Style.RESET_ALL}")
                elif "** (" in result and ")" in result:
                    print(f"{Fore.RED}\n⚠️ Erro no código Elixir{Style.RESET_ALL}")
                # Verificamos se é uma mensagem de timeout de segurança
                elif "[Timeout de segurança acionado" in result:
                    print(f"{Fore.YELLOW}\n⏱️ {result.split('\n')[0]}{Style.RESET_ALL}")
                    # Extrair e exibir a dica se existir
                    if "Dica:" in result:
                        dica = result.split("Dica:")[1].strip()
                        print(f"{Fore.CYAN}Dica: {dica}{Style.RESET_ALL}")
                
                # Adiciona o comando ao histórico
                self.history.append(command)
                return result
            elif response.status_code == 404:
                print(f"{Fore.RED}✗ Sessão não encontrada ou expirada.{Style.RESET_ALL}")
                self.session_id = None
                return None
            else:
                error_msg = data.get("message", response.text)
                print(f"{Fore.RED}✗ Erro ao executar comando: {error_msg}{Style.RESET_ALL}")
                return None
                
        except requests.exceptions.Timeout:
            print(f"{Fore.YELLOW}\n⏱️ Timeout: O comando está em execução, mas demorou mais que {timeout} segundos.{Style.RESET_ALL}")
            print(f"{Fore.YELLOW}Possíveis causas:{Style.RESET_ALL}")
            print(f"  • O comando é complexo e precisa de mais tempo")
            print(f"  • Há um erro de sintaxe que impediu o término do comando")
            print(f"  • O comando está em um loop infinito ou bloqueado\n")
            
            # Perguntar ao usuário se deseja tentar novamente com timeout maior
            retry = input(f"{Fore.CYAN}Deseja tentar novamente com um timeout maior? (s/n): {Style.RESET_ALL}").strip().lower()
            if retry == 's':
                # Aumentar o timeout em 50% e tentar novamente
                new_timeout = int(timeout * 1.5)
                print(f"{Fore.CYAN}Tentando novamente com timeout de {new_timeout} segundos...{Style.RESET_ALL}")
                try:
                    response = requests.post(
                        f"{self.api_url}/sessions/{self.session_id}/execute",
                        json={"command": command},
                        headers={"Content-Type": "application/json"},
                        timeout=new_timeout
                    )
                    
                    # Tentamos extrair a mensagem JSON, mesmo com código de erro
                    try:
                        data = response.json()
                        if response.status_code == 200:
                            result = data.get("result", "")
                            self.history.append(command)
                            return result
                    except ValueError:
                        pass
                    
                    print(f"{Fore.RED}A nova tentativa também falhou.{Style.RESET_ALL}")
                except Exception:
                    print(f"{Fore.RED}A nova tentativa também falhou.{Style.RESET_ALL}")
            
            return "[Comando em execução - Timeout do cliente atingido]"  
        except Exception as e:
            print(f"{Fore.RED}✗ Erro de conexão: {str(e)}{Style.RESET_ALL}")
            return None
    
    def terminate_session(self):
        """Encerra a sessão atual."""
        if not self.session_id:
            print(f"{Fore.YELLOW}Nenhuma sessão ativa para encerrar.{Style.RESET_ALL}")
            return False
        
        try:
            response = requests.delete(f"{self.api_url}/sessions/{self.session_id}")
            if response.status_code == 200:
                print(f"{Fore.GREEN}✓ Sessão encerrada com sucesso.{Style.RESET_ALL}")
                self.session_id = None
                return True
            elif response.status_code == 404:
                print(f"{Fore.YELLOW}Sessão não encontrada ou já encerrada.{Style.RESET_ALL}")
                self.session_id = None
                return True
            else:
                print(f"{Fore.RED}✗ Erro ao encerrar sessão: {response.text}{Style.RESET_ALL}")
                return False
        except Exception as e:
            print(f"{Fore.RED}✗ Erro de conexão: {str(e)}{Style.RESET_ALL}")
            return False
    
    def print_help(self):
        """Exibe a ajuda do terminal."""
        help_text = f"""
{Fore.CYAN}=== Terminal Interativo Elixir ==={Style.RESET_ALL}

{Fore.YELLOW}Comandos Especiais:{Style.RESET_ALL}
  {Fore.GREEN}help{Style.RESET_ALL}      - Exibe esta ajuda
  {Fore.GREEN}new{Style.RESET_ALL}       - Cria uma nova sessão
  {Fore.GREEN}list{Style.RESET_ALL}      - Lista todas as sessões ativas
  {Fore.GREEN}quit{Style.RESET_ALL}      - Sai do terminal (encerra a sessão atual)
  {Fore.GREEN}exit{Style.RESET_ALL}      - Sai do terminal (encerra a sessão atual)
  {Fore.GREEN}close{Style.RESET_ALL}     - Encerra a sessão atual sem sair do terminal
  {Fore.GREEN}cls{Style.RESET_ALL}       - Limpa a tela
  {Fore.GREEN}clear{Style.RESET_ALL}     - Limpa a tela
  
{Fore.YELLOW}Qualquer outro comando será enviado para o servidor Elixir.{Style.RESET_ALL}
"""
        print(help_text)
    
    def run_terminal(self):
        """Executa o terminal interativo."""
        print(f"{Fore.CYAN}=== Terminal Interativo Elixir ==={Style.RESET_ALL}")
        print(f"Digite '{Fore.GREEN}help{Style.RESET_ALL}' para ver os comandos disponíveis.")
        print(f"Digite '{Fore.GREEN}new{Style.RESET_ALL}' para criar uma nova sessão.")
        print("")
        
        # Loop principal do terminal
        while True:
            # Prompt com informação da sessão
            if self.session_id:
                prompt = f"{Fore.GREEN}iex ({self.session_id[:8]}...)> {Style.RESET_ALL}"
            else:
                prompt = f"{Fore.YELLOW}[Sem Sessão]> {Style.RESET_ALL}"
            
            try:
                # Lê o comando do usuário
                command = input(prompt)
                
                # Processa comandos especiais
                if command.strip().lower() in ["exit", "quit"]:
                    if self.session_id:
                        self.terminate_session()
                    print(f"{Fore.CYAN}Encerrando terminal...{Style.RESET_ALL}")
                    break
                    
                elif command.strip().lower() == "help":
                    self.print_help()
                    
                elif command.strip().lower() == "new":
                    self.create_session()
                    
                elif command.strip().lower() == "list":
                    self.list_sessions()
                    
                elif command.strip().lower() == "close":
                    self.terminate_session()
                    
                elif command.strip().lower() in ["clear", "cls"]:
                    os.system('cls' if os.name == 'nt' else 'clear')
                    
                elif command.strip():
                    # Executa o comando no servidor
                    result = self.execute_command(command)
                    if result is not None:
                        # Imprime o resultado com formatação adequada
                        if result:
                            print(f"\n{Fore.CYAN}Resultado:{Style.RESET_ALL}")
                            print(f"{Fore.CYAN}{'-' * 50}{Style.RESET_ALL}")
                            print(f"{Fore.WHITE}{result}{Style.RESET_ALL}")
                            print(f"{Fore.CYAN}{'-' * 50}{Style.RESET_ALL}")
                        else:
                            print(f"{Fore.YELLOW}Comando executado sem saída visível.{Style.RESET_ALL}")
                        
            except KeyboardInterrupt:
                print("\nPressione Ctrl+D ou digite 'exit' para sair.")
                
            except EOFError:
                if self.session_id:
                    self.terminate_session()
                print(f"\n{Fore.CYAN}Encerrando terminal...{Style.RESET_ALL}")
                break
                
            except Exception as e:
                print(f"{Fore.RED}✗ Erro: {str(e)}{Style.RESET_ALL}")

def main():
    """Função principal do cliente."""
    # Permite especificar uma URL de servidor alternativa
    server_url = SERVER_URL
    if len(sys.argv) > 1:
        server_url = sys.argv[1]
    
    # Cria e executa o cliente
    client = TerminalClient(server_url)
    client.run_terminal()

if __name__ == "__main__":
    main()
