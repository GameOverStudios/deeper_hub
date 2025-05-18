defmodule Deeper_Hub.Core.WebSockets.Security.SecuritySupervisor do
  @moduledoc """
  Supervisor para os serviços de segurança WebSocket.
  
  Este módulo supervisiona todos os processos relacionados à segurança WebSocket,
  garantindo que eles sejam iniciados e reiniciados adequadamente.
  """
  
  use Supervisor
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Security.SecurityMiddleware
  
  @doc """
  Inicia o supervisor de segurança.
  
  ## Parâmetros
  
    - `opts`: Opções para o supervisor
  
  ## Retorno
  
    - `{:ok, pid}` se o supervisor for iniciado com sucesso
    - `{:error, reason}` se ocorrer um erro
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Inicializa o supervisor e seus filhos.
  
  ## Parâmetros
  
    - `opts`: Opções para o supervisor
  
  ## Retorno
  
    - `{:ok, {supervisor_flags, child_specs}}` configuração do supervisor
  """
  @impl true
  def init(_opts) do
    Logger.info("Iniciando supervisor de segurança WebSocket", %{module: __MODULE__})
    
    # Inicializa o middleware de segurança
    SecurityMiddleware.init()
    
    # Define os processos filhos
    children = [
      # Adicione aqui processos de longa duração relacionados à segurança
      # Por exemplo, processos de monitoramento, limpeza periódica, etc.
      # {Deeper_Hub.Core.WebSockets.Security.SecurityMonitor, []},
    ]
    
    # Estratégia de supervisão: reinicia apenas o processo que falhou
    Supervisor.init(children, strategy: :one_for_one)
  end
  
  @doc """
  Aplica todas as verificações de segurança a uma requisição WebSocket.
  
  ## Parâmetros
  
    - `req`: Objeto de requisição Cowboy
    - `state`: Estado da conexão WebSocket
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, state}` se a requisição for segura
    - `{:error, reason}` se a requisição for bloqueada
  """
  def check_request(req, state, opts \\ []) do
    SecurityMiddleware.check_request(req, state, opts)
  end
  
  @doc """
  Aplica todas as verificações de segurança a uma mensagem WebSocket.
  
  ## Parâmetros
  
    - `message`: Mensagem a ser verificada
    - `state`: Estado da conexão WebSocket
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, sanitized_message}` se a mensagem for segura
    - `{:error, reason}` se a mensagem contiver conteúdo malicioso
  """
  def check_message(message, state, opts \\ []) do
    SecurityMiddleware.check_message(message, state, opts)
  end
  
  @doc """
  Registra uma tentativa de autenticação e verifica proteção contra força bruta.
  
  ## Parâmetros
  
    - `identifier`: Identificador para a tentativa (ex: username, IP)
    - `success`: Indica se a tentativa foi bem-sucedida
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, attempts_left}` se ainda houver tentativas disponíveis
    - `{:error, :account_locked, retry_after}` se a conta estiver bloqueada
  """
  def check_authentication_attempt(identifier, success, opts \\ []) do
    SecurityMiddleware.check_authentication_attempt(identifier, success, opts)
  end
  
  @doc """
  Verifica se uma tentativa de login é permitida.
  
  ## Parâmetros
  
    - `req`: Objeto de requisição Cowboy
    - `state`: Estado da conexão WebSocket
    - `username`: Nome de usuário
    - `password`: Senha (não utilizada diretamente, apenas passada adiante)
  
  ## Retorno
  
    - `{:ok, state}` se a tentativa for permitida
    - `{:error, reason}` se a tentativa for bloqueada
  """
  def check_login_attempt(req, state, username, password) do
    SecurityMiddleware.check_login_attempt(req, state, username, password)
  end
  
  @doc """
  Registra o resultado de uma tentativa de login.
  
  ## Parâmetros
  
    - `req`: Objeto de requisição Cowboy
    - `state`: Estado da conexão WebSocket
    - `username`: Nome de usuário
    - `auth_result`: Resultado da autenticação ({:ok, user} ou {:error, reason})
  
  ## Retorno
  
    - `{:ok, state}` se o registro for bem-sucedido
    - `{:error, reason}` se ocorrer um erro
  """
  def track_login_result(req, state, username, auth_result) do
    SecurityMiddleware.track_login_result(req, state, username, auth_result)
  end
end
