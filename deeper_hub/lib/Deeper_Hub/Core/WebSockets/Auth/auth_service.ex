defmodule Deeper_Hub.Core.WebSockets.Auth.AuthService do
  @moduledoc """
  Serviço para autenticação de usuários via WebSocket.

  Este módulo fornece funções para autenticação, validação de credenciais e
  gerenciamento de sessões de usuários conectados via WebSocket.
  """

  alias Deeper_Hub.Core.WebSockets.Auth.JwtService
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionManager
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionPolicy
  alias Deeper_Hub.Core.WebSockets.Auth.Token.TokenService
  alias Deeper_Hub.Core.WebSockets.Auth.Token.TokenRotationService
  alias Deeper_Hub.Core.Data.DBConnection.Repositories.UserRepository
  alias Deeper_Hub.Core.EventBus
  alias Deeper_Hub.Core.Logger

  @doc """
  Autentica um usuário com base em suas credenciais.

  ## Parâmetros
    * `username` - Nome de usuário
    * `password` - Senha do usuário

  ## Retorno
    * `{:ok, user, tokens}` - Autenticação bem-sucedida com dados do usuário e tokens
    * `{:error, reason}` - Erro na autenticação
  """
  def authenticate(username, password, remember_me \\ false, metadata \\ %{}) do
    with {:ok, user} <- UserRepository.get_by_username(username),
         true <- verify_password(user, password) do

      user_id = Map.get(user, "id")

      # Cria uma sessão para o usuário
      case SessionManager.create_session(user_id, remember_me, metadata) do
        {:ok, session} ->
          Logger.info("Usuário autenticado com sucesso", %{module: __MODULE__, user_id: user_id})
          EventBus.publish(:user_authenticated, %{user_id: user_id})

          tokens = %{
            access_token: session.access_token,
            refresh_token: session.refresh_token,
            session_id: session.id,
            expires_in: SessionPolicy.access_token_expiry()
          }

          {:ok, user, tokens}

        error ->
          Logger.error("Erro ao criar sessão", %{module: __MODULE__, error: error})
          {:error, :session_creation_failed}
      end
    else
      {:error, :not_found} ->
        Logger.warn("Tentativa de login com usuário inexistente", %{module: __MODULE__, username: username})
        # Retornamos o mesmo erro para não revelar se o usuário existe ou não
        {:error, :invalid_credentials}

      false ->
        Logger.warn("Tentativa de login com senha incorreta", %{module: __MODULE__, username: username})
        {:error, :invalid_credentials}

      error ->
        Logger.error("Erro ao autenticar usuário", %{module: __MODULE__, error: error})
        {:error, :authentication_failed}
    end
  end

  # Função de autenticação simplificada por ID removida - agora usamos apenas autenticação completa com JWT

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

      Logger.info("Token verificado com sucesso", %{module: __MODULE__, user_id: user_id})
      {:ok, user}
    else
      {:error, :token_blacklisted} ->
        Logger.warn("Tentativa de uso de token revogado", %{module: __MODULE__})
        {:error, :token_blacklisted}

      {:error, :not_found} ->
        Logger.warn("Token válido mas usuário não encontrado", %{module: __MODULE__})
        {:error, :user_not_found}

      error ->
        Logger.error("Erro ao verificar token", %{module: __MODULE__, error: error})
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
    # Usa o serviço de rotação de tokens para renovar os tokens
    case TokenRotationService.rotate_tokens(refresh_token) do
      {:ok, tokens} ->
        Logger.info("Tokens atualizados com sucesso", %{module: __MODULE__})
        {:ok, tokens}

      error ->
        Logger.error("Erro ao atualizar tokens", %{module: __MODULE__, error: error})
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
    # Encerra a sessão do usuário
    case SessionManager.end_session(access_token, refresh_token) do
      :ok ->
        # Tenta obter o ID do usuário para fins de log
        case JwtService.verify_token(access_token) do
          {:ok, claims} ->
            user_id = Map.get(claims, "user_id")
            Logger.info("Logout realizado com sucesso", %{module: __MODULE__, user_id: user_id})
            EventBus.publish(:user_logged_out, %{user_id: user_id})
          _ ->
            Logger.info("Logout realizado com sucesso (token já inválido)", %{module: __MODULE__})
        end
        :ok

      error ->
        Logger.warn("Erro ao encerrar sessão", %{module: __MODULE__, error: error})
        {:error, :session_end_failed}
    end
  end

  @doc """
  Gera um token opaco para recuperação de senha.

  ## Parâmetros

    - `email`: Email do usuário

  ## Retorno

    - `{:ok, token, expires_at}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def generate_password_reset_token(email) do
    with {:ok, user} <- UserRepository.get_by_email(email) do
      user_id = Map.get(user, "id")
      TokenService.generate_opaque_token(:password_reset, user_id)
    else
      error ->
        Logger.error("Erro ao gerar token de recuperação de senha", %{module: __MODULE__, email: email, error: error})
        {:error, :user_not_found}
    end
  end

  @doc """
  Verifica um token de recuperação de senha.

  ## Parâmetros

    - `token`: Token de recuperação de senha

  ## Retorno

    - `{:ok, user_id}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def verify_password_reset_token(token) do
    case TokenService.verify_opaque_token(token, :password_reset) do
      {:ok, data} ->
        {:ok, data.identifier}

      error ->
        Logger.error("Erro ao verificar token de recuperação de senha", %{module: __MODULE__, error: error})
        {:error, :invalid_token}
    end
  end

  @doc """
  Redefine a senha de um usuário usando um token de recuperação.

  ## Parâmetros

    - `token`: Token de recuperação de senha
    - `new_password`: Nova senha

  ## Retorno

    - `{:ok, user}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def reset_password(token, new_password) do
    with {:ok, user_id} <- verify_password_reset_token(token),
         {:ok, user} <- UserRepository.get_by_id(user_id),
         # Atualiza a senha
         updated_user = Map.put(user, :password_hash, new_password),
         {:ok, saved_user} <- UserRepository.update(updated_user) do

      # Revoga o token usado
      TokenService.revoke_opaque_token(token)

      # Encerra todas as sessões existentes do usuário
      SessionManager.end_all_user_sessions(user_id)

      {:ok, saved_user}
    else
      error ->
        Logger.error("Erro ao redefinir senha", %{module: __MODULE__, error: error})
        {:error, :password_reset_failed}
    end
  end

  # Funções privadas

  defp verify_password(user, password) do
    # Para fins de desenvolvimento, estamos usando a senha diretamente como hash
    # Em produção, isso deve ser substituído por uma função de hash segura

    # Tenta obter a senha armazenada, considerando que o usuário pode vir como mapa com chaves string ou atom
    stored_password = cond do
      is_map_key(user, "password_hash") -> Map.get(user, "password_hash")
      is_map_key(user, :password_hash) -> Map.get(user, :password_hash)
      true -> nil
    end

    Logger.debug("Verificando senha", %{
      module: __MODULE__,
      password_provided: password,
      stored_password: stored_password
    })

    # Verificação simplificada para desenvolvimento
    password == stored_password
  end
end
