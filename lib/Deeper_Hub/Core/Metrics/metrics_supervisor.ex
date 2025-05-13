defmodule Deeper_Hub.Core.Metrics.MetricsSupervisor do
  @moduledoc """
  Supervisor para o sistema de métricas.
  
  Este módulo é responsável por inicializar e supervisionar o sistema de métricas,
  garantindo que ele esteja disponível para todos os outros módulos da aplicação.
  """
  
  use Supervisor
  alias Deeper_Hub.Core.Metrics
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Inicia o supervisor de métricas.
  """
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end
  
  @doc """
  Inicializa o sistema de métricas.
  """
  @impl true
  def init(_args) do
    Logger.info("Iniciando o supervisor de métricas", %{module: __MODULE__})
    
    # Inicializa o sistema de métricas
    Metrics.initialize()
    
    # Define os processos filhos (nenhum neste caso, pois usamos ETS)
    children = []
    
    # Estratégia de supervisão
    Supervisor.init(children, strategy: :one_for_one)
  end
end
