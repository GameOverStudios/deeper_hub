defmodule Deeper_Hub.Core.WebSockets.Handlers.AuthHandler do
  @moduledoc """
  Handler para mensagens de autenticação via WebSocket.

  Este módulo processa mensagens relacionadas à autenticação de usuários,
  como login, logout e refresh de tokens.
  """

  alias Deeper_Hub.Core.WebSockets.Auth.AuthService
  alias Deeper_Hub.Core.EventBus
  alias Deeper_Hub.Core.Logger

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
    remember_me = Map.get(payload, "remember_me", false)
    
    # Coleta metadados da conexão
    metadata = %{
      user_agent: Map.get(state, :user_agent),
      ip_address: Map.get(state, :ip_address)
    }

    Logger.info("Processando solicitação de login", %{module: __MODULE__, username: username})

    case AuthService.authenticate(username, password, remember_me, metadata) do
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
            session_id: tokens.session_id,
            expires_in: tokens.expires_in,
            remember_me: remember_me
          }
        }

        Logger.info("Login bem-sucedido", %{module: __MODULE__, user_id: user_id})
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

        Logger.warning("Falha no login", %{module: __MODULE__, username: username, reason: reason})

        {:reply, response, state}
    end
  end

  # Método de autenticação simplificada por ID removido - agora usamos apenas login completo com JWT

  # Ação de logout
  defp handle_action("logout", payload, state) do
    access_token = Map.get(payload, "access_token")
    refresh_token = Map.get(payload, "refresh_token")
    user_id = Map.get(state, :user_id)

    Logger.info("Processando solicitação de logout", %{module: __MODULE__, user_id: user_id})

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

        Logger.info("Logout bem-sucedido", %{module: __MODULE__, user_id: user_id})

        {:reply, response, state}

      {:error, reason} ->
        response = %{
          type: "auth.logout.error",
          payload: %{
            error: reason,
            message: "Falha ao realizar logout"
          }
        }

        Logger.warning("Falha no logout", %{module: __MODULE__, user_id: user_id, reason: reason})

        {:reply, response, state}
    end
  end

  # Ação de refresh de tokens
  defp handle_action("refresh", payload, state) do
    refresh_token = Map.get(payload, "refresh_token")

    Logger.info("Processando solicitação de refresh de tokens", %{module: __MODULE__})

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

        Logger.info("Refresh de tokens bem-sucedido", %{module: __MODULE__})

        {:reply, response, state}

      {:error, reason} ->
        response = %{
          type: "auth.refresh.error",
          payload: %{
            error: reason,
            message: "Falha ao atualizar tokens"
          }
        }

        Logger.warning("Falha no refresh de tokens", %{module: __MODULE__, reason: reason})

        {:reply, response, state}
    end
  end

  # Ação de recuperação de senha
  defp handle_action("request_password_reset", payload, state) do
    email = Map.get(payload, "email")
    
    Logger.info("Processando solicitação de recuperação de senha", %{module: __MODULE__, email: email})
    
    case AuthService.generate_password_reset_token(email) do
      {:ok, token, expires_at} ->
        # Em um ambiente real, enviaríamos um email com o link de recuperação
        # Para fins de desenvolvimento, retornamos o token diretamente
        response = %{
          type: "auth.password_reset.requested",
          payload: %{
            message: "Solicitação de recuperação de senha enviada",
            token: token,  # Remover em produção!
            expires_at: DateTime.to_iso8601(expires_at)
          }
        }
        
        Logger.info("Token de recuperação de senha gerado", %{module: __MODULE__, email: email})
        
        {:reply, response, state}
        
      {:error, reason} ->
        response = %{
          type: "auth.password_reset.error",
          payload: %{
            error: reason,
            message: "Falha ao solicitar recuperação de senha"
          }
        }
        
        Logger.warning("Falha ao gerar token de recuperação de senha", %{module: __MODULE__, email: email, reason: reason})
        
        {:reply, response, state}
    end
  end
  
  # Ação de redefinição de senha
  defp handle_action("reset_password", payload, state) do
    token = Map.get(payload, "token")
    new_password = Map.get(payload, "password")
    
    Logger.info("Processando solicitação de redefinição de senha", %{module: __MODULE__})
    
    case AuthService.reset_password(token, new_password) do
      {:ok, user} ->
        response = %{
          type: "auth.password_reset.success",
          payload: %{
            message: "Senha redefinida com sucesso",
            username: Map.get(user, "username")
          }
        }
        
        Logger.info("Senha redefinida com sucesso", %{module: __MODULE__, user_id: Map.get(user, "id")})
        
        {:reply, response, state}
        
      {:error, reason} ->
        response = %{
          type: "auth.password_reset.error",
          payload: %{
            error: reason,
            message: "Falha ao redefinir senha"
          }
        }
        
        Logger.warning("Falha ao redefinir senha", %{module: __MODULE__, reason: reason})
        
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

    Logger.warning("Ação de autenticação desconhecida", %{module: __MODULE__, action: action})

    {:reply, response, state}
  end
end
