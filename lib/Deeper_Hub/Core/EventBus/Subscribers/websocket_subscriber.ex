defmodule Deeper_Hub.Core.EventBus.Subscribers.WebSocketSubscriber do
  @moduledoc """
  Subscriber para eventos relacionados ao WebSocket.
  
  Este subscriber escuta eventos específicos do WebSocket e realiza
  ações apropriadas, como logging e métricas.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Processa um evento.
  
  ## Parâmetros
  
    - `event`: O evento a ser processado
  
  ## Retorno
  
    - `:ok` - Se o evento for processado com sucesso
  """
  def process({topic, id} = event_shadow) when is_atom(topic) and is_binary(id) do
    # Busca os dados do evento
    event_data = EventBus.fetch_event({topic, id})
    
    if event_data do
      # Registra o evento no log
      Logger.info("Evento WebSocket recebido", %{
        module: __MODULE__,
        topic: topic,
        event_id: id,
        source: event_data.source
      })
      
      # Processa o evento com base no tópico
      process_event(event_data)
      
      # Marca o evento como processado
      EventBus.mark_as_completed({__MODULE__, event_shadow})
    else
      Logger.warning("Evento não encontrado", %{
        module: __MODULE__,
        topic: topic,
        id: id
      })
    end
    
    :ok
  end
  
  def process({:error, error}) do
    Logger.error("Erro ao processar evento WebSocket", %{
      module: __MODULE__,
      error: error
    })
    :ok
  end
  
  def process(event) do
    Logger.warning("Formato de evento desconhecido", %{
      module: __MODULE__,
      event: event
    })
    :ok
  end
  
  # Funções privadas para processamento de eventos específicos
  
  @doc false
  defp process_event(%{topic: :websocket_connected} = event) do
    client = event.data[:client]
    Logger.info("Cliente WebSocket conectado", %{
      module: __MODULE__,
      client: client
    })
    
    # Emite métrica de conexão
    :telemetry.execute(
      [:deeper_hub, :websocket, :connections, :count],
      %{count: 1},
      %{client: client}
    )
  end
  
  @doc false
  defp process_event(%{topic: :websocket_disconnected} = event) do
    client = event.data[:client]
    reason = event.data[:reason]
    Logger.info("Cliente WebSocket desconectado", %{
      module: __MODULE__,
      client: client,
      reason: reason
    })
    
    # Emite métrica de desconexão
    :telemetry.execute(
      [:deeper_hub, :websocket, :disconnections, :count],
      %{count: 1},
      %{client: client, reason: reason}
    )
  end
  
  @doc false
  defp process_event(%{topic: :websocket_message_received} = event) do
    client = event.data[:client]
    message = event.data[:message]
    Logger.info("Mensagem WebSocket recebida", %{
      module: __MODULE__,
      client: client,
      message: message
    })
    
    # Emite métrica de mensagem recebida
    :telemetry.execute(
      [:deeper_hub, :websocket, :messages, :received],
      %{count: 1},
      %{client: client}
    )
  end
  
  @doc false
  defp process_event(%{topic: :websocket_message_sent} = event) do
    client = event.data[:client]
    message = event.data[:message]
    Logger.info("Mensagem WebSocket enviada", %{
      module: __MODULE__,
      client: client,
      message: message
    })
    
    # Emite métrica de mensagem enviada
    :telemetry.execute(
      [:deeper_hub, :websocket, :messages, :sent],
      %{count: 1},
      %{client: client}
    )
  end
  
  @doc false
  defp process_event(%{topic: :websocket_binary_received} = event) do
    client = event.data[:client]
    payload_size = event.data[:payload_size]
    Logger.info("Mensagem binária WebSocket recebida", %{
      module: __MODULE__,
      client: client,
      payload_size: payload_size
    })
    
    # Emite métrica de mensagem binária recebida
    :telemetry.execute(
      [:deeper_hub, :websocket, :messages, :binary_received],
      %{count: 1, size: payload_size},
      %{client: client}
    )
  end
  
  @doc false
  defp process_event(%{topic: :websocket_error} = event) do
    client = event.data[:client]
    error = event.data[:error]
    Logger.error("Erro no WebSocket", %{
      module: __MODULE__,
      client: client,
      error: error
    })
    
    # Emite métrica de erro
    :telemetry.execute(
      [:deeper_hub, :websocket, :errors, :count],
      %{count: 1},
      %{client: client, error: error}
    )
  end
  
  @doc false
  defp process_event(event) do
    # Extrai informações do evento
    topic = event.topic
    data = event.data
    source = event.source
    event_id = event.id
    
    # Registra o evento no log
    Logger.debug("Evento WebSocket não processado", %{
      module: __MODULE__,
      topic: topic,
      event_id: event_id,
      source: source,
      data: data
    })
  end
end
