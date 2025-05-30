defmodule DeeperHub.Core.Telemetry.Storage.MetricsStore do
  @moduledoc """
  Armazenamento em memória para métricas de telemetria.
  
  Este módulo implementa um armazenamento temporário de métricas
  coletadas pelo sistema de telemetria, permitindo:
  
  1. Redução de sobrecarga - armazenando métricas na memória
  2. Consulta rápida - acesso eficiente a dados históricos recentes
  3. Retenção configurável - controle sobre o período de retenção
  """
  
  use GenServer
  require DeeperHub.Core.Logger
  
  @default_retention_period 3600 # 1 hora em segundos
  @cleanup_interval 60_000 # 1 minuto em milissegundos
  
  # API pública
  
  @doc """
  Inicia o armazenamento de métricas.
  
  ## Parâmetros
  
    * `opts` - Opções de configuração.
      * `:retention_period` - Período de retenção em segundos (padrão: 3600)
      * `:table_name` - Nome da tabela ETS (padrão: :deeper_hub_metrics_store)
  
  ## Retorno
  
    * `{:ok, pid}` - Iniciado com sucesso.
    * `{:error, reason}` - Erro ao iniciar.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end
  
  @doc """
  Armazena uma métrica no repositório.
  
  ## Parâmetros
  
    * `component` - Componente associado à métrica
    * `metric_key` - Chave única da métrica
    * `value` - Valor da métrica
    * `metadata` - Metadados adicionais
  
  ## Retorno
  
    * `:ok` - Armazenado com sucesso
  """
  @spec store(atom(), atom(), term(), map()) :: :ok
  def store(component, metric_key, value, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:store, component, metric_key, value, metadata})
  end
  
  @doc """
  Recupera métricas armazenadas para um componente específico.
  
  ## Parâmetros
  
    * `component` - Componente a consultar
    * `time_window` - Janela de tempo em segundos (padrão: 300 - 5 minutos)
  
  ## Retorno
  
    * `{:ok, metrics}` - Lista de métricas encontradas
    * `{:error, reason}` - Erro ao consultar
  """
  @spec get_metrics(atom(), integer()) :: {:ok, list()} | {:error, term()}
  def get_metrics(component, time_window \\ 300) do
    GenServer.call(__MODULE__, {:get_metrics, component, time_window})
  end
  
  @doc """
  Recupera um resumo de métricas para todos os componentes.
  
  ## Parâmetros
  
    * `time_window` - Janela de tempo em segundos (padrão: 300 - 5 minutos)
  
  ## Retorno
  
    * `{:ok, metrics}` - Resumo de métricas por componente
    * `{:error, reason}` - Erro ao consultar
  """
  @spec get_summary(integer()) :: {:ok, map()} | {:error, term()}
  def get_summary(time_window \\ 300) do
    GenServer.call(__MODULE__, {:get_summary, time_window})
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(opts) do
    retention_period = Keyword.get(opts, :retention_period, @default_retention_period)
    table_name = Keyword.get(opts, :table_name, :deeper_hub_metrics_store)
    
    # Cria tabela ETS para armazenar métricas
    table = :ets.new(table_name, [:named_table, :set, :public, 
                                  write_concurrency: true, 
                                  read_concurrency: true])
    
    # Agenda limpeza periódica
    schedule_cleanup()
    
    DeeperHub.Core.Logger.info("Armazenamento de métricas de telemetria inicializado com período de retenção de #{retention_period} segundos")
    
    {:ok, %{table: table, retention_period: retention_period}}
  end
  
  @impl true
  def handle_cast({:store, component, metric_key, value, metadata}, state) do
    timestamp = :os.system_time(:second)
    record = {
      {component, metric_key, timestamp},
      %{
        component: component,
        metric_key: metric_key,
        value: value,
        metadata: metadata,
        timestamp: timestamp
      }
    }
    
    :ets.insert(state.table, record)
    {:noreply, state}
  end
  
  @impl true
  def handle_call({:get_metrics, component, time_window}, _from, state) do
    now = :os.system_time(:second)
    cutoff = now - time_window
    
    # Constrói padrão de consulta
    # Recupera todas as métricas do componente dentro da janela de tempo
    pattern = {{component, :_, :"$1"}, :_}
    guard = [{:>, :"$1", cutoff}]
    result = :ets.select(state.table, [{pattern, guard, [:"$_"]}])
    
    # Extrai os valores da tupla
    metrics = Enum.map(result, fn {{_, _, _}, value} -> value end)
    
    {:reply, {:ok, metrics}, state}
  end
  
  @impl true
  def handle_call({:get_summary, time_window}, _from, state) do
    now = :os.system_time(:second)
    cutoff = now - time_window
    
    # Constrói padrão de consulta para todos os componentes
    pattern = {{:_, :_, :"$1"}, :"$2"}
    guard = [{:>, :"$1", cutoff}]
    result = :ets.select(state.table, [{pattern, guard, [:"$2"]}])
    
    # Agrupa métricas por componente
    summary = Enum.reduce(result, %{}, fn metric, acc ->
      component = metric.component
      Map.update(acc, component, [metric], fn metrics -> [metric | metrics] end)
    end)
    
    {:reply, {:ok, summary}, state}
  end
  
  @impl true
  def handle_info(:cleanup, state) do
    # Realiza limpeza de métricas antigas
    now = :os.system_time(:second)
    cutoff = now - state.retention_period
    
    # Remove registros mais antigos que o período de retenção
    pattern = {{:_, :_, :"$1"}, :_}
    guard = [{:<, :"$1", cutoff}]
    count = :ets.select_delete(state.table, [{pattern, guard, [true]}])
    
    if count > 0 do
      DeeperHub.Core.Logger.debug("Limpeza de métricas: #{count} registros removidos")
    end
    
    # Agenda próxima limpeza
    schedule_cleanup()
    
    {:noreply, state}
  end
  
  # Funções privadas
  
  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
