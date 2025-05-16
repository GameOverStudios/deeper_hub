defmodule Deeper_Hub.Core.EventBus.EventBusFacade do
  @moduledoc """
  Fachada para operações de barramento de eventos no sistema Deeper_Hub.

  Este módulo fornece uma interface simplificada para todas as operações de barramento
  de eventos, permitindo que outros módulos do sistema publiquem e consumam eventos
  sem conhecer os detalhes de implementação.

  A fachada delega as chamadas para o adaptador de barramento de eventos configurado,
  permitindo trocar a implementação subjacente sem afetar os consumidores do serviço.

  ## Exemplo de Uso

  ```elixir
  alias Deeper_Hub.Core.EventBus.EventBusFacade

  # Registrar um tópico
  EventBusFacade.register_topic(:user_registered)

  # Publicar um evento
  EventBusFacade.publish(
    :user_registered,
    %{id: 123, email: "user@example.com"},
    %{source: "registration_service"}
  )

  # Registrar um consumidor
  EventBusFacade.subscribe(
    :email_sender,
    [:user_registered],
    &EmailSender.handle_event/1
  )
  ```
  """

  @doc """
  Registra um tópico no barramento de eventos.

  ## Parâmetros

    * `topic` - Nome do tópico a ser registrado

  ## Retorno

    * `:ok` - Tópico registrado com sucesso
    * `{:error, reason}` - Falha ao registrar o tópico
  """
  @spec register_topic(atom()) :: :ok | {:error, term()}
  def register_topic(topic) do
    event_bus_adapter().register_topic(topic)
  end

  @doc """
  Registra um consumidor para um tópico específico.

  ## Parâmetros

    * `subscriber_name` - Nome único do consumidor
    * `topics` - Lista de tópicos de interesse
    * `handler_function` - Função a ser chamada quando um evento for publicado

  ## Retorno

    * `:ok` - Consumidor registrado com sucesso
    * `{:error, reason}` - Falha ao registrar o consumidor
  """
  @spec subscribe(term(), [atom()], function()) :: :ok | {:error, term()}
  def subscribe(subscriber_name, topics, handler_function) do
    event_bus_adapter().subscribe(subscriber_name, topics, handler_function)
  end

  @doc """
  Remove um consumidor previamente registrado.

  ## Parâmetros

    * `subscriber_name` - Nome do consumidor a ser removido

  ## Retorno

    * `:ok` - Consumidor removido com sucesso
    * `{:error, :not_found}` - Consumidor não encontrado
  """
  @spec unsubscribe(term()) :: :ok | {:error, :not_found}
  def unsubscribe(subscriber_name) do
    event_bus_adapter().unsubscribe(subscriber_name)
  end

  @doc """
  Publica um evento em um tópico específico.

  ## Parâmetros

    * `topic` - Tópico do evento
    * `data` - Dados do evento
    * `metadata` - Metadados adicionais do evento (opcional)

  ## Retorno

    * `:ok` - Evento publicado com sucesso
    * `{:error, reason}` - Falha ao publicar o evento
  """
  @spec publish(atom(), term(), map()) :: :ok | {:error, term()}
  def publish(topic, data, metadata \\ %{}) do
    event_bus_adapter().publish(topic, data, metadata)
  end

  @doc """
  Lista todos os tópicos registrados.

  ## Retorno

    * `[topic]` - Lista de tópicos registrados
  """
  @spec list_topics() :: [atom()]
  def list_topics do
    event_bus_adapter().list_topics()
  end

  @doc """
  Lista todos os consumidores registrados.

  ## Retorno

    * `[{subscriber_name, topics}]` - Lista de consumidores e seus tópicos
  """
  @spec list_subscribers() :: [{term(), [atom()]}]
  def list_subscribers do
    event_bus_adapter().list_subscribers()
  end

  @doc """
  Marca um evento como processado por um consumidor específico.

  ## Parâmetros

    * `event_id` - Identificador do evento
    * `subscriber_name` - Nome do consumidor que processou o evento

  ## Retorno

    * `:ok` - Evento marcado como processado com sucesso
    * `{:error, reason}` - Falha ao marcar o evento como processado
  """
  @spec mark_as_completed(term(), term()) :: :ok | {:error, term()}
  def mark_as_completed(event_id, subscriber_name) do
    event_bus_adapter().mark_as_completed(event_id, subscriber_name)
  end

  @doc """
  Marca um evento como falho por um consumidor específico.

  ## Parâmetros

    * `event_id` - Identificador do evento
    * `subscriber_name` - Nome do consumidor que falhou ao processar o evento
    * `error_reason` - Motivo da falha

  ## Retorno

    * `:ok` - Evento marcado como falho com sucesso
    * `{:error, reason}` - Falha ao marcar o evento como falho
  """
  @spec mark_as_failed(term(), term(), term()) :: :ok | {:error, term()}
  def mark_as_failed(event_id, subscriber_name, error_reason) do
    event_bus_adapter().mark_as_failed(event_id, subscriber_name, error_reason)
  end

  @doc """
  Obtém o status de um evento.

  ## Parâmetros

    * `event_id` - Identificador do evento

  ## Retorno

    * `{:ok, status}` - Status do evento obtido com sucesso
    * `{:error, :not_found}` - Evento não encontrado
  """
  @spec get_event_status(term()) :: {:ok, term()} | {:error, :not_found}
  def get_event_status(event_id) do
    event_bus_adapter().get_event_status(event_id)
  end

  # Função privada para obter o adaptador de barramento de eventos configurado
  defp event_bus_adapter do
    # Por enquanto, retornamos diretamente o adaptador padrão
    # No futuro, isso pode ser alterado para usar um módulo de configuração
    Deeper_Hub.Core.EventBus.EventBusAdapter
  end
end
