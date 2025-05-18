defmodule Deeper_Hub.Core.Auth.AuthService do
  @moduledoc """
  Serviço para autenticação de usuários via WebSocket.

  Este módulo fornece funções para autenticação, validação de credenciais e
  gerenciamento de sessões de usuários conectados via WebSocket.
  """

  alias Deeper_Hub.Core.Auth.JwtService
  alias Deeper_Hub.Core.Data.DBConnection.Repositories.UserRepository
  alias Deeper_Hub.Core.EventBus

  require Logger

  @doc """
  Autentica um usuário com base em suas credenciais.

  ## Parâmetros
    * `username` - Nome de usuário
    * `password` - Senha do usuário

  ## Retorno
    * `{:ok, user, tokens}` - Autenticação bem-sucedida com dados do usuário e tokens
    * `{:error, reason}` - Erro na autenticação
  """
  def authenticate(username, password) do
    with {:ok, user} <- UserRepository.get_by_username(username),
         true <- verify_password(user, password) do

      user_id = Map.get(user, "id")

      case JwtService.generate_token_pair(user_id) do
        {:ok, access_token, refresh_token, claims} ->
          Logger.info("[#{__MODULE__}] Usuário autenticado com sucesso user_id=#{user_id}")
          EventBus.publish(:user_authenticated, %{user_id: user_id})

          tokens = %{
            access_token: access_token,
            refresh_token: refresh_token,
            expires_in: Map.get(claims.access, "exp") - Map.get(claims.access, "iat")
          }

          {:ok, user, tokens}

        error ->
          Logger.error("[#{__MODULE__}] Erro ao gerar tokens: #{inspect(error)}")
          {:error, :token_generation_failed}
      end
    else
      {:error, :not_found} ->
        Logger.warning("[#{__MODULE__}] Tentativa de login com usuário inexistente username=#{username}")
        # Retornamos o mesmo erro para não revelar se o usuário existe ou não
        {:error, :invalid_credentials}

      false ->
        Logger.warning("[#{__MODULE__}] Tentativa de login com senha incorreta username=#{username}")
        {:error, :invalid_credentials}

      error ->
        Logger.error("[#{__MODULE__}] Erro ao autenticar usuário: #{inspect(error)}")
        {:error, :authentication_failed}
    end
  end

  @doc """
  Autentica um usuário apenas com o ID para uso em WebSockets.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * `{:ok, user}` - Autenticação bem-sucedida com dados do usuário
    * `{:error, reason}` - Erro na autenticação
  """
  def authenticate_by_id(user_id) do
    case UserRepository.get_by_id(user_id) do
      {:ok, user} ->
        Logger.info("[#{__MODULE__}] Usuário autenticado por ID user_id=#{user_id}")
        EventBus.publish(:user_authenticated, %{user_id: user_id})
        {:ok, user}

      {:error, :not_found} ->
        Logger.warning("[#{__MODULE__}] Tentativa de autenticação com ID de usuário inexistente user_id=#{user_id}")
        {:error, :user_not_found}

      error ->
        Logger.error("[#{__MODULE__}] Erro ao autenticar usuário por ID: #{inspect(error)}")
        {:error, :authentication_failed}
    end
  end

  @doc """
  Verifica um token JWT e retorna os dados do usuário.

  ## Parâmetros
    * `token` - Token JWT

  ## Retorno
    * `{:ok, user}` - Token válido com dados do usuário
    * `{:error, reason}` - Token inválido
  """
  def verify_token_and_get_user(token) do
    with {:ok, claims} <- JwtService.verify_token(token),
         user_id = Map.get(claims, "user_id"),
         {:ok, user} <- UserRepository.get_by_id(user_id) do

      Logger.info("[#{__MODULE__}] Token verificado com sucesso user_id=#{user_id}")
      {:ok, user}
    else
      {:error, :token_blacklisted} ->
        Logger.warning("[#{__MODULE__}] Tentativa de uso de token revogado")
        {:error, :token_blacklisted}

      {:error, :not_found} ->
        Logger.warning("[#{__MODULE__}] Token válido mas usuário não encontrado")
        {:error, :user_not_found}

      error ->
        Logger.error("[#{__MODULE__}] Erro ao verificar token: #{inspect(error)}")
        {:error, :invalid_token}
    end
  end

  @doc """
  Atualiza tokens usando um token de refresh.

  ## Parâmetros
    * `refresh_token` - Token de refresh

  ## Retorno
    * `{:ok, tokens}` - Novos tokens gerados com sucesso
    * `{:error, reason}` - Erro ao atualizar tokens
  """
  def refresh_tokens(refresh_token) do
    with {:ok, claims} <- JwtService.verify_token(refresh_token),
         "refresh" <- Map.get(claims, "typ"),
         user_id = Map.get(claims, "user_id"),
         {:ok, access_token, refresh_token, claims} <- JwtService.generate_token_pair(user_id) do

      Logger.info("[#{__MODULE__}] Tokens atualizados com sucesso user_id=#{user_id}")

      tokens = %{
        access_token: access_token,
        refresh_token: refresh_token,
        expires_in: Map.get(claims.access, "exp") - Map.get(claims.access, "iat")
      }

      {:ok, tokens}
    else
      "access" ->
        Logger.warning("[#{__MODULE__}] Tentativa de refresh com token de acesso")
        {:error, :invalid_token_type}

      error ->
        Logger.error("[#{__MODULE__}] Erro ao atualizar tokens: #{inspect(error)}")
        {:error, :invalid_refresh_token}
    end
  end

  @doc """
  Revoga todos os tokens de um usuário (logout).

  ## Parâmetros
    * `access_token` - Token de acesso atual
    * `refresh_token` - Token de refresh atual

  ## Retorno
    * `:ok` - Logout realizado com sucesso
    * `{:error, reason}` - Erro ao realizar logout
  """
  def logout(access_token, refresh_token) do
    # Revoga ambos os tokens
    JwtService.revoke_token(access_token)
    JwtService.revoke_token(refresh_token)

    case JwtService.verify_token(access_token) do
      {:ok, claims} ->
        user_id = Map.get(claims, "user_id")
        Logger.info("[#{__MODULE__}] Logout realizado com sucesso user_id=#{user_id}")
        EventBus.publish(:user_logged_out, %{user_id: user_id})
        :ok

      _ ->
        Logger.warning("[#{__MODULE__}] Logout com token inválido")
        {:error, :invalid_token}
    end
  end

  # Funções privadas

  defp verify_password(user, password) do
    stored_password = Map.get(user, "password_hash")

    # Em um ambiente de produção, usaríamos uma função de hash adequada
    # como Argon2, Bcrypt ou PBKDF2. Para simplificar, estamos comparando
    # diretamente, mas isso deve ser substituído por uma verificação segura.
    # Exemplo: Argon2.verify_pass(password, stored_password)
    password == stored_password
  end
end
