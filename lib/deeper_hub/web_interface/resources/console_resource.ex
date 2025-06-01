defmodule DeeperHub.WebInterface.Resources.ConsoleResource do
  @moduledoc """
  Recurso REST para interação com o console interativo via Plug.Router.
  Permite criar sessões, executar comandos (com streaming de resposta) e gerenciar sessões do console.
  Estrutura e rotas são semelhantes ao TerminalResource, mas podem ser customizadas para lógica de console.
  """
  use Plug.Router
  import Plug.Conn

  alias DeeperHub.Core.Console.ConsoleManager
  require Logger

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  # Rota para criar uma nova sessão de console
  post "/sessions" do
    case ConsoleManager.create_session() do
      {:ok, session_id} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{
          status: "success",
          message: "Sessão de console criada com sucesso",
          session_id: session_id
        }))
      {:error, reason} ->
        Logger.error("Erro ao criar sessão de console: #{inspect(reason)}")
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{
          status: "error",
          message: "Erro ao criar sessão de console"
        }))
    end
  end
  # Rota para listar sessões ativas
  get "/sessions" do
    case ConsoleManager.list_sessions() do
      {:ok, sessions} ->
        # Transform the sessions map into a list that matches the Python client's expectations
        formatted_sessions = Enum.map(sessions, fn {id, info} ->
          %{
            "id" => id,
            "created_at" => DateTime.to_iso8601(info.created_at),
            "last_command" => %{
              "command" => info.last_command || "",
              "executed_at" => DateTime.to_iso8601(info.created_at)
            }
          }
        end)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{
          status: "success",
          sessions: formatted_sessions
        }))
      {:error, reason} ->
        Logger.error("Erro ao listar sessões de console: #{inspect(reason)}")
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{
          status: "error",
          message: "Erro ao listar sessões de console"
        }))
    end
  end

  # Rota para executar comando em uma sessão de console
  post "/sessions/:id/execute" do
    with {:ok, %{"command" => command}} <- parse_json_body(conn),
         true <- is_binary(command) and String.length(String.trim(command)) > 0 do
      case ConsoleManager.execute_command(id, command, self()) do
        {:ok, :streaming_started} ->
          conn_ready_for_chunks =
            conn
            |> put_resp_header("content-type", "text/plain; charset=utf-8")
            |> put_resp_header("transfer-encoding", "chunked")
            |> put_resp_header("x-content-type-options", "nosniff")
            |> send_chunked(200)
          receive_chunks_loop(conn_ready_for_chunks)
        {:error, :session_not_found} ->
          send_json_error(conn, 404, "Sessão não encontrada")
        {:error, reason} ->
          Logger.error("ConsoleResource: Erro ao tentar iniciar comando na sessão #{id}: #{inspect(reason)}")
          send_json_error(conn, 500, "Erro ao executar comando: #{inspect(reason)}")
      end
    else
      {:error, :invalid_json_or_missing_command} ->
        send_json_error(conn, 400, "Corpo da requisição inválido, JSON malformado, ou campo 'command' ausente/inválido")
      false ->
        send_json_error(conn, 400, "Comando não pode ser vazio")
      error_term ->
        Logger.error("ConsoleResource: Erro inesperado durante validação da execução do comando: #{inspect(error_term)}")
        send_json_error(conn, 500, "Erro interno ao processar requisição")
    end
  end

  # Rota para encerrar uma sessão
  delete "/sessions/:id" do
    case ConsoleManager.terminate_session(id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{
          status: "success",
          message: "Sessão encerrada com sucesso"
        }))
      {:error, :session_not_found} ->
        send_json_error(conn, 404, "Sessão não encontrada para encerramento")
      {:error, reason} ->
        Logger.error("Erro ao encerrar sessão #{id}: #{inspect(reason)}")
        send_json_error(conn, 500, "Erro ao encerrar sessão")
    end
  end

  # Rota padrão para endpoints não encontrados
  match _ do
    send_json_error(conn, 404, "Rota não encontrada neste recurso de console")
  end

  # Loop para receber e enviar chunks de dados
  defp receive_chunks_loop(current_conn) do
    receive do
      {:console_chunk, data_chunk} ->
        cleaned_data =
          data_chunk
          |> to_string()
          |> String.replace(~r/\e\[[0-9;]*[mK]/, "")
        case chunk(current_conn, cleaned_data) do
          {:ok, next_conn} ->
            receive_chunks_loop(next_conn)
          {:error, _reason} ->
            current_conn
        end
      {:console_eof, _reason} ->
        current_conn
    after
      30_000 ->
        case chunk(current_conn, "\n[TIMEOUT NO SERVIDOR: Nenhum dado adicional recebido do console por 30 segundos]\n") do
          {:ok, final_conn} ->
            final_conn
          {:error, _reason} ->
            current_conn
        end
    end
  end

  defp parse_json_body(conn) do
    case conn.body_params do
      %{"command" => command_val} ->
        {:ok, %{"command" => command_val}}
      %{} ->
        {:error, :invalid_json_or_missing_command}
      _not_a_map_or_nil ->
        Logger.debug("ConsoleResource: parse_json_body falhou, conn.body_params: #{inspect conn.body_params}")
        {:error, :invalid_json_or_missing_command}
    end
  end

  defp send_json_error(conn, status_code, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, Jason.encode!(%{
      status: "error",
      message: message
    }))
  end
end
