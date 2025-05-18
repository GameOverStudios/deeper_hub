defmodule Deeper_Hub.Core.WebSockets.Handlers.AuthHandlerTest do
  @moduledoc """
  Testes para o módulo AuthHandler.
  """
  
  use ExUnit.Case, async: false
  import Deeper_Hub.Factory
  import Mock
  
  alias Deeper_Hub.Core.WebSockets.Handlers.AuthHandler
  alias Deeper_Hub.Core.WebSockets.Auth.AuthService
  
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
    
    {:ok, state: state}
  end
  
  describe "handle_message - login" do
    test "processa login com sucesso", %{state: state} do
      user = build(:user)
      tokens = %{
        access_token: "access_token_123",
        refresh_token: "refresh_token_456",
        session_id: "session_789",
        expires_in: 3600
      }
      
      with_mocks([
        {AuthService, [], [
          authenticate: fn _, _, _, _ -> {:ok, user, tokens} end
        ]}
      ]) do
        payload = %{
          "action" => "login",
          "username" => user.username,
          "password" => "password123",
          "remember_me" => false
        }
        
        {:reply, response, new_state} = AuthHandler.handle_message(payload, state)
        
        # Verificar resposta
        assert response.type == "auth.login.success"
        assert response.payload.user_id == user.id
        assert response.payload.username == user.username
        assert response.payload.access_token == tokens.access_token
        assert response.payload.refresh_token == tokens.refresh_token
        assert response.payload.session_id == tokens.session_id
        
        # Verificar estado atualizado
        assert new_state.authenticated == true
        assert new_state.user_id == user.id
      end
    end
    
    test "processa falha de login com credenciais inválidas", %{state: state} do
      with_mocks([
        {AuthService, [], [
          authenticate: fn _, _, _, _ -> {:error, :invalid_credentials} end
        ]}
      ]) do
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
    end
    
    test "processa login com remember_me", %{state: state} do
      user = build(:user)
      tokens = %{
        access_token: "access_token_123",
        refresh_token: "refresh_token_456",
        session_id: "session_789",
        expires_in: 604800 # 7 dias
      }
      
      with_mocks([
        {AuthService, [], [
          authenticate: fn _, _, true, _ -> {:ok, user, tokens} end
        ]}
      ]) do
        payload = %{
          "action" => "login",
          "username" => user.username,
          "password" => "password123",
          "remember_me" => true
        }
        
        {:reply, response, _} = AuthHandler.handle_message(payload, state)
        
        # Verificar que remember_me está na resposta
        assert response.payload.remember_me == true
        # Verificar que o token tem validade estendida
        assert response.payload.expires_in == 604800
      end
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
      
      with_mocks([
        {AuthService, [], [
          logout: fn _, _ -> :ok end
        ]}
      ]) do
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
  end
  
  describe "handle_message - refresh" do
    test "processa refresh de token com sucesso", %{state: state} do
      refresh_token = "refresh_token_123"
      new_tokens = %{
        access_token: "new_access_token",
        refresh_token: "new_refresh_token",
        session_id: "session_789",
        expires_in: 3600
      }
      
      with_mocks([
        {AuthService, [], [
          refresh_tokens: fn ^refresh_token -> {:ok, new_tokens} end
        ]}
      ]) do
        payload = %{
          "action" => "refresh",
          "refresh_token" => refresh_token
        }
        
        {:reply, response, _} = AuthHandler.handle_message(payload, state)
        
        # Verificar resposta
        assert response.type == "auth.refresh.success"
        assert response.payload.access_token == new_tokens.access_token
        assert response.payload.refresh_token == new_tokens.refresh_token
      end
    end
    
    test "processa falha no refresh de token", %{state: state} do
      refresh_token = "invalid_refresh_token"
      
      with_mocks([
        {AuthService, [], [
          refresh_tokens: fn ^refresh_token -> {:error, :invalid_token} end
        ]}
      ]) do
        payload = %{
          "action" => "refresh",
          "refresh_token" => refresh_token
        }
        
        {:reply, response, _} = AuthHandler.handle_message(payload, state)
        
        # Verificar resposta
        assert response.type == "auth.refresh.error"
        assert response.payload.error == :invalid_token
      end
    end
  end
  
  describe "handle_message - request_password_reset" do
    test "processa solicitação de recuperação de senha com sucesso", %{state: state} do
      email = "user@example.com"
      token = "reset_token_123"
      expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)
      
      with_mocks([
        {AuthService, [], [
          generate_password_reset_token: fn ^email -> {:ok, token, expires_at} end
        ]}
      ]) do
        payload = %{
          "action" => "request_password_reset",
          "email" => email
        }
        
        {:reply, response, _} = AuthHandler.handle_message(payload, state)
        
        # Verificar resposta
        assert response.type == "auth.password_reset.requested"
        assert response.payload.message =~ "Solicitação de recuperação de senha enviada"
        assert response.payload.token == token
      end
    end
    
    test "processa falha na solicitação de recuperação de senha", %{state: state} do
      email = "nonexistent@example.com"
      
      with_mocks([
        {AuthService, [], [
          generate_password_reset_token: fn ^email -> {:error, :user_not_found} end
        ]}
      ]) do
        payload = %{
          "action" => "request_password_reset",
          "email" => email
        }
        
        {:reply, response, _} = AuthHandler.handle_message(payload, state)
        
        # Verificar resposta
        assert response.type == "auth.password_reset.error"
        assert response.payload.error == :user_not_found
      end
    end
  end
  
  describe "handle_message - reset_password" do
    test "processa redefinição de senha com sucesso", %{state: state} do
      token = "reset_token_123"
      new_password = "new_password123"
      user = build(:user)
      
      with_mocks([
        {AuthService, [], [
          reset_password: fn ^token, ^new_password -> {:ok, user} end
        ]}
      ]) do
        payload = %{
          "action" => "reset_password",
          "token" => token,
          "password" => new_password
        }
        
        {:reply, response, _} = AuthHandler.handle_message(payload, state)
        
        # Verificar resposta
        assert response.type == "auth.password_reset.success"
        assert response.payload.message =~ "Senha redefinida com sucesso"
        assert response.payload.username == user.username
      end
    end
    
    test "processa falha na redefinição de senha", %{state: state} do
      token = "invalid_token"
      new_password = "new_password123"
      
      with_mocks([
        {AuthService, [], [
          reset_password: fn ^token, ^new_password -> {:error, :invalid_token} end
        ]}
      ]) do
        payload = %{
          "action" => "reset_password",
          "token" => token,
          "password" => new_password
        }
        
        {:reply, response, _} = AuthHandler.handle_message(payload, state)
        
        # Verificar resposta
        assert response.type == "auth.password_reset.error"
        assert response.payload.error == :invalid_token
      end
    end
  end
end
