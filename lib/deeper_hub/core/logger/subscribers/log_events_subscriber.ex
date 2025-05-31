defmodule DeeperHub.Core.Logger.Subscribers.LogEventsSubscriber do
  @moduledoc """
  Subscriber que processa eventos relacionados a logs importantes.
  
  Este módulo monitora eventos específicos de logging, permitindo
  que o sistema reaja a mensagens de log importantes como erros e alertas.
  """
  
  use DeeperHub.Core.EventManager.Subscriber, topics: [
    "log_error",
    "log_alert",
    "log_critical",
    "log_emergency",
    "system_started"
  ]
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger, as: Logger
  
  @impl true
  def process({:system_started, _id} = event_shadow) do
    # Ao iniciar o sistema, apenas registramos o subscriber
    event = fetch_event(event_shadow)
    Logger.info("LogEventsSubscriber iniciado: #{inspect(event.data)}")
    mark_as_completed(event_shadow)
    :ok
  end
  
  def process({:log_error, _id} = event_shadow) do
    event = fetch_event(event_shadow)
    process_log_event(event, :error)
    mark_as_completed(event_shadow)
    :ok
  end
  
  def process({:log_alert, _id} = event_shadow) do
    event = fetch_event(event_shadow)
    process_log_event(event, :alert)
    mark_as_completed(event_shadow)
    :ok
  end
  
  def process({:log_critical, _id} = event_shadow) do
    event = fetch_event(event_shadow)
    process_log_event(event, :critical)
    mark_as_completed(event_shadow)
    :ok
  end
  
  def process({:log_emergency, _id} = event_shadow) do
    event = fetch_event(event_shadow)
    process_log_event(event, :emergency)
    mark_as_completed(event_shadow)
    :ok
  end
  
  def process(event_shadow) do
    # Ignoramos outros eventos
    mark_as_skipped(event_shadow)
    :ok
  end
  
  # Processa um evento de log com base no nível
  defp process_log_event(event, level) do
    # Aqui você pode implementar ações específicas para cada tipo de log
    # Por exemplo, enviar notificações, acionar alarmes, etc.
    
    # Por enquanto, apenas registramos que recebemos o evento
    Logger.info("Evento de log #{level} recebido: #{inspect(event.data)}")
    
    # Exemplo de possível integração com sistema de notificação
    # if level in [:emergency, :critical] do
    #   notificar_administradores(event.data)
    # end
    
    :ok
  end
end
