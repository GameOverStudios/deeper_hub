defmodule Deeper_Hub.Core.EventBus.EventBuilder do
  @moduledoc """
  Utilitário para construção de eventos no sistema Deeper_Hub.

  Este módulo fornece funções auxiliares para criar eventos de forma
  mais simples e consistente, seguindo as melhores práticas para
  estrutura de eventos no barramento de eventos.

  ## Funcionalidades

  * 🏗️ Construção simplificada de eventos
  * 🔄 Geração automática de IDs e timestamps
  * 🔍 Validação de estrutura de eventos
  * 📊 Suporte para campos adicionais como transaction_id e TTL

  ## Exemplo de Uso

  ```elixir
  alias Deeper_Hub.Core.EventBus.EventBuilder
  alias Deeper_Hub.Core.EventBus.Topics
  alias Deeper_Hub.Core.EventBus.EventBusFacade

  # Criar um evento simples
  event = EventBuilder.build(
    Topics.user_registered(),
    %{id: 123, email: "user@example.com"}
  )

  # Criar um evento com metadados adicionais
  event_with_metadata = EventBuilder.build(
    Topics.user_registered(),
    %{id: 123, email: "user@example.com"},
    %{source: "registration_service", transaction_id: "tx-123"}
  )

  # Publicar o evento
  EventBusFacade.publish(event.topic, event.data, event.metadata)
  ```
  """

  # Alias removido pois não é utilizado neste módulo

  @doc """
  Constrói um evento para o barramento de eventos.

  ## Parâmetros

    * `topic` - Tópico do evento
    * `data` - Dados do evento
    * `metadata` - Metadados adicionais do evento (opcional)

  ## Retorno

    * `event` - Estrutura de evento pronta para publicação

  ## Exemplos

  ```elixir
  EventBuilder.build(:user_registered, %{id: 123, email: "user@example.com"})
  ```
  """
  @spec build(atom(), term(), map()) :: map()
  def build(topic, data, metadata \\ %{}) when is_atom(topic) and is_map(metadata) do
    # Gerar ID único para o evento
    id = UUID.uuid4()

    # Obter timestamp atual
    now = System.system_time(:microsecond)

    # Extrair campos especiais dos metadados
    transaction_id = Map.get(metadata, :transaction_id)
    source = Map.get(metadata, :source, __MODULE__)
    ttl = Map.get(metadata, :ttl)

    # Remover campos especiais dos metadados para evitar duplicação
    filtered_metadata = metadata
      |> Map.drop([:transaction_id, :source, :ttl])

    # Construir o evento
    %{
      id: id,
      transaction_id: transaction_id,
      topic: topic,
      data: data,
      metadata: filtered_metadata,
      initialized_at: now,
      occurred_at: now,
      source: source,
      ttl: ttl
    }
  end

  @doc """
  Constrói um evento para o barramento de eventos com um transaction_id específico.

  ## Parâmetros

    * `topic` - Tópico do evento
    * `data` - Dados do evento
    * `transaction_id` - ID da transação
    * `metadata` - Metadados adicionais do evento (opcional)

  ## Retorno

    * `event` - Estrutura de evento pronta para publicação

  ## Exemplos

  ```elixir
  EventBuilder.build_with_transaction(
    :user_registered,
    %{id: 123, email: "user@example.com"},
    "tx-123"
  )
  ```
  """
  @spec build_with_transaction(atom(), term(), String.t(), map()) :: map()
  def build_with_transaction(topic, data, transaction_id, metadata \\ %{}) when is_atom(topic) and is_map(metadata) do
    # Adicionar transaction_id aos metadados
    metadata_with_transaction = Map.put(metadata, :transaction_id, transaction_id)

    # Construir o evento usando a função build
    build(topic, data, metadata_with_transaction)
  end

  @doc """
  Constrói um evento para o barramento de eventos com um TTL específico.

  ## Parâmetros

    * `topic` - Tópico do evento
    * `data` - Dados do evento
    * `ttl` - Tempo de vida do evento em microssegundos
    * `metadata` - Metadados adicionais do evento (opcional)

  ## Retorno

    * `event` - Estrutura de evento pronta para publicação

  ## Exemplos

  ```elixir
  # Evento com TTL de 1 hora
  EventBuilder.build_with_ttl(
    :user_registered,
    %{id: 123, email: "user@example.com"},
    3_600_000_000 # 1 hora em microssegundos
  )
  ```
  """
  @spec build_with_ttl(atom(), term(), integer(), map()) :: map()
  def build_with_ttl(topic, data, ttl, metadata \\ %{}) when is_atom(topic) and is_integer(ttl) and is_map(metadata) do
    # Adicionar TTL aos metadados
    metadata_with_ttl = Map.put(metadata, :ttl, ttl)

    # Construir o evento usando a função build
    build(topic, data, metadata_with_ttl)
  end

  @doc """
  Constrói um evento para o barramento de eventos com uma fonte específica.

  ## Parâmetros

    * `topic` - Tópico do evento
    * `data` - Dados do evento
    * `source` - Fonte do evento
    * `metadata` - Metadados adicionais do evento (opcional)

  ## Retorno

    * `event` - Estrutura de evento pronta para publicação

  ## Exemplos

  ```elixir
  EventBuilder.build_with_source(
    :user_registered,
    %{id: 123, email: "user@example.com"},
    "registration_service"
  )
  ```
  """
  @spec build_with_source(atom(), term(), String.t(), map()) :: map()
  def build_with_source(topic, data, source, metadata \\ %{}) when is_atom(topic) and is_binary(source) and is_map(metadata) do
    # Adicionar source aos metadados
    metadata_with_source = Map.put(metadata, :source, source)

    # Construir o evento usando a função build
    build(topic, data, metadata_with_source)
  end

  @doc """
  Valida se um evento possui todos os campos obrigatórios.

  ## Parâmetros

    * `event` - Evento a ser validado

  ## Retorno

    * `{:ok, event}` - Evento válido
    * `{:error, reason}` - Evento inválido com motivo da falha

  ## Exemplos

  ```elixir
  event = EventBuilder.build(:user_registered, %{id: 123})
  {:ok, _} = EventBuilder.validate(event)
  ```
  """
  @spec validate(map()) :: {:ok, map()} | {:error, String.t()}
  def validate(event) when is_map(event) do
    # Verificar campos obrigatórios
    required_fields = [:id, :topic, :data]

    # Verificar se todos os campos obrigatórios estão presentes
    missing_fields = Enum.filter(required_fields, fn field -> !Map.has_key?(event, field) end)

    if Enum.empty?(missing_fields) do
      # Verificar se o tópico é um átomo
      if is_atom(event.topic) do
        {:ok, event}
      else
        {:error, "O tópico deve ser um átomo"}
      end
    else
      {:error, "Campos obrigatórios ausentes: #{Enum.join(missing_fields, ", ")}"}
    end
  end
end
