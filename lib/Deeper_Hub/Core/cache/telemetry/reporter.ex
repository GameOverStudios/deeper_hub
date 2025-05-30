defmodule DeeperHub.Core.Cache.Telemetry.Reporter do
  @moduledoc """
  Módulo para relatar métricas de telemetria do sistema de cache.
  
  Este módulo é responsável por coletar, processar e relatar métricas
  relacionadas ao desempenho e uso do sistema de cache. Ele se integra
  com o sistema de telemetria do Elixir para publicar eventos que podem
  ser consumidos por ferramentas de monitoramento.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias Cachex
  
  @doc """
  Inicializa o reporter de telemetria para o cache.
  
  Configura os handlers de eventos e inicia a coleta de métricas.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser monitorado
    * `opts` - Opções adicionais de configuração
  
  ## Opções
  
    * `:interval` - Intervalo em milissegundos para coleta de métricas (padrão: 60_000)
    * `:prefix` - Prefixo para eventos de telemetria (padrão: "deeper_hub.cache")
  
  ## Retorno
  
    * `:ok` - Reporter inicializado com sucesso
    * `{:error, reason}` - Erro durante a inicialização
  """
  @spec init(atom(), keyword()) :: :ok | {:error, term()}
  def init(cache_name, opts \\ []) do
    Logger.info("Inicializando reporter de telemetria para cache", module: __MODULE__)
    
    interval = Keyword.get(opts, :interval, 60_000)
    prefix = Keyword.get(opts, :prefix, "deeper_hub.cache")
    
    # Inicia coleta periódica de métricas
    {:ok, _pid} = Task.start_link(fn -> 
      metrics_loop(cache_name, interval, prefix)
    end)
    
    # Registra handlers para eventos de telemetria
    :telemetry.attach(
      "#{prefix}.cache-stats",
      [:cachex, :stats],
      &handle_stats_event/4,
      %{cache_name: cache_name, prefix: prefix}
    )
    
    :telemetry.attach(
      "#{prefix}.cache-operation",
      [:cachex, :operation],
      &handle_operation_event/4,
      %{cache_name: cache_name, prefix: prefix}
    )
    
    :ok
  end
  
  @doc """
  Obtém as métricas atuais do cache.
  
  Coleta estatísticas sobre o uso de memória, hit rate, e outras
  métricas importantes do cache.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser monitorado
  
  ## Retorno
  
    * `{:ok, metrics}` - Métricas coletadas
    * `{:error, reason}` - Erro durante a coleta
  """
  @spec get_metrics(atom()) :: {:ok, map()} | {:error, term()}
  def get_metrics(cache_name) do
    try do
      # Obtém estatísticas do Cachex
      {:ok, stats} = Cachex.stats(cache_name)
      {:ok, size} = Cachex.size(cache_name)
      {:ok, memory} = cachex_memory(cache_name)
      
      # Obtém informações sobre itens expirados
      expired_count = case Cachex.inspect(cache_name, {:expired, :count}) do
        {:ok, count} -> count
        _ -> 0
      end
      
      # Calcula taxas de acerto/erro
      hits = stats.hits || 0
      misses = stats.misses || 0
      total_ops = hits + misses
      hit_rate = if total_ops > 0, do: hits / total_ops, else: 0
      
      # Constrói mapa de métricas
      metrics = %{
        size: size,
        memory: memory,
        hit_rate: hit_rate,
        hits: hits,
        misses: misses,
        operations: stats.operations || 0,
        expired_count: expired_count,
        timestamp: :os.system_time(:millisecond)
      }
      
      {:ok, metrics}
    rescue
      error ->
        Logger.error("Erro ao coletar métricas do cache: #{inspect(error)}", module: __MODULE__)
        {:error, error}
    end
  end
  
  @doc """
  Para o reporter de telemetria.
  
  Remove os handlers de eventos de telemetria.
  
  ## Parâmetros
  
    * `prefix` - Prefixo usado na inicialização (padrão: "deeper_hub.cache")
  
  ## Retorno
  
    * `:ok` - Reporter parado com sucesso
  """
  @spec stop(binary()) :: :ok
  def stop(prefix \\ "deeper_hub.cache") do
    :telemetry.detach("#{prefix}.cache-stats")
    :telemetry.detach("#{prefix}.cache-operation")
    :ok
  end
  
  # Funções privadas
  
  # Loop para coleta periódica de métricas
  defp metrics_loop(cache_name, interval, prefix) do
    # Coleta métricas
    case get_metrics(cache_name) do
      {:ok, metrics} ->
        # Emite evento de telemetria com as métricas
        :telemetry.execute(
          :"#{prefix}.periodic_metrics",
          metrics,
          %{cache_name: cache_name}
        )
        
      {:error, _} ->
        # Ignora erros durante a coleta
        :ok
    end
    
    # Aguarda intervalo e repete
    :timer.sleep(interval)
    metrics_loop(cache_name, interval, prefix)
  end
  
  # Handler para eventos de estatísticas do cache
  defp handle_stats_event(_event, measurements, metadata, config) do
    %{cache_name: cache_name, prefix: prefix} = config
    
    if metadata[:name] == cache_name do
      # Emite evento de telemetria específico da aplicação
      :telemetry.execute(
        :"#{prefix}.stats",
        measurements,
        metadata
      )
    end
  end
  
  # Handler para eventos de operação do cache
  defp handle_operation_event(_event, measurements, metadata, config) do
    %{cache_name: cache_name, prefix: prefix} = config
    
    if metadata[:name] == cache_name do
      # Emite evento de telemetria específico da aplicação
      :telemetry.execute(
        :"#{prefix}.operation",
        measurements,
        metadata
      )
      
      # Registra operações mais lentas em log
      if measurements[:duration] > 100_000_000 do # 100ms em nanossegundos
        duration_ms = measurements[:duration] / 1_000_000
        Logger.warn(
          "Operação de cache lenta: #{metadata[:operation]} (#{duration_ms}ms)",
          module: __MODULE__
        )
      end
    end
  end

  # Função wrapper para Cachex para evitar avisos de compilação

  @doc false
  defp cachex_memory(cache_name) do
    try do
      # Chama a função usando apply para evitar warnings
      apply(Cachex, :memory, [cache_name])
    rescue
      e -> 
        Logger.error("Erro ao obter memória do cache: #{inspect(e)}", module: __MODULE__)
        {:error, :memory_unavailable}
    end
  end
end
