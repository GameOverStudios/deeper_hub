defmodule DeeperHub.WebInterface.Resources.ConsoleResource do
  @moduledoc """
  Recurso REST para gerenciamento de sessões de console.
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

  # Rota para listar todas as sessões de console
  get "/sessions" do
    require Logger
    Logger.info("Listando todas as sessões de console")

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

  # Rota para criar uma nova sessão de console
  post "/sessions" do
    require Logger
    Logger.info("Criando nova sessão de console")

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(201, Jason.encode!(%{
      status: "success",
      message: "Sessão de console criada com sucesso",
      session_id: UUID.uuid4()
    }))
  end

  # Rota para executar comandos em uma sessão
  post "/sessions/:session_id/execute" do
    session_id = conn.path_params["session_id"]

    # Extrair o comando do corpo da requisição
    command = conn.body_params["command"]

    require Logger
    Logger.info("Executando comando na sessão de console #{session_id}: #{command}")

    # Executar o comando Elixir e capturar a saída
    {result, exit_status} = execute_elixir_command(command)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      status: if(exit_status == 0, do: "success", else: "error"),
      session_id: session_id,
      result: result
    }))
  end

  # Rota para encerrar uma sessão
  delete "/sessions/:session_id" do
    session_id = conn.path_params["session_id"]

    require Logger
    Logger.info("Encerrando sessão de console #{session_id}")

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      status: "success",
      message: "Sessão de console encerrada com sucesso"
    }))
  end

  # Fallback para rotas não encontradas
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{erro: "Rota de console não encontrada"}))
  end

  # Função para executar comandos Elixir
  defp execute_elixir_command(command) do
    # Criar um arquivo temporário para o código
    tmp_file = Path.join(System.tmp_dir!(), "elixir_cmd_#{:erlang.unique_integer([:positive])}.exs")

    try do
      # Escrever o comando no arquivo
      File.write!(tmp_file, command)

      # Executar o comando usando o elixir
      case System.cmd("elixir", [tmp_file], stderr_to_stdout: true) do
        {output, 0} -> {output, 0}
        {error, status} -> {error, status}
      end
    rescue
      e -> {"Erro ao executar comando: #{inspect(e)}", 1}
    after
      # Limpar o arquivo temporário
      File.rm(tmp_file)
    end
  end

  # Tratamento de erros
  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    require Logger
    Logger.error("Erro no recurso de console: #{inspect(kind)} - #{inspect(reason)}")
    Logger.debug("Stack: #{inspect(stack)}")

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(conn.status || 500, Jason.encode!(%{
      erro: "Erro interno no serviço de console",
      details: inspect(reason)
    }))
  end
end
