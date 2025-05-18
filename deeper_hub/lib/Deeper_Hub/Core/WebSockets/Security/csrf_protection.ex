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
    token = get_header(req, "x-csrf-token")
    session_id = get_session_id(req)
    origin = get_header(req, "origin")
    referer = get_header(req, "referer")

    # Verificação do token CSRF primeiro
    token_valid = not is_nil(token) and verify_token(session_id, token)

    cond do
      # Caso 1: Se não tem origem nem referer, mas tem token válido
      is_nil(origin) and is_nil(referer) and token_valid ->
        Logger.info("Requisição sem origem ou referer, mas com token CSRF válido", %{
          module: __MODULE__,
          ip: get_client_ip(req)
        })
        {:ok, state}

      # Caso 2: Se não tem token válido
      not token_valid ->
        reason = if is_nil(token), do: "Token CSRF ausente", else: "Token CSRF inválido"
        Logger.warn("Possível ataque CSRF detectado", %{
          module: __MODULE__,
          reason: reason,
          ip: get_client_ip(req)
        })
        {:error, "Requisição inválida: #{reason}"}

      # Caso 3: Se tem token válido, verifica a origem
      true ->
        case validate_origin(req) do
          {:ok, _origin} ->
            {:ok, state}
          {:error, reason} ->
            Logger.warn("Possível ataque CSRF detectado", %{
              module: __MODULE__,
              reason: reason,
              ip: get_client_ip(req)
            })
            {:error, "Requisição inválida: #{reason}"}
        end
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
    origin = get_header(req, "origin")
    referer = get_header(req, "referer")
    token = get_header(req, "x-csrf-token")
    session_id = get_session_id(req)

    allowed_origins = get_allowed_origins()

    cond do
      # Caso 1: Se não tem origem nem referer, mas tem token válido
      is_nil(origin) and is_nil(referer) and not is_nil(token) and verify_token(session_id, token) ->
        {:ok, nil}

      # Caso 2: Se tem origem e está na lista de permitidas
      not is_nil(origin) and origin in allowed_origins ->
        {:ok, origin}

      # Caso 3: Se tem referer e começa com uma origem permitida
      not is_nil(referer) and Enum.any?(allowed_origins, fn allowed ->
        String.starts_with?(to_string(referer), allowed)
      end) ->
        {:ok, referer}

      # Caso 4: Se não atende nenhuma condição acima
      true ->
        {:error, "Origem não permitida"}
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
    get_header(req, "x-session-id", "unknown")
  end

  # Obtém o IP do cliente
  defp get_client_ip(req) do
    try do
      # Tenta usar a função peer diretamente para testes
      if is_function(req[:peer]) do
        {ip, _port} = req.peer.()
        ip |> :inet.ntoa() |> to_string()
      else
        # Comportamento padrão para requisições reais
        {ip, _port} = :cowboy_req.peer(req)
        ip |> :inet.ntoa() |> to_string()
      end
    rescue
      # Fallback para testes ou casos onde peer não está disponível
      _ -> "127.0.0.1"
    end
  end

  # Função auxiliar para obter cabeçalhos de forma compatível com testes e produção
  defp get_header(req, header, default \\ nil) do
    cond do
      # Caso 1: Requisição de teste com cabeçalhos em um mapa
      is_map(req) and is_map(req[:headers]) ->
        Map.get(req.headers, header, default)

      # Caso 2: Requisição real do Cowboy
      true ->
        :cowboy_req.header(header, req, default)
    end
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
