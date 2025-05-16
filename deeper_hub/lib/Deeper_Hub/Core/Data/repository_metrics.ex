defmodule Deeper_Hub.Core.Data.RepositoryMetrics do
  @moduledoc """
  Módulo de métricas para operações de repositório.
  
  Este módulo centraliza todas as métricas relacionadas às operações
  de banco de dados, facilitando o monitoramento e a observabilidade do sistema.
  
  ## Métricas Disponíveis
  
  ### Contadores
  
  - `deeper_hub.core.data.repository.{operation}.count` - Número de operações por tipo
  - `deeper_hub.core.data.repository.{operation}.success` - Número de operações bem-sucedidas
  - `deeper_hub.core.data.repository.{operation}.error` - Número de operações com erro
  - `deeper_hub.core.data.repository.cache.hit` - Número de acertos no cache
  - `deeper_hub.core.data.repository.cache.miss` - Número de erros no cache
  
  ### Histogramas
  
  - `deeper_hub.core.data.repository.{operation}.duration_ms` - Duração das operações
  - `deeper_hub.core.data.repository.query.result_count` - Número de registros retornados
  
  ### Gauges
  
  - `deeper_hub.core.data.repository.circuit_breaker.state` - Estado do circuit breaker
  - `deeper_hub.core.data.repository.cache.size` - Tamanho do cache
  
  ## Tags
  
  Todas as métricas incluem as seguintes tags:
  
  - `schema` - O schema Ecto envolvido na operação
  - `result` - O resultado da operação (success, error, not_found)
  - `operation` - A operação realizada (quando aplicável)
  """
  
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  
  @doc """
  Configura as métricas para operações de repositório.
  
  Esta função deve ser chamada durante a inicialização da aplicação para
  garantir que todas as métricas estejam registradas.
  """
  def setup do
    # Não precisamos declarar métricas explicitamente, pois a MetricsFacade
    # cria métricas dinamicamente quando são usadas pela primeira vez
    
    # Registramos algumas métricas iniciais para garantir que apareçam nos dashboards
    # mesmo antes de serem usadas
    
    # Contadores de operações
    Metrics.increment("deeper_hub.core.data.repository.get.count", %{result: :init}, 0)
    Metrics.increment("deeper_hub.core.data.repository.insert.count", %{result: :init}, 0)
    Metrics.increment("deeper_hub.core.data.repository.update.count", %{result: :init}, 0)
    Metrics.increment("deeper_hub.core.data.repository.delete.count", %{result: :init}, 0)
    Metrics.increment("deeper_hub.core.data.repository.list.count", %{result: :init}, 0)
    Metrics.increment("deeper_hub.core.data.repository.find.count", %{result: :init}, 0)
    
    # Contadores de cache
    Metrics.increment("deeper_hub.core.data.repository.cache.hit", %{operation: :init}, 0)
    Metrics.increment("deeper_hub.core.data.repository.cache.miss", %{operation: :init}, 0)
    
    # Histogramas de duração
    Metrics.histogram("deeper_hub.core.data.repository.get.duration_ms", 0, %{result: :init})
    Metrics.histogram("deeper_hub.core.data.repository.insert.duration_ms", 0, %{result: :init})
    Metrics.histogram("deeper_hub.core.data.repository.update.duration_ms", 0, %{result: :init})
    Metrics.histogram("deeper_hub.core.data.repository.delete.duration_ms", 0, %{result: :init})
    Metrics.histogram("deeper_hub.core.data.repository.list.duration_ms", 0, %{result: :init})
    Metrics.histogram("deeper_hub.core.data.repository.find.duration_ms", 0, %{result: :init})
    
    # Histograma de contagem de resultados
    Metrics.histogram("deeper_hub.core.data.repository.query.result_count", 0, %{operation: :init})
    
    # Gauges
    Metrics.gauge("deeper_hub.core.data.repository.circuit_breaker.state", -1, %{schema: "init"})
    Metrics.gauge("deeper_hub.core.data.repository.cache.size", 0, %{schema: "init"})
    
    :ok
  end
  
  @doc """
  Incrementa o contador de operações.
  
  ## Parâmetros
  
  - `operation` - A operação realizada
  - `schema` - O schema Ecto envolvido na operação
  - `result` - O resultado da operação
  """
  def increment_operation_count(operation, schema, result) do
    Metrics.increment("deeper_hub.core.data.repository.#{operation}.count", %{
      schema: inspect(schema),
      result: result
    })
  end
  
  @doc """
  Registra a duração de uma operação.
  
  ## Parâmetros
  
  - `operation` - A operação realizada
  - `duration_ms` - A duração da operação em milissegundos
  - `schema` - O schema Ecto envolvido na operação
  - `result` - O resultado da operação
  """
  def observe_operation_duration(operation, duration_ms, schema, result) do
    Metrics.histogram("deeper_hub.core.data.repository.#{operation}.duration_ms", duration_ms, %{
      schema: inspect(schema),
      result: result
    })
  end
  
  @doc """
  Incrementa o contador de acertos no cache.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto envolvido na operação
  - `operation` - A operação realizada
  """
  def increment_cache_hit(schema, operation) do
    Metrics.increment("deeper_hub.core.data.repository.cache.hit", %{
      schema: inspect(schema),
      operation: operation
    })
  end
  
  @doc """
  Incrementa o contador de erros no cache.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto envolvido na operação
  - `operation` - A operação realizada
  """
  def increment_cache_miss(schema, operation) do
    Metrics.increment("deeper_hub.core.data.repository.cache.miss", %{
      schema: inspect(schema),
      operation: operation
    })
  end
  
  @doc """
  Registra o número de registros retornados por uma consulta.
  
  ## Parâmetros
  
  - `count` - O número de registros retornados
  - `schema` - O schema Ecto envolvido na operação
  - `operation` - A operação realizada
  """
  def observe_query_result_count(count, schema, operation) do
    Metrics.histogram("deeper_hub.core.data.repository.query.result_count", count, %{
      schema: inspect(schema),
      operation: operation
    })
  end
  
  @doc """
  Atualiza o estado do circuit breaker.
  
  ## Parâmetros
  
  - `state` - O estado do circuit breaker
    - 0: aberto (falhas)
    - 1: meio-aberto (testando)
    - 2: fechado (normal)
  - `schema` - O schema Ecto envolvido na operação
  """
  def set_circuit_breaker_state(state, schema) do
    state_value = case state do
      :open -> 0
      :half_open -> 1
      :closed -> 2
      _ -> -1
    end
    
    Metrics.gauge("deeper_hub.core.data.repository.circuit_breaker.state", state_value, %{
      schema: inspect(schema)
    })
  end
  
  @doc """
  Atualiza o tamanho do cache.
  
  ## Parâmetros
  
  - `size` - O tamanho do cache em número de entradas
  - `schema` - O schema Ecto envolvido na operação (opcional)
  """
  def set_cache_size(size, schema \\ nil) do
    tags = if schema do
      %{schema: inspect(schema)}
    else
      %{}
    end
    
    Metrics.gauge("deeper_hub.core.data.repository.cache.size", size, tags)
  end
  
  @doc """
  Executa uma função e registra métricas de duração e resultado.
  
  ## Parâmetros
  
  - `operation` - A operação realizada
  - `schema` - O schema Ecto envolvido na operação
  - `fun` - A função a ser executada
  
  ## Retorno
  
  Retorna o resultado da função.
  """
  def measure(operation, schema, fun) do
    start_time = System.monotonic_time()
    
    # Incrementa o contador de operações iniciadas
    increment_operation_count(operation, schema, :started)
    
    # Executa a função
    result = try do
      fun.()
    rescue
      e ->
        # Incrementa o contador de operações com erro
        increment_operation_count(operation, schema, :error)
        
        # Calcula a duração
        duration = System.monotonic_time() - start_time
        duration_ms = System.convert_time_unit(duration, :native, :millisecond)
        
        # Registra a duração
        observe_operation_duration(operation, duration_ms, schema, :error)
        
        # Re-lança a exceção
        reraise e, __STACKTRACE__
    end
    
    # Calcula a duração
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    # Determina o resultado
    result_status = case result do
      {:ok, _} -> :success
      {:error, :not_found} -> :not_found
      {:error, _} -> :error
      nil -> :not_found
      _ when is_list(result) -> :success
      _ -> :success
    end
    
    # Incrementa o contador de operações pelo resultado
    increment_operation_count(operation, schema, result_status)
    
    # Registra a duração
    observe_operation_duration(operation, duration_ms, schema, result_status)
    
    # Registra o número de registros para operações de consulta
    if operation in [:list, :find] and result_status == :success do
      count = case result do
        {:ok, records} when is_list(records) -> length(records)
        records when is_list(records) -> length(records)
        _ -> 0
      end
      
      observe_query_result_count(count, schema, operation)
    end
    
    # Retorna o resultado original
    result
  end
end
