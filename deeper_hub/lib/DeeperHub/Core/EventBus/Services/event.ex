defmodule DeeperHub.Core.EventBus.Services.Event do
  @moduledoc """
  Serviço para gerenciar os eventos armazenados no banco de dados Mnesia.

  Este serviço oferece operações CRUD para eventos, incluindo validação,
  serialização/deserialização de valores, e interação com o banco de dados.
  """

  alias DeeperHub.Core.EventBus.Schema.Event
  alias DeeperHub.Core.EventBus.Schema.EventTable

  @doc """
  Inicializa as tabelas necessárias para o serviço de eventos.
  """
  def setup do
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
    with {:ok, event} <- Event.new(attrs) do
      Memento.transaction! fn ->
        Memento.Query.write(event)
      end

      {:ok, event}
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
    result = Memento.transaction! fn ->
      Memento.Query.read(EventTable, id)
    end

    case result do
      nil -> {:error, :not_found}
      event -> {:ok, Event.deserialize_payload(event)}
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
    Memento.transaction! fn ->
      Memento.Query.select(EventTable, {:==, :topic, topic})
      |> Enum.map(&Event.deserialize_payload/1)
    end
  end

  @doc """
  Lista todos os eventos com um status específico.

  ## Parâmetros

    * `status` - O status dos eventos (:pending, :delivered, :failed).

  ## Retorno

    * Lista de eventos.
  """
  def list_by_status(status) do
    Memento.transaction! fn ->
      Memento.Query.select(EventTable, {:==, :status, status})
      |> Enum.map(&Event.deserialize_payload/1)
    end
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
    # Mescla os atributos existentes com os novos
    attrs = Map.merge(Map.from_struct(event), attrs)
    attrs = Map.put(attrs, :updated_at, DateTime.utc_now() |> DateTime.to_iso8601())

    with {:ok, updated_event} <- Event.validate(attrs) do
      Memento.transaction! fn ->
        Memento.Query.write(updated_event)
      end

      {:ok, updated_event}
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
    attrs = %{
      status: :failed,
      error_message: error_message,
      retry_count: event.retry_count + 1,
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    update(event, attrs)
  end
end
