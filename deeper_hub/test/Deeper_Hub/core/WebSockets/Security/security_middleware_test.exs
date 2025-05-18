defmodule Deeper_Hub.Core.WebSockets.Security.SecurityMiddlewareTest do
  use ExUnit.Case

  alias Deeper_Hub.Core.WebSockets.Security.SecurityMiddleware
  # Apenas o alias necessário para os testes
  alias Deeper_Hub.Core.WebSockets.Security.SecurityMiddleware

  setup do
    %{
      req: %{},
      state: %{user_id: "test_user", account_id: "acc_123"},
      message: %{"content" => "Hello, world!", "action" => "test_action"}
    }
  end

  describe "check_request/3" do
    test "middleware de segurança existe", %{req: _req, state: _state} do
      # Verificamos apenas que o módulo existe e pode ser chamado
      assert function_exported?(SecurityMiddleware, :check_request, 2)
    end
  end

  describe "check_message/3" do
    test "middleware de mensagens existe" do
      # Verificamos apenas que o módulo existe e pode ser chamado
      assert function_exported?(SecurityMiddleware, :check_message, 2)
    end
  end

  describe "login_security" do
    test "middleware de login existe" do
      # Verificamos apenas que os módulos existem e podem ser chamados
      assert function_exported?(SecurityMiddleware, :check_login_attempt, 4)
      assert function_exported?(SecurityMiddleware, :track_login_result, 4)
    end
  end
end
