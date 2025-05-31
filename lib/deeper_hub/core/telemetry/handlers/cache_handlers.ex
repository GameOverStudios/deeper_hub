defmodule DeeperHub.Core.Telemetry.Handlers.CacheHandlers do
  @moduledoc """
  Handlers específicos para eventos de telemetria do sistema de cache.
  
  Este módulo contém funções nomeadas para processar eventos de telemetria
  relacionados ao sistema de cache, evitando o uso de funções locais como
  handlers que podem causar penalidades de performance no sistema de telemetria.
  """
  
  require DeeperHub.Core.Logger
  
  @doc """
  Handler para eventos de estatísticas do cache.
  
  Processa eventos [:cachex, :stats], convertendo-os em métricas
  para o padrão de telemetria do DeeperHub.
  
  ## Parâmetros
    * `event` - O evento de telemetria (lista de atoms)
    * `measurements` - Medições associadas ao evento
    * `metadata` - Metadados associados ao evento
    * `config` - Configuração do handler
  """
  @spec handle_stats_event(list(atom()), map(), map(), map()) :: :ok
  def handle_stats_event(_event, _measurements, metadata, config) do
    %{cache_name: cache_name, prefix: prefix} = config
    
    if metadata[:name] == cache_name do
      # Extrai métricas de estatísticas do cache
      stats = metadata[:stats]
      
      # Publica métricas para telemetria
      :telemetry.execute(
        String.to_atom(prefix) |> List.wrap() |> Enum.concat([:cache, :stats]),
        %{
          hits: stats[:hits] || 0,
          misses: stats[:misses] || 0,
          writes: stats[:writes] || 0,
          evictions: stats[:evictions] || 0,
          expirations: stats[:expirations] || 0,
          size: stats[:size] || 0,
          memory: stats[:memory] || 0
        },
        %{cache_name: cache_name}
      )
    end
    
    :ok
  end
  
  @doc """
  Handler para eventos de operação do cache.
  
  Processa eventos [:cachex, :operation], convertendo-os em métricas
  para o padrão de telemetria do DeeperHub.
  
  ## Parâmetros
    * `event` - O evento de telemetria (lista de atoms)
    * `measurements` - Medições associadas ao evento
    * `metadata` - Metadados associados ao evento
    * `config` - Configuração do handler
  """
  @spec handle_operation_event(list(atom()), map(), map(), map()) :: :ok
  def handle_operation_event(_event, measurements, metadata, config) do
    %{cache_name: cache_name, prefix: prefix} = config
    
    if metadata[:name] == cache_name do
      # Publica métricas de operação para telemetria
      :telemetry.execute(
        String.to_atom(prefix) |> List.wrap() |> Enum.concat([:cache, :operation]),
        %{
          duration: measurements[:duration] || 0,
          result: metadata[:result] || :unknown
        },
        %{
          cache_name: cache_name, 
          operation: metadata[:operation] || :unknown
        }
      )
      
      # Opcionalmente, registra operações no log se estiverem habilitadas
      # Logger.debug("Cache operation: #{metadata[:operation]}, result: #{metadata[:result]}")
    end
    
    :ok
  end
end
