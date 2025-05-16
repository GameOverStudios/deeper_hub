defmodule Deeper_Hub.Core.EventBus.EventDefinitions do
  @moduledoc """
  Define eventos para o sistema EventBus do Deeper_Hub.
  Este módulo contém constantes e funções auxiliares para emitir eventos.
  """

  # Prefixo comum para todos os eventos do Deeper_Hub
  @prefix :deeper_hub

  # Eventos de banco de dados
  @db_event "#{@prefix}_database"
  @db_query "#{@prefix}_database_query"
  @db_transaction "#{@prefix}_database_transaction"
  @db_error "#{@prefix}_database_error"

  # Eventos de repositório
  @repo_event "#{@prefix}_repository"
  @repo_operation "#{@prefix}_repository_operation"
  @repo_error "#{@prefix}_repository_error"

  # Eventos de cache
  @cache_event "#{@prefix}_cache"
  @cache_hit "#{@prefix}_cache_hit"
  @cache_miss "#{@prefix}_cache_miss"
  @cache_update "#{@prefix}_cache_update"

  # Eventos de circuit breaker
  @circuit_breaker_event "#{@prefix}_circuit_breaker"
  @circuit_breaker_trip "#{@prefix}_circuit_breaker_trip"
  @circuit_breaker_reset "#{@prefix}_circuit_breaker_reset"

  # Eventos de WebSocket
  @websocket_event "#{@prefix}_websocket"
  @websocket_connection "#{@prefix}_websocket_connection"
  @websocket_disconnection "#{@prefix}_websocket_disconnection"
  @websocket_message "#{@prefix}_websocket_message"
  @websocket_event_ack "#{@prefix}_websocket_event_ack"
  @websocket_zombie_connection "#{@prefix}_websocket_zombie_connection"
  @websocket_monitor_started "#{@prefix}_websocket_monitor_started"
  @websocket_db_operation "#{@prefix}_websocket_db_operation"

  # Funções para obter os nomes dos eventos
  def prefix, do: @prefix
  
  # Eventos de banco de dados
  def db_event, do: @db_event
  def db_query, do: @db_query
  def db_transaction, do: @db_transaction
  def db_error, do: @db_error
  
  # Eventos de repositório
  def repo_event, do: @repo_event
  def repo_operation, do: @repo_operation
  def repo_error, do: @repo_error
  
  # Eventos de cache
  def cache_event, do: @cache_event
  def cache_hit, do: @cache_hit
  def cache_miss, do: @cache_miss
  def cache_update, do: @cache_update
  
  # Eventos de circuit breaker
  def circuit_breaker_event, do: @circuit_breaker_event
  def circuit_breaker_trip, do: @circuit_breaker_trip
  def circuit_breaker_reset, do: @circuit_breaker_reset
  
  # Eventos de WebSocket
  def websocket_event, do: @websocket_event
  def websocket_connection, do: @websocket_connection
  def websocket_disconnection, do: @websocket_disconnection
  def websocket_message, do: @websocket_message
  def websocket_event_ack, do: @websocket_event_ack
  def websocket_zombie_connection, do: @websocket_zombie_connection
  def websocket_monitor_started, do: @websocket_monitor_started
  def websocket_db_operation, do: @websocket_db_operation

  @doc """
  Lista todos os tópicos de eventos definidos para registro no EventBus.
  """
  def all_topics do
    [
      db_event(),
      db_query(),
      db_transaction(),
      db_error(),
      repo_event(),
      repo_operation(),
      repo_error(),
      cache_event(),
      cache_hit(),
      cache_miss(),
      cache_update(),
      circuit_breaker_event(),
      circuit_breaker_trip(),
      circuit_breaker_reset(),
      websocket_event(),
      websocket_connection(),
      websocket_disconnection(),
      websocket_message(),
      websocket_event_ack(),
      websocket_zombie_connection(),
      websocket_monitor_started(),
      websocket_db_operation()
    ]
  end

  @doc """
  Cria um novo evento para o EventBus.
  
  ## Parâmetros
  
    - `topic`: O tópico do evento
    - `data`: Os dados do evento
    - `opts`: Opções adicionais (source, transaction_id, etc.)
  
  ## Retorno
  
    - `%EventBus.Model.Event{}`: Estrutura do evento
  """
  def new_event(topic, data, opts \\ []) do
    # Obtém o ID único para o evento
    id = UUID.uuid4()
    
    # Obtém o timestamp atual em microssegundos
    now = :os.system_time(:micro_seconds)
    
    # Obtém a fonte do evento (quem o criou)
    source = Keyword.get(opts, :source, "deeper_hub")
    
    # Obtém o ID da transação, se houver
    transaction_id = Keyword.get(opts, :transaction_id, nil)
    
    # Cria o evento usando o EventBus.Model.Event
    %EventBus.Model.Event{
      id: id,
      topic: topic,
      data: data,
      initialized_at: now,
      occurred_at: now,
      source: source,
      transaction_id: transaction_id
    }
  end

  @doc """
  Emite um evento para o EventBus.
  
  ## Parâmetros
  
    - `topic`: O tópico do evento
    - `data`: Os dados do evento
    - `opts`: Opções adicionais (source, transaction_id, etc.)
  
  ## Retorno
  
    - `:ok`: Se o evento foi emitido com sucesso
  """
  def emit(topic, data, opts \\ []) do
    # Cria o evento
    event = new_event(topic, data, opts)
    
    # Emite o evento usando o EventBus
    EventBus.notify(event)
  end
end
