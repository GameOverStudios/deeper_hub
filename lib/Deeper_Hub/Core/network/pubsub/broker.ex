defmodule DeeperHub.Core.Network.PubSub.Broker do
  @moduledoc """
  Broker central para o sistema de publicação/assinatura.

  Este módulo implementa um broker de mensagens de alto desempenho que gerencia
  a distribuição de mensagens entre publicadores e assinantes. Ele é projetado
  para alta concorrência e baixa latência, sendo capaz de processar milhares
  de mensagens por segundo.

  O broker utiliza o Registry do Elixir para rastrear assinantes de forma eficiente,
  e implementa mecanismos de backpressure para lidar com picos de carga.
  """
  use GenServer

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  # Nome do registro usado para rastrear assinantes
  @registry DeeperHub.Core.Network.PubSub.Registry

  # Limite de mensagens em fila antes de aplicar backpressure
  @backpressure_threshold 10_000

  # Estrutura que representa o estado do broker
  defstruct [
    :message_count,      # Contador de mensagens processadas
    :start_time,         # Timestamp de início do broker
    :queue_size,         # Tamanho atual da fila de mensagens
    :topic_metrics       # Métricas por tópico
  ]

  @doc """
  Inicia o broker de mensagens.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Publica uma mensagem em um tópico.

  ## Parâmetros

  - `topic` - Nome do tópico
  - `message` - Mensagem a ser publicada
  - `opts` - Opções adicionais
    - `:priority` - Prioridade da mensagem (`:high`, `:normal`, `:low`)
    - `:ttl` - Tempo de vida da mensagem em milissegundos

  ## Retorno

  - `:ok` - Mensagem publicada com sucesso
  - `{:error, reason}` - Falha ao publicar a mensagem
  """
  def publish(topic, message, opts \\ []) do
    GenServer.call(__MODULE__, {:publish, topic, message, opts})
  end

  @doc """
  Assina um tópico para receber mensagens.

  ## Parâmetros

  - `topic` - Nome do tópico
  - `subscriber` - PID ou nome registrado do assinante
  - `opts` - Opções adicionais
    - `:selector` - Função para filtrar mensagens

  ## Retorno

  - `{:ok, subscription_id}` - Assinatura criada com sucesso
  - `{:error, reason}` - Falha ao criar a assinatura
  """
  def subscribe(topic, subscriber, opts \\ []) do
    # Registra o assinante no Registry
    {:ok, _} = Registry.register(@registry, topic, {subscriber, opts})

    # Gera um ID único para a assinatura
    subscription_id = "#{topic}:#{UUID.uuid4()}"

    # Notifica o broker sobre a nova assinatura
    GenServer.cast(__MODULE__, {:subscription_added, topic, subscriber})

    {:ok, subscription_id}
  end

  @doc """
  Cancela a assinatura de um tópico.

  ## Parâmetros

  - `topic` - Nome do tópico
  - `subscriber` - PID ou nome registrado do assinante

  ## Retorno

  - `:ok` - Assinatura cancelada com sucesso
  - `{:error, reason}` - Falha ao cancelar a assinatura
  """
  def unsubscribe(topic, subscriber) do
    # Remove o assinante do Registry
    Registry.unregister(@registry, topic)

    # Notifica o broker sobre a remoção da assinatura
    GenServer.cast(__MODULE__, {:subscription_removed, topic, subscriber})

    :ok
  end

  @doc """
  Obtém estatísticas do broker.

  ## Retorno

  Um mapa contendo estatísticas do broker, como:

  - `:message_count` - Número total de mensagens processadas
  - `:uptime_seconds` - Tempo de atividade em segundos
  - `:messages_per_second` - Taxa média de mensagens por segundo
  - `:queue_size` - Tamanho atual da fila de mensagens
  - `:topics` - Número de tópicos ativos
  - `:subscribers` - Número total de assinantes
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # Callbacks do GenServer

  @impl true
  def init(_opts) do
    Logger.info("Iniciando broker de mensagens...", module: __MODULE__)

    # Inicializa o estado do broker
    state = %__MODULE__{
      message_count: 0,
      start_time: DateTime.utc_now(),
      queue_size: 0,
      topic_metrics: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:publish, topic, message, opts}, _from, state) do
    # Verifica se há backpressure
    if state.queue_size > @backpressure_threshold do
      # Aplica backpressure baseado na prioridade da mensagem
      priority = Keyword.get(opts, :priority, :normal)

      case priority do
        :high ->
          # Mensagens de alta prioridade são sempre processadas
          :ok
        :normal when state.queue_size > @backpressure_threshold * 2 ->
          # Mensagens normais são rejeitadas em caso de sobrecarga severa
          Logger.warn("Backpressure aplicado para mensagem normal no tópico #{topic}", module: __MODULE__)
          {:reply, {:error, :backpressure}, state}
        :low when state.queue_size > @backpressure_threshold ->
          # Mensagens de baixa prioridade são as primeiras a serem rejeitadas
          Logger.warn("Backpressure aplicado para mensagem de baixa prioridade no tópico #{topic}", module: __MODULE__)
          {:reply, {:error, :backpressure}, state}
        _ ->
          # Outras mensagens são processadas normalmente
          :ok
      end
    end

    # Distribui a mensagem para todos os assinantes do tópico
    dispatch_message(topic, message, opts)

    # Atualiza o estado do broker
    state = %{state |
      message_count: state.message_count + 1,
      queue_size: state.queue_size - 1,
      topic_metrics: update_topic_metrics(state.topic_metrics, topic, :publish)
    }

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    # Calcula estatísticas do broker
    uptime_seconds = DateTime.diff(DateTime.utc_now(), state.start_time)
    messages_per_second = if uptime_seconds > 0, do: state.message_count / uptime_seconds, else: 0

    # Conta o número de tópicos e assinantes
    topics = Registry.select(@registry, [{{:"$1", :_, :_}, [], [:"$1"]}]) |> Enum.uniq() |> length()
    subscribers = Registry.select(@registry, [{{:_, :_, :"$1"}, [], [:"$1"]}]) |> length()

    stats = %{
      message_count: state.message_count,
      uptime_seconds: uptime_seconds,
      messages_per_second: messages_per_second,
      queue_size: state.queue_size,
      topics: topics,
      subscribers: subscribers,
      topic_metrics: state.topic_metrics
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_cast({:subscription_added, topic, _subscriber}, state) do
    # Atualiza métricas do tópico
    topic_metrics = update_topic_metrics(state.topic_metrics, topic, :subscribe)
    {:noreply, %{state | topic_metrics: topic_metrics}}
  end

  @impl true
  def handle_cast({:subscription_removed, topic, _subscriber}, state) do
    # Atualiza métricas do tópico
    topic_metrics = update_topic_metrics(state.topic_metrics, topic, :unsubscribe)
    {:noreply, %{state | topic_metrics: topic_metrics}}
  end

  @impl true
  def handle_cast({:queue_size_update, size}, state) do
    # Atualiza o tamanho da fila
    {:noreply, %{state | queue_size: size}}
  end

  # Funções privadas

  # Distribui uma mensagem para todos os assinantes de um tópico
  defp dispatch_message(topic, message, opts) do
    # Obtém todos os assinantes do tópico
    Registry.dispatch(@registry, topic, fn entries ->
      # Para cada assinante, verifica se a mensagem deve ser entregue
      Enum.each(entries, fn {_pid, {subscriber, sub_opts}} ->
        # Verifica se há um seletor definido
        if selector = Keyword.get(sub_opts, :selector) do
          # Aplica o seletor para filtrar a mensagem
          if selector.(message) do
            deliver_message(subscriber, topic, message, opts)
          end
        else
          # Sem seletor, entrega a mensagem diretamente
          deliver_message(subscriber, topic, message, opts)
        end
      end)
    end)
  end

  # Entrega uma mensagem para um assinante
  defp deliver_message(subscriber, topic, message, _opts) do
    # Cria a mensagem formatada
    formatted_message = %{
      topic: topic,
      payload: message,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    # Envia a mensagem para o assinante
    try do
      send(subscriber, {:pubsub_message, formatted_message})
    rescue
      _ ->
        Logger.warn("Falha ao entregar mensagem para assinante #{inspect(subscriber)}", module: __MODULE__)
    end
  end

  # Atualiza as métricas de um tópico
  defp update_topic_metrics(metrics, topic, action) do
    # Obtém as métricas atuais do tópico ou inicializa novas
    topic_metrics = Map.get(metrics, topic, %{
      message_count: 0,
      subscriber_count: 0,
      last_activity: DateTime.utc_now()
    })

    # Atualiza as métricas com base na ação
    topic_metrics = case action do
      :publish ->
        %{topic_metrics |
          message_count: topic_metrics.message_count + 1,
          last_activity: DateTime.utc_now()
        }
      :subscribe ->
        %{topic_metrics |
          subscriber_count: topic_metrics.subscriber_count + 1,
          last_activity: DateTime.utc_now()
        }
      :unsubscribe ->
        %{topic_metrics |
          subscriber_count: max(0, topic_metrics.subscriber_count - 1),
          last_activity: DateTime.utc_now()
        }
    end

    # Atualiza o mapa de métricas
    Map.put(metrics, topic, topic_metrics)
  end
end
