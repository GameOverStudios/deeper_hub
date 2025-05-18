defmodule Deeper_Hub.Core.WebSockets.Security.SecurityMiddleware do
  @moduledoc """
  Middleware de segurança para WebSockets.
  
  Este módulo integra todas as proteções de segurança para WebSockets,
  fornecendo uma interface unificada para aplicar múltiplas camadas de segurança.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Security.CsrfProtection
  alias Deeper_Hub.Core.WebSockets.Security.XssProtection
  alias Deeper_Hub.Core.WebSockets.Security.SqlInjectionProtection
  alias Deeper_Hub.Core.WebSockets.Security.PathTraversalProtection
  alias Deeper_Hub.Core.WebSockets.Security.DdosProtection
  alias Deeper_Hub.Core.WebSockets.Security.BruteForceProtection
  
  @doc """
  Inicializa o middleware de segurança.
  
  Deve ser chamado durante a inicialização da aplicação.
  
  ## Retorno
  
    - `:ok` se a inicialização for bem-sucedida
  """
  def init do
    # Inicializa todos os módulos de proteção
    DdosProtection.init()
    BruteForceProtection.init()
    
    :ok
  end
  
  @doc """
  Verifica a segurança de uma requisição WebSocket.
  
  ## Parâmetros
  
    - `req`: Objeto de requisição Cowboy
    - `state`: Estado da conexão WebSocket
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, state}` se a requisição for segura
    - `{:error, reason}` se a requisição for bloqueada por alguma proteção
  """
  def check_request(req, state, opts \\ []) do
    ip = get_client_ip(req)
    
    with {:ok, _} <- check_ddos(ip, opts),
         {:ok, state} <- check_csrf(req, state, opts) do
      {:ok, state}
    else
      {:error, reason} ->
        Logger.warning("Requisição WebSocket bloqueada", %{
          module: __MODULE__,
          reason: reason,
          ip: ip
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Verifica a segurança de uma mensagem WebSocket.
  
  ## Parâmetros
  
    - `message`: Mensagem a ser verificada
    - `state`: Estado da conexão WebSocket
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, sanitized_message}` se a mensagem for segura
    - `{:error, reason}` se a mensagem contiver conteúdo malicioso
  """
  def check_message(message, state, opts \\ []) do
    with {:ok, sanitized} <- check_xss(message, opts),
         {:ok, sanitized} <- check_sql_injection(sanitized, opts),
         {:ok, sanitized} <- check_path_traversal(sanitized, opts) do
      {:ok, sanitized}
    else
      {:error, reason} ->
        Logger.warning("Mensagem WebSocket bloqueada", %{
          module: __MODULE__,
          reason: reason,
          user_id: state[:user_id]
        })
        
        {:error, reason}
    end
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
    BruteForceProtection.record_attempt(identifier, success, opts)
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
  def check_login_attempt(req, state, username, _password) do
    ip = get_client_ip(req)
    
    case BruteForceProtection.check_login_allowed(ip, username) do
      {:ok, _attempts_left} ->
        # Verifica também o status da conta
        account_id = state[:account_id]
        if account_id do
          case BruteForceProtection.check_account_status(account_id) do
            {:ok, _} ->
              {:ok, Map.put(state, :login_checked, true)}
              
            {:error, reason, _retry_after} ->
              # Formato esperado pelos testes
              {:error, reason}
          end
        else
          {:ok, Map.put(state, :login_checked, true)}
        end
        
      {:error, reason, _retry_after} ->
        # Formato esperado pelos testes
        {:error, reason}
    end
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
    ip = get_client_ip(req)
    success = match?({:ok, _}, auth_result)
    
    # Registra a tentativa
    BruteForceProtection.track_login_attempt(ip, username, success)
    
    if success do
      user_data = elem(auth_result, 1)
      {:ok, Map.put(state, :login_tracked, true) |> Map.put(:user_data, user_data)}
    else
      {:error, elem(auth_result, 1)}
    end
  end
  
  # Funções privadas para verificações específicas
  
  defp check_ddos(ip, opts) do
    DdosProtection.check_rate_limit(ip, opts)
  end
  
  defp check_csrf(req, state, _opts) do
    CsrfProtection.validate_request(req, state)
  end
  
  defp check_xss(message, _opts) when is_map(message) do
    XssProtection.sanitize_message(message)
  end
  
  defp check_xss(message, _opts) do
    {:ok, message}
  end
  
  defp check_sql_injection(message, _opts) when is_map(message) do
    # Verifica todos os valores de string na mensagem
    Enum.reduce_while(message, {:ok, message}, fn {_key, value}, acc ->
      if is_binary(value) do
        case SqlInjectionProtection.check_for_sql_injection(value) do
          {:ok, _} -> {:cont, acc}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      else
        {:cont, acc}
      end
    end)
  end
  
  defp check_sql_injection(message, _opts) do
    {:ok, message}
  end
  
  defp check_path_traversal(message, _opts) when is_map(message) do
    # Verifica todos os valores de string na mensagem
    Enum.reduce_while(message, {:ok, message}, fn {_key, value}, acc ->
      if is_binary(value) do
        case PathTraversalProtection.check_path(value) do
          {:ok, _} -> {:cont, acc}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      else
        {:cont, acc}
      end
    end)
  end
  
  defp check_path_traversal(message, _opts) do
    {:ok, message}
  end
  
  # Funções auxiliares
  
  defp get_client_ip(req) do
    {ip, _port} = :cowboy_req.peer(req)
    ip |> :inet.ntoa() |> to_string()
  end
  
  # Estas funções foram removidas por não serem utilizadas
  # O código agora verifica todas as strings em mensagens, não apenas campos específicos
end
