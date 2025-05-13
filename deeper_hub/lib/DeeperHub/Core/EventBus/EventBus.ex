defmodule DeeperHub.Core.EventBus do
  @moduledoc """
  Barramento de eventos para comunicação assíncrona entre módulos do sistema DeeperHub.

  Este módulo permite que diferentes partes da aplicação se comuniquem de forma desacoplada,
  através de um mecanismo de publicação e assinatura de eventos.

  Exemplo de uso:

  ```elixir
  # Publicando um evento
  DeeperHub.Core.EventBus.publish("user.created", %{user_id: 123, email: "user@example.com"})

  # Assinando eventos
  DeeperHub.Core.EventBus.subscribe("user.*", self())

  # Recebendo eventos (em handle_info de um GenServer)
  def handle_info({:event, "user.created", payload, metadata}, state) do
    # Processar o evento
    {:noreply, state}
  end
  ```
  """

  alias DeeperHub.Core.EventBus.Server
  alias DeeperHub.Core.Logger

  @doc """
  Publica um evento no barramento para todos os assinantes interessados.

  ## Parâmetros

    * `topic` - O tópico do evento (ex: "user.created").
    * `payload` - Os dados associados ao evento.
    * `opts` - Opções adicionais:
      * `:metadata` - Metadados personalizados a serem incluídos no evento. (Padrão: %{})
      * `:event_id` - Um ID de evento customizado. Se não fornecido, um UUID será gerado.
      * `:scope` - O escopo do evento (ex: "global", "tenant:123").
      * `:publisher_id` - Identificador de quem está publicando o evento.

  ## Retorno

    * `{:ok, event_id}` - O ID do evento publicado.
    * `{:error, reason}` - Se ocorrer um erro ao publicar.

  ## Exemplos

      iex> DeeperHub.Core.EventBus.publish("user.created", %{user_id: "123"})
      {:ok, "550e8400-e29b-41d4-a716-446655440000"}
  """
  @spec publish(String.t(), term(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def publish(topic, payload, opts \\ []) do
    Logger.debug("Fachada: Publicando evento", %{
      topic: topic,
      module: __MODULE__
    })
    Server.publish(topic, payload, opts)
  end

  @doc """
  Registra um processo para receber eventos que correspondam a um padrão de tópico.

  ## Parâmetros

    * `topic_pattern` - O padrão do tópico para assinar (ex: "user.*").
    * `subscriber` - O PID do processo que receberá os eventos.

  ## Retorno

    * `:ok` - Se a assinatura for bem-sucedida.
    * `{:error, reason}` - Se ocorrer um erro ao assinar.

  ## Exemplos

      iex> DeeperHub.Core.EventBus.subscribe("user.*", self())
      :ok
  """
  @spec subscribe(String.t(), pid()) :: :ok | {:error, term()}
  def subscribe(topic_pattern, subscriber) do
    Logger.debug("Fachada: Registrando assinante", %{
      topic_pattern: topic_pattern,
      subscriber: inspect(subscriber),
      module: __MODULE__
    })
    Server.subscribe(topic_pattern, subscriber)
  end

  @doc """
  Cancela a assinatura para um padrão de tópico específico.

  ## Parâmetros

    * `topic_pattern` - O padrão do tópico da assinatura a ser removida.
    * `subscriber` - O PID do processo que estava inscrito.

  ## Retorno

    * `:ok` - Se a remoção for bem-sucedida.

  ## Exemplos

      iex> DeeperHub.Core.EventBus.unsubscribe("user.*", self())
      :ok
  """
  @spec unsubscribe(String.t(), pid()) :: :ok
  def unsubscribe(topic_pattern, subscriber) do
    Logger.debug("Fachada: Cancelando assinatura", %{
      topic_pattern: topic_pattern,
      subscriber: inspect(subscriber),
      module: __MODULE__
    })
    Server.unsubscribe(topic_pattern, subscriber)
  end

  @doc """
  Cancela todas as assinaturas de um processo.

  ## Parâmetros

    * `subscriber` - O PID do processo cujas assinaturas serão removidas.

  ## Retorno

    * `:ok` - Se a remoção for bem-sucedida.

  ## Exemplos

      iex> DeeperHub.Core.EventBus.unsubscribe_all(self())
      :ok
  """
  @spec unsubscribe_all(pid()) :: :ok
  def unsubscribe_all(subscriber) do
    Logger.debug("Fachada: Cancelando todas as assinaturas", %{
      subscriber: inspect(subscriber),
      module: __MODULE__
    })
    Server.unsubscribe_all(subscriber)
  end
end
