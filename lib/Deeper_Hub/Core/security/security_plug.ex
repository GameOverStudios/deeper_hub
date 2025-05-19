defmodule DeeperHub.Core.Security.SecurityPlug do
  @moduledoc """
  Plug para aplicar medidas de segurança às requisições HTTP.

  Este plug integra o PlugAttack e outras medidas de segurança
  ao pipeline de processamento de requisições HTTP, incluindo:
  
  - Proteção contra ataques de força bruta
  - Limitação de taxa de requisições
  - Bloqueio de IPs maliciosos
  - Headers de segurança (CSP, X-XSS-Protection, etc.)
  """

  import Plug.Conn

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger

  @doc """
  Inicializa o plug com as opções fornecidas.
  
  ## Parâmetros
  
  - `opts` - Opções de configuração para o plug
  
  ## Retorno
  
  - As opções processadas
  """
  @spec init(Keyword.t()) :: Keyword.t()
  def init(opts) do
    opts
  end

  @doc """
  Aplica as medidas de segurança à conexão.

  ## Parâmetros

  - `conn` - A conexão Plug
  - `_opts` - Opções do plug (não utilizadas atualmente)

  ## Retorno

  - A conexão Plug, possivelmente modificada
  """
  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, _opts) do
    conn
    |> apply_attack_protection()
    |> apply_security_headers()
  end

  # Aplica a proteção do PlugAttack
  defp apply_attack_protection(conn) do
    # Inicializa o armazenamento ETS se necessário
    DeeperHub.Core.Security.Attack.storage_setup()
    
    # Aplica as regras de proteção
    DeeperHub.Core.Security.Attack.call(conn, [])
  end

  # Aplica headers de segurança recomendados
  defp apply_security_headers(conn) do
    conn
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-frame-options", "SAMEORIGIN")
    |> put_resp_header("x-xss-protection", "1; mode=block")
    |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    |> put_resp_header("x-permitted-cross-domain-policies", "none")
    |> put_resp_header("x-download-options", "noopen")
    |> put_content_security_policy()
  end

  # Aplica a política de segurança de conteúdo (CSP)
  defp put_content_security_policy(conn) do
    # Obtém o host atual para configurar a CSP
    host = get_host(conn)
    
    # Obtém o ambiente de execução
    env = Application.get_env(:deeper_hub, :environment, :dev)
    
    # Define a política CSP com base no ambiente
    csp = case env do
      :prod ->
        # Política mais restritiva para produção
        [
          "default-src 'self'",
          "script-src 'self'",
          "style-src 'self'",
          "img-src 'self' data:",
          "font-src 'self' data:",
          "connect-src 'self' wss://#{host} https://#{host}",
          "frame-src 'none'",
          "base-uri 'self'",
          "form-action 'self'"
        ] |> Enum.join("; ")
        
      _ ->
        # Política mais permissiva para desenvolvimento
        [
          "default-src 'self'",
          "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
          "style-src 'self' 'unsafe-inline'",
          "img-src 'self' data: https:",
          "font-src 'self' data:",
          "connect-src 'self' wss://#{host} https://#{host} ws://#{host}",
          "frame-src 'self'",
          "base-uri 'self'",
          "form-action 'self'"
        ] |> Enum.join("; ")
    end

    Logger.debug("Aplicando CSP para host: #{host}", module: __MODULE__, environment: env)
    put_resp_header(conn, "content-security-policy", csp)
  end

  # Obtém o host da requisição
  defp get_host(conn) do
    conn
    |> get_req_header("host")
    |> List.first()
    |> case do
      nil -> 
        # Fallback para o host configurado ou localhost
        Application.get_env(:deeper_hub, :host, "localhost")
      host -> 
        # Remove a porta, se presente
        String.split(host, ":") |> hd()
    end
  end
end
