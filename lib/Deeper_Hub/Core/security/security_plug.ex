defmodule DeeperHub.Core.Security.SecurityPlug do
  @moduledoc """
  Plug para aplicar medidas de segurança às requisições HTTP.

  Este plug integra o Plug.Attack e outras medidas de segurança
  ao pipeline de processamento de requisições HTTP.
  """

  import Plug.Conn

  require DeeperHub.Core.Logger

  @doc """
  Inicializa o plug com as opções fornecidas.
  """
  def init(opts), do: opts

  @doc """
  Aplica as medidas de segurança à conexão.

  ## Parâmetros

  - `conn` - A conexão Plug
  - `_opts` - Opções do plug (não utilizadas atualmente)

  ## Retorno

  - A conexão Plug, possivelmente modificada
  """
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
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("x-xss-protection", "1; mode=block")
    |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    |> put_content_security_policy()
  end

  # Aplica a política de segurança de conteúdo (CSP)
  defp put_content_security_policy(conn) do
    # Obtém o host atual para configurar a CSP
    host = get_host(conn)

    # Define a política CSP
    csp = [
      "default-src 'self'",
      "connect-src 'self' wss://#{host} ws://#{host}",
      "img-src 'self' data:",
      "style-src 'self' 'unsafe-inline'",
      "script-src 'self'",
      "font-src 'self'",
      "base-uri 'self'",
      "form-action 'self'"
    ] |> Enum.join("; ")

    put_resp_header(conn, "content-security-policy", csp)
  end

  # Obtém o host da requisição
  defp get_host(conn) do
    conn
    |> get_req_header("host")
    |> List.first()
    |> case do
      nil -> "localhost"
      host -> host
    end
  end
end
