defmodule Deeper_Hub.Core.WebSockets.Security.SecurityIntegrationTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.WebSocketHandler
  alias Deeper_Hub.Core.WebSockets.Security.SecuritySupervisor
  alias Deeper_Hub.Core.WebSockets.Security.SecurityConfig
  
  # Mock do EventBus
  defp mock_event_bus do
    :meck.new(Deeper_Hub.Core.EventBus, [:passthrough])
    :meck.expect(Deeper_Hub.Core.EventBus, :publish, fn _topic, _event -> :ok end)
    
    on_exit(fn -> :meck.unload(Deeper_Hub.Core.EventBus) end)
  end
  
  # Mock do cowboy_req
  defp mock_cowboy_req do
    :meck.new(:cowboy_req, [:passthrough])
    
    :meck.expect(:cowboy_req, :peer, fn _req ->
      {{127, 0, 0, 1}, 12345}
    end)
    
    :meck.expect(:cowboy_req, :header, fn name, req, default ->
      Map.get(req.headers, name, default)
    end)
    
    :meck.expect(:cowboy_req, :reply, fn _status, _headers, _body, _req -> 
      :ok 
    end)
    
    on_exit(fn -> :meck.unload(:cowboy_req) end)
  end
  
  # Mock do SecuritySupervisor
  defp mock_security_supervisor do
    :meck.new(SecuritySupervisor, [:passthrough])
    
    :meck.expect(SecuritySupervisor, :check_request, fn req, state, _opts -> 
      case req do
        %{headers: %{"x-malicious" => "true"}} ->
          {:error, "Security check failed: Malicious request detected"}
        _ ->
          {:ok, Map.put(state, :security_checked, true)}
      end
    end)
    
    :meck.expect(SecuritySupervisor, :check_message, fn message, state, _opts -> 
      case message do
        %{"content" => "<script>alert('XSS')</script>"} ->
          {:error, "Security check failed: XSS detected"}
        %{"content" => "DROP TABLE users"} ->
          {:error, "Security check failed: SQL Injection detected"}
        %{"path" => "../config/config.exs"} ->
          {:error, "Security check failed: Path Traversal detected"}
        _ ->
          {:ok, Map.put(message, "security_checked", true)}
      end
    end)
    
    on_exit(fn -> :meck.unload(SecuritySupervisor) end)
  end
  
  # Mock do Logger
  defp mock_logger do
    :meck.new(Logger, [:passthrough])
    :meck.expect(Logger, :error, fn _message, _opts -> :ok end)
    :meck.expect(Logger, :warning, fn _message, _opts -> :ok end)
    :meck.expect(Logger, :info, fn _message, _opts -> :ok end)
    
    on_exit(fn -> :meck.unload(Logger) end)
  end
  
  setup do
    mock_event_bus()
    mock_cowboy_req()
    mock_security_supervisor()
    mock_logger()
    
    # Cria um req de teste
    req = %{
      headers: %{
        "origin" => "http://localhost",
        "x-csrf-token" => "valid-token",
        "x-session-id" => "test-session"
      }
    }
    
    # Cria um estado inicial
    state = %{
      user_id: "test_user",
      account_id: "acc_123"
    }
    
    %{
      req: req,
      state: state
    }
  end
  
  describe "WebSocketHandler.init/2" do
    test "aceita conexão quando as verificações de segurança passam", %{req: req, state: state} do
      result = WebSocketHandler.init(req, state)
      
      assert match?({:cowboy_websocket, _req, _state, _opts}, result)
      
      # Extrai o estado para verificação
      {:cowboy_websocket, _req, new_state, _opts} = result
      assert Map.has_key?(new_state, :security_checked)
    end
    
    test "rejeita conexão quando as verificações de segurança falham" do
      # Cria um req malicioso
      req = %{
        headers: %{
          "origin" => "http://localhost",
          "x-csrf-token" => "valid-token",
          "x-session-id" => "test-session",
          "x-malicious" => "true"
        }
      }
      
      state = %{user_id: "test_user"}
      
      result = WebSocketHandler.init(req, state)
      
      # Deve rejeitar a conexão
      assert match?({:ok, _req}, result)
      
      # Verifica se o evento de segurança foi publicado
      assert :meck.called(Deeper_Hub.Core.EventBus, :publish, [
        :security_event,
        :_
      ])
    end
  end
  
  describe "WebSocketHandler.websocket_handle/2" do
    test "processa mensagem quando as verificações de segurança passam", %{state: state} do
      # Cria uma mensagem válida
      frame = {:text, Jason.encode!(%{"content" => "Hello, world!", "action" => "test_action"})}
      
      result = WebSocketHandler.websocket_handle(frame, state)
      
      # Deve processar a mensagem normalmente
      assert match?({:ok, _state}, result) or match?({:reply, _frames, _state}, result)
    end
    
    test "rejeita mensagem com XSS", %{state: state} do
      # Cria uma mensagem com XSS
      frame = {:text, Jason.encode!(%{"content" => "<script>alert('XSS')</script>", "action" => "test_action"})}
      
      result = WebSocketHandler.websocket_handle(frame, state)
      
      # Deve rejeitar a mensagem
      assert match?({:reply, [{:close, 1008, _reason}], _state}, result)
      
      # Verifica se o evento de segurança foi publicado
      assert :meck.called(Deeper_Hub.Core.EventBus, :publish, [
        :security_event,
        :_
      ])
    end
    
    test "rejeita mensagem com SQL Injection", %{state: state} do
      # Cria uma mensagem com SQL Injection
      frame = {:text, Jason.encode!(%{"content" => "DROP TABLE users", "action" => "test_action"})}
      
      result = WebSocketHandler.websocket_handle(frame, state)
      
      # Deve rejeitar a mensagem
      assert match?({:reply, [{:close, 1008, _reason}], _state}, result)
    end
    
    test "rejeita mensagem com Path Traversal", %{state: state} do
      # Cria uma mensagem com Path Traversal
      frame = {:text, Jason.encode!(%{"path" => "../config/config.exs", "action" => "read_file"})}
      
      result = WebSocketHandler.websocket_handle(frame, state)
      
      # Deve rejeitar a mensagem
      assert match?({:reply, [{:close, 1008, _reason}], _state}, result)
    end
  end
  
  describe "Integração com SecurityConfig" do
    test "respeita configurações de recursos habilitados/desabilitados" do
      # Salva configuração original
      original_config = Application.get_env(:deeper_hub, :security, %{})
      
      # Desabilita a proteção XSS
      updated_config = put_in(original_config[:xss][:enabled], false)
      Application.put_env(:deeper_hub, :security, updated_config)
      
      # Verifica que o recurso está desabilitado
      assert SecurityConfig.is_feature_enabled?(:xss) == false
      
      # Restaura configuração
      Application.put_env(:deeper_hub, :security, original_config)
    end
  end
end
