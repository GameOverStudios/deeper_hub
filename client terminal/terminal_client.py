#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Cliente Python para terminal interativo Elixir com streaming.
Este script permite conectar ao servidor DeeperHub e executar comandos Elixir remotamente,
recebendo a saída em tempo real.
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
        import pyreadline3 as readline # pyreadline está obsoleto, pyreadline3 é o sucessor
    except ImportError:
        try:
            import pyreadline as readline # Fallback para pyreadline se pyreadline3 não estiver disponível
        except ImportError:
            pass # Se não conseguir importar readline, continue sem suporte a histórico

# Configuração do servidor
SERVER_URL = "http://localhost:4000"
API_PATH = "/api/terminal"

# Inicializa o colorama para formatação de cores
colorama.init(autoreset=True) # autoreset=True para não precisar adicionar Style.RESET_ALL sempre


class TerminalClient:
    """Cliente para interação com o terminal ou console remoto Elixir."""

    def __init__(self, server_url=SERVER_URL):
        """Inicializa o cliente com a URL do servidor e modo (terminal/console)."""
        self.server_url = server_url
        self.mode = "terminal"  # terminal ou console
        self.api_url = self._get_api_url()
        self.session_id = None

    def _get_api_url(self):
        if self.mode == "console":
            return f"{self.server_url}/api/console"
        return f"{self.server_url}/api/terminal"

    def set_mode(self, mode):
        mode = mode.lower()
        if mode not in ["terminal", "console"]:
            print(f"{Fore.RED}✗ Modo inválido: {mode}. Use 'terminal' ou 'console'.")
            return
        if self.session_id:
            print(f"{Fore.CYAN}Encerrando sessão atual antes de trocar de modo...")
            self.terminate_session()
        self.mode = mode
        self.api_url = self._get_api_url()
        print(f"{Fore.CYAN}Modo alterado para: {self.mode}{Style.RESET_ALL}")

    def create_session(self):
        """Cria uma nova sessão no modo atual (terminal ou console)."""
        try:
            response = requests.post(f"{self.api_url}/sessions", timeout=10)
            if response.status_code == 201:
                data = response.json()
                self.session_id = data.get("session_id")
                print(f"{Fore.GREEN}✓ Sessão criada com sucesso no modo {self.mode}. ID: {self.session_id}")
                return True
            else:
                print(f"{Fore.RED}✗ Erro ao criar sessão (HTTP {response.status_code}): {response.text}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"{Fore.RED}✗ Erro de conexão ao criar sessão: {str(e)}")
            return False
        except json.JSONDecodeError:
            print(f"{Fore.RED}✗ Erro ao decodificar resposta JSON do servidor ao criar sessão.")
            return False

    def list_sessions(self):
        """Lista todas as sessões ativas no servidor."""
        try:
            response = requests.get(f"{self.api_url}/sessions", timeout=10)
            if response.status_code == 200:
                data = response.json()
                sessions = data.get("sessions", [])

                if not sessions:
                    print(f"{Fore.YELLOW}Nenhuma sessão ativa encontrada.")
                    return

                print(f"{Fore.CYAN}Sessões ativas:")
                for session in sessions:
                    created_at = session.get("created_at", "N/A")
                    session_id_info = session.get("id", "N/A") # Renomeado para evitar conflito
                    last_command_info = session.get("last_command") # Renomeado

                    print(f"{Fore.CYAN}ID: {session_id_info}")
                    print(f"  Criada em: {created_at}")
                    if last_command_info and isinstance(last_command_info, dict):
                        command_text = last_command_info.get("command", "N/A") # Renomeado
                        executed_at = last_command_info.get("executed_at", "N/A")
                        print(f"  Último comando: {command_text}")
                        print(f"  Executado em: {executed_at}")
                    elif last_command_info: # Se for string (caso de formato antigo)
                        print(f"  Último comando: {last_command_info}")
                    print("") # Linha em branco para separar sessões
            else:
                print(f"{Fore.RED}✗ Erro ao listar sessões (HTTP {response.status_code}): {response.text}")
        except requests.exceptions.RequestException as e:
            print(f"{Fore.RED}✗ Erro de conexão ao listar sessões: {str(e)}")
        except json.JSONDecodeError:
            print(f"{Fore.RED}✗ Erro ao decodificar resposta JSON do servidor ao listar sessões.")

    def execute_command(self, command_to_execute): # Renomeado para evitar conflito
        """Executa um comando na sessão atual e processa a saída em stream."""
        if not self.session_id:
            print(f"{Fore.RED}✗ Nenhuma sessão ativa. Use 'new' para criar uma sessão.")
            return

        url = f"{self.api_url}/sessions/{self.session_id}/execute"
        payload = {"command": command_to_execute}
        headers = {"Content-Type": "application/json", "Accept": "text/plain"} # Aceita text/plain para stream

        # Timeout para a conexão inicial e para cada chunk recebido.
        # O timeout total da operação de streaming pode ser maior.
        # Um timeout muito longo aqui pode fazer o cliente travar se o servidor não enviar nada.
        # Um timeout muito curto pode interromper streams longos.
        # O servidor tem seu próprio timeout de comando.
        # O timeout do requests.post com stream=True se aplica à conexão e ao tempo entre chunks.
        stream_timeout = 60  # Segundos para esperar por cada parte do stream

        print(f"{Fore.BLUE}Executando (aguardando saída)...{Style.RESET_ALL}")
        output_buffer = [] # Para coletar toda a saída antes de imprimir (opcional, mas pode ajudar na formatação)
        has_output = False

        try:
            with requests.post(url, json=payload, headers=headers, stream=True, timeout=stream_timeout) as r:
                if r.status_code == 200:
                    # O servidor respondeu com 200 OK, indicando que o streaming começou.
                    # Agora iteramos sobre os chunks.
                    for chunk_bytes in r.iter_content(chunk_size=None, decode_unicode=True): # chunk_size=None para ler o que vier
                        if chunk_bytes: # Filtra chunks de keep-alive vazios
                            # Decodifica bytes para string (o servidor envia UTF-8)
                            # r.iter_lines() já decodifica, mas iter_content dá mais controle
                            # Se usar decode_unicode=True, chunk_bytes já será string
                            chunk_str = chunk_bytes

                            # Aqui, você pode processar cada chunk_str.
                            # O servidor está enviando linhas completas, mas com iter_content
                            # você pode receber partes de linhas. Para simplicidade, vamos assumir
                            # que cada chunk do servidor é uma unidade de impressão.
                            # Se o servidor envia cada chunk como uma linha JSON separada (NDJSON),
                            # você faria json.loads(chunk_str) aqui.
                            # No nosso caso, o servidor envia texto plano.
                            
                            # Imprime o chunk diretamente
                            # print(chunk_str, end='', flush=True) # end='' para não adicionar nova linha extra
                            
                            # Ou acumula no buffer
                            output_buffer.append(chunk_str)
                            has_output = True

                    # Após o loop, o stream terminou (ou o timeout do servidor foi atingido)
                    # Imprime o buffer acumulado, se houver
                    if has_output:
                        # print() # Garante uma nova linha se a última não tiver
                        full_output = "".join(output_buffer)

                        # Tratamento de erros com base na saída (opcional, mas útil)
                        if "ERRO:" in full_output or "** (" in full_output or "[TIMEOUT NO SERVIDOR:" in full_output or "[Sessão Manager:" in full_output:
                            print(f"{Fore.YELLOW}{full_output}{Style.RESET_ALL}")
                        elif "[Terminal process exited" in full_output or "[Processo do terminal da sessão encerrou" in full_output:
                             print(f"{Fore.RED}{full_output}{Style.RESET_ALL}")
                        else:
                            print(f"{Fore.WHITE}{full_output}{Style.RESET_ALL}", end='') # end='' se a saída já tiver novas linhas

                        # Adiciona ao histórico apenas se for bem-sucedido e tiver output
                        # (readline cuida do histórico de entrada)
                    # else:
                    #     print(f"{Fore.YELLOW}Comando executado, mas sem saída do stream.{Style.RESET_ALL}")

                elif r.status_code == 400:
                    error_data = r.json()
                    print(f"{Fore.RED}✗ Erro na requisição (HTTP {r.status_code}): {error_data.get('message', r.text)}")
                elif r.status_code == 404:
                    error_data = r.json()
                    print(f"{Fore.RED}✗ Sessão não encontrada (HTTP {r.status_code}): {error_data.get('message', r.text)}")
                    self.session_id = None # Reseta a sessão se não encontrada
                else:
                    # Outros erros HTTP antes do início do streaming
                    print(f"{Fore.RED}✗ Erro ao iniciar execução (HTTP {r.status_code}): {r.text}")

        except requests.exceptions.Timeout:
            # Timeout pode ocorrer durante a conexão inicial ou entre chunks do stream
            print(f"{Fore.YELLOW}\n⏱️ Timeout do cliente: A conexão com o servidor ou o stream de dados demorou mais que {stream_timeout}s.")
            print(f"{Fore.YELLOW}   O comando pode ainda estar em execução no servidor ou a rede pode estar lenta.")
        except requests.exceptions.ConnectionError as e:
            print(f"{Fore.RED}✗ Erro de conexão ao executar comando: {str(e)}")
        except json.JSONDecodeError:
            # Isso aconteceria se um erro HTTP (ex: 400) retornasse algo que não é JSON válido
            print(f"{Fore.RED}✗ Erro ao decodificar resposta de erro JSON do servidor.")
        except Exception as e:
            print(f"{Fore.RED}✗ Erro inesperado ao executar comando: {str(e)}")

    def terminate_session(self):
        """Encerra a sessão atual."""
        if not self.session_id:
            print(f"{Fore.YELLOW}Nenhuma sessão ativa para encerrar.")
            return False

        try:
            response = requests.delete(f"{self.api_url}/sessions/{self.session_id}", timeout=10)
            if response.status_code == 200:
                data = response.json()
                print(f"{Fore.GREEN}✓ {data.get('message', 'Sessão encerrada com sucesso.')}")
                self.session_id = None
                return True
            elif response.status_code == 404:
                data = response.json()
                print(f"{Fore.YELLOW}{data.get('message', 'Sessão não encontrada ou já encerrada.')}")
                self.session_id = None # Considera encerrada
                return True
            else:
                print(f"{Fore.RED}✗ Erro ao encerrar sessão (HTTP {response.status_code}): {response.text}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"{Fore.RED}✗ Erro de conexão ao encerrar sessão: {str(e)}")
            return False
        except json.JSONDecodeError:
            print(f"{Fore.RED}✗ Erro ao decodificar resposta JSON do servidor ao encerrar sessão.")
            return False


    def print_help(self):
        """Exibe a ajuda do terminal."""
        help_text = f"""
{Fore.CYAN}=== Terminal Interativo Elixir ==={Style.RESET_ALL}

{Fore.YELLOW}Comandos Especiais:{Style.RESET_ALL}
  {Fore.GREEN}help{Style.RESET_ALL}      - Exibe esta ajuda
  {Fore.GREEN}new{Style.RESET_ALL}       - Cria uma nova sessão (encerra a atual se existir)
  {Fore.GREEN}list{Style.RESET_ALL}      - Lista todas as sessões ativas
  {Fore.GREEN}quit{Style.RESET_ALL}      - Sai do terminal (encerra a sessão atual)
  {Fore.GREEN}exit{Style.RESET_ALL}      - Sai do terminal (encerra a sessão atual)
  {Fore.GREEN}close{Style.RESET_ALL}     - Encerra a sessão atual sem sair do terminal
  {Fore.GREEN}cls{Style.RESET_ALL}       - Limpa a tela (Windows)
  {Fore.GREEN}clear{Style.RESET_ALL}     - Limpa a tela (Linux/Mac)

{Fore.YELLOW}Qualquer outro comando será enviado para o servidor Elixir.{Style.RESET_ALL}
"""
        print(help_text)


    def run_terminal(self):
        """Executa o terminal/console interativo."""
        print(f"{Fore.CYAN}=== Terminal/Console Interativo Elixir (Cliente Python) ===")
        print(f"Digite '{Fore.GREEN}help{Style.RESET_ALL}' para ver os comandos disponíveis.")
        print(f"Use '{Fore.GREEN}new terminal{Style.RESET_ALL}' ou '{Fore.GREEN}new console{Style.RESET_ALL}' para criar sua primeira sessão.")
        print("")

        while True:
            if self.session_id:
                prompt_session_id = self.session_id[:8]
                prompt = f"{Fore.GREEN}{self.mode} ({prompt_session_id})> {Style.RESET_ALL}"
            else:
                prompt = f"{Fore.YELLOW}[Sem Sessão - modo: {self.mode}]> {Style.RESET_ALL}"

            try:
                user_input = input(prompt)
                user_input_lower = user_input.strip().lower()

                if user_input_lower in ["exit", "quit"]:
                    if self.session_id:
                        print(f"{Fore.CYAN}Encerrando sessão atual antes de sair...")
                        self.terminate_session()
                    print(f"{Fore.CYAN}Saindo do terminal...{Style.RESET_ALL}")
                    break
                elif user_input_lower == "help":
                    self.print_help()
                elif user_input_lower.startswith("new"):
                    # Suporta: new, new terminal, new console
                    parts = user_input_lower.split()
                    if len(parts) == 1:
                        # Apenas 'new' (mantém compatibilidade, padrão terminal)
                        mode = "terminal"
                    elif len(parts) == 2 and parts[1] in ["terminal", "console"]:
                        mode = parts[1]
                    else:
                        print(f"{Fore.RED}✗ Uso: new [terminal|console]{Style.RESET_ALL}")
                        continue
                    self.set_mode(mode)
                    self.create_session()
                elif user_input_lower == "list":
                    self.list_sessions()
                elif user_input_lower == "close":
                    self.terminate_session()
                elif user_input_lower in ["clear", "cls"]:
                    os.system('cls' if os.name == 'nt' else 'clear')
                elif user_input.strip():
                    self.execute_command(user_input)
                    print()
                # Não faz nada se a entrada for vazia

            except KeyboardInterrupt:
                print("\nInterrupção pelo teclado. Digite 'exit' ou 'quit' para sair.")
            except EOFError:
                print(f"\n{Fore.CYAN}Sinal de EOF recebido.{Style.RESET_ALL}")
                if self.session_id:
                    print(f"{Fore.CYAN}Encerrando sessão atual antes de sair...")
                    self.terminate_session()
                print(f"{Fore.CYAN}Saindo do terminal...{Style.RESET_ALL}")
                break
            except Exception as e:
                print(f"{Fore.RED}✗ Erro inesperado no loop do terminal: {str(e)}")

def main():
    """Função principal do cliente."""
    server_url_to_use = SERVER_URL
    if len(sys.argv) > 1:
        server_url_to_use = sys.argv[1]
        print(f"{Fore.YELLOW}Usando URL do servidor: {server_url_to_use}{Style.RESET_ALL}")

    client = TerminalClient(server_url_to_use)
    client.run_terminal()

if __name__ == "__main__":
    main()