defmodule Deeper_Hub.Core.EventBus.Subscribers.MetricsSubscriber do
  @moduledoc """
  Subscriber para integrar eventos com o sistema de métricas.
  
  Este subscriber escuta eventos específicos e os registra como métricas
  usando o sistema de métricas do DeeperHub.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics
  
  @doc """
  Processa um evento.
  
  ## Parâmetros
  
    - `event`: O evento a ser processado
  
  ## Retorno
  
    - `:ok` - Se o evento for processado com sucesso
  """
  def process({:error, error}) do
    Logger.error("Erro ao processar evento para métricas", %{
      module: __MODULE__,
      error: error
    })
    
    :ok
  end
  
  def process({:event, event}) do
    # Extrai informações do evento
    topic = event.topic
    data = event.data
    
    # Registra métricas com base no tópico do evento
    case topic do
      :cache_hit ->
        # Registra um hit no cache
        Metrics.cache_hit(data[:key])
        
      :cache_miss ->
        # Registra um miss no cache
        Metrics.cache_miss(data[:key])
        
      :query_executed ->
        # Registra uma consulta executada
        duration = Map.get(data, :duration, 0)
        rows = Map.get(data, :rows, 0)
        
        # Emite evento de telemetria para a consulta
        :telemetry.execute(
          [:deeper_hub, :database, :query, :count],
          %{count: 1},
          %{query: data[:query]}
        )
        
        # Emite evento de telemetria para a duração da consulta
        :telemetry.execute(
          [:deeper_hub, :database, :query, :duration],
          %{duration: duration},
          %{query: data[:query]}
        )
        
        # Emite evento de telemetria para as linhas retornadas
        :telemetry.execute(
          [:deeper_hub, :database, :query, :rows],
          %{rows: rows},
          %{query: data[:query]}
        )
        
      :transaction_completed ->
        # Registra uma transação concluída
        duration = Map.get(data, :duration, 0)
        result = Map.get(data, :result, :commit)
        
        # Emite evento de telemetria para a transação
        :telemetry.execute(
          [:deeper_hub, :database, :transaction, :count],
          %{count: 1},
          %{result: result}
        )
        
        # Emite evento de telemetria para a duração da transação
        :telemetry.execute(
          [:deeper_hub, :database, :transaction, :duration],
          %{duration: duration},
          %{result: result}
        )
        
      :error_occurred ->
        # Registra um erro ocorrido
        :telemetry.execute(
          [:deeper_hub, :error, :count],
          %{count: 1},
          %{
            module: data[:module],
            error: data[:error],
            stacktrace: data[:stacktrace]
          }
        )
        
      _ ->
        # Para outros tópicos, apenas registra que o evento foi recebido
        :telemetry.execute(
          [:deeper_hub, :event, :received],
          %{count: 1},
          %{topic: topic}
        )
    end
    
    # Registra que o evento foi processado
    Logger.debug("Evento processado para métricas", %{
      module: __MODULE__,
      topic: topic,
      event_id: event.id
    })
    
    # Marca o evento como processado
    EventBus.mark_as_completed({__MODULE__, event})
    
    :ok
  end
  
  @doc """
  Manipula erros durante o processamento de eventos.
  
  ## Parâmetros
  
    - `event`: O evento que causou o erro
    - `error`: O erro ocorrido
  
  ## Retorno
  
    - `:ok` - Sempre retorna :ok
  """
  def handle_error(event, error) do
    Logger.error("Erro ao processar evento para métricas", %{
      module: __MODULE__,
      topic: event.topic,
      event_id: event.id,
      error: error
    })
    
    # Registra o erro como uma métrica
    :telemetry.execute(
      [:deeper_hub, :metrics, :error],
      %{count: 1},
      %{
        topic: event.topic,
        event_id: event.id,
        error: error
      }
    )
    
    # Marca o evento como pulado
    EventBus.mark_as_skipped({__MODULE__, event})
    
    :ok
  end
end
