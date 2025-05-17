defmodule Deeper_Hub.Core.Supervisor do
  @moduledoc """
  Supervisor principal para os componentes do Core.
  
  Este supervisor é responsável por iniciar e supervisionar os componentes
  centrais da aplicação, como cache e métricas.
  """
  
  use Supervisor
  
  # Importamos o módulo Cachex.Spec para usar a função hook
  import Cachex.Spec
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Inicia o supervisor.
  
  ## Parâmetros
  
    - `opts`: Opções para o supervisor
  
  ## Retorno
  
    - `{:ok, pid}` se o supervisor for iniciado com sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    Logger.info("Iniciando supervisor do Core", %{module: __MODULE__})
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Inicializa o supervisor com os componentes necessários.
  
  ## Parâmetros
  
    - `opts`: Opções para o supervisor
  
  ## Retorno
  
    - `{:ok, {supervisor_opts, children}}` com as opções do supervisor e os filhos
  """
  @impl true
  def init(_opts) do
    Logger.debug("Inicializando componentes do Core", %{module: __MODULE__})
    
    children = [
      # Inicia o cache com estatísticas habilitadas
      {Cachex, name: Deeper_Hub.Core.Cache.cache_name(), 
       opts: [
         # Configura a expiração padrão para entradas no cache
         expiration: [
           default: :timer.minutes(10),
           interval: :timer.minutes(1)
         ],
         # Habilita estatísticas usando nosso hook personalizado
         hooks: [
           hook(module: Deeper_Hub.Core.Cache.StatsHook)
         ]
       ]
      },
      
      # Inicia o repórter de métricas
      Deeper_Hub.Core.Metrics.Reporter,
      
      # Inicia um worker para configurar o EventBus
      {Task, fn -> Deeper_Hub.Core.EventBus.init() end},
      
      # Inicia o supervisor do WebSocket
      Deeper_Hub.Core.WebSockets.Supervisor
    ]
    
    # Configura o supervisor para reiniciar os filhos individualmente
    Supervisor.init(children, strategy: :one_for_one)
  end
end
