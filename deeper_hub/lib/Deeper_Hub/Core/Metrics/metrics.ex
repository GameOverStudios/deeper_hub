defmodule Deeper_Hub.Core.Metrics do
  @moduledoc """
  Módulo para gerenciamento de métricas de desempenho usando Telemetry.
  
  Este módulo define as métricas a serem coletadas e fornece funções para
  emitir eventos de telemetria em pontos estratégicos da aplicação.
  """
  
  require Logger
  alias Telemetry.Metrics
  
  @doc """
  Define as métricas a serem coletadas pela aplicação.
  
  ## Retorno
  
    - Lista de métricas definidas
  """
  def metrics do
    [
      # Métricas de banco de dados
      Metrics.counter(
        "deeper_hub.database.query.count",
        description: "Número total de consultas executadas"
      ),
      Metrics.distribution(
        "deeper_hub.database.query.duration",
        unit: {:native, :millisecond},
        description: "Distribuição do tempo de execução das consultas",
        reporter_options: [
          buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000]
        ]
      ),
      Metrics.sum(
        "deeper_hub.database.query.rows",
        description: "Número total de linhas retornadas pelas consultas"
      ),
      
      # Métricas de cache
      Metrics.counter(
        "deeper_hub.cache.hit",
        description: "Número de acertos no cache"
      ),
      Metrics.counter(
        "deeper_hub.cache.miss",
        description: "Número de falhas no cache"
      ),
      Metrics.last_value(
        "deeper_hub.cache.size",
        description: "Tamanho atual do cache (número de entradas)"
      ),
      Metrics.last_value(
        "deeper_hub.cache.hits",
        description: "Número total de acertos no cache"
      ),
      Metrics.last_value(
        "deeper_hub.cache.misses",
        description: "Número total de falhas no cache"
      ),
      Metrics.last_value(
        "deeper_hub.cache.hit_rate",
        description: "Taxa de acertos no cache (percentual)"
      ),
      
      # Métricas de conexão
      Metrics.counter(
        "deeper_hub.database.connection.count",
        description: "Número de conexões estabelecidas com o banco de dados"
      ),
      Metrics.sum(
        "deeper_hub.database.connection.idle_time",
        unit: {:native, :millisecond},
        description: "Tempo total em que as conexões ficaram ociosas"
      ),
      
      # Métricas de transação
      Metrics.counter(
        "deeper_hub.database.transaction.count",
        description: "Número total de transações executadas"
      ),
      Metrics.distribution(
        "deeper_hub.database.transaction.duration",
        unit: {:native, :millisecond},
        description: "Distribuição do tempo de execução das transações",
        reporter_options: [
          buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000]
        ]
      ),
      
      # Métricas de VM
      Metrics.last_value(
        "vm.memory.total",
        unit: :byte,
        description: "Memória total alocada pela VM Erlang"
      ),
      Metrics.last_value(
        "vm.total_run_queue_lengths",
        description: "Tamanho total das filas de execução"
      ),
      Metrics.last_value(
        "vm.system_counts",
        description: "Contagens de processos e portas do sistema"
      )
    ]
  end
  
  @doc """
  Emite um evento de telemetria para o início de uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
  """
  def start_query(query, params) do
    start_time = System.monotonic_time()
    
    # Armazena o tempo de início no processo atual
    Process.put(:deeper_hub_query_start_time, start_time)
    
    :telemetry.execute(
      [:deeper_hub, :database, :query, :start],
      %{system_time: System.system_time()},
      %{query: query, params: params}
    )
  end
  
  @doc """
  Emite um evento de telemetria para o fim de uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `result`: Resultado da consulta
  """
  def stop_query(query, params, result) do
    case Process.get(:deeper_hub_query_start_time) do
      nil ->
        Logger.warning("Tentativa de parar medição de consulta sem início registrado", %{
          query: query,
          params: params
        })
      
      start_time ->
        # Remove o tempo de início do processo atual
        Process.delete(:deeper_hub_query_start_time)
        
        # Calcula a duração da consulta
        duration = System.monotonic_time() - start_time
        
        # Determina o número de linhas retornadas (se aplicável)
        rows = case result do
          {:ok, %{rows: rows}} when is_list(rows) -> length(rows)
          _ -> 0
        end
        
        # Emite o evento de fim de consulta
        :telemetry.execute(
          [:deeper_hub, :database, :query, :stop],
          %{
            duration: duration,
            rows: rows
          },
          %{
            query: query,
            params: params,
            result: result
          }
        )
        
        # Incrementa o contador de consultas
        :telemetry.execute(
          [:deeper_hub, :database, :query, :count],
          %{count: 1},
          %{query: query}
        )
    end
  end
  
  @doc """
  Emite um evento de telemetria para um acerto no cache.
  
  ## Parâmetros
  
    - `key`: A chave do cache
  """
  def cache_hit(key) do
    :telemetry.execute(
      [:deeper_hub, :cache, :hit],
      %{count: 1},
      %{key: key}
    )
  end
  
  @doc """
  Emite um evento de telemetria para uma falha no cache.
  
  ## Parâmetros
  
    - `key`: A chave do cache
  """
  def cache_miss(key) do
    :telemetry.execute(
      [:deeper_hub, :cache, :miss],
      %{count: 1},
      %{key: key}
    )
  end
  
  @doc """
  Emite um evento de telemetria para o tamanho atual do cache.
  
  ## Parâmetros
  
    - `size`: O tamanho do cache (número de entradas)
  """
  def cache_size(size), do: :telemetry.execute([:deeper_hub, :cache, :size], %{value: size}, %{})
  def cache_hits(hits), do: :telemetry.execute([:deeper_hub, :cache, :hits], %{value: hits}, %{})
  def cache_misses(misses), do: :telemetry.execute([:deeper_hub, :cache, :misses], %{value: misses}, %{})
  def cache_hit_rate(rate), do: :telemetry.execute([:deeper_hub, :cache, :hit_rate], %{value: rate}, %{})
  
  @doc """
  Emite um evento de telemetria para o início de uma transação.
  """
  def start_transaction do
    start_time = System.monotonic_time()
    
    # Armazena o tempo de início no processo atual
    Process.put(:deeper_hub_transaction_start_time, start_time)
    
    :telemetry.execute(
      [:deeper_hub, :database, :transaction, :start],
      %{system_time: System.system_time()},
      %{}
    )
  end
  
  @doc """
  Emite um evento de telemetria para o fim de uma transação.
  
  ## Parâmetros
  
    - `result`: Resultado da transação (:commit ou :rollback)
  """
  def stop_transaction(result) do
    case Process.get(:deeper_hub_transaction_start_time) do
      nil ->
        Logger.warning("Tentativa de parar medição de transação sem início registrado")
      
      start_time ->
        # Remove o tempo de início do processo atual
        Process.delete(:deeper_hub_transaction_start_time)
        
        # Calcula a duração da transação
        duration = System.monotonic_time() - start_time
        
        # Emite o evento de fim de transação
        :telemetry.execute(
          [:deeper_hub, :database, :transaction, :stop],
          %{duration: duration},
          %{result: result}
        )
        
        # Incrementa o contador de transações
        :telemetry.execute(
          [:deeper_hub, :database, :transaction, :count],
          %{count: 1},
          %{result: result}
        )
    end
  end
end
