defmodule DeeperHub.Core.Telemetry.Adapters.CacheAdapter do
  @moduledoc """
  Adaptador de telemetria para o sistema de cache.
  
  Este módulo conecta o sistema genérico de telemetria do DeeperHub
  ao sistema de cache, fornecendo coletores e formatadores específicos
  para métricas de cache.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  alias Cachex
  
  @doc """
  Coleta métricas específicas do sistema de cache.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser monitorado
  
  ## Retorno
  
    * `{:ok, metrics}` - Métricas coletadas
    * `{:error, reason}` - Erro durante a coleta
  """
  @spec collect_metrics(atom()) :: {:ok, map()} | {:error, term()}
  def collect_metrics(cache_name) do
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
        cache_name: cache_name,
        size: size,
        memory: memory,
        hits: hits,
        misses: misses,
        operations: stats.operations || 0,
        hit_rate: hit_rate,
        expired_count: expired_count,
        timestamp: DateTime.utc_now()
      }
      
      {:ok, metrics}
    rescue
      e ->
        Logger.error("Erro ao coletar métricas do cache: #{inspect(e)}", 
                    module: __MODULE__)
        {:error, e}
    end
  end
  
  @doc """
  Configura handlers de telemetria específicos para o cache.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache a ser monitorado
    * `prefix` - Prefixo para eventos de telemetria
  
  ## Retorno
  
    * `:ok` - Handlers configurados com sucesso
    * `{:error, reason}` - Erro durante a configuração
  """
  @spec setup(keyword()) :: {:ok, pid()} | {:error, term()}
  def setup(opts \\ []) do
    component = :cache
    
    try do
      DeeperHub.Core.Telemetry.Configurator.setup(component, opts)
    rescue
      e -> {:error, e}
    end
  end
  
  @spec setup_handlers(atom(), binary()) :: :ok | {:error, term()}
  def setup_handlers(cache_name, prefix) do
    try do
      # Importa o módulo de handlers nomeados
      alias DeeperHub.Core.Telemetry.Handlers.CacheHandlers
      
      # Registra handlers para eventos de telemetria do Cachex
      :telemetry.attach(
        "#{prefix}.cache-stats",
        [:cachex, :stats],
        &CacheHandlers.handle_stats_event/4,
        %{cache_name: cache_name, prefix: prefix}
      )
      
      :telemetry.attach(
        "#{prefix}.cache-operation",
        [:cachex, :operation],
        &CacheHandlers.handle_operation_event/4,
        %{cache_name: cache_name, prefix: prefix}
      )
      
      Logger.info("Handlers de telemetria configurados para o cache: #{inspect(cache_name)}", 
                 module: __MODULE__)
      :ok
    rescue
      e ->
        Logger.error("Erro ao configurar handlers de telemetria: #{inspect(e)}", 
                    module: __MODULE__)
        {:error, e}
    end
  end
  
  @doc """
  Remove handlers de telemetria específicos para o cache.
  
  ## Parâmetros
  
    * `cache_name` - Nome do cache
    * `prefix` - Prefixo para eventos de telemetria
  
  ## Retorno
  
    * `:ok` - Handlers removidos com sucesso
  """
  @spec remove_handlers(atom(), binary()) :: :ok
  def remove_handlers(cache_name, prefix) do
    :telemetry.detach("#{prefix}.cache-stats")
    :telemetry.detach("#{prefix}.cache-operation")
    
    Logger.info("Handlers de telemetria removidos para o cache: #{inspect(cache_name)}", 
               module: __MODULE__)
    :ok
  end
  
  # Funções privadas
  
  # Obtém uso de memória do cache
  defp cachex_memory(cache_name) do
    case Cachex.inspect(cache_name, {:memory, :bytes}) do
      {:ok, memory} -> {:ok, memory}
      _ -> {:ok, 0}
    end
  end
  
  # As funções locais foram movidas para o módulo DeeperHub.Core.Telemetry.Handlers.CacheHandlers
end
