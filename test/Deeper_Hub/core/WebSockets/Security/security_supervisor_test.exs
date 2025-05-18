defmodule Deeper_Hub.Core.WebSockets.Security.SecuritySupervisorTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.SecuritySupervisor
  # Aliases necessários para os testes
  alias Deeper_Hub.Core.WebSockets.Security.SecuritySupervisor
  
  setup do
    %{
      req: %{},
      state: %{user_id: "test_user"},
      message: %{"content" => "Hello, world!", "action" => "test_action"}
    }
  end
  
  describe "start_link/1" do
    test "verifica se o supervisor está rodando" do
      # Tenta obter o PID do supervisor se já estiver rodando
      pid = Process.whereis(SecuritySupervisor)
      
      if pid do
        # Se o supervisor já está rodando, apenas verifica que está vivo
        assert Process.alive?(pid)
      else
        # Se não está rodando, tenta iniciá-lo
        assert {:ok, new_pid} = SecuritySupervisor.start_link([])
        assert Process.alive?(new_pid)
        assert :ok = Supervisor.stop(new_pid)
      end
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
    test "a função existe", %{req: _req, state: _state} do
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
