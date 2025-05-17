defmodule Deeper_Hub.Core.Metrics.Reporter do
  @moduledoc """
  Módulo para inicialização e gerenciamento dos repórteres de telemetria.
  
  Este módulo é responsável por iniciar os repórteres de telemetria e
  configurar a coleta de métricas da aplicação.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics
  
  @doc """
  Inicia o repórter de telemetria como parte da árvore de supervisão.
  
  ## Retorno
  
    - Especificação para o supervisor
  """
  def child_spec(_opts) do
    # Definimos as métricas a serem coletadas
    metrics = Metrics.metrics()
    
    # Configuramos o repórter de console para exibir as métricas
    children = [
      {
        Telemetry.Metrics.ConsoleReporter,
        metrics: metrics
      }
    ]
    
    # Configuramos o poller para coletar métricas de VM periodicamente
    # Formato correto conforme a documentação oficial
    children = children ++ [
      {:telemetry_poller, 
       measurements: [
         # Medida de memória total (emite evento [vm, memory])
         :memory,
         # Medida de tamanhos de filas (emite evento [vm, total_run_queue_lengths])
         :total_run_queue_lengths,
         # Medida de contadores do sistema (emite eventos para process_count, etc)
         :system_counts,
         # Função para coletar métricas de cache
         {__MODULE__, :collect_cache_metrics, []}
       ], 
       period: 10_000}
    ]
    
    # Retornamos a especificação para o supervisor
    %{
      id: __MODULE__,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]},
      type: :supervisor
    }
  end
  
  # A função vm_measurements foi removida pois agora definimos as medições diretamente na configuração do telemetry_poller
  
  @doc """
  Coleta métricas do cache e emite eventos de telemetria.
  
  Esta função é chamada periodicamente pelo telemetry_poller.
  
  ## Retorno
  
    - `:ok`
  """
  @spec collect_cache_metrics() :: :ok
  def collect_cache_metrics do
    # Obtém estatísticas do cache usando nosso hook personalizado
    case Deeper_Hub.Core.Cache.stats() do
      {:ok, stats} ->
        # Emite eventos de telemetria para as métricas do cache
        Metrics.cache_size(stats[:size] || 0)
        Metrics.cache_hits(stats[:hits] || 0)
        Metrics.cache_misses(stats[:misses] || 0)
        
        # Calcula a taxa de acertos se disponível
        if stats[:hit_rate] do
          Metrics.cache_hit_rate(stats[:hit_rate])
        end
        
        # Registra as estatísticas no log para depuração
        Logger.debug("Estatísticas do cache", %{
          module: __MODULE__,
          stats: stats
        })
      
      {:error, reason} ->
        Logger.error("Erro ao coletar estatísticas do cache", %{
          module: __MODULE__,
          error: reason
        })
    end
    
    # Sempre retorna :ok conforme a especificação
    :ok
  end
  
  @doc """
  Registra handlers para eventos de telemetria específicos da aplicação.
  """
  def setup do
    # Registra handlers para eventos de consulta
    :telemetry.attach(
      "deeper-hub-query-handler",
      [:deeper_hub, :database, :query, :stop],
      &__MODULE__.handle_query_event/4,
      nil
    )
    
    # Registra handlers para eventos de cache
    :telemetry.attach(
      "deeper-hub-cache-handler",
      [:deeper_hub, :cache, :hit],
      &__MODULE__.handle_cache_hit_event/4,
      nil
    )
    
    :telemetry.attach(
      "deeper-hub-cache-miss-handler",
      [:deeper_hub, :cache, :miss],
      &__MODULE__.handle_cache_miss_event/4,
      nil
    )
    
    # Registra handlers para eventos de transação
    :telemetry.attach(
      "deeper-hub-transaction-handler",
      [:deeper_hub, :database, :transaction, :stop],
      &__MODULE__.handle_transaction_event/4,
      nil
    )
    
    :ok
  end
  
  # Handlers de eventos de telemetria
  
  @doc """
  Handler para eventos de consulta.
  """
  def handle_query_event(_event, measurements, metadata, _config) do
    # Registra informações sobre a consulta no log
    Logger.debug("Consulta executada", %{
      module: __MODULE__,
      duration_ms: native_to_ms(measurements.duration),
      rows: measurements.rows,
      query: metadata.query
    })
  end
  
  @doc """
  Handler para eventos de acerto no cache.
  """
  def handle_cache_hit_event(_event, _measurements, metadata, _config) do
    # Registra informações sobre o acerto no cache
    Logger.debug("Cache hit", %{
      module: __MODULE__,
      key: metadata.key
    })
  end
  
  @doc """
  Handler para eventos de falha no cache.
  """
  def handle_cache_miss_event(_event, _measurements, metadata, _config) do
    # Registra informações sobre a falha no cache
    Logger.debug("Cache miss", %{
      module: __MODULE__,
      key: metadata.key
    })
  end
  
  @doc """
  Handler para eventos de transação.
  """
  def handle_transaction_event(_event, measurements, metadata, _config) do
    # Registra informações sobre a transação
    Logger.debug("Transação concluída", %{
      module: __MODULE__,
      duration_ms: native_to_ms(measurements.duration),
      result: metadata.result
    })
  end
  
  # Funções auxiliares
  
  defp native_to_ms(native) do
    System.convert_time_unit(native, :native, :millisecond)
  end
end
