defmodule DeeperHub.Core.EventBus.Server do
  @moduledoc """
  Servidor GenServer que gerencia o estado e distribuição de eventos do sistema.

  Este módulo é responsável por:
  - Receber eventos publicados
  - Encontrar assinantes interessados
  - Distribuir eventos para assinantes
  - Gerenciar retentativas de entrega
  - Gerenciar o histórico de eventos
  """

  use GenServer

  alias DeeperHub.Core.EventBus.Services.Event, as: EventService

  # API Pública

  @doc """
  Inicia o servidor do EventBus.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Publica um evento no barramento.
  """
  def publish(topic, payload, opts \\ []) do
    event_id = Keyword.get(opts, :event_id, UUID.uuid4())
    metadata = Keyword.get(opts, :metadata, %{})
    scope = Keyword.get(opts, :scope, "global")
    publisher_id = Keyword.get(opts, :publisher_id, "system")

    # Cria o evento com os atributos fornecidos
    event_attrs = %{
      id: event_id,
      topic: topic,
      payload: payload,
      metadata: metadata,
      scope: scope,
      published_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      publisher_id: publisher_id
    }

    GenServer.call(__MODULE__, {:publish, event_attrs})
  end

  @doc """
  Subscreve para receber eventos que correspondam ao padrão do tópico.
  """
  def subscribe(topic_pattern, subscriber) do
    GenServer.call(__MODULE__, {:subscribe, topic_pattern, subscriber})
  end

  @doc """
  Cancela a subscrição para um padrão de tópico específico.
  """
  def unsubscribe(topic_pattern, subscriber) do
    GenServer.call(__MODULE__, {:unsubscribe, topic_pattern, subscriber})
  end

  @doc """
  Cancela todas as subscrições para um assinante.
  """
  def unsubscribe_all(subscriber) do
    GenServer.call(__MODULE__, {:unsubscribe_all, subscriber})
  end

  # Callbacks do GenServer

  @impl true
  def init(_opts) do
    # Garantir que as tabelas Mnesia estejam criadas
    :ok = ensure_tables_created()

    # Estado inicial
    {:ok, %{
      subscribers: %{},        # Mapa de {topic_pattern => [subscribers]}
      monitors: %{},           # Mapa de {ref => {topic_pattern, subscriber}}
      history_config: %{
        enabled: true,
        max_events: 100,       # Número máximo de eventos por tópico
        max_age_seconds: 3600  # Idade máxima dos eventos (1 hora)
      }
    }}
  end

  @impl true
  def handle_call({:publish, event_attrs}, _from, state) do
    # Persistir o evento no banco de dados
    case EventService.create(event_attrs) do
      {:ok, event} ->
        # Encontra assinantes interessados para este tópico
        interested_subscribers = find_interested_subscribers(state.subscribers, event.topic)

        # Distribui o evento para os assinantes
        distribute_event(interested_subscribers, event)

        {:reply, {:ok, event.id}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:subscribe, topic_pattern, subscriber}, _from, state) do
    # Adiciona o assinante à lista para este padrão
    subscribers = Map.get(state.subscribers, topic_pattern, [])
    new_subscribers = [subscriber | subscribers] |> Enum.uniq()
    new_subscribers_map = Map.put(state.subscribers, topic_pattern, new_subscribers)

    # Monitora o processo assinante para detectar quando ele terminar
    ref = Process.monitor(subscriber)
    new_monitors = Map.put(state.monitors, ref, {topic_pattern, subscriber})

    new_state = %{state |
      subscribers: new_subscribers_map,
      monitors: new_monitors
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:unsubscribe, topic_pattern, subscriber}, _from, state) do
    # Remove o assinante da lista para este padrão
    case Map.get(state.subscribers, topic_pattern) do
      nil ->
        # Não há assinantes para este padrão
        {:reply, :ok, state}
      subscribers ->
        new_subscribers = subscribers -- [subscriber]

        new_subscribers_map = if new_subscribers == [] do
          # Se não houver mais assinantes, remove o padrão
          Map.delete(state.subscribers, topic_pattern)
        else
          Map.put(state.subscribers, topic_pattern, new_subscribers)
        end

        # Remove o monitor para este assinante
        {ref, new_monitors} = find_and_remove_monitor(state.monitors, topic_pattern, subscriber)
        if ref, do: Process.demonitor(ref)

        new_state = %{state |
          subscribers: new_subscribers_map,
          monitors: new_monitors
        }

        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:unsubscribe_all, subscriber}, _from, state) do
    # Remove o assinante de todos os padrões
    {new_subscribers, refs_to_remove} = Enum.reduce(state.subscribers, {%{}, []}, fn {pattern, subscribers}, {acc_subscribers, acc_refs} ->
      if subscriber in subscribers do
        new_subscribers = subscribers -- [subscriber]

        new_pattern_subscribers = if new_subscribers == [] do
          # Se não houver mais assinantes, não incluímos o padrão
          acc_subscribers
        else
          Map.put(acc_subscribers, pattern, new_subscribers)
        end

        # Procura o ref do monitor para esta combinação
        ref = find_monitor_ref(state.monitors, pattern, subscriber)
        new_refs = if ref, do: [ref | acc_refs], else: acc_refs

        {new_pattern_subscribers, new_refs}
      else
        # Não há mudanças para este padrão
        {Map.put(acc_subscribers, pattern, subscribers), acc_refs}
      end
    end)

    # Remove os monitores
    Enum.each(refs_to_remove, &Process.demonitor/1)

    new_monitors = Enum.reduce(refs_to_remove, state.monitors, fn ref, acc ->
      Map.delete(acc, ref)
    end)

    new_state = %{state |
      subscribers: new_subscribers,
      monitors: new_monitors
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    # Remove o assinante que terminou
    case Map.get(state.monitors, ref) do
      nil ->
        {:noreply, state}
      {topic_pattern, subscriber} ->
        # Remove da lista de assinantes
        subscribers = Map.get(state.subscribers, topic_pattern, [])
        new_subscribers = subscribers -- [subscriber]

        new_subscribers_map = if new_subscribers == [] do
          # Se não houver mais assinantes para este padrão, remove o padrão
          Map.delete(state.subscribers, topic_pattern)
        else
          Map.put(state.subscribers, topic_pattern, new_subscribers)
        end

        # Remove o monitor
        new_monitors = Map.delete(state.monitors, ref)

        new_state = %{state |
          subscribers: new_subscribers_map,
          monitors: new_monitors
        }

        {:noreply, new_state}
    end
  end

  # Funções privadas

  defp ensure_tables_created do
    try do
      case :mnesia.system_info(:is_running) do
        :yes ->
          # Garantir que a tabela Event esteja criada
          EventService.setup()
          :ok
        _ ->
          # Iniciar o Mnesia
          :mnesia.start()
          EventService.setup()
          :ok
      end
    rescue
      _ ->
        # Se houver algum erro, tentar iniciar o Mnesia e criar as tabelas
        :mnesia.start()
        EventService.setup()
        :ok
    end
  end

  defp find_interested_subscribers(subscribers, topic) do
    Enum.flat_map(subscribers, fn {pattern, subscriber_list} ->
      if topic_matches_pattern?(topic, pattern) do
        subscriber_list
      else
        []
      end
    end)
    |> Enum.uniq()
  end

  defp topic_matches_pattern?(topic, pattern) do
    pattern_regex = pattern
      |> String.replace(".", "\\.")  # Escapa pontos literais
      |> String.replace("*", ".*")   # Converte * em .* para regex
      |> String.replace("**", ".*")  # Converte ** em .* para regex

    regex = ~r/^#{pattern_regex}$/
    Regex.match?(regex, topic)
  end

  defp distribute_event(subscribers, event) do
    Enum.each(subscribers, fn subscriber ->
      # Usa tasks para enviar em paralelo e não bloquear
      Task.start(fn ->
        try do
          send(subscriber, {:event, event.topic, event.payload, event.metadata})

          # Marca o evento como entregue no banco de dados
          # Apenas para registro e diagnóstico
          EventService.mark_as_delivered(event)
        catch
          _kind, reason ->
            # Log do erro (em uma implementação completa usaríamos DeeperHub.Core.Logger)
            IO.puts("Erro ao enviar evento para #{inspect(subscriber)}: #{inspect(reason)}")

            # Marca o evento como falho no banco de dados
            EventService.mark_as_failed(event, "Erro ao entregar: #{inspect(reason)}")
        end
      end)
    end)
  end

  defp find_and_remove_monitor(monitors, topic_pattern, subscriber) do
    {ref, monitors} = Enum.find_value(monitors, {nil, monitors}, fn {ref, {pattern, sub}} ->
      if pattern == topic_pattern && sub == subscriber do
        {ref, Map.delete(monitors, ref)}
      else
        nil
      end
    end)

    {ref, monitors}
  end

  defp find_monitor_ref(monitors, topic_pattern, subscriber) do
    Enum.find_value(monitors, fn {ref, {pattern, sub}} ->
      if pattern == topic_pattern && sub == subscriber do
        ref
      else
        nil
      end
    end)
  end
end
