defmodule Deeper_Hub.Core.CircuitBreaker.Supervisor do
  @moduledoc """
  Supervisor para o sistema de CircuitBreaker.
  
  Este módulo é responsável por iniciar e supervisionar os componentes do sistema
  de CircuitBreaker, garantindo que eles sejam reiniciados em caso de falha.
  """
  
  use Supervisor
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Inicia o supervisor do CircuitBreaker.
  
  ## Parâmetros
  
    - `opts`: Opções para o supervisor
  
  ## Retorno
  
    - `{:ok, pid}` se o supervisor for iniciado com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Logger.info("Iniciando supervisor do CircuitBreaker", %{
      module: __MODULE__
    })
    
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    Logger.debug("Inicializando componentes do CircuitBreaker", %{
      module: __MODULE__
    })
    
    children = [
      # Registry para as instâncias de CircuitBreaker
      {Registry, keys: :unique, name: Deeper_Hub.Core.CircuitBreaker.InstanceRegistry},
      
      # Módulo de registro que gerencia as instâncias
      Deeper_Hub.Core.CircuitBreaker.Registry
    ]
    
    # Estratégia one_for_one: se um processo falhar, apenas ele será reiniciado
    Supervisor.init(children, strategy: :one_for_one)
  end
end
