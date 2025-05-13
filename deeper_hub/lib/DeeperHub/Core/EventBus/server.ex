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
  alias DeeperHub.Core.Logger

  # API Pública

  @doc """
  Inicia o servidor do EventBus.
  """
  def start_link(opts \\ []) do
    Logger.debug("Iniciando servidor do EventBus", %{module: __MODULE__})
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

    Logger.debug("Publicando evento", %{
      topic: topic,
      event_id: event_id,
      scope: scope,
      publisher_id: publisher_id
    })

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
    Logger.debug("Adicionando assinante", %{
      topic_pattern: topic_pattern,
      subscriber: inspect(subscriber)
    })
    GenServer.call(__MODULE__, {:subscribe, topic_pattern, subscriber})
  end

  @doc """
  Cancela a subscrição para um padrão de tópico específico.
  """
  def unsubscribe(topic_pattern, subscriber) do
    Logger.debug("Removendo assinante específico", %{
      topic_pattern: topic_pattern,
      subscriber: inspect(subscriber)
    })
    GenServer.call(__MODULE__, {:unsubscribe, topic_pattern, subscriber})
  end

  @doc """
  Cancela todas as subscrições para um assinante.
  """
  def unsubscribe_all(subscriber) do
    Logger.debug("Removendo todas as assinaturas", %{
      subscriber: inspect(subscriber)
    })
    GenServer.call(__MODULE__, {:unsubscribe_all, subscriber})
  end

  # Callbacks do GenServer

  @impl true
  def init(_opts) do
    Logger.info("Inicializando estado do EventBus", %{module: __MODULE__})

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
    Logger.debug("Processando publicação de evento", %{
      topic: event_attrs.topic,
      event_id: event_attrs.id
    })

    # Persistir o evento no banco de dados
    case EventService.create(event_attrs) do
      {:ok, event} ->
        # Encontra assinantes interessados para este tópico
        interested_subscribers = find_interested_subscribers(state.subscribers, event.topic)

        Logger.debug("Assinantes encontrados para o evento", %{
          topic: event.topic,
          subscriber_count: length(interested_subscribers)
        })

        # Distribui o evento para os assinantes
        distribute_event(interested_subscribers, event)

        Logger.info("Evento publicado com sucesso", %{
          topic: event.topic,
          event_id: event.id,
          subscriber_count: length(interested_subscribers)
        })

        {:reply, {:ok, event.id}, state}

      {:error, reason} ->
        Logger.error("Falha ao persistir evento", %{
          topic: event_attrs.topic,
          reason: inspect(reason)
        })

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

    Logger.info("Assinante adicionado com sucesso", %{
      topic_pattern: topic_pattern,
      subscriber: inspect(subscriber),
      subscriber_count: length(new_subscribers)
    })

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:unsubscribe, topic_pattern, subscriber}, _from, state) do
    Logger.debug("Processando cancelamento de assinatura", %{
      topic_pattern: topic_pattern,
      subscriber: inspect(subscriber)
    })

    # Remove o assinante da lista para este padrão
    case Map.get(state.subscribers, topic_pattern) do
      nil ->
        # Não há assinantes para este padrão
        Logger.debug("Nenhum assinante encontrado para o padrão", %{
          topic_pattern: topic_pattern
        })

        {:reply, :ok, state}
      subscribers ->
        new_subscribers = subscribers -- [subscriber]

        new_subscribers_map = if new_subscribers == [] do
          # Se não houver mais assinantes, remove o padrão
          Logger.debug("Removendo padrão de tópico sem assinantes", %{
            topic_pattern: topic_pattern
          })

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

        Logger.info("Assinatura cancelada com sucesso", %{
          topic_pattern: topic_pattern,
          subscriber: inspect(subscriber)
        })

        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:unsubscribe_all, subscriber}, _from, state) do
    Logger.debug("Processando cancelamento de todas as assinaturas", %{
      subscriber: inspect(subscriber)
    })

    # Remove o assinante de todos os padrões
    {new_subscribers, refs_to_remove} = Enum.reduce(state.subscribers, {%{}, []}, fn {pattern, subscribers}, {acc_subscribers, acc_refs} ->
      if subscriber in subscribers do
        new_subscribers = subscribers -- [subscriber]

        new_pattern_subscribers = if new_subscribers == [] do
          # Se não houver mais assinantes, não incluímos o padrão
          Logger.debug("Removendo padrão de tópico sem assinantes", %{
            topic_pattern: pattern
          })

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

    Logger.info("Todas as assinaturas foram canceladas", %{
      subscriber: inspect(subscriber),
      patterns_affected: length(refs_to_remove)
    })

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    Logger.debug("Processo assinante terminado", %{
      pid: inspect(pid),
      reason: inspect(reason)
    })

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
          Logger.debug("Removendo padrão de tópico sem assinantes", %{
            topic_pattern: topic_pattern
          })

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

        Logger.info("Assinante removido após término do processo", %{
          topic_pattern: topic_pattern,
          subscriber: inspect(subscriber)
        })

        {:noreply, new_state}
    end
  end

  # Funções privadas

  defp ensure_tables_created do
    Logger.debug("Garantindo que as tabelas Mnesia estejam criadas", %{})

    try do
      case :mnesia.system_info(:is_running) do
        :yes ->
          # Garantir que a tabela Event esteja criada
          EventService.setup()
          Logger.debug("Tabelas Mnesia verificadas com sucesso", %{})
          :ok
        _ ->
          # Iniciar o Mnesia
          Logger.debug("Iniciando Mnesia", %{})
          :mnesia.start()
          EventService.setup()
          Logger.debug("Tabelas Mnesia criadas com sucesso", %{})
          :ok
      end
    rescue
      error ->
        Logger.warn("Erro ao verificar tabelas Mnesia, tentando inicializar", %{
          error: inspect(error)
        })

        # Se houver algum erro, tentar iniciar o Mnesia e criar as tabelas
        :mnesia.start()
        EventService.setup()
        Logger.info("Tabelas Mnesia criadas após erro", %{})
        :ok
    end
  end

  defp find_interested_subscribers(subscribers, topic) do
    Logger.debug("Buscando assinantes interessados", %{topic: topic})

    result = Enum.flat_map(subscribers, fn {pattern, subscriber_list} ->
      if topic_matches_pattern?(topic, pattern) do
        Logger.debug("Padrão corresponde ao tópico", %{
          pattern: pattern,
          topic: topic,
          subscriber_count: length(subscriber_list)
        })

        subscriber_list
      else
        []
      end
    end)
    |> Enum.uniq()

    Logger.debug("Total de assinantes encontrados", %{
      topic: topic,
      count: length(result)
    })

    result
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
    Logger.debug("Distribuindo evento para assinantes", %{
      topic: event.topic,
      event_id: event.id,
      subscriber_count: length(subscribers)
    })

    Enum.each(subscribers, fn subscriber ->
      # Usa tasks para enviar em paralelo e não bloquear
      Task.start(fn ->
        try do
          Logger.debug("Enviando evento para assinante", %{
            topic: event.topic,
            event_id: event.id,
            subscriber: inspect(subscriber)
          })

          send(subscriber, {:event, event.topic, event.payload, event.metadata})

          # Marca o evento como entregue no banco de dados
          # Apenas para registro e diagnóstico
          EventService.mark_as_delivered(event)

          Logger.debug("Evento entregue com sucesso", %{
            topic: event.topic,
            event_id: event.id,
            subscriber: inspect(subscriber)
          })
        catch
          kind, reason ->
            Logger.error("Erro ao enviar evento para assinante", %{
              topic: event.topic,
              event_id: event.id,
              subscriber: inspect(subscriber),
              kind: kind,
              error: inspect(reason)
            })

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
