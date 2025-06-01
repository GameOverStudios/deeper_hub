defmodule DeeperHub.WebInterface.Resources.TerminalResource do
  @moduledoc """
  Recurso REST para interação com o terminal interativo.
  Este módulo permite criar sessões, executar comandos e obter resultados via API REST.
  """
  use Plug.Router
  alias DeeperHub.Core.Terminal.SessionManager
  require Logger

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  
  plug :match
  plug :dispatch

  # Rota para criar uma nova sessão
  post "/sessions" do
    case SessionManager.create_session() do
      {:ok, session_id} ->
        # Resposta de sucesso com o ID da sessão criada
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{
          status: "success",
          message: "Sessão de terminal criada com sucesso",
          session_id: session_id
        }))
        
      _ ->
        # Resposta de erro caso a criação da sessão falhe
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{
          status: "error",
          message: "Erro ao criar sessão de terminal"
        }))
    end
  end

  # Rota para listar sessões ativas
  get "/sessions" do
    case SessionManager.list_sessions() do
      {:ok, sessions} ->
        # Resposta de sucesso com a lista de sessões
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{
          status: "success",
          sessions: sessions
        }))
        
      _ ->
        # Resposta de erro caso a listagem falhe
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{
          status: "error",
          message: "Erro ao listar sessões de terminal"
        }))
    end
  end

  # Rota para executar comando em uma sessão
  # Plug.Conn tem um timeout padrão de 60 segundos
  post "/sessions/:id/execute" do
    # Configuramos a conexão para aumentar o timeout (opcional, pois o padrão já é de 60s)
    
    with {:ok, session_id} <- UUID.info(id),
         {:ok, params} <- parse_json(conn),
         command <- Map.get(params, "command") do
      
      Logger.debug("Executando comando '#{command}' na sessão #{id}")
      
      # Configuramos um timeout mais longo para comandos que podem demorar mais
      case SessionManager.execute_command(id, command) do
        {:ok, result} ->
          # Processamos o resultado para remover possíveis caracteres de controle
          cleaned_result = result
            |> String.replace(~r/\e\[[0-9;]*[mK]/, "")  # Remove códigos ANSI
            |> String.trim()
          
          # Retorna o resultado do comando
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{
            status: "success",
            session_id: id,
            result: cleaned_result
          }))
          
        {:error, :session_not_found} ->
          # Sessão não encontrada
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(404, Jason.encode!(%{
            status: "error",
            message: "Sessão não encontrada"
          }))
          
        {:error, reason} ->
          # Erro ao executar o comando
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(500, Jason.encode!(%{
            status: "error",
            message: "Erro ao executar comando: #{inspect(reason)}"
          }))
      end
    else
      # Erro ao analisar o JSON ou ID inválido
      {:error, _} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{
          status: "error",
          message: "Formato inválido de solicitação ou ID de sessão inválido"
        }))
    end
  end

  # Rota para encerrar uma sessão
  delete "/sessions/:id" do
    # Extrai o ID da sessão da URL
    session_id = id
    
    # Encerra a sessão especificada
    case SessionManager.terminate_session(session_id) do
      :ok ->
        # Resposta de sucesso
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{
          status: "success",
          message: "Sessão encerrada com sucesso"
        }))
        
      {:error, :session_not_found} ->
        # Resposta de erro caso a sessão não seja encontrada
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{
          status: "error",
          message: "Sessão não encontrada"
        }))
        
      _ ->
        # Resposta de erro caso o encerramento falhe
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{
          status: "error",
          message: "Erro ao encerrar sessão"
        }))
    end
  end

  # Fallback para rotas não encontradas
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{
      status: "error",
      message: "Rota não encontrada"
    }))
  end
  
  # Função auxiliar para analisar o corpo JSON da solicitação
  defp parse_json(conn) do
    case conn.body_params do
      %{} = params when map_size(params) > 0 -> {:ok, params}
      _ ->
        try do
          {:ok, Jason.decode!(conn.body_params) || %{}}
        rescue
          _ -> {:error, :invalid_json}
        end
    end
  end
end
