defmodule DeeperHub.Core.Network.Channels.Supervisor do
  @moduledoc """
  Supervisor para o subsistema de canais de comunicação.
  
  Este supervisor gerencia os canais de comunicação temáticos, permitindo
  que clientes se inscrevam em canais específicos e recebam mensagens
  relacionadas a esses canais.
  
  O sistema de canais é fundamental para organizar a comunicação em um
  ambiente com muitos usuários e diferentes tópicos de interesse.
  """
  use Supervisor
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicia o supervisor do subsistema de canais.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor de canais de comunicação...", module: __MODULE__)
    
    children = [
      # Registro para rastrear canais ativos
      {Registry, keys: :unique, name: DeeperHub.Core.Network.Channels.Registry},
      
      # Supervisor dinâmico para gerenciar processos de canal
      {DynamicSupervisor, 
        strategy: :one_for_one, 
        name: DeeperHub.Core.Network.Channels.ChannelSupervisor
      }
    ]
    
    # Estratégia one_for_one: cada componente é tratado independentemente
    Supervisor.init(children, strategy: :one_for_one)
  end
end
