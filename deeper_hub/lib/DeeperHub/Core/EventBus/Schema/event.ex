defmodule DeeperHub.Core.EventBus.Schema.EventTable do
  @moduledoc """
  Definição da tabela Mnesia para eventos.
  """

  use Memento.Table,
    attributes: [
      :id,          # ID único do evento
      :topic,       # Tópico do evento (ex: "user.created")
      :payload,     # Dados do evento (serializado)
      :metadata,    # Metadados adicionais
      :scope,       # Escopo do evento (ex: "global", "tenant:123")
      :status,      # Status do evento (:pending, :delivered, :failed)
      :published_at,# Data e hora de publicação
      :delivered_at,# Data e hora de entrega
      :retry_count, # Contagem de tentativas de entrega
      :publisher_id,# Identificador de quem publicou
      :error_message,# Mensagem de erro caso falhe
      :inserted_at, # Data de criação
      :updated_at   # Data de atualização
    ],
    index: [:topic, :status],
    type: :ordered_set
end

defmodule DeeperHub.Core.EventBus.Schema.Event do
  @moduledoc """
  Schema para representar eventos no sistema de EventBus.

  Este schema define a estrutura dos eventos que são publicados e assinados
  através do sistema de barramento de eventos.
  """

  alias DeeperHub.Core.EventBus.Schema.EventTable

  # Define explicitamente os atributos da estrutura em vez de usar Memento.Table.attributes
  defstruct [
    :id,
    :topic,
    :payload,
    :metadata,
    :scope,
    :status,
    :published_at,
    :delivered_at,
    :retry_count,
    :publisher_id,
    :error_message,
    :inserted_at,
    :updated_at
  ]

  @doc """
  Cria um novo registro de evento.
  """
  def new(attrs) do
    id = attrs[:id] || UUID.uuid4()
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    published_at = attrs[:published_at] || timestamp

    # Valores padrão
    defaults = %{
      id: id,
      metadata: %{},
      scope: "global",
      status: :pending,
      retry_count: 0,
      delivered_at: nil,
      error_message: nil,
      inserted_at: timestamp,
      updated_at: timestamp,
      published_at: published_at
    }

    # Mescla os atributos fornecidos com os padrões
    attrs = Map.merge(defaults, Map.new(attrs))

    # Valida os dados
    validate(attrs)
  end

  @doc """
  Valida os dados de um evento.
  """
  def validate(attrs) do
    with :ok <- validate_required(attrs, [:topic, :payload]),
         :ok <- validate_topic_length(attrs.topic) do
      # Serializa o payload se necessário
      attrs = prepare_payload(attrs)
      {:ok, struct(EventTable, attrs)}
    end
  end

  defp validate_required(attrs, fields) do
    missing = Enum.filter(fields, fn field ->
      is_nil(Map.get(attrs, field))
    end)

    if Enum.empty?(missing) do
      :ok
    else
      {:error, "Campos obrigatórios ausentes: #{Enum.join(missing, ", ")}"}
    end
  end

  defp validate_topic_length(topic) when is_binary(topic) do
    if String.length(topic) >= 1 and String.length(topic) <= 255 do
      :ok
    else
      {:error, "O tópico deve ter entre 1 e 255 caracteres"}
    end
  end

  defp prepare_payload(attrs) do
    payload = attrs.payload

    # Se o payload já não for binário, serializa usando Erlang
    if is_binary(payload) do
      attrs
    else
      Map.put(attrs, :payload, :erlang.term_to_binary(payload))
    end
  end

  @doc """
  Deserializa o payload de um evento.
  """
  def deserialize_payload(event) do
    try do
      payload = :erlang.binary_to_term(event.payload)
      Map.put(event, :payload, payload)
    rescue
      _ -> event
    end
  end
end
