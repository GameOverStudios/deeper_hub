defmodule DeeperHub.Core.Network.Supervisor do
  @moduledoc """
  Supervisor principal para o subsistema de rede do DeeperHub.
  
  Este supervisor gerencia todos os componentes relacionados à comunicação em rede,
  incluindo WebSockets, PubSub, canais e sistema de presença.
  """
  use Supervisor
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicia o supervisor do subsistema de rede.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor do subsistema de rede...", module: __MODULE__)
    
    children = [
      # Supervisor para gerenciar conexões WebSocket
      # {DeeperHub.Core.Network.Socket.Supervisor, []},
      
      # Supervisor para o sistema de PubSub
      # {DeeperHub.Core.Network.PubSub.Supervisor, []},
      
      # Supervisor para gerenciar canais de comunicação
      # {DeeperHub.Core.Network.Channels.Supervisor, []},
      
      # Supervisor para o sistema de presença
      # {DeeperHub.Core.Network.Presence.Supervisor, []}
    ]
    
    # Estratégia rest_for_one: se um componente falhar, todos os componentes
    # que dependem dele (iniciados depois) também serão reiniciados
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
