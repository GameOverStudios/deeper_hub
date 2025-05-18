defmodule DeeperHub.Core.Network.Presence.Supervisor do
  @moduledoc """
  Supervisor para o subsistema de presença.
  
  Este supervisor gerencia o sistema de rastreamento de presença online,
  permitindo que a aplicação saiba quais usuários estão ativos e em quais canais.
  
  O sistema de presença é fundamental para funcionalidades sociais e para
  otimizar a entrega de mensagens apenas para usuários ativos.
  """
  use Supervisor
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicia o supervisor do subsistema de presença.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor do subsistema de presença...", module: __MODULE__)
    
    children = [
      # Servidor de presença
      {DeeperHub.Core.Network.Presence.Server, []}
    ]
    
    # Estratégia one_for_one: cada componente é tratado independentemente
    Supervisor.init(children, strategy: :one_for_one)
  end
end
