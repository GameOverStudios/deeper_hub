defmodule Deeper_Hub.Core.Data.RepositoryCircuitBreakerTest do
  use ExUnit.Case, async: false
  
  alias Deeper_Hub.Core.Data.RepositoryCircuitBreaker
  alias Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade, as: CircuitBreaker
  
  # Define um schema de teste
  defmodule TestSchema do
  end
  
  # Configura o ambiente de teste
  setup do
    # Remove os circuit breakers existentes antes de cada teste
    CircuitBreaker.unregister("repository:TestSchema:read")
    CircuitBreaker.unregister("repository:TestSchema:write")
    
    # Configura circuit breakers com valores específicos para teste
    Application.put_env(:deeper_hub, Deeper_Hub.Core.Data.RepositoryCircuitBreaker, [
      max_failures: 3,
      reset_timeout: 1_000,  # 1 segundo para facilitar os testes
      half_open_threshold: 1
    ])
    
    on_exit(fn ->
      # Limpa a configuração após os testes
      Application.delete_env(:deeper_hub, Deeper_Hub.Core.Data.RepositoryCircuitBreaker)
    end)
    
    :ok
  end
  
  describe "setup/1" do
    test "inicializa os circuit breakers para os schemas fornecidos" do
      # Executa a função de setup
      RepositoryCircuitBreaker.setup([TestSchema])
      
      # Verifica se os circuit breakers foram registrados
      assert CircuitBreaker.exists?("repository:TestSchema:read")
      assert CircuitBreaker.exists?("repository:TestSchema:write")
      
      # Verifica o estado inicial dos circuit breakers
      assert CircuitBreaker.get_state("repository:TestSchema:read") == :closed
      assert CircuitBreaker.get_state("repository:TestSchema:write") == :closed
    end
  end
  
  describe "run_read_protected/3" do
    test "executa função protegida com sucesso" do
      # Inicializa os circuit breakers
      RepositoryCircuitBreaker.setup([TestSchema])
      
      # Define uma função de sucesso
      success_fun = fn -> {:ok, %{id: 123, name: "Test"}} end
      
      # Executa a função protegida
      assert {:ok, %{id: 123, name: "Test"}} = 
        RepositoryCircuitBreaker.run_read_protected(TestSchema, success_fun)
      
      # Verifica se o circuit breaker permanece fechado
      assert RepositoryCircuitBreaker.get_read_state(TestSchema) == :closed
    end
    
    test "trata falhas e abre o circuit breaker após múltiplas falhas" do
      # Inicializa os circuit breakers
      RepositoryCircuitBreaker.setup([TestSchema])
      
      # Define uma função que falha
      failure_fun = fn -> {:error, :database_error} end
      
      # Executa a função protegida várias vezes para abrir o circuit breaker
      for _ <- 1..3 do
        assert {:error, :database_error} = 
          RepositoryCircuitBreaker.run_read_protected(TestSchema, failure_fun)
      end
      
      # Verifica se o circuit breaker foi aberto
      assert RepositoryCircuitBreaker.get_read_state(TestSchema) == :open
      
      # Tenta executar novamente com o circuit breaker aberto
      assert {:error, :circuit_open} = 
        RepositoryCircuitBreaker.run_read_protected(TestSchema, failure_fun)
    end
    
    test "usa função de fallback quando o circuit breaker está aberto" do
      # Inicializa os circuit breakers
      RepositoryCircuitBreaker.setup([TestSchema])
      
      # Define uma função que falha e uma função de fallback
      failure_fun = fn -> {:error, :database_error} end
      fallback_fun = fn -> {:ok, %{id: 123, name: "Fallback"}} end
      
      # Executa a função protegida várias vezes para abrir o circuit breaker
      for _ <- 1..3 do
        RepositoryCircuitBreaker.run_read_protected(TestSchema, failure_fun)
      end
      
      # Verifica se o circuit breaker foi aberto
      assert RepositoryCircuitBreaker.get_read_state(TestSchema) == :open
      
      # Executa com o circuit breaker aberto, usando a função de fallback
      assert {:ok, %{id: 123, name: "Fallback"}} = 
        RepositoryCircuitBreaker.run_read_protected(TestSchema, failure_fun, fallback_fun)
    end
  end
  
  describe "run_write_protected/3" do
    test "executa função protegida com sucesso" do
      # Inicializa os circuit breakers
      RepositoryCircuitBreaker.setup([TestSchema])
      
      # Define uma função de sucesso
      success_fun = fn -> {:ok, %{id: 123, name: "Test"}} end
      
      # Executa a função protegida
      assert {:ok, %{id: 123, name: "Test"}} = 
        RepositoryCircuitBreaker.run_write_protected(TestSchema, success_fun)
      
      # Verifica se o circuit breaker permanece fechado
      assert RepositoryCircuitBreaker.get_write_state(TestSchema) == :closed
    end
    
    test "trata falhas e abre o circuit breaker após múltiplas falhas" do
      # Inicializa os circuit breakers
      RepositoryCircuitBreaker.setup([TestSchema])
      
      # Define uma função que falha
      failure_fun = fn -> {:error, :database_error} end
      
      # Executa a função protegida várias vezes para abrir o circuit breaker
      for _ <- 1..3 do
        assert {:error, :database_error} = 
          RepositoryCircuitBreaker.run_write_protected(TestSchema, failure_fun)
      end
      
      # Verifica se o circuit breaker foi aberto
      assert RepositoryCircuitBreaker.get_write_state(TestSchema) == :open
      
      # Tenta executar novamente com o circuit breaker aberto
      assert {:error, :circuit_open} = 
        RepositoryCircuitBreaker.run_write_protected(TestSchema, failure_fun)
    end
  end
  
  describe "reset/1" do
    test "reseta os circuit breakers para um schema específico" do
      # Inicializa os circuit breakers
      RepositoryCircuitBreaker.setup([TestSchema])
      
      # Define uma função que falha
      failure_fun = fn -> {:error, :database_error} end
      
      # Executa a função protegida várias vezes para abrir os circuit breakers
      for _ <- 1..3 do
        RepositoryCircuitBreaker.run_read_protected(TestSchema, failure_fun)
        RepositoryCircuitBreaker.run_write_protected(TestSchema, failure_fun)
      end
      
      # Verifica se os circuit breakers foram abertos
      assert RepositoryCircuitBreaker.get_read_state(TestSchema) == :open
      assert RepositoryCircuitBreaker.get_write_state(TestSchema) == :open
      
      # Reseta os circuit breakers
      RepositoryCircuitBreaker.reset(TestSchema)
      
      # Verifica se os circuit breakers foram fechados
      assert RepositoryCircuitBreaker.get_read_state(TestSchema) == :closed
      assert RepositoryCircuitBreaker.get_write_state(TestSchema) == :closed
    end
  end
  
  describe "circuit_state_change_callback/2" do
    test "processa mudanças de estado do circuit breaker" do
      # Inicializa os circuit breakers
      RepositoryCircuitBreaker.setup([TestSchema])
      
      # Chama o callback diretamente
      RepositoryCircuitBreaker.circuit_state_change_callback(
        "repository:TestSchema:read", 
        :open
      )
      
      # Como o callback apenas registra logs e métricas, não há como verificar
      # diretamente seu comportamento sem mockar essas dependências.
      # Em um teste real, você poderia usar mocks para verificar se as funções
      # de log e métricas foram chamadas corretamente.
      
      # Este teste serve principalmente para garantir que o callback não lança exceções
    end
  end
  
  describe "get_read_state/1 e get_write_state/1" do
    test "retorna o estado atual dos circuit breakers" do
      # Inicializa os circuit breakers
      RepositoryCircuitBreaker.setup([TestSchema])
      
      # Verifica o estado inicial
      assert RepositoryCircuitBreaker.get_read_state(TestSchema) == :closed
      assert RepositoryCircuitBreaker.get_write_state(TestSchema) == :closed
      
      # Altera o estado manualmente para teste
      CircuitBreaker.set_state("repository:TestSchema:read", :open)
      CircuitBreaker.set_state("repository:TestSchema:write", :half_open)
      
      # Verifica se os estados foram atualizados
      assert RepositoryCircuitBreaker.get_read_state(TestSchema) == :open
      assert RepositoryCircuitBreaker.get_write_state(TestSchema) == :half_open
    end
  end
end
