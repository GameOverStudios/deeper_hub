defmodule DeeperHub.Core.Network.PubSub.Supervisor do
  @moduledoc """
  Supervisor para o subsistema de PubSub.
  
  Este supervisor gerencia os componentes do sistema de publicação/assinatura,
  permitindo comunicação eficiente entre processos e nós distribuídos.
  
  O sistema PubSub é fundamental para a escalabilidade da aplicação, permitindo
  que mensagens sejam distribuídas para múltiplos assinantes de forma eficiente.
  """
  use Supervisor
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicia o supervisor do subsistema de PubSub.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor do subsistema de PubSub...", module: __MODULE__)
    
    children = [
      # Registro para rastrear tópicos e assinantes
      {Registry, keys: :duplicate, name: DeeperHub.Core.Network.PubSub.Registry, partitions: System.schedulers_online()},
      
      # Broker central de mensagens
      {DeeperHub.Core.Network.PubSub.Broker, []},
      
      # Supervisor dinâmico para gerenciar tópicos
      {DynamicSupervisor, 
        strategy: :one_for_one, 
        name: DeeperHub.Core.Network.PubSub.TopicSupervisor
      }
    ]
    
    # Estratégia one_for_one: cada componente é tratado independentemente
    Supervisor.init(children, strategy: :one_for_one)
  end
end
