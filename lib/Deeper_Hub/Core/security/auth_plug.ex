defmodule DeeperHub.Core.Security.AuthPlug do
  @moduledoc """
  Plug para autenticação de requisições HTTP.

  Este plug verifica se a requisição possui um token JWT válido
  no cabeçalho de autorização e adiciona as informações do usuário
  ao contexto da requisição.
  """

  import Plug.Conn

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.Auth.Guardian

  @doc """
  Inicializa o plug com as opções fornecidas.

  ## Opções

  - `:required` - Se `true`, a autenticação é obrigatória (padrão: `true`)
  - `:resource_type` - Tipo de recurso a ser verificado (padrão: `"access"`)
  """
  def init(opts) do
    %{
      required: Keyword.get(opts, :required, true),
      resource_type: Keyword.get(opts, :resource_type, "access")
    }
  end

  @doc """
  Verifica se a requisição possui um token JWT válido.

  ## Parâmetros

  - `conn` - A conexão Plug
  - `opts` - Opções do plug

  ## Retorno

  - A conexão Plug, possivelmente modificada
  """
  def call(conn, opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Guardian.decode_and_verify(token, %{"typ" => opts.resource_type}),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      # Adiciona as informações do usuário ao contexto da requisição
      conn
      |> assign(:current_user, user)
      |> assign(:current_token, token)
      |> assign(:token_claims, claims)
    else
      error ->
        # Registra a tentativa de autenticação malsucedida
        log_failed_auth_attempt(conn, error, opts)
        
        if opts.required do
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(401, Jason.encode!(%{
            error: "Não autorizado",
            code: "unauthorized"
          }))
          |> halt()
        else
          conn
        end
    end
  end
  
  # Registra tentativas de autenticação malsucedidas
  defp log_failed_auth_attempt(conn, error, _opts) do
    # Obtém informações da requisição
    ip = get_client_ip(conn)
    path = conn.request_path
    method = conn.method
    user_agent = get_user_agent(conn)
    
    # Determina o motivo da falha
    reason = case error do
      [] -> "token_ausente"
      {:error, :invalid_token} -> "token_invalido"
      {:error, :token_expired} -> "token_expirado"
      {:error, :invalid_signature} -> "assinatura_invalida"
      {:error, :resource_not_found} -> "usuario_nao_encontrado"
      _ -> "erro_desconhecido"
    end
    
    # Registra no log
    Logger.warn("Tentativa de autenticação malsucedida: #{reason}", 
      module: __MODULE__, 
      ip: ip,
      path: path,
      method: method,
      user_agent: user_agent
    )
    
    # Registra no log de eventos de segurança, se disponível
    if Code.ensure_loaded?(DeeperHub.Accounts.ActivityLog) do
      # Extrai informações adicionais da requisição
      details = %{
        ip: ip,
        path: path,
        method: method,
        user_agent: user_agent,
        timestamp: DateTime.utc_now(),
        failure_reason: reason
      }
      
      # Registra a atividade de segurança
      DeeperHub.Accounts.ActivityLog.log_security_event(
        "auth_failure",
        nil,  # user_id (desconhecido neste ponto)
        details
      )
    end
  rescue
    # Garante que falhas no log não afetem o fluxo principal
    _ -> :ok
  end
  
  # Obtém o IP do cliente
  defp get_client_ip(conn) do
    # Tenta obter o IP do header X-Forwarded-For primeiro (para casos com proxy)
    forwarded_for = get_req_header(conn, "x-forwarded-for")
    
    cond do
      # Se tiver X-Forwarded-For, usa o primeiro IP (mais à esquerda)
      length(forwarded_for) > 0 ->
        forwarded_for
        |> hd()
        |> String.split(",")
        |> hd()
        |> String.trim()
        
      # Caso contrário, usa o IP remoto da conexão
      true ->
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
    end
  end
  
  # Obtém o User-Agent da requisição
  defp get_user_agent(conn) do
    case get_req_header(conn, "user-agent") do
      [user_agent | _] -> user_agent
      _ -> "desconhecido"
    end
  end
end
