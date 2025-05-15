defmodule Deeper_Hub.Core.Metrics.Supervisor do
  @moduledoc """
  Supervisor para o sistema de métricas do DeeperHub.
  
  Este módulo é responsável por iniciar e supervisionar os componentes
  do sistema de métricas, incluindo o coletor periódico de métricas e
  os reporters que enviam as métricas para sistemas externos.
  
  ## Funcionalidades
  
  * 🔄 Inicialização do coletor periódico de métricas
  * 📊 Configuração dos reporters de métricas
  * 👀 Supervisão dos processos de métricas
  * 🛠️ Configuração flexível através de opções
  
  ## Exemplo de Uso
  
  ```elixir
  # Iniciar o supervisor com configurações padrão
  Deeper_Hub.Core.Metrics.Supervisor.start_link([])
  
  # Ou adicionar à árvore de supervisão da aplicação
  children = [
    {Deeper_Hub.Core.Metrics.Supervisor, []}
  ]
  
  Supervisor.start_link(children, strategy: :one_for_one)
  ```
  """
  
  use Supervisor
  
  alias Deeper_Hub.Core.Metrics.TelemetryMetrics
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Inicia o supervisor de métricas.
  
  ## Parâmetros
  
    * `arg` - Argumentos de inicialização (opcional)
    
  ## Retorno
  
    * `{:ok, pid}` - Supervisor iniciado com sucesso
    * `{:error, reason}` - Erro ao iniciar o supervisor
  """
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(arg) do
    Logger.info("Iniciando supervisor de métricas", %{
      module: __MODULE__
    })
    
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end
  
  @doc """
  Inicializa o supervisor e seus processos filhos.
  
  ## Parâmetros
  
    * `_arg` - Argumentos de inicialização (não utilizados)
    
  ## Retorno
  
    * `{:ok, {supervisor_flags, child_specs}}` - Configuração do supervisor
  """
  @impl true
  def init(_arg) do
    Logger.debug("Inicializando supervisor de métricas", %{
      module: __MODULE__
    })
    
    children = [
      # Coletor periódico de métricas
      {:telemetry_poller,
       measurements: TelemetryMetrics.periodic_measurements(),
       period: 10_000},
       
      # Aqui você pode adicionar reporters específicos, como:
      # {TelemetryMetricsStatsd, metrics: TelemetryMetrics.metrics()},
      # {TelemetryMetricsPrometheus, metrics: TelemetryMetrics.metrics()},
      # etc.
    ]
    
    Logger.info("Supervisor de métricas inicializado com sucesso", %{
      module: __MODULE__,
      children_count: length(children)
    })
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end
