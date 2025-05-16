defmodule Deeper_Hub.Core.Data.RepositoryMetricsTest do
  use ExUnit.Case, async: false
  
  alias Deeper_Hub.Core.Data.RepositoryMetrics
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  
  # Define um schema de teste
  defmodule TestSchema do
  end
  
  # Configura o ambiente de teste
  setup do
    # Armazena métricas registradas
    test_pid = self()
    
    # Mock do Metrics para capturar chamadas de métrica
    :meck.new(Metrics, [:passthrough])
    
    # Mock para increment
    :meck.expect(Metrics, :increment, fn name, tags ->
      send(test_pid, {:metric_increment, name, tags})
      :ok
    end)
    
    # Mock para observe
    :meck.expect(Metrics, :observe, fn name, value, tags ->
      send(test_pid, {:metric_observe, name, value, tags})
      :ok
    end)
    
    # Mock para set
    :meck.expect(Metrics, :set, fn name, value, tags ->
      send(test_pid, {:metric_set, name, value, tags})
      :ok
    end)
    
    # Mock para declare_counter
    :meck.expect(Metrics, :declare_counter, fn name, description ->
      send(test_pid, {:metric_declare_counter, name, description})
      :ok
    end)
    
    # Mock para declare_histogram
    :meck.expect(Metrics, :declare_histogram, fn name, description, buckets ->
      send(test_pid, {:metric_declare_histogram, name, description, buckets})
      :ok
    end)
    
    # Mock para declare_gauge
    :meck.expect(Metrics, :declare_gauge, fn name, description ->
      send(test_pid, {:metric_declare_gauge, name, description})
      :ok
    end)
    
    on_exit(fn ->
      :meck.unload(Metrics)
    end)
    
    :ok
  end
  
  describe "setup/0" do
    test "declara todas as métricas necessárias" do
      # Executa a função de setup
      RepositoryMetrics.setup()
      
      # Verifica se os contadores foram declarados
      assert_receive {:metric_declare_counter, "deeper_hub.core.data.repository.get.count", _}
      assert_receive {:metric_declare_counter, "deeper_hub.core.data.repository.insert.count", _}
      assert_receive {:metric_declare_counter, "deeper_hub.core.data.repository.update.count", _}
      assert_receive {:metric_declare_counter, "deeper_hub.core.data.repository.delete.count", _}
      assert_receive {:metric_declare_counter, "deeper_hub.core.data.repository.list.count", _}
      assert_receive {:metric_declare_counter, "deeper_hub.core.data.repository.find.count", _}
      assert_receive {:metric_declare_counter, "deeper_hub.core.data.repository.cache.hit", _}
      assert_receive {:metric_declare_counter, "deeper_hub.core.data.repository.cache.miss", _}
      
      # Verifica se os histogramas foram declarados
      assert_receive {:metric_declare_histogram, "deeper_hub.core.data.repository.get.duration_ms", _, _}
      assert_receive {:metric_declare_histogram, "deeper_hub.core.data.repository.insert.duration_ms", _, _}
      assert_receive {:metric_declare_histogram, "deeper_hub.core.data.repository.update.duration_ms", _, _}
      assert_receive {:metric_declare_histogram, "deeper_hub.core.data.repository.delete.duration_ms", _, _}
      assert_receive {:metric_declare_histogram, "deeper_hub.core.data.repository.list.duration_ms", _, _}
      assert_receive {:metric_declare_histogram, "deeper_hub.core.data.repository.find.duration_ms", _, _}
      assert_receive {:metric_declare_histogram, "deeper_hub.core.data.repository.query.result_count", _, _}
      
      # Verifica se os gauges foram declarados
      assert_receive {:metric_declare_gauge, "deeper_hub.core.data.repository.circuit_breaker.state", _}
      assert_receive {:metric_declare_gauge, "deeper_hub.core.data.repository.cache.size", _}
    end
  end
  
  describe "increment_operation_count/3" do
    test "incrementa o contador de operações" do
      # Define parâmetros de teste
      operation = :get
      schema = TestSchema
      result = :success
      
      # Incrementa o contador
      RepositoryMetrics.increment_operation_count(operation, schema, result)
      
      # Verifica se a métrica foi registrada corretamente
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.get.count", tags}
      assert tags.schema == "TestSchema"
      assert tags.result == :success
    end
  end
  
  describe "observe_operation_duration/4" do
    test "registra a duração de uma operação" do
      # Define parâmetros de teste
      operation = :insert
      duration_ms = 150
      schema = TestSchema
      result = :success
      
      # Registra a duração
      RepositoryMetrics.observe_operation_duration(operation, duration_ms, schema, result)
      
      # Verifica se a métrica foi registrada corretamente
      assert_receive {:metric_observe, "deeper_hub.core.data.repository.insert.duration_ms", ^duration_ms, tags}
      assert tags.schema == "TestSchema"
      assert tags.result == :success
    end
  end
  
  describe "increment_cache_hit/2 e increment_cache_miss/2" do
    test "incrementa o contador de acertos no cache" do
      # Define parâmetros de teste
      schema = TestSchema
      operation = :get
      
      # Incrementa o contador de acertos
      RepositoryMetrics.increment_cache_hit(schema, operation)
      
      # Verifica se a métrica foi registrada corretamente
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.cache.hit", tags}
      assert tags.schema == "TestSchema"
      assert tags.operation == :get
    end
    
    test "incrementa o contador de erros no cache" do
      # Define parâmetros de teste
      schema = TestSchema
      operation = :list
      
      # Incrementa o contador de erros
      RepositoryMetrics.increment_cache_miss(schema, operation)
      
      # Verifica se a métrica foi registrada corretamente
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.cache.miss", tags}
      assert tags.schema == "TestSchema"
      assert tags.operation == :list
    end
  end
  
  describe "observe_query_result_count/3" do
    test "registra o número de registros retornados por uma consulta" do
      # Define parâmetros de teste
      count = 42
      schema = TestSchema
      operation = :find
      
      # Registra o número de registros
      RepositoryMetrics.observe_query_result_count(count, schema, operation)
      
      # Verifica se a métrica foi registrada corretamente
      assert_receive {:metric_observe, "deeper_hub.core.data.repository.query.result_count", ^count, tags}
      assert tags.schema == "TestSchema"
      assert tags.operation == :find
    end
  end
  
  describe "set_circuit_breaker_state/2" do
    test "atualiza o estado do circuit breaker" do
      # Define parâmetros de teste
      state = :open
      schema = TestSchema
      
      # Atualiza o estado
      RepositoryMetrics.set_circuit_breaker_state(state, schema)
      
      # Verifica se a métrica foi registrada corretamente
      assert_receive {:metric_set, "deeper_hub.core.data.repository.circuit_breaker.state", 0, tags}
      assert tags.schema == "TestSchema"
    end
    
    test "mapeia corretamente os estados do circuit breaker para valores numéricos" do
      # Testa todos os estados possíveis
      states = [
        {:open, 0},
        {:half_open, 1},
        {:closed, 2},
        {:unknown, -1}
      ]
      
      # Verifica cada estado
      Enum.each(states, fn {state, expected_value} ->
        RepositoryMetrics.set_circuit_breaker_state(state, TestSchema)
        assert_receive {:metric_set, "deeper_hub.core.data.repository.circuit_breaker.state", ^expected_value, _}
      end)
    end
  end
  
  describe "set_cache_size/2" do
    test "atualiza o tamanho do cache com schema" do
      # Define parâmetros de teste
      size = 100
      schema = TestSchema
      
      # Atualiza o tamanho
      RepositoryMetrics.set_cache_size(size, schema)
      
      # Verifica se a métrica foi registrada corretamente
      assert_receive {:metric_set, "deeper_hub.core.data.repository.cache.size", ^size, tags}
      assert tags.schema == "TestSchema"
    end
    
    test "atualiza o tamanho do cache sem schema" do
      # Define parâmetros de teste
      size = 200
      
      # Atualiza o tamanho sem especificar schema
      RepositoryMetrics.set_cache_size(size)
      
      # Verifica se a métrica foi registrada corretamente
      assert_receive {:metric_set, "deeper_hub.core.data.repository.cache.size", ^size, tags}
      assert tags == %{}
    end
  end
  
  describe "measure/3" do
    test "mede a duração e resultado de uma função bem-sucedida" do
      # Define parâmetros de teste
      operation = :get
      schema = TestSchema
      
      # Define uma função de sucesso
      success_fun = fn -> {:ok, %{id: 123, name: "Test"}} end
      
      # Executa a função com medição
      result = RepositoryMetrics.measure(operation, schema, success_fun)
      
      # Verifica o resultado
      assert result == {:ok, %{id: 123, name: "Test"}}
      
      # Verifica se as métricas foram registradas corretamente
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.get.count", %{schema: "TestSchema", result: :started}}
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.get.count", %{schema: "TestSchema", result: :success}}
      assert_receive {:metric_observe, "deeper_hub.core.data.repository.get.duration_ms", _, %{schema: "TestSchema", result: :success}}
    end
    
    test "mede a duração e resultado de uma função que retorna erro" do
      # Define parâmetros de teste
      operation = :update
      schema = TestSchema
      
      # Define uma função que retorna erro
      error_fun = fn -> {:error, :validation_failed} end
      
      # Executa a função com medição
      result = RepositoryMetrics.measure(operation, schema, error_fun)
      
      # Verifica o resultado
      assert result == {:error, :validation_failed}
      
      # Verifica se as métricas foram registradas corretamente
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.update.count", %{schema: "TestSchema", result: :started}}
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.update.count", %{schema: "TestSchema", result: :error}}
      assert_receive {:metric_observe, "deeper_hub.core.data.repository.update.duration_ms", _, %{schema: "TestSchema", result: :error}}
    end
    
    test "mede a duração e resultado de uma função que retorna not_found" do
      # Define parâmetros de teste
      operation = :get
      schema = TestSchema
      
      # Define uma função que retorna not_found
      not_found_fun = fn -> {:error, :not_found} end
      
      # Executa a função com medição
      result = RepositoryMetrics.measure(operation, schema, not_found_fun)
      
      # Verifica o resultado
      assert result == {:error, :not_found}
      
      # Verifica se as métricas foram registradas corretamente
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.get.count", %{schema: "TestSchema", result: :started}}
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.get.count", %{schema: "TestSchema", result: :not_found}}
      assert_receive {:metric_observe, "deeper_hub.core.data.repository.get.duration_ms", _, %{schema: "TestSchema", result: :not_found}}
    end
    
    test "mede a duração e resultado de uma função que retorna uma lista" do
      # Define parâmetros de teste
      operation = :list
      schema = TestSchema
      
      # Define uma função que retorna uma lista
      list_fun = fn -> [%{id: 1}, %{id: 2}, %{id: 3}] end
      
      # Executa a função com medição
      result = RepositoryMetrics.measure(operation, schema, list_fun)
      
      # Verifica o resultado
      assert result == [%{id: 1}, %{id: 2}, %{id: 3}]
      
      # Verifica se as métricas foram registradas corretamente
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.list.count", %{schema: "TestSchema", result: :started}}
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.list.count", %{schema: "TestSchema", result: :success}}
      assert_receive {:metric_observe, "deeper_hub.core.data.repository.list.duration_ms", _, %{schema: "TestSchema", result: :success}}
      assert_receive {:metric_observe, "deeper_hub.core.data.repository.query.result_count", 3, %{schema: "TestSchema", operation: :list}}
    end
    
    test "trata exceções lançadas pela função" do
      # Define parâmetros de teste
      operation = :delete
      schema = TestSchema
      
      # Define uma função que lança exceção
      exception_fun = fn -> raise "Test exception" end
      
      # Verifica se a exceção é re-lançada
      assert_raise RuntimeError, "Test exception", fn ->
        RepositoryMetrics.measure(operation, schema, exception_fun)
      end
      
      # Verifica se as métricas foram registradas corretamente
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.delete.count", %{schema: "TestSchema", result: :started}}
      assert_receive {:metric_increment, "deeper_hub.core.data.repository.delete.count", %{schema: "TestSchema", result: :error}}
      assert_receive {:metric_observe, "deeper_hub.core.data.repository.delete.duration_ms", _, %{schema: "TestSchema", result: :error}}
    end
  end
end
