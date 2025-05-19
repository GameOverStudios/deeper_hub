defmodule DeeperHub.Accounts.Auth.Guardian do
  @moduledoc """
  Implementação do Guardian para autenticação JWT no DeeperHub.
  
  Este módulo é responsável por gerenciar tokens JWT para autenticação
  de usuários, incluindo geração, validação e revogação de tokens.
  """
  use Guardian, otp_app: :deeper_hub

  alias DeeperHub.Accounts.User
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Função chamada pelo Guardian para buscar o recurso associado a um token.
  Recebe o subject do token e retorna o recurso correspondente.
  """
  def subject_for_token(user, _claims) when is_map(user) do
    # Extrai o ID do usuário do mapa
    sub = to_string(user["id"] || user[:id])
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  @doc """
  Função chamada pelo Guardian para converter um subject de token em um recurso.
  Recebe o subject e retorna o recurso correspondente.
  """
  def resource_from_claims(%{"sub" => sub}) do
    case User.get(sub) do
      {:ok, user} -> {:ok, user}
      {:error, :not_found} -> {:error, :resource_not_found}
      {:error, reason} -> 
        Logger.error("Erro ao buscar usuário para claims: #{inspect(reason)}", module: __MODULE__)
        {:error, :resource_error}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end

  @doc """
  Gera um token de acesso para um usuário.
  """
  def generate_access_token(user) do
    encode_and_sign(user, %{}, token_options(:access))
  end

  @doc """
  Gera um token de atualização (refresh token) para um usuário.
  """
  def generate_refresh_token(user) do
    encode_and_sign(user, %{}, token_options(:refresh))
  end

  @doc """
  Verifica se um token é válido.
  
  Além da verificação padrão do Guardian, também verifica se o token
  está na blacklist de tokens revogados.
  
  ## Parâmetros
    * `token` - Token JWT a ser verificado
  
  ## Retorno
    * `{:ok, claims}` - Se o token for válido
    * `{:error, reason}` - Se o token for inválido ou estiver na blacklist
  """
  def verify_token(token) do
    with {:ok, claims} <- decode_and_verify(token),
         jti <- Map.get(claims, "jti"),
         {:ok, false} <- DeeperHub.Accounts.Auth.TokenBlacklist.is_blacklisted?(jti) do
      {:ok, claims}
    else
      {:ok, true} -> 
        # Token está na blacklist
        Logger.warn("Tentativa de uso de token revogado", module: __MODULE__)
        {:error, :token_revoked}
      error -> error
    end
  end

  @doc """
  Revoga um token.
  """
  def revoke_token(token) do
    revoke(token)
  end

  # Configurações para diferentes tipos de tokens
  defp token_options(:access) do
    # Obtém configurações do config ou usa valores padrão
    ttl = get_token_ttl("access", {1, :hour})
    
    [
      token_type: "access",
      ttl: ttl,
      # Adiciona JTI (JWT ID) para rastreamento e revogação
      jti: generate_jti(),
      # Adiciona metadados úteis para auditoria
      iat: DateTime.utc_now() |> DateTime.to_unix()
    ]
  end

  defp token_options(:refresh) do
    # Obtém configurações do config ou usa valores padrão
    ttl = get_token_ttl("refresh", {30, :days})
    
    [
      token_type: "refresh",
      ttl: ttl,
      # Adiciona JTI (JWT ID) para rastreamento e revogação
      jti: generate_jti(),
      # Adiciona metadados úteis para auditoria
      iat: DateTime.utc_now() |> DateTime.to_unix()
    ]
  end
  
  # Obtém a configuração TTL para um tipo específico de token
  defp get_token_ttl(type, default) do
    case Application.get_env(:deeper_hub, __MODULE__)[:token_ttl] do
      %{^type => ttl} when is_tuple(ttl) -> ttl
      _ -> default
    end
  end
  
  # Gera um identificador único para o token (JWT ID)
  defp generate_jti do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
