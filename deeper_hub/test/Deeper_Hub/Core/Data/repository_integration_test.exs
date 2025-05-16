defmodule Deeper_Hub.Core.Data.RepositoryIntegrationTest do
  use ExUnit.Case, async: false
  
  alias Deeper_Hub.Core.Data.RepositoryIntegration
  alias Deeper_Hub.Core.Data.RepositoryTelemetry
  alias Deeper_Hub.Core.Data.RepositoryCache
  alias Deeper_Hub.Core.Data.RepositoryCircuitBreaker
  alias Deeper_Hub.Core.Data.RepositoryMetrics
  alias Deeper_Hub.Core.Cache.CacheFacade, as: Cache
  
  # Define schemas de teste
  defmodule TestSchema do
  end
  
  defmodule AnotherTestSchema do
  end
  
  # Configura o ambiente de teste
  setup do
    # Mock dos módulos de componentes
    :meck.new(RepositoryTelemetry, [:passthrough])
    :meck.new(RepositoryCache, [:passthrough])
    :meck.new(RepositoryCircuitBreaker, [:passthrough])
    :meck.new(RepositoryMetrics, [:passthrough])
    
    # Mock das funções de setup
    :meck.expect(RepositoryTelemetry, :setup, fn -> :ok end)
    :meck.expect(RepositoryCache, :setup, fn _schemas -> :ok end)
    :meck.expect(RepositoryCircuitBreaker, :setup, fn _schemas -> :ok end)
    :meck.expect(RepositoryMetrics, :setup, fn -> :ok end)
    
    # Mock das funções de invalidação e reset
    :meck.expect(RepositoryCache, :invalidate_schema, fn _schema -> :ok end)
    :meck.expect(RepositoryCircuitBreaker, :reset, fn _schema -> :ok end)
    
    # Mock do Cache para get_status
    :meck.new(Cache, [:passthrough])
    :meck.expect(Cache, :size, fn namespace -> 
      cond do
        String.ends_with?(namespace, ":records") -> {:ok, 10}
        String.ends_with?(namespace, ":queries") -> {:ok, 5}
        true -> {:ok, 0}
      end
    end)
    
    # Mock do CircuitBreaker para get_status
    :meck.expect(RepositoryCircuitBreaker, :get_read_state, fn _schema -> :closed end)
    :meck.expect(RepositoryCircuitBreaker, :get_write_state, fn _schema -> :closed end)
    
    on_exit(fn ->
      :meck.unload(RepositoryTelemetry)
      :meck.unload(RepositoryCache)
      :meck.unload(RepositoryCircuitBreaker)
      :meck.unload(RepositoryMetrics)
      :meck.unload(Cache)
    end)
    
    :ok
  end
  
  describe "setup/1" do
    test "inicializa todos os componentes do repositório" do
      # Define schemas de teste
      schemas = [TestSchema, AnotherTestSchema]
      
      # Executa a função de setup
      assert :ok = RepositoryIntegration.setup(schemas)
      
      # Verifica se as funções de setup foram chamadas com os parâmetros corretos
      assert :meck.called(RepositoryTelemetry, :setup, [])
      assert :meck.called(RepositoryMetrics, :setup, [])
      assert :meck.called(RepositoryCache, :setup, [schemas])
      assert :meck.called(RepositoryCircuitBreaker, :setup, [schemas])
    end
  end
  
  describe "restart/1" do
    test "reinicia todos os componentes do repositório" do
      # Define schemas de teste
      schemas = [TestSchema, AnotherTestSchema]
      
      # Executa a função de restart
      assert :ok = RepositoryIntegration.restart(schemas)
      
      # Verifica se as funções de invalidação e reset foram chamadas para cada schema
      Enum.each(schemas, fn schema ->
        assert :meck.called(RepositoryCache, :invalidate_schema, [schema])
        assert :meck.called(RepositoryCircuitBreaker, :reset, [schema])
      end)
      
      # Verifica se a telemetria foi reinicializada
      assert :meck.called(RepositoryTelemetry, :setup, [])
    end
  end
  
  describe "get_status/1" do
    test "retorna o estado atual de todos os componentes" do
      # Define um schema de teste
      schema = TestSchema
      
      # Obtém o status
      status = RepositoryIntegration.get_status(schema)
      
      # Verifica se o status contém todas as informações esperadas
      assert status.schema == schema
      
      # Verifica o estado do circuit breaker
      assert status.circuit_breaker.read == :closed
      assert status.circuit_breaker.write == :closed
      
      # Verifica o tamanho do cache
      assert status.cache.records == 10
      assert status.cache.queries == 5
      assert status.cache.total == 15
      
      # Verifica se as funções corretas foram chamadas
      assert :meck.called(RepositoryCircuitBreaker, :get_read_state, [schema])
      assert :meck.called(RepositoryCircuitBreaker, :get_write_state, [schema])
      assert :meck.called(Cache, :size, ["repository:TestSchema:records"])
      assert :meck.called(Cache, :size, ["repository:TestSchema:queries"])
    end
  end
end
