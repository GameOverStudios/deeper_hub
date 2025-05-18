defmodule Deeper_Hub.Core.WebSockets.Security.SecurityMiddlewareTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.SecurityMiddleware
  alias Deeper_Hub.Core.WebSockets.Security.CsrfProtection
  alias Deeper_Hub.Core.WebSockets.Security.XssProtection
  alias Deeper_Hub.Core.WebSockets.Security.SqlInjectionProtection
  alias Deeper_Hub.Core.WebSockets.Security.PathTraversalProtection
  alias Deeper_Hub.Core.WebSockets.Security.DdosProtection
  alias Deeper_Hub.Core.WebSockets.Security.BruteForceProtection
  
  # Mock do EventBus
  defp mock_event_bus do
    :meck.new(Deeper_Hub.Core.EventBus, [:passthrough])
    :meck.expect(Deeper_Hub.Core.EventBus, :publish, fn _topic, _event -> :ok end)
    
    on_exit(fn -> :meck.unload(Deeper_Hub.Core.EventBus) end)
  end
  
  # Mock das funções de proteção
  defp mock_security_modules do
    # Mock CsrfProtection
    :meck.new(CsrfProtection, [:passthrough])
    :meck.expect(CsrfProtection, :validate_request, fn _req, _state -> {:ok, %{}} end)
    
    # Mock XssProtection
    :meck.new(XssProtection, [:passthrough])
    :meck.expect(XssProtection, :check_for_xss, fn _message -> {:ok, %{}} end)
    :meck.expect(XssProtection, :sanitize_message, fn message -> {:ok, message} end)
    
    # Mock SqlInjectionProtection
    :meck.new(SqlInjectionProtection, [:passthrough])
    :meck.expect(SqlInjectionProtection, :check_for_sql_injection, fn _message -> {:ok, %{}} end)
    :meck.expect(SqlInjectionProtection, :sanitize_sql_value, fn message -> {:ok, message} end)
    
    # Mock PathTraversalProtection
    :meck.new(PathTraversalProtection, [:passthrough])
    :meck.expect(PathTraversalProtection, :check_path, fn _path -> {:ok, %{}} end)
    :meck.expect(PathTraversalProtection, :sanitize_path, fn path, _base_dir -> {:ok, path} end)
    
    # Mock DdosProtection
    :meck.new(DdosProtection, [:passthrough])
    :meck.expect(DdosProtection, :check_rate_limit, fn _ip -> {:ok, %{}} end)
    :meck.expect(DdosProtection, :detect_anomaly, fn _ip, _user_id -> {:ok, %{}} end)
    
    # Mock BruteForceProtection
    :meck.new(BruteForceProtection, [:passthrough])
    :meck.expect(BruteForceProtection, :check_login_allowed, fn _ip, _username -> {:ok, %{}} end)
    :meck.expect(BruteForceProtection, :check_account_status, fn _account_id -> {:ok, %{}} end)
    
    # Mock cowboy_req
    :meck.new(:cowboy_req, [:passthrough])
    :meck.expect(:cowboy_req, :peer, fn _req -> {{127, 0, 0, 1}, 12345} end)
    :meck.expect(:cowboy_req, :header, fn _name, _req, default -> default end)
    
    on_exit(fn ->
      :meck.unload(CsrfProtection)
      :meck.unload(XssProtection)
      :meck.unload(SqlInjectionProtection)
      :meck.unload(PathTraversalProtection)
      :meck.unload(DdosProtection)
      :meck.unload(BruteForceProtection)
      :meck.unload(:cowboy_req)
    end)
  end
  
  setup do
    mock_event_bus()
    mock_security_modules()
    
    %{
      req: %{},
      state: %{user_id: "test_user", account_id: "acc_123"},
      message: %{"content" => "Hello, world!", "action" => "test_action"}
    }
  end
  
  describe "check_request/3" do
    test "permite requisição quando todas as verificações passam", %{req: req, state: state} do
      assert {:ok, _secured_state} = SecurityMiddleware.check_request(req, state)
    end
    
    test "rejeita requisição quando CSRF falha", %{req: req, state: state} do
      # Configura o mock para falhar na validação CSRF
      :meck.expect(CsrfProtection, :validate_request, fn _req, _state -> 
        {:error, "CSRF validation failed"} 
      end)
      
      assert {:error, _reason} = SecurityMiddleware.check_request(req, state)
    end
    
    test "rejeita requisição quando DDoS é detectado", %{req: req, state: state} do
      # Configura o mock para falhar na verificação de DDoS
      :meck.expect(DdosProtection, :check_rate_limit, fn _ip -> 
        {:error, "Rate limit exceeded"} 
      end)
      
      assert {:error, _reason} = SecurityMiddleware.check_request(req, state)
    end
    
    test "rejeita requisição quando a conta está bloqueada", %{req: req, state: state} do
      # Configura o mock para falhar na verificação de status da conta
      :meck.expect(BruteForceProtection, :check_account_status, fn _account_id -> 
        {:error, "Account is blocked"} 
      end)
      
      assert {:error, _reason} = SecurityMiddleware.check_request(req, state)
    end
  end
  
  describe "check_message/3" do
    test "permite mensagem quando todas as verificações passam", %{state: state, message: message} do
      assert {:ok, _sanitized_message} = SecurityMiddleware.check_message(message, state)
    end
    
    test "rejeita mensagem quando XSS é detectado", %{state: state, message: message} do
      # Configura o mock para falhar na verificação de XSS
      :meck.expect(XssProtection, :check_for_xss, fn _message -> 
        {:error, "XSS detected"} 
      end)
      
      assert {:error, _reason} = SecurityMiddleware.check_message(message, state)
    end
    
    test "rejeita mensagem quando SQL Injection é detectado", %{state: state, message: message} do
      # Configura o mock para falhar na verificação de SQL Injection
      :meck.expect(SqlInjectionProtection, :check_for_sql_injection, fn _message -> 
        {:error, "SQL Injection detected"} 
      end)
      
      assert {:error, _reason} = SecurityMiddleware.check_message(message, state)
    end
    
    test "rejeita mensagem quando Path Traversal é detectado", %{state: state} do
      # Mensagem com caminho
      message = %{"path" => "../config/config.exs", "action" => "read_file"}
      
      # Configura o mock para falhar na verificação de Path Traversal
      :meck.expect(PathTraversalProtection, :check_path, fn _path -> 
        {:error, "Path Traversal detected"} 
      end)
      
      assert {:error, _reason} = SecurityMiddleware.check_message(message, state)
    end
    
    test "sanitiza mensagem corretamente", %{state: state, message: message} do
      # Configura os mocks para sanitizar a mensagem
      sanitized_content = "Sanitized content"
      :meck.expect(XssProtection, :sanitize_message, fn _message -> 
        {:ok, %{"content" => sanitized_content, "action" => "test_action"}} 
      end)
      
      {:ok, sanitized_message} = SecurityMiddleware.check_message(message, state)
      assert sanitized_message["content"] == sanitized_content
    end
  end
  
  describe "check_login_attempt/4" do
    test "permite tentativa de login quando dentro do limite", %{req: req, state: state} do
      username = "test_user"
      password = "password123"
      
      assert {:ok, _} = SecurityMiddleware.check_login_attempt(req, state, username, password)
    end
    
    test "rejeita tentativa de login quando excede o limite", %{req: req, state: state} do
      username = "test_user"
      password = "password123"
      
      # Configura o mock para falhar na verificação de tentativas de login
      :meck.expect(BruteForceProtection, :check_login_allowed, fn _ip, _username -> 
        {:error, "Too many failed login attempts"} 
      end)
      
      assert {:error, _reason} = SecurityMiddleware.check_login_attempt(req, state, username, password)
    end
    
    test "rastreia tentativa de login bem-sucedida", %{req: req, state: state} do
      username = "test_user"
      password = "password123"
      
      # Configura o mock para verificar se track_login_attempt é chamado com success=true
      :meck.expect(BruteForceProtection, :track_login_attempt, fn _ip, _username, success -> 
        assert success == true
        :ok
      end)
      
      # Simula uma autenticação bem-sucedida
      auth_result = {:ok, %{user_id: "user_123"}}
      
      assert {:ok, _} = SecurityMiddleware.track_login_result(req, state, username, auth_result)
    end
    
    test "rastreia tentativa de login mal-sucedida", %{req: req, state: state} do
      username = "test_user"
      
      # Configura o mock para verificar se track_login_attempt é chamado com success=false
      :meck.expect(BruteForceProtection, :track_login_attempt, fn _ip, _username, success -> 
        assert success == false
        :ok
      end)
      
      # Simula uma autenticação mal-sucedida
      auth_result = {:error, "Invalid credentials"}
      
      assert {:error, _} = SecurityMiddleware.track_login_result(req, state, username, auth_result)
    end
  end
end
