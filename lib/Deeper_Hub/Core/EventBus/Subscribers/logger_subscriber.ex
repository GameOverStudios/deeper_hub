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
  def process({topic, id} = event_shadow) when is_atom(topic) and is_binary(id) do
    # Busca os dados do evento
    event_data = EventBus.fetch_event({topic, id})
    
    if event_data do
      # Extrai informações do evento
      data = event_data.data
      source = event_data.source
      
      # Registra o evento no log
      Logger.info("Evento recebido", %{
        module: __MODULE__,
        topic: topic,
        event_id: id,
        source: source,
        data: data
      })
      
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
    Logger.error("Erro ao processar evento", %{
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
