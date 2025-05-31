defmodule DeeperHub.Core.Cache.Subscribers.CacheEventsSubscriber do
  @moduledoc """
  Subscriber que processa eventos relacionados ao cache.
  
  Este módulo escuta eventos do sistema e realiza ações específicas 
  relacionadas ao cache, como invalidação de cache em resposta a 
  atualizações de dados.
  """
  
  use DeeperHub.Core.EventManager.Subscriber, topics: [
    "data_created",
    "data_updated", 
    "data_deleted",
    "system_started"
  ]
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Cache
  
  @impl true
  def process({:system_started, _id} = event_shadow) do
    # Ao iniciar o sistema, apenas registramos o subscriber
    event = fetch_event(event_shadow)
    DeeperHub.Core.Logger.info("CacheEventsSubscriber iniciado: #{inspect(event.data)}")
    mark_as_completed(event_shadow)
    :ok
  end
  
  def process({:data_created, _id} = event_shadow) do
    event = fetch_event(event_shadow)
    
    # Para criação de dados, geralmente não é necessário invalidar cache,
    # mas podemos pré-carregar dados em cache se necessário
    case event.data do
      %{entity_type: entity_type, id: entity_id} when not is_nil(entity_type) and not is_nil(entity_id) ->
        # Potencialmente pré-carregar o dado no cache
        DeeperHub.Core.Logger.debug("Evento de criação de dados recebido: #{entity_type}:#{entity_id}")
      _ -> 
        :ok
    end
    
    mark_as_completed(event_shadow)
    :ok
  end
  
  def process({:data_updated, _id} = event_shadow) do
    event = fetch_event(event_shadow)
    
    # Para atualizações, invalidamos o cache relacionado
    case event.data do
      %{entity_type: entity_type, id: entity_id} when not is_nil(entity_type) and not is_nil(entity_id) ->
        cache_key = "#{entity_type}:#{entity_id}"
        # Invalida a entrada específica
        Cache.delete(cache_key, namespace: entity_type)
        DeeperHub.Core.Logger.debug("Cache invalidado para #{entity_type}:#{entity_id}")
        
        # Opcional: invalidar caches relacionados, como listas que contêm esta entidade
        # Cache.delete("list:#{entity_type}", namespace: "lists")
      _ -> 
        :ok
    end
    
    mark_as_completed(event_shadow)
    :ok
  end
  
  def process({:data_deleted, _id} = event_shadow) do
    event = fetch_event(event_shadow)
    
    # Para exclusões, invalidamos o cache relacionado
    case event.data do
      %{entity_type: entity_type, id: entity_id} when not is_nil(entity_type) and not is_nil(entity_id) ->
        cache_key = "#{entity_type}:#{entity_id}"
        # Invalida a entrada específica
        Cache.delete(cache_key, namespace: entity_type)
        DeeperHub.Core.Logger.debug("Cache invalidado para #{entity_type}:#{entity_id} (exclusão)")
        
        # Opcional: invalidar caches relacionados
        # Cache.delete("list:#{entity_type}", namespace: "lists")
      _ -> 
        :ok
    end
    
    mark_as_completed(event_shadow)
    :ok
  end
  
  def process(event_shadow) do
    # Ignoramos outros eventos
    mark_as_skipped(event_shadow)
    :ok
  end
end
