defmodule Deeper_Hub.Core.WebSockets.WebSocketSupervisor do
  @moduledoc """
  Supervisor para o servidor WebSocket.

  Este módulo gerencia o ciclo de vida do servidor WebSocket e seus componentes.
  """

  use Supervisor
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionManager
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionCleanupWorker
  alias Deeper_Hub.Core.WebSockets.Auth.Token.OpaqueTokenService
  alias Deeper_Hub.Core.WebSockets.Security.SecuritySupervisor

  @doc """
  Inicia o supervisor do WebSocket.

  ## Parâmetros

    - `opts`: Opções para o supervisor

  ## Retorno

    - `{:ok, pid}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    Logger.info("Iniciando supervisor do WebSocket", %{module: __MODULE__})
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, 4000)
    
    # Inicializa o serviço de tokens opacos
    OpaqueTokenService.init()

    children = [
      # Supervisor de segurança WebSocket
      {SecuritySupervisor, []},
      
      # Gerenciador de sessões
      {SessionManager, []},

      # Worker de limpeza de sessões (executa a cada 1 hora)
      {SessionCleanupWorker, [cleanup_interval: 60 * 60 * 1000]},

      # Servidor WebSocket
      {Plug.Cowboy,
       scheme: :http,
       plug: Deeper_Hub.Core.WebSockets.WebSocketServer,
       options: [
         port: port,
         dispatch: dispatch()
       ]}
    ]

    Logger.info("Servidor WebSocket iniciado na porta #{port}", %{module: __MODULE__})

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp dispatch do
    [
      {:_, [
        {"/ws", Deeper_Hub.Core.WebSockets.WebSocketHandler, []},
        {:_, Plug.Cowboy.Handler, {Deeper_Hub.Core.WebSockets.WebSocketServer, []}}
      ]}
    ]
  end
end
