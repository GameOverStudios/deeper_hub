defmodule DeeperHub.WebInterface.Router do
  @moduledoc """
  Roteador principal para a API REST do DeeperHub.
  Este módulo define as rotas e recursos disponíveis na API.
  """
  use Plug.Router
  use Plug.ErrorHandler

  # Plugs de depuração
  plug(Plug.Logger, log: :debug)

  # Parsers para formatos diferentes
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  # Pipeline principal
  plug(:match)
  plug(:dispatch)

  # API Routes
  {{API_ROUTES}}

  
  forward("/api/terminal", to: DeeperHub.WebInterface.Resources.TerminalResource)
  forward("/api/console", to: DeeperHub.WebInterface.Resources.ConsoleResource)

  # Rota principal para verificação da API
  get "/" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", api: "DeeperHub API v1"}))
  end

  # Fallback para rotas não encontradas
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{erro: "Rota não encontrada"}))
  end

  # Log de erros
  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    IO.puts("Erro na API: #{inspect(kind)} - #{inspect(reason)}")
    IO.puts("Stack: #{inspect(stack)}")
    send_resp(conn, conn.status || 500, "Erro interno do servidor")
  end
end
