defmodule Deeper_Hub.Core.WebSockets.Security.SecuritySupervisorTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.SecuritySupervisor
  alias Deeper_Hub.Core.WebSockets.Security.SecurityMiddleware
  
  # Mock do SecurityMiddleware
  defp mock_security_middleware do
    :meck.new(SecurityMiddleware, [:passthrough])
    :meck.expect(SecurityMiddleware, :check_request, fn req, state, _opts -> 
      {:ok, Map.put(state, :security_checked, true)} 
    end)
    
    :meck.expect(SecurityMiddleware, :check_message, fn message, _state, _opts -> 
      {:ok, Map.put(message, :security_checked, true)} 
    end)
    
    on_exit(fn -> :meck.unload(SecurityMiddleware) end)
  end
  
  setup do
    mock_security_middleware()
    
    %{
      req: %{},
      state: %{user_id: "test_user"},
      message: %{"content" => "Hello, world!", "action" => "test_action"}
    }
  end
  
  describe "start_link/1" do
    test "inicia o supervisor corretamente" do
      # Tenta iniciar o supervisor
      assert {:ok, pid} = SecuritySupervisor.start_link([])
      
      # Verifica se o processo está rodando
      assert Process.alive?(pid)
      
      # Encerra o processo
      assert :ok = Supervisor.stop(pid)
    end
  end
  
  describe "child_spec/1" do
    test "retorna a especificação de child correta" do
      child_spec = SecuritySupervisor.child_spec([])
      
      assert child_spec.id == SecuritySupervisor
      assert child_spec.start == {SecuritySupervisor, :start_link, [[]]}
      assert child_spec.type == :supervisor
    end
  end
  
  describe "check_request/3" do
    test "delega para o SecurityMiddleware e retorna o resultado", %{req: req, state: state} do
      assert {:ok, secured_state} = SecuritySupervisor.check_request(req, state)
      assert secured_state.security_checked == true
    end
    
    test "passa as opções para o SecurityMiddleware", %{req: req, state: state} do
      # Configura o mock para verificar as opções
      :meck.expect(SecurityMiddleware, :check_request, fn _req, _state, opts -> 
        assert opts == [skip_csrf: true]
        {:ok, %{security_checked: true}} 
      end)
      
      assert {:ok, _} = SecuritySupervisor.check_request(req, state, skip_csrf: true)
    end
  end
  
  describe "check_message/3" do
    test "delega para o SecurityMiddleware e retorna o resultado", %{state: state, message: message} do
      assert {:ok, secured_message} = SecuritySupervisor.check_message(message, state)
      assert secured_message.security_checked == true
    end
    
    test "passa as opções para o SecurityMiddleware", %{state: state, message: message} do
      # Configura o mock para verificar as opções
      :meck.expect(SecurityMiddleware, :check_message, fn _message, _state, opts -> 
        assert opts == [skip_xss: true]
        {:ok, %{"security_checked" => true}} 
      end)
      
      assert {:ok, _} = SecuritySupervisor.check_message(message, state, skip_xss: true)
    end
  end
  
  describe "check_login_attempt/4" do
    test "delega para o SecurityMiddleware e retorna o resultado", %{req: req, state: state} do
      username = "test_user"
      password = "password123"
      
      # Configura o mock para retornar um resultado específico
      :meck.expect(SecurityMiddleware, :check_login_attempt, fn _req, _state, _username, _password -> 
        {:ok, %{login_checked: true}} 
      end)
      
      assert {:ok, result} = SecuritySupervisor.check_login_attempt(req, state, username, password)
      assert result.login_checked == true
    end
  end
  
  describe "track_login_result/4" do
    test "delega para o SecurityMiddleware e retorna o resultado", %{req: req, state: state} do
      username = "test_user"
      auth_result = {:ok, %{user_id: "user_123"}}
      
      # Configura o mock para retornar um resultado específico
      :meck.expect(SecurityMiddleware, :track_login_result, fn _req, _state, _username, _auth_result -> 
        {:ok, %{login_tracked: true}} 
      end)
      
      assert {:ok, result} = SecuritySupervisor.track_login_result(req, state, username, auth_result)
      assert result.login_tracked == true
    end
    
    test "propaga erros do SecurityMiddleware", %{req: req, state: state} do
      username = "test_user"
      auth_result = {:error, "Invalid credentials"}
      
      # Configura o mock para retornar um erro
      :meck.expect(SecurityMiddleware, :track_login_result, fn _req, _state, _username, _auth_result -> 
        {:error, "Login attempt tracking failed"} 
      end)
      
      assert {:error, "Login attempt tracking failed"} = 
        SecuritySupervisor.track_login_result(req, state, username, auth_result)
    end
  end
end
