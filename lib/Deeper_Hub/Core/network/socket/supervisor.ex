defmodule DeeperHub.Core.Network.Socket.Supervisor do
  @moduledoc """
  Supervisor para o subsistema de WebSockets.
  
  Este supervisor gerencia os processos relacionados às conexões WebSocket,
  incluindo o servidor HTTP/WebSocket e os processos de conexão individuais.
  
  Ele é projetado para suportar um grande número de conexões simultâneas,
  aproveitando a natureza concorrente do Elixir/OTP.
  """
  use Supervisor
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicia o supervisor do subsistema de WebSockets.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    Logger.info("Iniciando supervisor de WebSockets...", module: __MODULE__)
    
    children = [
      # Registro para rastrear conexões WebSocket ativas
      {Registry, keys: :unique, name: DeeperHub.Core.Network.Socket.Registry},
      
      # Servidor HTTP/WebSocket usando Cowboy
      # Será implementado posteriormente
      # {DeeperHub.Core.Network.Socket.Server, []},
      
      # Supervisor dinâmico para gerenciar processos de conexão individuais
      {DynamicSupervisor, 
        strategy: :one_for_one, 
        name: DeeperHub.Core.Network.Socket.ConnectionSupervisor,
        max_restarts: 10000,  # Valor alto para suportar muitas reconexões
        max_seconds: 1,       # Período curto para evitar sobrecarga
        max_children: :infinity  # Sem limite para número de conexões
      }
    ]
    
    # Estratégia one_for_one: cada componente é tratado independentemente
    Supervisor.init(children, strategy: :one_for_one)
  end
end
