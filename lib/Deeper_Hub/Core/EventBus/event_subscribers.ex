defmodule Deeper_Hub.Core.EventBus.EventSubscribers do
  @moduledoc """
  Módulo para subscribers (consumidores) de eventos do EventBus no Deeper_Hub.
  
  Este módulo contém implementações de subscribers para processar eventos
  emitidos pelos diversos componentes do sistema.
  """

  alias Deeper_Hub.Core.Logger

  @doc """
  Registra todos os subscribers no EventBus.
  """
  def register_subscribers do
    # Registra o subscriber de logs para todos os eventos
    EventBus.subscribe({__MODULE__.LogSubscriber, [".*"]})
    
    # Registra outros subscribers específicos
    EventBus.subscribe({__MODULE__.DatabaseSubscriber, ["deeper_hub_database.*"]})
    EventBus.subscribe({__MODULE__.CacheSubscriber, ["deeper_hub_cache.*"]})
    
    :ok
  end

  defmodule LogSubscriber do
    @moduledoc """
    Subscriber para registrar todos os eventos em log.
    """
    
    @doc """
    Processa um evento e registra em log.
    """
    def process({:error, error}) do
      Logger.error("Erro ao processar evento", %{
        module: __MODULE__,
        error: inspect(error)
      })
    end
    
    def process({:event, event}) do
      # Registra o evento em log
      Logger.debug("Evento recebido", %{
        module: __MODULE__,
        topic: event.topic,
        id: event.id,
        source: event.source,
        data: inspect(event.data)
      })
      
      # Marca o evento como processado
      EventBus.mark_as_completed({__MODULE__, event})
    end
    
    def process(event) do
      # Se o evento for uma tupla {"deeper_hub_websocket_monitor_started", _}, ignoramos
      case event do
        {"deeper_hub_websocket_monitor_started", _} ->
          :ok
          
        {"deeper_hub_websocket_monitor_stopped", _} ->
          :ok
          
        _ ->
          # Para outros eventos desconhecidos, registramos em log
          Logger.debug("Evento recebido em formato desconhecido", %{
            module: __MODULE__,
            event: inspect(event)
          })
          
          # Tenta marcar o evento como processado se possível
          try do
            EventBus.mark_as_completed({__MODULE__, event})
          rescue
            _ -> :ok
          end
      end
    end
  end

  defmodule DatabaseSubscriber do
    @moduledoc """
    Subscriber para eventos relacionados ao banco de dados.
    """
    
    @doc """
    Processa eventos de banco de dados.
    """
    def process({:event, event}) do
      # Implementação específica para eventos de banco de dados
      case event.topic do
        :deeper_hub_database_query ->
          # Processa evento de consulta
          process_query_event(event)
          
        :deeper_hub_database_transaction ->
          # Processa evento de transação
          process_transaction_event(event)
          
        :deeper_hub_database_error ->
          # Processa evento de erro
          process_error_event(event)
          
        _ ->
          # Processa outros eventos de banco de dados
          :ok
      end
      
      # Marca o evento como processado
      EventBus.mark_as_completed({__MODULE__, event})
    end
    
    # Processa eventos no formato de string
    def process({topic, id}) when is_binary(topic) do
      # Converte o tópico para atom se possível
      topic_atom = String.to_existing_atom(topic)
      
      # Processa com base no tópico
      case topic_atom do
        :deeper_hub_database_query ->
          Logger.debug("Evento de consulta de banco de dados", %{id: id})
          
        :deeper_hub_database_transaction ->
          Logger.debug("Evento de transação de banco de dados", %{id: id})
          
        :deeper_hub_database_error ->
          Logger.warning("Evento de erro de banco de dados", %{id: id})
          
        _ ->
          Logger.debug("Outro evento de banco de dados", %{topic: topic, id: id})
      end
      
      # Tenta marcar o evento como processado
      try do
        EventBus.mark_as_completed({__MODULE__, {topic, id}})
      rescue
        _ -> :ok
      end
    end
    
    # Fallback para outros formatos de evento
    def process(event) do
      Logger.debug("Evento de banco de dados em formato desconhecido", %{
        module: __MODULE__,
        event: inspect(event)
      })
      
      # Tenta marcar o evento como processado
      try do
        EventBus.mark_as_completed({__MODULE__, event})
      rescue
        _ -> :ok
      end
    end
    
    # Funções privadas para processamento específico de eventos
    
    defp process_query_event(_event) do
      # Aqui você pode implementar lógica específica para eventos de consulta
      # Por exemplo, registrar métricas, enviar para um sistema de monitoramento, etc.
      :ok
    end
    
    defp process_transaction_event(_event) do
      # Aqui você pode implementar lógica específica para eventos de transação
      :ok
    end
    
    defp process_error_event(event) do
      # Aqui você pode implementar lógica específica para eventos de erro
      # Por exemplo, enviar alertas, notificar administradores, etc.
      Logger.warning("Erro de banco de dados detectado", %{
        module: __MODULE__,
        error: inspect(event.data)
      })
      :ok
    end
  end

  defmodule CacheSubscriber do
    @moduledoc """
    Subscriber para processar eventos de cache.
    """
    
    @doc """
    Processa um evento de cache.
    """
    def process({:error, error}) do
      Logger.error("Erro ao processar evento de cache", %{
        module: __MODULE__,
        error: inspect(error)
      })
    end
    
    def process({:event, event}) do
      # Processa o evento de cache
      case event.topic do
        :deeper_hub_cache_hit ->
          # Processa evento de cache hit
          :ok
          
        :deeper_hub_cache_miss ->
          # Processa evento de cache miss
          :ok
          
        :deeper_hub_cache_update ->
          # Processa evento de atualização de cache
          :ok
          
        _ ->
          # Processa outros eventos de cache
          :ok
      end
      
      # Marca o evento como processado
      EventBus.mark_as_completed({__MODULE__, event})
    end
    
    # Processa eventos no formato de string
    def process({topic, id}) when is_binary(topic) do
      # Converte o tópico para atom se possível
      topic_atom = String.to_existing_atom(topic)
      
      # Processa com base no tópico
      case topic_atom do
        :deeper_hub_cache_hit ->
          Logger.debug("Evento de cache hit", %{id: id})
          
        :deeper_hub_cache_miss ->
          Logger.debug("Evento de cache miss", %{id: id})
          
        :deeper_hub_cache_update ->
          Logger.debug("Evento de atualização de cache", %{id: id})
          
        _ ->
          Logger.debug("Outro evento de cache", %{topic: topic, id: id})
      end
      
      # Tenta marcar o evento como processado
      try do
        EventBus.mark_as_completed({__MODULE__, {topic, id}})
      rescue
        _ -> :ok
      end
    end
    
    # Fallback para outros formatos de evento
    def process(event) do
      Logger.debug("Evento de cache em formato desconhecido", %{
        module: __MODULE__,
        event: inspect(event)
      })
      
      # Tenta marcar o evento como processado
      try do
        EventBus.mark_as_completed({__MODULE__, event})
      rescue
        _ -> :ok
      end
    end
  end
end
