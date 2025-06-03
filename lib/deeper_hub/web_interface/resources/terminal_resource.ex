# lib/deeper_hub/web_interface/resources/terminal_resource.ex
defmodule DeeperHub.WebInterface.Resources.TerminalResource do
  @moduledoc """
  Recurso REST para interação com o terminal interativo via Plug.Router.
  Permite criar sessões, executar comandos (com streaming de resposta) e gerenciar sessões.
  """
  use Plug.Router
  import Plug.Conn # Para ter acesso a put_resp_content_type, send_resp, send_chunked, chunk

  alias DeeperHub.Core.Terminal.SessionManager
  require Logger

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"], # Processa apenas se Content-Type for application/json
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  # Timeout para o loop de recebimento de chunks na rota de execução.
  # Se nenhuma mensagem (:terminal_chunk ou :terminal_eof) for recebida
  # por este período, o loop considera que o stream parou ou houve um problema.
  # Deve ser generoso o suficiente para permitir pausas entre os outputs do comando,
  # mas não tão longo a ponto de prender a conexão indefinidamente se algo der muito errado.
  @chunk_receive_timeout 30_000 # 30 segundos

  # Rota para criar uma nova sessão
  post "/sessions" do
    case SessionManager.create_session() do
      {:ok, session_id} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          201,
          Jason.encode!(%{
            status: "success",
            message: "Sessão de terminal criada com sucesso",
            session_id: session_id
          })
        )

      {:error, reason} -> # Captura genérica de erro
        Logger.error("Erro ao criar sessão de terminal: #{inspect(reason)}")
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          500,
          Jason.encode!(%{
            status: "error",
            message: "Erro ao criar sessão de terminal"
          })
        )
    end
  end

  # Rota para listar sessões ativas
  get "/sessions" do
    case SessionManager.list_sessions() do
      {:ok, sessions} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(%{
            status: "success",
            sessions: sessions
          })
        )

      {:error, reason} -> # Captura genérica de erro
        Logger.error("Erro ao listar sessões de terminal: #{inspect(reason)}")
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          500,
          Jason.encode!(%{
            status: "error",
            message: "Erro ao listar sessões de terminal"
          })
        )
    end
  end

  # Rota para executar comando em uma sessão (com streaming)
  # :id é o session_id (string UUID)
  post "/sessions/:id/execute" do
    # A variável 'id' é automaticamente vinculada do path.
    # A variável 'conn' é a conexão Plug.

    # Usamos `with` para uma sequência de validações e operações.
    # Se qualquer etapa falhar (retornar algo que não seja {:ok, _}), o bloco `else` é executado.
    with {:ok, _valid_uuid} <- UUID.info(id), # Valida se 'id' é um formato UUID válido
         {:ok, %{"command" => command}} <- parse_json_body(conn), # Extrai o comando do corpo JSON
         true <- is_binary(command) and String.length(String.trim(command)) > 0 # Valida o comando
      do
        # Se todas as validações acima passarem:
        Logger.debug("TerminalResource: Preparando para executar comando '#{command}' na sessão #{id} para o processo #{inspect(self())}")

        # Chama o SessionManager, passando `self()` como o client_pid que receberá os chunks.
        # O 'id' aqui é o session_id (string).
        case SessionManager.execute_command(id, command, self()) do
          {:ok, :streaming_started} ->
            # Streaming foi iniciado com sucesso pelo SessionManager.
            # Preparamos a `conn` para enviar uma resposta chunked.
            conn_ready_for_chunks =
              conn
              |> put_resp_header("content-type", "text/plain; charset=utf-8") # Ou application/x-ndjson
              |> put_resp_header("transfer-encoding", "chunked")
              |> put_resp_header("x-content-type-options", "nosniff") # Boa prática de segurança
              |> send_chunked(200) # Envia os cabeçalhos HTTP com status 200 e abre a conexão para chunks.

            Logger.info("TerminalResource (pid #{inspect(self())}): Streaming iniciado para sessão #{id}. Aguardando chunks...")

            # Entra no loop para receber os chunks e enviá-los pela `conn_ready_for_chunks`.
            # Esta função bloqueará este processo até que o stream termine ou haja timeout.
            receive_chunks_loop(conn_ready_for_chunks)

          {:error, :session_not_found} ->
            send_json_error(conn, 404, "Sessão não encontrada")

          {:error, :session_port_closed} ->
            send_json_error(conn, 500, "Porta da sessão do terminal está fechada")

          {:error, reason} ->
            Logger.error("TerminalResource: Erro ao tentar iniciar comando na sessão #{id}: #{inspect(reason)}")
            send_json_error(conn, 500, "Erro ao executar comando: #{inspect(reason)}")
        end
      else
        # Bloco 'else' do `with` - executado se alguma validação falhar.
        {:error, :invalid_uuid} -> # Erro específico de UUID.info(id)
          send_json_error(conn, 400, "ID de sessão inválido (não é um UUID)")

        {:error, :invalid_json_or_missing_command} -> # Erro de parse_json_body
          send_json_error(conn, 400, "Corpo da requisição inválido, JSON malformado, ou campo 'command' ausente/inválido")

        false -> # Falha na validação `is_binary(command) and String.length(String.trim(command)) > 0`
          send_json_error(conn, 400, "Comando não pode ser vazio")

        # Captura para outros erros inesperados no `with`
        error_term ->
          Logger.error("TerminalResource: Erro inesperado durante validação da execução do comando: #{inspect(error_term)}")
          send_json_error(conn, 500, "Erro interno ao processar requisição")
      end

    # A função da rota Plug deve retornar uma `conn`.
    # Se o streaming ocorreu, `receive_chunks_loop` retorna a `conn` final.
    # Se houve erro antes do streaming, `send_json_error` retorna a `conn` com a resposta de erro.
    # Não precisa de variável temporária, o resultado do with é retornado diretamente
  end

  # Loop para receber e enviar chunks de dados.
  # Esta função é executada no processo do Plug (geralmente um worker Cowboy).
  defp receive_chunks_loop(current_conn) do
    receive do
      {:terminal_chunk, data_chunk} ->
        # Limpa os dados (ex: remove códigos de escape ANSI) antes de enviar.
        # Se o Content-Type fosse application/x-ndjson, aqui você garantiria que
        # `data_chunk` é uma string JSON válida seguida de "\n".
        cleaned_data =
          data_chunk
          |> to_string() # Garante que é uma string
          |> String.replace(~r/\e\[[0-9;]*[mK]/, "") # Remove códigos ANSI comuns
          # Não faça String.trim() em chunks intermediários, pode quebrar a formatação de múltiplas linhas.

        # Envia o chunk pela conexão. `Plug.Conn.chunk` retorna {:ok, conn} ou {:error, reason}
        # É importante extrair o conn do retorno para a próxima iteração do loop.
        # Logger.debug("TerminalResource (pid #{inspect(self())}): Enviando chunk de #{byte_size(cleaned_data)} bytes.")
        case chunk(current_conn, cleaned_data) do
          {:ok, next_conn} ->
            # Continua o loop com a `conn` atualizada
            receive_chunks_loop(next_conn)
          {:error, reason} ->
            Logger.error("TerminalResource: Erro ao enviar chunk: #{inspect(reason)}")
            # Encerra o loop se não for possível continuar enviando chunks
            current_conn
        end

      {:terminal_eof, reason} ->
        Logger.info("TerminalResource (pid #{inspect(self())}): EOF recebido, razão: #{reason}. Finalizando stream.")
        # O stream terminou. Um chunk final opcional poderia ser enviado aqui.
        # Ex: chunk(current_conn, "\n--- FIM DO STREAM (#{reason}) ---\n")
        # Simplesmente retornar a `current_conn` é geralmente suficiente para o adaptador
        # (Cowboy) fechar a conexão chunked corretamente.
        current_conn

    after
      @chunk_receive_timeout ->
        Logger.warning("TerminalResource (pid #{inspect(self())}): Timeout no receive_chunks_loop. Nenhuma mensagem recebida por #{@chunk_receive_timeout}ms. Fechando stream.")
        # Envia um chunk final indicando o timeout e então retorna a `conn`.
        case chunk(current_conn, "\n[TIMEOUT NO SERVIDOR: Nenhum dado adicional recebido do terminal por #{@chunk_receive_timeout / 1000} segundos]\n") do
          {:ok, final_conn} ->
            # Retorna a `conn` atualizada para finalizar a resposta
            final_conn
          {:error, reason} ->
            Logger.error("TerminalResource: Erro ao enviar chunk de timeout: #{inspect(reason)}")
            # Retorna a `conn` original se houve erro
            current_conn
        end
    end
  end

  # Rota para encerrar uma sessão
  delete "/sessions/:id" do
    session_id_from_path = id # 'id' é o parâmetro da rota

    # Validar se o ID é um UUID antes de prosseguir
    case UUID.info(session_id_from_path) do
      {:ok, _valid_uuid} ->
        case SessionManager.terminate_session(session_id_from_path) do
          :ok ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{status: "success", message: "Sessão encerrada com sucesso"}))

          {:error, :session_not_found} ->
            send_json_error(conn, 404, "Sessão não encontrada para encerramento")

          {:error, reason} ->
            Logger.error("Erro ao encerrar sessão #{session_id_from_path}: #{inspect(reason)}")
            send_json_error(conn, 500, "Erro ao encerrar sessão")
        end

      {:error, :invalid_uuid} ->
        send_json_error(conn, 400, "ID de sessão inválido para encerramento (não é um UUID)")

      error_term -> # Outro erro de UUID.info
        Logger.error("Erro ao validar UUID para encerramento de sessão #{session_id_from_path}: #{inspect(error_term)}")
        send_json_error(conn, 500, "Erro interno ao processar ID de sessão para encerramento")
    end
  end

  # Fallback para rotas não encontradas dentro deste Router
  match _ do
    send_json_error(conn, 404, "Rota não encontrada neste recurso de terminal")
  end

  # Função auxiliar para analisar o corpo JSON da requisição e extrair o comando.
  defp parse_json_body(conn) do
    # `Plug.Parsers` já deve ter decodificado o JSON e colocado em `conn.body_params`.
    case conn.body_params do
      %{"command" => command_val} -> # Verifica se a chave "command" existe
        # Poderia adicionar mais validações aqui, como `is_binary(command_val)`
        {:ok, %{"command" => command_val}}
      %{} -> # É um JSON, mas não tem a chave "command"
        {:error, :invalid_json_or_missing_command}
      _not_a_map_or_nil -> # Não foi parseado como JSON ou é nil
        Logger.debug("TerminalResource: parse_json_body falhou, conn.body_params: #{inspect conn.body_params}")
        {:error, :invalid_json_or_missing_command}
    end
  end

  # Função auxiliar para enviar respostas de erro JSON padronizadas
  defp send_json_error(conn, status_code, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, Jason.encode!(%{status: "error", message: message}))
  end
end
