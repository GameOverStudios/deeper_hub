defmodule Deeper_Hub.Core.WebSockets.Handlers.AuthHandler do
  @moduledoc """
  Handler para mensagens de autenticação via WebSocket.

  Este módulo processa mensagens relacionadas à autenticação de usuários,
  como login, logout e refresh de tokens.
  """

  alias Deeper_Hub.Core.Auth.AuthService
  alias Deeper_Hub.Core.EventBus

  require Logger

  @doc """
  Processa uma mensagem de autenticação.

  ## Parâmetros
    * `payload` - Payload da mensagem
    * `state` - Estado atual da conexão WebSocket

  ## Retorno
    * `{:reply, response, state}` - Resposta a ser enviada ao cliente
    * `{:ok, state}` - Estado atualizado sem resposta
    * `{:error, reason}` - Erro ao processar a mensagem
  """
  def handle_message(payload, state) do
    action = Map.get(payload, "action")
    handle_action(action, payload, state)
  end

  # Ação de login
  defp handle_action("login", payload, state) do
    username = Map.get(payload, "username")
    password = Map.get(payload, "password")

    Logger.info("[#{__MODULE__}] Processando solicitação de login username=#{username}")

    case AuthService.authenticate(username, password) do
      {:ok, user, tokens} ->
        user_id = Map.get(user, "id")

        # Atualiza o estado da conexão com o ID do usuário
        state = Map.put(state, :user_id, user_id)
        state = Map.put(state, :authenticated, true)

        response = %{
          type: "auth.login.success",
          payload: %{
            user_id: user_id,
            username: Map.get(user, "username"),
            access_token: tokens.access_token,
            refresh_token: tokens.refresh_token,
            expires_in: tokens.expires_in
          }
        }

        Logger.info("[#{__MODULE__}] Login bem-sucedido user_id=#{user_id}")
        EventBus.publish(:user_logged_in, %{user_id: user_id})

        {:reply, response, state}

      {:error, reason} ->
        response = %{
          type: "auth.login.error",
          payload: %{
            error: reason,
            message: "Falha na autenticação"
          }
        }

        Logger.warning("[#{__MODULE__}] Falha no login username=#{username} reason=#{inspect(reason)}")

        {:reply, response, state}
    end
  end

  # Ação de autenticação simples por ID (para WebSockets)
  defp handle_action("auth", payload, state) do
    user_id = Map.get(payload, "user_id")

    Logger.info("[#{__MODULE__}] Processando solicitação de autenticação user_id=#{user_id}")

    case AuthService.authenticate_by_id(user_id) do
      {:ok, _user} ->
        # Atualiza o estado da conexão com o ID do usuário
        state = Map.put(state, :user_id, user_id)
        state = Map.put(state, :authenticated, true)

        response = %{
          type: "auth_success",
          payload: %{
            user_id: user_id
          }
        }

        Logger.info("[#{__MODULE__}] Autenticação bem-sucedida user_id=#{user_id}")

        {:reply, response, state}

      {:error, reason} ->
        response = %{
          type: "auth_error",
          payload: %{
            error: reason,
            message: "Falha na autenticação"
          }
        }

        Logger.warning("[#{__MODULE__}] Falha na autenticação user_id=#{user_id} reason=#{inspect(reason)}")

        {:reply, response, state}
    end
  end

  # Ação de logout
  defp handle_action("logout", payload, state) do
    access_token = Map.get(payload, "access_token")
    refresh_token = Map.get(payload, "refresh_token")
    user_id = Map.get(state, :user_id)

    Logger.info("[#{__MODULE__}] Processando solicitação de logout user_id=#{user_id}")

    case AuthService.logout(access_token, refresh_token) do
      :ok ->
        # Remove as informações de autenticação do estado
        state = Map.delete(state, :user_id)
        state = Map.put(state, :authenticated, false)

        response = %{
          type: "auth.logout.success",
          payload: %{
            message: "Logout realizado com sucesso"
          }
        }

        Logger.info("[#{__MODULE__}] Logout bem-sucedido user_id=#{user_id}")

        {:reply, response, state}

      {:error, reason} ->
        response = %{
          type: "auth.logout.error",
          payload: %{
            error: reason,
            message: "Falha ao realizar logout"
          }
        }

        Logger.warning("[#{__MODULE__}] Falha no logout user_id=#{user_id} reason=#{inspect(reason)}")

        {:reply, response, state}
    end
  end

  # Ação de refresh de tokens
  defp handle_action("refresh", payload, state) do
    refresh_token = Map.get(payload, "refresh_token")

    Logger.info("[#{__MODULE__}] Processando solicitação de refresh de tokens")

    case AuthService.refresh_tokens(refresh_token) do
      {:ok, tokens} ->
        response = %{
          type: "auth.refresh.success",
          payload: %{
            access_token: tokens.access_token,
            refresh_token: tokens.refresh_token,
            expires_in: tokens.expires_in
          }
        }

        Logger.info("[#{__MODULE__}] Refresh de tokens bem-sucedido")

        {:reply, response, state}

      {:error, reason} ->
        response = %{
          type: "auth.refresh.error",
          payload: %{
            error: reason,
            message: "Falha ao atualizar tokens"
          }
        }

        Logger.warning("[#{__MODULE__}] Falha no refresh de tokens reason=#{inspect(reason)}")

        {:reply, response, state}
    end
  end

  # Ação desconhecida
  defp handle_action(action, _payload, state) do
    response = %{
      type: "auth.error",
      payload: %{
        error: :unknown_action,
        message: "Ação desconhecida: #{action}"
      }
    }

    Logger.warning("[#{__MODULE__}] Ação de autenticação desconhecida action=#{action}")

    {:reply, response, state}
  end
end
