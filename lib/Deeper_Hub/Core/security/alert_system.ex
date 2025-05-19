defmodule DeeperHub.Core.Security.AlertSystem do
  @moduledoc """
  Sistema de alertas de segurança para o DeeperHub.

  Este módulo gerencia a geração e envio de alertas para tentativas
  de ataque e eventos de segurança relevantes.
  """

  use GenServer

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger

  # Níveis de severidade de alertas
  # @severity_levels [:info, :warning, :critical]

  # Tabela ETS para armazenar alertas
  @alerts_table :deeper_hub_security_alerts

  # Intervalo de limpeza de alertas antigos (1 dia)
  @cleanup_interval 86_400_000

  # Limite de alertas por tipo por hora (para evitar spam)
  @alert_rate_limit 10

  #
  # API Pública
  #

  @doc """
  Inicia o sistema de alertas.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gera um alerta de segurança.

  ## Parâmetros

  - `type` - Tipo de alerta
  - `message` - Mensagem do alerta
  - `details` - Detalhes adicionais do alerta
  - `severity` - Severidade do alerta (:info, :warning, :critical)

  ## Retorno

  - ID do alerta gerado
  """
  def generate_alert(type, message, details \\ %{}, severity \\ :warning) do
    GenServer.call(__MODULE__, {:generate_alert, type, message, details, severity})
  end

  @doc """
  Obtém todos os alertas ativos.

  ## Parâmetros

  - `options` - Opções de filtragem
    - `:severity` - Filtrar por severidade
    - `:type` - Filtrar por tipo
    - `:since` - Filtrar por timestamp (desde)
    - `:limit` - Limitar número de resultados

  ## Retorno

  - Lista de alertas
  """
  def get_alerts(options \\ []) do
    severity = Keyword.get(options, :severity)
    type = Keyword.get(options, :type)
    since = Keyword.get(options, :since, 0)
    limit = Keyword.get(options, :limit, 100)

    # Obtém todos os alertas
    alerts = :ets.tab2list(@alerts_table)
    |> Enum.map(fn {_id, alert} -> alert end)
    |> Enum.filter(fn alert ->
      (is_nil(severity) or alert.severity == severity) and
      (is_nil(type) or alert.type == type) and
      alert.timestamp >= since
    end)
    |> Enum.sort_by(fn alert -> alert.timestamp end, :desc)
    |> Enum.take(limit)

    alerts
  end

  @doc """
  Marca um alerta como resolvido.

  ## Parâmetros

  - `id` - ID do alerta
  - `resolution_notes` - Notas de resolução

  ## Retorno

  - `:ok` se o alerta foi marcado como resolvido
  - `{:error, reason}` caso contrário
  """
  def resolve_alert(id, resolution_notes \\ "") do
    GenServer.call(__MODULE__, {:resolve_alert, id, resolution_notes})
  end

  #
  # Callbacks do GenServer
  #

  @impl true
  def init(_opts) do
    # Inicializa a tabela ETS para alertas
    create_alerts_table()

    # Agenda a limpeza periódica
    schedule_cleanup()

    # Carrega a configuração
    config = Application.get_env(:deeper_hub, :security_alerts, [])

    # Configura os canais de notificação
    notification_channels = config[:notification_channels] || []

    Logger.info("Sistema de alertas de segurança iniciado", module: __MODULE__)

    {:ok, %{
      notification_channels: notification_channels,
      alert_counts: %{}
    }}
  end

  @impl true
  def handle_call({:generate_alert, type, message, details, severity}, _from, state) do
    now = :os.system_time(:second)

    # Verifica se o alerta deve ser limitado (para evitar spam)
    hour_key = "#{type}_#{div(now, 3600)}"
    current_count = Map.get(state.alert_counts, hour_key, 0)

    if current_count >= @alert_rate_limit do
      # Alerta limitado, apenas registra no log
      Logger.warn("Alerta de segurança limitado: #{type}",
                  module: __MODULE__,
                  message: message,
                  severity: severity)

      {:reply, {:error, :rate_limited}, state}
    else
      # Gera um ID único para o alerta
      id = generate_alert_id()

      # Cria o alerta
      alert = %{
        id: id,
        type: type,
        message: message,
        details: details,
        severity: severity,
        timestamp: now,
        resolved: false,
        resolution_timestamp: nil,
        resolution_notes: nil
      }

      # Armazena o alerta
      :ets.insert(@alerts_table, {id, alert})

      # Atualiza o contador de alertas
      updated_counts = Map.put(state.alert_counts, hour_key, current_count + 1)

      # Envia notificações
      send_notifications(alert, state.notification_channels)

      # Registra o alerta no log
      log_alert(alert)

      {:reply, {:ok, id}, %{state | alert_counts: updated_counts}}
    end
  end

  @impl true
  def handle_call({:resolve_alert, id, resolution_notes}, _from, state) do
    case :ets.lookup(@alerts_table, id) do
      [{^id, alert}] ->
        now = :os.system_time(:second)

        # Atualiza o alerta
        updated_alert = Map.merge(alert, %{
          resolved: true,
          resolution_timestamp: now,
          resolution_notes: resolution_notes
        })

        # Armazena o alerta atualizado
        :ets.insert(@alerts_table, {id, updated_alert})

        Logger.info("Alerta de segurança resolvido: #{id}",
                    module: __MODULE__,
                    type: alert.type,
                    resolution_notes: resolution_notes)

        {:reply, :ok, state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_old_alerts()
    schedule_cleanup()
    {:noreply, state}
  end

  #
  # Funções privadas
  #

  # Cria a tabela ETS para alertas
  defp create_alerts_table do
    try do
      :ets.new(@alerts_table, [:named_table, :public, :set, {:read_concurrency, true}, {:write_concurrency, true}])
      Logger.debug("Tabela ETS #{@alerts_table} criada com sucesso", module: __MODULE__)
    rescue
      ArgumentError ->
        Logger.debug("Tabela ETS #{@alerts_table} já existe", module: __MODULE__)
    end
  end

  # Agenda a limpeza periódica
  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  # Limpa alertas antigos
  defp cleanup_old_alerts do
    now = :os.system_time(:second)
    cutoff = now - 30 * 86400 # 30 dias

    # Obtém todos os alertas
    all_alerts = :ets.tab2list(@alerts_table)

    # Filtra alertas antigos e resolvidos
    old_alerts = Enum.filter(all_alerts, fn {_id, alert} ->
      alert.resolved and alert.timestamp < cutoff
    end)

    # Remove alertas antigos
    Enum.each(old_alerts, fn {id, _alert} ->
      :ets.delete(@alerts_table, id)
    end)

    Logger.debug("Limpeza de alertas antigos concluída. Removidos: #{length(old_alerts)}",
                 module: __MODULE__)
  end

  # Gera um ID único para o alerta
  defp generate_alert_id do
    UUID.uuid4()
  end

  # Envia notificações para os canais configurados
  defp send_notifications(alert, channels) do
    Enum.each(channels, fn channel ->
      try do
        case channel do
          {:webhook, url} ->
            send_webhook_notification(url, alert)

          {:email, email_config} ->
            send_email_notification(email_config, alert)

          {:log, _} ->
            # Já registrado no log, não precisa fazer nada
            :ok

          _ ->
            Logger.warn("Canal de notificação desconhecido",
                        module: __MODULE__,
                        channel: channel)
        end
      rescue
        e ->
          Logger.error("Erro ao enviar notificação: #{inspect(e)}",
                      module: __MODULE__,
                      channel: channel,
                      alert_id: alert.id)
      end
    end)
  end

  # Envia notificação via webhook
  defp send_webhook_notification(url, alert) do
    # Prepara o payload
    _payload = %{
      id: alert.id,
      type: alert.type,
      message: alert.message,
      severity: alert.severity,
      timestamp: alert.timestamp,
      details: alert.details
    }

    # Aqui seria implementado o envio HTTP real
    # Por enquanto, apenas registra no log
    Logger.info("Enviando notificação webhook para #{url}",
                module: __MODULE__,
                alert_id: alert.id)
  end

  # Envia notificação via email
  defp send_email_notification(email_config, alert) do
    # Aqui seria implementado o envio de email real
    # Por enquanto, apenas registra no log
    Logger.info("Enviando notificação email para #{inspect(email_config[:recipients])}",
                module: __MODULE__,
                alert_id: alert.id)
  end

  # Registra o alerta no log
  defp log_alert(alert) do
    log_fn = case alert.severity do
      :info -> &Logger.info/2
      :warning -> &Logger.warn/2
      :critical -> &Logger.error/2
    end

    log_fn.("Alerta de segurança: #{alert.message}",
            module: __MODULE__,
            alert_id: alert.id,
            alert_type: alert.type,
            severity: alert.severity,
            details: alert.details)
  end
end
