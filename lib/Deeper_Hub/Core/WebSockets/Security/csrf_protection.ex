defmodule Deeper_Hub.Core.WebSockets.Security.CsrfProtection do
  @moduledoc """
  Proteção contra ataques CSRF (Cross-Site Request Forgery) para WebSockets.
  
  Este módulo implementa mecanismos para prevenir ataques CSRF em conexões WebSocket,
  verificando a origem das requisições e validando tokens anti-CSRF.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Verifica se a requisição WebSocket está protegida contra CSRF.
  
  ## Parâmetros
  
    - `req`: Objeto de requisição Cowboy
    - `state`: Estado da conexão WebSocket
  
  ## Retorno
  
    - `{:ok, state}` se a requisição for segura
    - `{:error, reason}` se a requisição for suspeita
  """
  def validate_request(req, state) do
    with {:ok, _origin} <- validate_origin(req),
         {:ok, _token} <- validate_csrf_token(req) do
      {:ok, state}
    else
      {:error, reason} ->
        Logger.warning("Possível ataque CSRF detectado", %{
          module: __MODULE__,
          reason: reason,
          ip: get_client_ip(req)
        })
        
        {:error, "Requisição inválida: #{reason}"}
    end
  end
  
  @doc """
  Gera um novo token CSRF para uma sessão.
  
  ## Parâmetros
  
    - `session_id`: ID da sessão para a qual gerar o token
  
  ## Retorno
  
    - `{:ok, token}` com o token gerado
  """
  def generate_token(session_id) do
    token = :crypto.strong_rand_bytes(32) |> Base.encode64()
    
    # Armazenar o token em um lugar seguro (ETS, Redis, etc.)
    # Implementação simplificada para exemplo
    store_token(session_id, token)
    
    {:ok, token}
  end
  
  @doc """
  Invalida um token CSRF existente.
  
  ## Parâmetros
  
    - `session_id`: ID da sessão
    - `token`: Token a ser invalidado
  
  ## Retorno
  
    - `:ok` se o token foi invalidado com sucesso
  """
  def invalidate_token(session_id, _token) do
    # Remover o token do armazenamento
    # Implementação simplificada para exemplo
    remove_token(session_id)
    
    :ok
  end
  
  # Valida a origem da requisição
  defp validate_origin(req) do
    origin = :cowboy_req.header("origin", req)
    referer = :cowboy_req.header("referer", req)
    
    allowed_origins = get_allowed_origins()
    
    cond do
      is_nil(origin) and is_nil(referer) ->
        # Requisições sem origem podem ser permitidas em alguns casos
        # Mas é recomendável registrar para análise
        Logger.info("Requisição sem origem ou referer", %{
          module: __MODULE__,
          ip: get_client_ip(req)
        })
        {:ok, nil}
        
      origin in allowed_origins ->
        {:ok, origin}
        
      String.starts_with?(to_string(referer || ""), allowed_origins) ->
        {:ok, referer}
        
      true ->
        {:error, "Origem não permitida"}
    end
  end
  
  # Valida o token CSRF
  defp validate_csrf_token(req) do
    token = :cowboy_req.header("x-csrf-token", req)
    session_id = get_session_id(req)
    
    if is_nil(token) do
      {:error, "Token CSRF ausente"}
    else
      # Verificar token contra armazenamento seguro
      case verify_token(session_id, token) do
        true -> {:ok, token}
        false -> {:error, "Token CSRF inválido"}
      end
    end
  end
  
  # Obtém origens permitidas da configuração
  defp get_allowed_origins do
    Application.get_env(:deeper_hub, :allowed_origins, ["http://localhost"])
  end
  
  # Obtém o ID da sessão da requisição
  defp get_session_id(req) do
    # Implementação simplificada para exemplo
    # Em um sistema real, isso seria extraído de um cookie ou cabeçalho
    :cowboy_req.header("x-session-id", req, "unknown")
  end
  
  # Obtém o IP do cliente
  defp get_client_ip(req) do
    {ip, _port} = :cowboy_req.peer(req)
    ip |> :inet.ntoa() |> to_string()
  end
  
  # Funções para gerenciamento de tokens (implementação simplificada)
  
  defp store_token(session_id, token) do
    # Em uma implementação real, isso usaria ETS, Redis ou banco de dados
    # Para este exemplo, usamos o Process Dictionary
    Process.put({:csrf_token, session_id}, token)
    :ok
  end
  
  defp verify_token(session_id, token) do
    stored_token = Process.get({:csrf_token, session_id})
    stored_token == token
  end
  
  defp remove_token(session_id) do
    Process.delete({:csrf_token, session_id})
    :ok
  end
end
