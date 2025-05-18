defmodule Deeper_Hub.Core.WebSockets.Auth.JwtService do
  @moduledoc """
  Serviço para gerenciamento de tokens JWT para autenticação WebSocket.

  Este módulo fornece funções para geração e validação de tokens JWT,
  utilizando a biblioteca Joken para autenticação de conexões WebSocket.
  """

  # Importa as funções necessárias da biblioteca Joken
  use Joken.Config

  alias Deeper_Hub.Core.WebSockets.Auth.TokenBlacklist
  alias Deeper_Hub.Core.EventBus
  alias Deeper_Hub.Core.Logger

  # Configuração padrão de claims
  @impl true
  def token_config do
    default_claims(
      iss: "deeper_hub",
      aud: "deeper_hub_websocket",
      default_exp: 60 * 60  # 1 hora
    )
    |> add_claim("typ", fn -> "access" end, &(&1 == "access"))
  end

  @doc """
  Gera um token de acesso para o usuário especificado.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `extra_claims` - Claims adicionais (opcional)

  ## Retorno
    * `{:ok, token, claims}` - Token gerado com sucesso
    * `{:error, reason}` - Erro ao gerar token
  """
  def generate_access_token(user_id, extra_claims \\ %{}) do
    # Configuração para token de acesso (1 hora de duração)
    access_config =
      default_claims(
        iss: "deeper_hub",
        aud: "deeper_hub_websocket",
        default_exp: 60 * 60  # 1 hora
      )
      |> add_claim("typ", fn -> "access" end, &(&1 == "access"))

    # Adiciona claims específicas do usuário
    extra_claims = Map.merge(%{"user_id" => user_id, "typ" => "access"}, extra_claims)

    # Gera o token com as claims e configurações
    result = Joken.generate_and_sign(access_config, extra_claims, signer())

    case result do
      {:ok, token, claims} ->
        Logger.info("Token de acesso gerado para usuário", %{module: __MODULE__, user_id: user_id})
        EventBus.publish(:token_generated, %{user_id: user_id, token_type: "access"})
        {:ok, token, claims}

      {:error, reason} ->
        Logger.error("Erro ao gerar token de acesso", %{module: __MODULE__, error: reason})
        {:error, reason}
    end
  end

  @doc """
  Gera um token de refresh para o usuário especificado.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `extra_claims` - Claims adicionais (opcional)

  ## Retorno
    * `{:ok, token, claims}` - Token gerado com sucesso
    * `{:error, reason}` - Erro ao gerar token
  """
  def generate_refresh_token(user_id, extra_claims \\ %{}) do
    # Configuração para token de refresh (7 dias de duração)
    refresh_config =
      default_claims(
        iss: "deeper_hub",
        aud: "deeper_hub_websocket",
        default_exp: 7 * 24 * 60 * 60  # 7 dias
      )
      |> add_claim("typ", fn -> "refresh" end, &(&1 == "refresh"))

    # Adiciona claims específicas do usuário
    extra_claims = Map.merge(%{"user_id" => user_id, "typ" => "refresh"}, extra_claims)

    # Gera o token com as claims e configurações
    result = Joken.generate_and_sign(refresh_config, extra_claims, signer())

    case result do
      {:ok, token, claims} ->
        Logger.info("Token de refresh gerado para usuário", %{module: __MODULE__, user_id: user_id})
        EventBus.publish(:token_generated, %{user_id: user_id, token_type: "refresh"})
        {:ok, token, claims}

      {:error, reason} ->
        Logger.error("Erro ao gerar token de refresh", %{module: __MODULE__, error: reason})
        {:error, reason}
    end
  end

  @doc """
  Verifica e valida um token JWT.

  ## Parâmetros
    * `token` - Token JWT a ser validado

  ## Retorno
    * `{:ok, claims}` - Token válido com claims
    * `{:error, reason}` - Token inválido
  """
  def verify_token(token) do
    with {:ok, claims} <- validate_token(token),
         false <- TokenBlacklist.is_blacklisted?(token) do
      Logger.debug("Token verificado com sucesso", %{module: __MODULE__, claims: claims})
      {:ok, claims}
    else
      true ->
        Logger.warning("Tentativa de uso de token na blacklist", %{module: __MODULE__})
        {:error, :token_blacklisted}

      {:error, reason} = error ->
        Logger.warning("Falha na validação de token", %{module: __MODULE__, error: reason})
        error
    end
  end

  # Função auxiliar para verificar e validar tokens
  defp validate_token(token) do
    case Joken.verify(token, signer()) do
      {:ok, %{"exp" => exp} = claims} ->
        # Verifica se o token expirou
        now = DateTime.utc_now() |> DateTime.to_unix()
        if exp > now do
          {:ok, claims}
        else
          {:error, :token_expired}
        end

      error -> error
    end
  end

  @doc """
  Gera um par de tokens (acesso e refresh) para o usuário.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `extra_claims` - Claims adicionais (opcional)

  ## Retorno
    * `{:ok, access_token, refresh_token, claims}` - Tokens gerados com sucesso
    * `{:error, reason}` - Erro ao gerar tokens
  """
  def generate_token_pair(user_id, extra_claims \\ %{}) do
    with {:ok, access_token, access_claims} <- generate_access_token(user_id, extra_claims),
         {:ok, refresh_token, refresh_claims} <- generate_refresh_token(user_id, extra_claims) do
      {:ok, access_token, refresh_token, %{access: access_claims, refresh: refresh_claims}}
    end
  end

  @doc """
  Revoga um token adicionando-o à blacklist.

  ## Parâmetros
    * `token` - Token a ser revogado

  ## Retorno
    * `:ok` - Token revogado com sucesso
    * `{:error, reason}` - Erro ao revogar token
  """
  def revoke_token(token) do
    case validate_token(token) do
      {:ok, claims} ->
        exp = Map.get(claims, "exp")
        TokenBlacklist.add(token, exp)
        Logger.info("Token revogado", %{module: __MODULE__, user_id: Map.get(claims, "user_id")})
        EventBus.publish(:token_revoked, %{user_id: Map.get(claims, "user_id")})
        :ok

      error ->
        Logger.warning("Tentativa de revogar token inválido", %{module: __MODULE__, error: error})
        error
    end
  end

  # Função auxiliar para obter o signer padrão configurado
  defp signer do
    Joken.Signer.create("HS256", Application.fetch_env!(:joken, :default_signer)[:key_octet])
  end
end
