defmodule Deeper_Hub.Core.Telemetry.TelemetryEvents do
  @moduledoc """
  Define eventos de telemetria para o Deeper_Hub.
  Este módulo contém constantes e funções auxiliares para emitir eventos de telemetria.
  """

  # Prefixo comum para todos os eventos de telemetria do Deeper_Hub
  @prefix [:deeper_hub]

  # Eventos de banco de dados
  @db_prefix @prefix ++ [:database]
  @db_query @db_prefix ++ [:query]
  @db_transaction @db_prefix ++ [:transaction]
  @db_connection @db_prefix ++ [:connection]

  # Eventos de repositório
  @repo_prefix @prefix ++ [:repository]
  @repo_operation @repo_prefix ++ [:operation]

  # Eventos de cache
  @cache_prefix @prefix ++ [:cache]
  @cache_hit @cache_prefix ++ [:hit]
  @cache_miss @cache_prefix ++ [:miss]
  @cache_update @cache_prefix ++ [:update]

  # Eventos de circuit breaker
  @circuit_breaker_prefix @prefix ++ [:circuit_breaker]
  @circuit_breaker_trip @circuit_breaker_prefix ++ [:trip]
  @circuit_breaker_reset @circuit_breaker_prefix ++ [:reset]

  # Eventos de WebSocket
  @websocket_prefix @prefix ++ [:websocket]
  @websocket_connection @websocket_prefix ++ [:connection]
  @websocket_disconnection @websocket_prefix ++ [:disconnection]
  @websocket_message @websocket_prefix ++ [:message]
  @websocket_heartbeat @websocket_prefix ++ [:heartbeat]
  @websocket_zombie @websocket_prefix ++ [:zombie]
  @websocket_monitor @websocket_prefix ++ [:monitor]
  @websocket_db_operation @websocket_prefix ++ [:db_operation]

  # Funções para obter os nomes dos eventos
  def prefix, do: @prefix
  
  # Eventos de banco de dados
  def db_query, do: @db_query
  def db_transaction, do: @db_transaction
  def db_connection, do: @db_connection
  
  # Eventos de repositório
  def repo_operation, do: @repo_operation
  
  # Eventos de cache
  def cache_hit, do: @cache_hit
  def cache_miss, do: @cache_miss
  def cache_update, do: @cache_update
  
  # Eventos de circuit breaker
  def circuit_breaker_trip, do: @circuit_breaker_trip
  def circuit_breaker_reset, do: @circuit_breaker_reset
  
  # Eventos de WebSocket
  def websocket_connection, do: @websocket_connection
  def websocket_disconnection, do: @websocket_disconnection
  def websocket_message, do: @websocket_message
  def websocket_heartbeat, do: @websocket_heartbeat
  def websocket_zombie, do: @websocket_zombie
  def websocket_monitor, do: @websocket_monitor
  def websocket_db_operation, do: @websocket_db_operation

  @doc """
  Emite um evento de telemetria para operações de banco de dados.
  """
  def execute_db_query(measurements, metadata) do
    :telemetry.execute(@db_query, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para transações de banco de dados.
  """
  def execute_db_transaction(measurements, metadata) do
    :telemetry.execute(@db_transaction, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para conexões de banco de dados.
  """
  def execute_db_connection(measurements, metadata) do
    :telemetry.execute(@db_connection, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para operações de repositório.
  """
  def execute_repo_operation(measurements, metadata) do
    :telemetry.execute(@repo_operation, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para cache hit.
  """
  def execute_cache_hit(measurements, metadata) do
    :telemetry.execute(@cache_hit, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para cache miss.
  """
  def execute_cache_miss(measurements, metadata) do
    :telemetry.execute(@cache_miss, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para atualizações de cache.
  """
  def execute_cache_update(measurements, metadata) do
    :telemetry.execute(@cache_update, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria quando um circuit breaker é aberto (trip).
  """
  def execute_circuit_breaker_trip(measurements, metadata) do
    :telemetry.execute(@circuit_breaker_trip, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria quando um circuit breaker é resetado.
  """
  def execute_circuit_breaker_reset(measurements, metadata) do
    :telemetry.execute(@circuit_breaker_reset, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para conexões WebSocket.
  """
  def execute_websocket_connection(measurements, metadata) do
    :telemetry.execute(@websocket_connection, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para desconexões WebSocket.
  """
  def execute_websocket_disconnection(measurements, metadata) do
    :telemetry.execute(@websocket_disconnection, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para mensagens WebSocket.
  """
  def execute_websocket_message(measurements, metadata) do
    :telemetry.execute(@websocket_message, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para heartbeats WebSocket.
  """
  def execute_websocket_heartbeat(measurements, metadata) do
    :telemetry.execute(@websocket_heartbeat, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para conexões zumbis WebSocket.
  """
  def execute_websocket_zombie(measurements, metadata) do
    :telemetry.execute(@websocket_zombie, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para o monitor de WebSocket.
  """
  def execute_websocket_monitor(measurements, metadata) do
    :telemetry.execute(@websocket_monitor, measurements, metadata)
  end

  @doc """
  Emite um evento de telemetria para operações de banco de dados via WebSocket.
  
  ## Parâmetros
  
  - `measurements`: Medições como duração e contagem
  - `metadata`: Metadados como operação, schema e status
  """
  def execute_websocket_db_operation(measurements, metadata) do
    :telemetry.execute(@websocket_db_operation, measurements, metadata)
  end
end
