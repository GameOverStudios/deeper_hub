defmodule Deeper_Hub.Core.WebSockets.WebSocketServer do
  @moduledoc """
  Servidor WebSocket para o DeeperHub.

  Este módulo implementa um servidor HTTP/WebSocket usando Plug e Cowboy.
  """

  use Plug.Router

  alias Deeper_Hub.Core.Logger

  # Plugins do Plug
  plug Plug.Logger
  plug :match
  plug :dispatch

  # Rota padrão para requisições HTTP
  get "/" do
    send_resp(conn, 200, "DeeperHub WebSocket Server")
  end

  # Rota para verificação de status
  get "/status" do
    response = %{
      status: "ok",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(response))
  end

  # Coordena todas as outras rotas
  match _ do
    send_resp(conn, 404, "Not Found")
  end

  @doc """
  Inicia o servidor WebSocket.

  ## Parâmetros

    - `opts`: Opções para o servidor

  ## Retorno

    - `{:ok, pid}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, 4000)

    Logger.info("Iniciando servidor WebSocket", %{
      module: __MODULE__,
      port: port
    })

    Plug.Cowboy.http(__MODULE__, [], opts)
  end

  @doc """
  Para o servidor WebSocket.

  ## Retorno

    - `:ok` em caso de sucesso
  """
  def stop do
    Logger.info("Parando servidor WebSocket", %{module: __MODULE__})
    Plug.Cowboy.shutdown(__MODULE__)
  end
end
