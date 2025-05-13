defmodule DeeperHub.Core.EventBus.Services.Event do
  @moduledoc """
  Serviço para gerenciar os eventos armazenados no banco de dados Mnesia.

  Este serviço oferece operações CRUD para eventos, incluindo validação,
  serialização/deserialização de valores, e interação com o banco de dados.
  """

  alias DeeperHub.Core.EventBus.Schema.Event
  alias DeeperHub.Core.EventBus.Schema.EventTable
  alias DeeperHub.Core.Logger

  @doc """
  Inicializa as tabelas necessárias para o serviço de eventos.
  """
  def setup do
    Logger.debug("Criando tabela Mnesia para eventos", %{module: __MODULE__})
    Memento.Table.create(EventTable)
  end

  @doc """
  Cria um novo evento.

  ## Parâmetros

    * `attrs` - Um mapa com os atributos do evento.

  ## Retorno

    * `{:ok, event}` - Em caso de sucesso.
    * `{:error, reason}` - Se houver erros de validação.
  """
  def create(attrs) do
    Logger.debug("Criando novo evento", %{
      id: attrs[:id],
      topic: attrs[:topic]
    })

    with {:ok, event} <- Event.new(attrs) do
      Logger.debug("Evento validado, persistindo", %{
        id: event.id,
        topic: event.topic
      })

      Memento.transaction! fn ->
        Memento.Query.write(event)
      end

      Logger.info("Evento criado com sucesso", %{
        id: event.id,
        topic: event.topic
      })
      {:ok, event}
    else
      {:error, reason} ->
        Logger.error("Falha ao criar evento", %{
          id: attrs[:id],
          topic: attrs[:topic],
          error: inspect(reason)
        })
        {:error, reason}
    end
  end

  @doc """
  Obtém um evento pelo ID.

  ## Parâmetros

    * `id` - O ID do evento.

  ## Retorno

    * `{:ok, event}` - Se o evento for encontrado.
    * `{:error, :not_found}` - Se o evento não for encontrado.
  """
  def get_by_id(id) do
    Logger.debug("Buscando evento por ID", %{id: id})

    result = Memento.transaction! fn ->
      Logger.debug("Executando consulta Mnesia para evento", %{id: id})
      Memento.Query.read(EventTable, id)
    end

    case result do
      nil ->
        Logger.debug("Evento não encontrado", %{id: id})
        {:error, :not_found}
      event ->
        Logger.debug("Evento encontrado, deserializando payload", %{
          id: id,
          topic: event.topic
        })
        {:ok, Event.deserialize_payload(event)}
    end
  end

  @doc """
  Lista todos os eventos para um tópico específico.

  ## Parâmetros

    * `topic` - O tópico dos eventos.

  ## Retorno

    * Lista de eventos.
  """
  def list_by_topic(topic) do
    Logger.debug("Listando eventos por tópico", %{topic: topic})

    result = Memento.transaction! fn ->
      Logger.debug("Executando consulta Mnesia para eventos do tópico", %{topic: topic})

      Memento.Query.select(EventTable, {:==, :topic, topic})
      |> Enum.map(&Event.deserialize_payload/1)
    end

    Logger.debug("Eventos encontrados para o tópico", %{
      topic: topic,
      count: length(result)
    })

    result
  end

  @doc """
  Lista todos os eventos com um status específico.

  ## Parâmetros

    * `status` - O status dos eventos (:pending, :delivered, :failed).

  ## Retorno

    * Lista de eventos.
  """
  def list_by_status(status) do
    Logger.debug("Listando eventos por status", %{status: status})

    result = Memento.transaction! fn ->
      Logger.debug("Executando consulta Mnesia para eventos com status", %{status: status})

      Memento.Query.select(EventTable, {:==, :status, status})
      |> Enum.map(&Event.deserialize_payload/1)
    end

    Logger.debug("Eventos encontrados para o status", %{
      status: status,
      count: length(result)
    })

    result
  end

  @doc """
  Atualiza um evento existente.

  ## Parâmetros

    * `event` - O evento a ser atualizado.
    * `attrs` - Um mapa com os novos atributos.

  ## Retorno

    * `{:ok, updated_event}` - Em caso de sucesso.
    * `{:error, reason}` - Se houver erros de validação.
  """
  def update(event, attrs) do
    Logger.debug("Atualizando evento", %{
      id: event.id,
      topic: event.topic
    })

    # Mescla os atributos existentes com os novos
    attrs = Map.merge(Map.from_struct(event), attrs)
    attrs = Map.put(attrs, :updated_at, DateTime.utc_now() |> DateTime.to_iso8601())

    with {:ok, updated_event} <- Event.validate(attrs) do
      Logger.debug("Evento validado, persistindo alterações", %{
        id: updated_event.id,
        topic: updated_event.topic
      })

      Memento.transaction! fn ->
        Memento.Query.write(updated_event)
      end

      Logger.info("Evento atualizado com sucesso", %{
        id: updated_event.id,
        topic: updated_event.topic,
        status: updated_event.status
      })
      {:ok, updated_event}
    else
      {:error, reason} ->
        Logger.error("Falha ao atualizar evento", %{
          id: event.id,
          topic: event.topic,
          error: inspect(reason)
        })
        {:error, reason}
    end
  end

  @doc """
  Marca um evento como entregue.

  ## Parâmetros

    * `event` - O evento a ser marcado como entregue.

  ## Retorno

    * `{:ok, updated_event}` - Em caso de sucesso.
    * `{:error, reason}` - Se houver erros.
  """
  def mark_as_delivered(event) do
    Logger.debug("Marcando evento como entregue", %{
      id: event.id,
      topic: event.topic
    })

    attrs = %{
      status: :delivered,
      delivered_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    update(event, attrs)
  end

  @doc """
  Marca um evento como falho.

  ## Parâmetros

    * `event` - O evento a ser marcado como falho.
    * `error_message` - Mensagem de erro.

  ## Retorno

    * `{:ok, updated_event}` - Em caso de sucesso.
    * `{:error, reason}` - Se houver erros.
  """
  def mark_as_failed(event, error_message) do
    Logger.debug("Marcando evento como falho", %{
      id: event.id,
      topic: event.topic,
      retry_count: event.retry_count + 1,
      error: error_message
    })

    attrs = %{
      status: :failed,
      error_message: error_message,
      retry_count: event.retry_count + 1,
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    update(event, attrs)
  end
end
