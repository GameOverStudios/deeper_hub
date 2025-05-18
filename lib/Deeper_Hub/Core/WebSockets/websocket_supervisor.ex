defmodule Deeper_Hub.Core.WebSockets.WebSocketSupervisor do
  @moduledoc """
  Supervisor para o servidor WebSocket.

  Este módulo gerencia o ciclo de vida do servidor WebSocket e seus componentes.
  """

  use Supervisor
  alias Deeper_Hub.Core.Logger

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

    children = [
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
