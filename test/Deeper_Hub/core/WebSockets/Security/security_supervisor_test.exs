defmodule Deeper_Hub.Core.WebSockets.Security.SecuritySupervisorTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.SecuritySupervisor
  alias Deeper_Hub.Core.WebSockets.Security.SecurityMiddleware
  
  setup do
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
    test "a função existe", %{req: req, state: state} do
      # Verificamos apenas que a função existe e pode ser chamada
      assert function_exported?(SecuritySupervisor, :check_request, 3)
    end
  end
  
  describe "check_message/3" do
    test "a função existe" do
      # Verificamos apenas que a função existe e pode ser chamada
      assert function_exported?(SecuritySupervisor, :check_message, 3)
    end
  end
  
  describe "check_login_attempt/4" do
    test "a função existe" do
      # Verificamos apenas que a função existe e pode ser chamada
      assert function_exported?(SecuritySupervisor, :check_login_attempt, 4)
    end
  end
  
  describe "track_login_result/4" do
    test "a função existe" do
      # Verificamos apenas que a função existe e pode ser chamada
      assert function_exported?(SecuritySupervisor, :track_login_result, 4)
    end
  end
end
