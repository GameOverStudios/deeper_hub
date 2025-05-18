defmodule Deeper_Hub.Core.WebSockets.Auth.AuthService do
  @moduledoc """
  Serviço para autenticação de usuários via WebSocket.

  Este módulo fornece funções para autenticação, validação de credenciais e
  gerenciamento de sessões de usuários conectados via WebSocket.
  """

  alias Deeper_Hub.Core.WebSockets.Auth.JwtService
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
  def authenticate(username, password) do
    with {:ok, user} <- UserRepository.get_by_username(username),
         true <- verify_password(user, password) do

      user_id = Map.get(user, "id")

      case JwtService.generate_token_pair(user_id) do
        {:ok, access_token, refresh_token, claims} ->
          Logger.info("Usuário autenticado com sucesso", %{module: __MODULE__, user_id: user_id})
          EventBus.publish(:user_authenticated, %{user_id: user_id})

          tokens = %{
            access_token: access_token,
            refresh_token: refresh_token,
            expires_in: Map.get(claims.access, "exp") - Map.get(claims.access, "iat")
          }

          {:ok, user, tokens}

        error ->
          Logger.error("Erro ao gerar tokens", %{module: __MODULE__, error: error})
          {:error, :token_generation_failed}
      end
    else
      {:error, :not_found} ->
        Logger.warning("Tentativa de login com usuário inexistente", %{module: __MODULE__, username: username})
        # Retornamos o mesmo erro para não revelar se o usuário existe ou não
        {:error, :invalid_credentials}

      false ->
        Logger.warning("Tentativa de login com senha incorreta", %{module: __MODULE__, username: username})
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
        Logger.warning("Tentativa de uso de token revogado", %{module: __MODULE__})
        {:error, :token_blacklisted}

      {:error, :not_found} ->
        Logger.warning("Token válido mas usuário não encontrado", %{module: __MODULE__})
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
    with {:ok, claims} <- JwtService.verify_token(refresh_token),
         "refresh" <- Map.get(claims, "typ"),
         user_id = Map.get(claims, "user_id"),
         {:ok, access_token, refresh_token, claims} <- JwtService.generate_token_pair(user_id) do

      Logger.info("Tokens atualizados com sucesso", %{module: __MODULE__, user_id: user_id})

      tokens = %{
        access_token: access_token,
        refresh_token: refresh_token,
        expires_in: Map.get(claims.access, "exp") - Map.get(claims.access, "iat")
      }

      {:ok, tokens}
    else
      "access" ->
        Logger.warning("Tentativa de refresh com token de acesso", %{module: __MODULE__})
        {:error, :invalid_token_type}

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
    # Revoga ambos os tokens
    JwtService.revoke_token(access_token)
    JwtService.revoke_token(refresh_token)

    case JwtService.verify_token(access_token) do
      {:ok, claims} ->
        user_id = Map.get(claims, "user_id")
        Logger.info("Logout realizado com sucesso", %{module: __MODULE__, user_id: user_id})
        EventBus.publish(:user_logged_out, %{user_id: user_id})
        :ok

      _ ->
        Logger.warning("Logout com token inválido", %{module: __MODULE__})
        {:error, :invalid_token}
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
