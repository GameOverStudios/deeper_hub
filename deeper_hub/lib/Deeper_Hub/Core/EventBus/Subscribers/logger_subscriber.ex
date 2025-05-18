defmodule Deeper_Hub.Core.EventBus.Subscribers.LoggerSubscriber do
  @moduledoc """
  Subscriber para registrar eventos no log.
  
  Este subscriber escuta todos os eventos e os registra no sistema de log.
  Serve como exemplo de implementação de um subscriber do EventBus.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Processa um evento.
  
  ## Parâmetros
  
    - `event`: O evento a ser processado
  
  ## Retorno
  
    - `:ok` - Se o evento for processado com sucesso
  """
  def process({:error, error}) do
    Logger.error("Erro ao processar evento", %{
      module: __MODULE__,
      error: error
    })
    
    :ok
  end
  
  def process({:event, event}) do
    # Extrai informações do evento
    topic = event.topic
    data = event.data
    source = event.source
    event_id = event.id
    
    # Registra o evento no log
    Logger.info("Evento recebido", %{
      module: __MODULE__,
      topic: topic,
      event_id: event_id,
      source: source,
      data: data
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
    Logger.error("Erro ao processar evento", %{
      module: __MODULE__,
      topic: event.topic,
      event_id: event.id,
      error: error
    })
    
    # Marca o evento como pulado
    EventBus.mark_as_skipped({__MODULE__, event})
    
    :ok
  end
end
