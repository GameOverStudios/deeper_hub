defmodule Deeper_Hub.Core.WebSockets.Handlers.AuthHandlerTest do
  @moduledoc """
  Testes para o módulo AuthHandler.
  """  
  use ExUnit.Case, async: false
  import Deeper_Hub.Factory
  
  alias Deeper_Hub.Core.WebSockets.Handlers.AuthHandler
  
  # Módulo de teste para substituir o AuthService
  defmodule MockAuthService do
    def authenticate(username, password, remember_me, _metadata) do
      cond do
        username == "valid_user" and password == "valid_password" ->
          user = %{id: "user_123", username: "valid_user", email: "user@example.com"}
          tokens = %{
            access_token: "access_token_123",
            refresh_token: "refresh_token_456",
            session_id: "session_789",
            expires_in: if(remember_me, do: 604800, else: 3600)
          }
          {:ok, user, tokens}
        true ->
          {:error, :invalid_credentials}
      end
    end
    
    def logout(_user_id, _session_id), do: :ok
    
    def refresh_tokens(refresh_token) do
      case refresh_token do
        "refresh_token_123" ->
          {:ok, %{
            access_token: "new_access_token",
            refresh_token: "new_refresh_token",
            session_id: "session_789",
            expires_in: 3600
          }}
        _ ->
          {:error, :invalid_token}
      end
    end
    
    def generate_password_reset_token(email) do
      case email do
        "user@example.com" ->
          token = "reset_token_123"
          expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)
          {:ok, token, expires_at}
        _ ->
          {:error, :user_not_found}
      end
    end
    
    def reset_password(token, _password) do
      case token do
        "reset_token_123" ->
          user = %{id: "user_123", username: "valid_user", email: "user@example.com"}
          {:ok, user}
        _ ->
          {:error, :invalid_token}
      end
    end
  end
  
  setup do
    # Inicializar serviços necessários
    Deeper_Hub.Core.WebSockets.Auth.TokenBlacklist.init()
    
    # Estado inicial para o handler
    state = %{
      user_id: nil,
      authenticated: false,
      user_agent: "Test Browser",
      ip_address: "127.0.0.1"
    }
    
    # Substituir o módulo AuthService pelo MockAuthService durante os testes
    Application.put_env(:deeper_hub, :auth_service, MockAuthService)
    
    on_exit(fn ->
      # Restaurar a configuração original após os testes
      Application.delete_env(:deeper_hub, :auth_service)
    end)
    
    {:ok, state: state}
  end
  
  describe "handle_message - login" do
    test "processa login com sucesso", %{state: state} do
      # Usar o MockAuthService configurado no setup
      payload = %{
        "action" => "login",
        "username" => "valid_user",
        "password" => "valid_password",
        "remember_me" => false
      }
      
      {:reply, response, new_state} = AuthHandler.handle_message(payload, state)
      
      # Verificar resposta
      assert response.type == "auth.login.success"
      assert response.payload.user_id == "user_123"
      assert response.payload.username == "valid_user"
      assert response.payload.access_token == "access_token_123"
      assert response.payload.refresh_token == "refresh_token_456"
      assert response.payload.session_id == "session_789"
      
      # Verificar estado atualizado
      assert new_state.authenticated == true
      assert new_state.user_id == "user_123"
    end
    
    test "processa falha de login com credenciais inválidas", %{state: state} do
      # Usar o MockAuthService configurado no setup
      payload = %{
        "action" => "login",
        "username" => "invalid_user",
        "password" => "wrong_password",
        "remember_me" => false
      }
      
      {:reply, response, new_state} = AuthHandler.handle_message(payload, state)
      
      # Verificar resposta
      assert response.type == "auth.login.error"
      assert response.payload.error == :invalid_credentials
      
      # Verificar estado não alterado
      assert new_state.authenticated == false
      assert new_state.user_id == nil
    end
    
    test "processa login com remember_me", %{state: state} do
      # Usar o MockAuthService configurado no setup
      payload = %{
        "action" => "login",
        "username" => "valid_user",
        "password" => "valid_password",
        "remember_me" => true
      }
      
      {:reply, response, _} = AuthHandler.handle_message(payload, state)
      
      # Verificar que remember_me está na resposta
      assert response.payload.remember_me == true
      # Verificar que o token tem validade estendida
      assert response.payload.expires_in == 604800
    end
  end
  
  describe "handle_message - logout" do
    test "processa logout com sucesso", %{state: state} do
      # Configurar estado autenticado
      authenticated_state = Map.merge(state, %{
        authenticated: true,
        user_id: "user_123",
        session_id: "session_456"
      })
      
      # Usar o MockAuthService configurado no setup
      payload = %{"action" => "logout"}
      
      {:reply, response, new_state} = AuthHandler.handle_message(payload, authenticated_state)
      
      # Verificar resposta
      assert response.type == "auth.logout.success"
      assert response.payload.message =~ "Logout realizado com sucesso"
      
      # Verificar estado atualizado
      assert new_state.authenticated == false
      assert new_state.user_id == nil
    end
  end
  
  describe "handle_message - refresh" do
    test "processa refresh de token com sucesso", %{state: state} do
      # Usar o MockAuthService configurado no setup
      payload = %{
        "action" => "refresh",
        "refresh_token" => "refresh_token_123"
      }
      
      {:reply, response, _} = AuthHandler.handle_message(payload, state)
      
      # Verificar resposta
      assert response.type == "auth.refresh.success"
      assert response.payload.access_token == "new_access_token"
      assert response.payload.refresh_token == "new_refresh_token"
    end
    
    test "processa falha no refresh de token", %{state: state} do
      # Usar o MockAuthService configurado no setup
      payload = %{
        "action" => "refresh",
        "refresh_token" => "invalid_refresh_token"
      }
      
      {:reply, response, _} = AuthHandler.handle_message(payload, state)
      
      # Verificar resposta
      assert response.type == "auth.refresh.error"
      assert response.payload.error == :invalid_token
    end
  end
  
  describe "handle_message - request_password_reset" do
    test "processa solicitação de recuperação de senha com sucesso", %{state: state} do
      # Usar o MockAuthService configurado no setup
      payload = %{
        "action" => "request_password_reset",
        "email" => "user@example.com"
      }
      
      {:reply, response, _} = AuthHandler.handle_message(payload, state)
      
      # Verificar resposta
      assert response.type == "auth.password_reset.requested"
      assert response.payload.message =~ "Solicitação de recuperação de senha enviada"
      assert response.payload.token == "reset_token_123"
    end
    
    test "processa falha na solicitação de recuperação de senha", %{state: state} do
      # Usar o MockAuthService configurado no setup
      payload = %{
        "action" => "request_password_reset",
        "email" => "nonexistent@example.com"
      }
      
      {:reply, response, _} = AuthHandler.handle_message(payload, state)
      
      # Verificar resposta
      assert response.type == "auth.password_reset.error"
      assert response.payload.error == :user_not_found
    end
  end
  
  describe "handle_message - reset_password" do
    test "processa redefinição de senha com sucesso", %{state: state} do
      # Usar o MockAuthService configurado no setup
      payload = %{
        "action" => "reset_password",
        "token" => "reset_token_123",
        "password" => "new_password123"
      }
      
      {:reply, response, _} = AuthHandler.handle_message(payload, state)
      
      # Verificar resposta
      assert response.type == "auth.password_reset.success"
      assert response.payload.message =~ "Senha redefinida com sucesso"
      assert response.payload.username == "valid_user"
    end
    
    test "processa falha na redefinição de senha", %{state: state} do
      # Usar o MockAuthService configurado no setup
      payload = %{
        "action" => "reset_password",
        "token" => "invalid_token",
        "password" => "new_password123"
      }
      
      {:reply, response, _} = AuthHandler.handle_message(payload, state)
      
      # Verificar resposta
      assert response.type == "auth.password_reset.error"
      assert response.payload.error == :invalid_token
    end
  end
end
