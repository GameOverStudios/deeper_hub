defmodule Deeper_Hub.Core.Telemetry.TelemetrySupervisor do
  @moduledoc """
  Supervisor para o sistema de telemetria do DeeperHub. 🔍
  
  Este módulo é responsável por iniciar e supervisionar os processos
  relacionados à telemetria, garantindo que eles sejam reiniciados
  em caso de falha.
  """
  
  use Supervisor
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics
  alias Deeper_Hub.Core.Telemetry.TelemetryConfig
  
  @doc """
  Inicia o supervisor de telemetria.
  
  ## Parâmetros
  
  - `opts`: Opções para o supervisor (opcional)
  
  ## Retorno
  
  - `{:ok, pid}` se o supervisor for iniciado com sucesso
  - `{:error, reason}` em caso de falha
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    # Registra métricas de início
    Metrics.increment_counter(:system, :telemetry_supervisor_start_total)
    start_time = System.monotonic_time()
    
    Logger.info("Iniciando supervisor de telemetria", %{module: __MODULE__})
    
    # Inicia o supervisor
    result = Supervisor.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
    
    # Registra métricas de resultado
    case result do
      {:ok, _pid} ->
        duration = System.monotonic_time() - start_time
        duration_ms = System.convert_time_unit(duration, :native, :millisecond)
        
        Metrics.increment_counter(:system, :telemetry_supervisor_start_success)
        Metrics.record_execution_time(:system, :telemetry_supervisor_start_time, duration_ms)
        
        Logger.info("Supervisor de telemetria iniciado com sucesso", %{
          module: __MODULE__,
          duration_ms: duration_ms
        })
        
      {:error, reason} ->
        Metrics.increment_counter(:system, :telemetry_supervisor_start_failure)
        
        Logger.error("Falha ao iniciar supervisor de telemetria", %{
          module: __MODULE__,
          error: reason
        })
    end
    
    result
  end
  
  @impl true
  def init(:ok) do
    # Inicializa o sistema de telemetria
    :ok = TelemetryConfig.initialize()
    
    # Define os processos filhos
    # Neste momento, não temos processos filhos específicos para telemetria,
    # mas podemos adicionar no futuro (como coletores de telemetria, exportadores, etc.)
    children = []
    
    # Estratégia de supervisão: one_for_one
    # Cada processo filho é tratado independentemente
    Supervisor.init(children, strategy: :one_for_one)
  end
  
  @doc """
  Retorna os child specs para inclusão na árvore de supervisão principal.
  
  Esta função é usada para incluir o supervisor de telemetria na árvore
  de supervisão principal da aplicação.
  
  ## Retorno
  
  - Lista de child specs
  """
  @spec child_specs() :: list()
  def child_specs do
    [
      # Supervisor de telemetria
      {__MODULE__, []}
    ]
  end
end
