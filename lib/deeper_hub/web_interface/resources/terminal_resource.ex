defmodule DeeperHub.WebInterface.Resources.TerminalResource do
  @moduledoc """
  Recurso REST para gerenciamento de sessões de terminal.
  """
  use Plug.Router
  use Plug.ErrorHandler
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger

  # Plugs
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )
  
  plug(:match)
  plug(:dispatch)

  # Rota para listar todas as sessões de terminal
  get "/sessions" do
    require Logger
    Logger.info("Listando todas as sessões de terminal")
    
    # Simulação de lista de sessões
    sessions = [
      %{id: UUID.uuid4(), created_at: DateTime.utc_now() |> DateTime.to_string(), status: "active"},
      %{id: UUID.uuid4(), created_at: DateTime.utc_now() |> DateTime.to_string(), status: "active"}
    ]
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      status: "success",
      sessions: sessions
    }))
  end
  
  # Rota para criar uma nova sessão de terminal
  post "/sessions" do
    require Logger
    Logger.info("Criando nova sessão de terminal")
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(201, Jason.encode!(%{
      status: "success",
      message: "Sessão de terminal criada com sucesso",
      session_id: UUID.uuid4()
    }))
  end

  # Rota para executar comandos em uma sessão
  post "/sessions/:session_id/execute" do
    session_id = conn.path_params["session_id"]
    
    # Extrair o comando do corpo da requisição
    command = conn.body_params["command"]
    
    require Logger
    Logger.info("Executando comando na sessão de terminal #{session_id}: #{command}")
    
    # Simulação de execução de comando
    result = "Comando executado: #{command}"
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      status: "success",
      session_id: session_id,
      result: result
    }))
  end

  # Rota para encerrar uma sessão
  delete "/sessions/:session_id" do
    session_id = conn.path_params["session_id"]
    
    require Logger
    Logger.info("Encerrando sessão de terminal #{session_id}")
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      status: "success",
      message: "Sessão de terminal encerrada com sucesso"
    }))
  end

  # Fallback para rotas não encontradas
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{erro: "Rota de terminal não encontrada"}))
  end

  # Tratamento de erros
  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    require Logger
    Logger.error("Erro no recurso de terminal: #{inspect(kind)} - #{inspect(reason)}")
    Logger.debug("Stack: #{inspect(stack)}")
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(conn.status || 500, Jason.encode!(%{
      erro: "Erro interno no serviço de terminal",
      details: inspect(reason)
    }))
  end
end
