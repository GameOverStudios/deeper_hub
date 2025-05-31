defmodule DeeperHub.Core.EventManager do
  @moduledoc """
  Módulo principal para gerenciamento de eventos no DeeperHub.
  
  Este módulo encapsula as funcionalidades do EventBus e fornece
  uma interface padronizada para publicação e manipulação de eventos
  no sistema.
  """

  alias EventBus.Model.Event
  alias DeeperHub.Core.EventManager.Config

  @doc """
  Inicializa o sistema de eventos.
  
  Registra todos os tópicos padrão.
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.initialize()
      :ok
  
  """
  def initialize do
    Config.initialize()
  end

  @doc """
  Publica um evento no sistema.
  
  ## Parâmetros
  
    * `topic` - Tópico do evento (atom)
    * `data` - Dados associados ao evento
    * `source` - Origem do evento (opcional)
    * `transaction_id` - ID de transação para rastreamento (opcional)
  
  ## Retorno
  
  Retorna `:ok` em caso de sucesso.
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.publish(:user_created, %{id: 123, name: "João"})
      :ok
  
      iex> DeeperHub.Core.EventManager.publish(:data_updated, %{id: 456}, "atualização_agendada")
      :ok
  
  """
  def publish(topic, data, source \\ nil, transaction_id \\ nil) do
    event_id = UUID.uuid4()
    
    event = %Event{
      id: event_id,
      topic: topic,
      data: data,
      source: source || "deeper_hub",
      transaction_id: transaction_id,
      initialized_at: :os.system_time(:microsecond),
      occurred_at: :os.system_time(:microsecond)
    }
    
    EventBus.notify(event)
    :ok
  end

  @doc """
  Obtém um evento específico a partir de um shadow.
  
  ## Parâmetros
  
    * `event_shadow` - Shadow do evento no formato `{topic, id}`
  
  ## Retorno
  
  Retorna o evento completo.
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.fetch_event({:user_created, "some_id"})
      %EventBus.Model.Event{...}
  
  """
  def fetch_event({topic, id}) do
    EventBus.fetch_event({topic, id})
  end

  @doc """
  Marca um evento como concluído por um subscriber.
  
  ## Parâmetros
  
    * `subscriber` - Módulo subscriber ou tupla {subscriber, config}
    * `event_shadow` - Shadow do evento no formato `{topic, id}`
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.mark_as_completed(MySubscriber, {:user_created, "some_id"})
      :ok
  
  """
  def mark_as_completed(subscriber, {topic, id} = _event_shadow) do
    EventBus.mark_as_completed({subscriber, topic, id})
  end

  @doc """
  Marca um evento como ignorado por um subscriber.
  
  ## Parâmetros
  
    * `subscriber` - Módulo subscriber ou tupla {subscriber, config}
    * `event_shadow` - Shadow do evento no formato `{topic, id}`
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.mark_as_skipped(MySubscriber, {:unknown_event, "some_id"})
      :ok
  
  """
  def mark_as_skipped(subscriber, {topic, id} = _event_shadow) do
    EventBus.mark_as_skipped({subscriber, topic, id})
  end

  @doc """
  Subscreve um módulo aos tópicos de eventos especificados.
  
  ## Parâmetros
  
    * `subscriber` - Módulo subscriber ou tupla {subscriber, config}
    * `topics` - Lista de tópicos (strings ou regex patterns) para subscrição
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.subscribe(MySubscriber, ["user_.*"])
      :ok
  
  """
  def subscribe(subscriber, topics) when is_list(topics) do
    EventBus.subscribe({subscriber, topics})
  end

  @doc """
  Cancela a subscrição de um módulo.
  
  ## Parâmetros
  
    * `subscriber` - Módulo subscriber ou tupla {subscriber, config}
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.unsubscribe(MySubscriber)
      :ok
  
  """
  def unsubscribe(subscriber) do
    EventBus.unsubscribe(subscriber)
  end

  @doc """
  Lista todos os subscribers atuais.
  
  ## Retorno
  
  Lista de tuplas contendo {subscriber, [topics]}
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.subscribers()
      [{MySubscriber, ["user_.*"]}, {{AnotherSubscriber, %{}}, [".*"]}]
  
  """
  def subscribers do
    EventBus.subscribers()
  end

  @doc """
  Lista os subscribers de um tópico específico.
  
  ## Parâmetros
  
    * `topic` - Tópico (atom) para listar subscribers
  
  ## Retorno
  
  Lista de subscribers interessados no tópico
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.subscribers(:user_created)
      [MySubscriber, {AnotherSubscriber, %{}}]
  
  """
  def subscribers(topic) when is_atom(topic) do
    EventBus.subscribers(topic)
  end
end
