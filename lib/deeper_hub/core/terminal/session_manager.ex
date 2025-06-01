defmodule DeeperHub.Core.Terminal.SessionManager do
  @moduledoc """
  Gerenciador de sessões de terminal interativo.
  Este módulo é responsável por gerenciar sessões IEX, executar comandos
  e retornar os resultados para o cliente.
  """
  use GenServer
  require Logger

  # Timeout para execução de comandos (milissegundos)
  @command_timeout 10_000

  # Client API

  @doc """
  Inicia o gerenciador de sessões.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Cria uma nova sessão de terminal.
  Retorna um identificador único para a sessão.
  """
  def create_session() do
    GenServer.call(__MODULE__, :create_session)
  end

  @doc """
  Executa um comando em uma sessão específica.
  Retorna {:ok, resultado} ou {:error, razão}
  """
  def execute_command(session_id, command) do
    # Aumenta o timeout para comandos que podem demorar muito mais
    # Nota: 30 segundos é o timeout padrão de HTTP, então usamos um valor menor
    GenServer.call(__MODULE__, {:execute_command, session_id, command}, 25_000)
  end

  @doc """
  Lista todas as sessões ativas.
  """
  def list_sessions() do
    GenServer.call(__MODULE__, :list_sessions)
  end

  @doc """
  Encerra uma sessão específica.
  """
  def terminate_session(session_id) do
    GenServer.call(__MODULE__, {:terminate_session, session_id})
  end

  @doc """
  Encerra todas as sessões ativas.
  """
  def terminate_all_sessions() do
    GenServer.call(__MODULE__, :terminate_all_sessions)
  end

  # GenServer Callbacks

  @impl true
  def init(:ok) do
    Process.flag(:trap_exit, true)
    {:ok, %{sessions: %{}}}
  end

  @impl true
  def handle_call(:create_session, _from, state) do
    # Gera um ID único para a sessão
    session_id = UUID.uuid4()

    # Inicia um novo processo do IEX
    port = start_port()

    # Adiciona a sessão ao mapa de sessões
    sessions = Map.put(state.sessions, session_id, %{
      port: port,
      created_at: DateTime.utc_now(),
      last_command: nil
    })

    Logger.info("Nova sessão de terminal criada: #{session_id}")

    {:reply, {:ok, session_id}, %{state | sessions: sessions}}
  end

  @impl true
  def handle_call({:execute_command, session_id, command}, from, state) do
    Logger.debug("Executando comando '#{command}' na sessão #{session_id}")

    case Map.get(state.sessions, session_id) do
      nil ->
        {:reply, {:error, :session_not_found}, state}

      session ->
        # Limpa o buffer de saída antes de enviar o novo comando
        flush_output(session.port)

        # Cria um marcador único para identificar o fim da saída do comando
        marker = "__CMD_END_#{:rand.uniform(1000000)}__"

        # Criamos um comando mais robusto que captura erros e sempre imprime o marcador
        # Isso garante que receberemos o marcador mesmo se o comando falhar
        command_with_marker = """
        resultado_temp = try do
          #{command}
        rescue
          e in RuntimeError ->
            "** Runtime Error: " <> Exception.message(e)
          e in ArgumentError ->
            "** Argument Error: " <> Exception.message(e)
          e in CompileError ->
            "** Compile Error: " <> Exception.message(e)
          e ->
            "** " <> inspect(e.__struct__) <> ": " <> Exception.message(e)
        catch
          :exit, valor -> "** Exit: " <> inspect(valor)
          :throw, valor -> "** Throw: " <> inspect(valor)
          tipo, valor -> "** " <> Atom.to_string(tipo) <> ": " <> inspect(valor)
        end;
        IO.puts(\"#{marker}\");
        resultado_temp
        """

        # Envia o comando para o processo IEx
        Logger.debug("Enviando comando para a sessão #{session_id}")
        Port.command(session.port, command_with_marker <> "\n")

        # Atualiza o último comando da sessão
        last_command = %{
          command: command,
          executed_at: DateTime.utc_now() |> DateTime.to_string()
        }

        updated_session = %{session | last_command: last_command}
        _updated_sessions = Map.put(state.sessions, session_id, updated_session)

        # Inicia processo assíncrono para coletar a saída com um timeout mais curto
        # e um mecanismo de segurança para evitar timeout do GenServer (mais longo que antes)
        timer_ref = Process.send_after(self(), {:safety_timeout, from, session_id}, 20_000)

        # Armazenamos o tempo inicial para calcular o tempo decorrido
        start_time = System.monotonic_time(:millisecond)

        # Armazenamos o timer_ref na sessão para poder cancelar externamente se necessário
        updated_session = Map.put(updated_session, :safety_timer_ref, timer_ref)
        updated_sessions = Map.put(state.sessions, session_id, updated_session)

        # Usamos Task.start para processar de forma assíncrona
        Task.start(fn ->
          collect_output(session.port, from, marker, [], start_time, timer_ref)
        end)

        {:noreply, %{state | sessions: updated_sessions}}
    end
  end

  @impl true
  def handle_call(:list_sessions, _from, state) do
    # Formata as informações das sessões para serem retornadas
    sessions_info = Enum.map(state.sessions, fn {id, session} ->
      %{
        id: id,
        created_at: session.created_at,
        last_command: session.last_command
      }
    end)

    {:reply, {:ok, sessions_info}, state}
  end

  @impl true
  def handle_call(:get_all_sessions, _from, state) do
    {:reply, state.sessions, state}
  end

  @impl true
  def handle_cast({:clear_safety_timer, session_id}, state) do
    case Map.get(state.sessions, session_id) do
      nil ->
        # Sessão não existe, ignoramos
        {:noreply, state}
      session ->
        # Removemos o timer_ref da sessão
        updated_session = Map.delete(session, :safety_timer_ref)
        updated_sessions = Map.put(state.sessions, session_id, updated_session)
        Logger.debug("Timer de segurança removido para sessão #{session_id} (via cast)")
        {:noreply, %{state | sessions: updated_sessions}}
    end
  end

  @impl true
  def handle_call({:terminate_session, session_id}, _from, state) do
    case Map.get(state.sessions, session_id) do
      nil ->
        {:reply, {:error, :session_not_found}, state}

      session ->
        # Encerra o processo do port
        Port.close(session.port)

        # Remove a sessão do mapa de sessões
        sessions = Map.delete(state.sessions, session_id)

        Logger.info("Sessão de terminal encerrada: #{session_id}")

        {:reply, :ok, %{state | sessions: sessions}}
    end
  end

  @impl true
  def handle_call(:terminate_all_sessions, _from, state) do
    Logger.info("Encerrando todas as sessões de terminal")

    # Encerra cada porta de sessão
    Enum.each(state.sessions, fn {_id, session} ->
      Port.close(session.port)
    end)

    {:reply, :ok, %{state | sessions: %{}}}
  end

  @impl true
  def terminate(_reason, state) do
    # Encerra todas as sessões ao terminar o GenServer
    Enum.each(state.sessions, fn {_id, session} ->
      Port.close(session.port)
    end)

    :ok
  end

  # Private Functions

  # Inicia um novo processo do IEX
  defp start_port() do
    # Inicia um processo de IEX com a flag de início silencioso
    Port.open({:spawn, "iex --no-halt"}, [:binary, :exit_status, {:line, 2048}])
  end

  # Função para limpar o buffer de saída
  defp flush_output(port) do
    receive do
      {^port, {:data, {:eol, _}}} -> flush_output(port)
      {^port, {:data, _}} -> flush_output(port)
    after
      0 -> :ok
    end
  end

  # Implementa handle_info para receber mensagens do port
  @impl true
  def handle_info({port, {:data, {:eol, line}}}, state) do
    # Identifica a qual sessão este port pertence
    session_id = find_session_by_port(port, state.sessions)

    if session_id do
      Logger.debug("Recebido do port: #{inspect(line)}")
    end

    {:noreply, state}
  end

  # Implementa handle_info para mensagens de saída de processos
  @impl true
  def handle_info({port, {:exit_status, status}}, state) do
    # Identifica a qual sessão este port pertence
    session_id = find_session_by_port(port, state.sessions)

    if session_id do
      Logger.warning("Processo do terminal encerrado com status #{status} para sessão #{session_id}")
      # Remove a sessão do mapa
      updated_sessions = Map.delete(state.sessions, session_id)
      {:noreply, %{state | sessions: updated_sessions}}
    else
      {:noreply, state}
    end
  end

  # Tratamento do timeout de segurança para evitar que o GenServer fique travado
  @impl true
  def handle_info({:safety_timeout, caller, session_id}, state) do
    case Map.get(state.sessions, session_id) do
      nil ->
        # A sessão já foi removida, não fazemos nada
        {:noreply, state}
      session ->
        # Verificamos se a resposta já foi entregue verificando se o timer foi cancelado
        # Se o timer_ref estiver nil, a resposta já foi enviada pelo processo de coleta
        if Map.get(session, :safety_timer_ref) == nil do
          Logger.debug("Ignorando timeout de segurança, timer já foi cancelado para sessão #{session_id}")
          {:noreply, state}
        else
          # Removemos o timer_ref da sessão
          updated_session = Map.delete(session, :safety_timer_ref)
          updated_sessions = Map.put(state.sessions, session_id, updated_session)

          # Verificamos se o caller já recebeu resposta
          try do
            # Verificamos se o chamador já está em estado 'dead_process'
            # Essa verificação evita que tentemos responder a um processo que já não existe mais
            Process.alive?(elem(caller, 0))

            # Tenta enviar uma resposta de timeout, vai falhar silenciosamente se já tiver respondido
            GenServer.reply(caller, {:ok, "[Timeout de segurança acionado - A execução pode estar em andamento]\n\nDica: Se estiver usando IO.put/1, utilize IO.puts/1 em vez disso. Verifique também se há erros de sintaxe."})
            Logger.warning("Acionado timeout de segurança para a sessão #{session_id}")
          catch
            :error, :dead_process ->
              # O processo do chamador não existe mais, provavelmente já recebeu resposta
              Logger.debug("Timeout de segurança ignorado, processo chamador não existe mais")
            _kind, _reason ->
              Logger.debug("Timeout de segurança ignorado, resposta já enviada anteriormente")
              :ok
          end
          {:noreply, %{state | sessions: updated_sessions}}
        end
    end
  end

  # Handle info padrão para mensagens não tratadas
  @impl true
  def handle_info(msg, state) do
    Logger.debug("Mensagem não tratada: #{inspect(msg)}")
    {:noreply, state}
  end

  # Função auxiliar para encontrar a sessão pelo port
  defp find_session_by_port(port, sessions) do
    Enum.find_value(sessions, fn {id, session} ->
      if session.port == port, do: id, else: nil
    end)
  end

  # Função auxiliar para obter o ID da sessão a partir do port
  # Usada quando precisamos encontrar o ID da sessão dentro do contexto do processo collect_output
  defp find_session_id_from_port(port) do
    # Obtemos todas as sessões diretamente do estado atual do GenServer
    case GenServer.call(Process.whereis(__MODULE__), :get_all_sessions) do
      sessions when is_map(sessions) -> find_session_by_port(port, sessions)
      _ -> nil
    end
  end

  # Função para coletar a saída até encontrar o marcador de fim
  defp collect_output(port, caller, marker, output_acc, start_time, timer_ref) do
    # Definimos um timeout mais curto para a recepção de mensagens
    # para aumentar a responsividade
    timeout = 500

    receive do
      {^port, {:data, {:eol, line}}} ->
        cond do
          # Se encontramos o marcador de fim, retornamos o resultado acumulado
          String.contains?(line, marker) ->
            Logger.debug("Marcador encontrado: #{line}, retornando resultado")

            # Primeiro enviamos a resposta para evitar qualquer delay
            filtered_output = output_acc
              |> Enum.filter(fn line -> not String.contains?(line, marker) end)

            result = Enum.join(filtered_output, "\n")
            GenServer.reply(caller, {:ok, result})

            # Agora lidamos com o timer de segurança (depois de enviar a resposta)
            Process.cancel_timer(timer_ref)

            # Notificamos o GenServer de forma assíncrona
            session_id = find_session_id_from_port(port)
            if session_id do
              GenServer.cast(Process.whereis(__MODULE__), {:clear_safety_timer, session_id})
              Logger.debug("Limpeza assíncrona do timer para sessão #{session_id} solicitada")
            end

            # Não precisamos retornar nada, já respondemos ao caller
            :ok

          # Se encontramos um erro, retornamos o resultado acumulado com o erro
          String.contains?(line, "UndefinedFunctionError") or String.contains?(line, "CompileError") or
          String.contains?(line, "ArithmeticError") or String.contains?(line, "ArgumentError") or
          String.contains?(line, "Protocol.UndefinedError") or String.contains?(line, "FunctionClauseError") or
          String.contains?(line, "SyntaxError") or String.contains?(line, "KeyError") or
          String.contains?(line, "RuntimeError") or String.contains?(line, "ErlangError") ->

            Logger.debug("Erro detectado: #{line}, retornando resultado")

            # Formatamos a mensagem de erro
            error_message = format_error_message(line, output_acc)
            GenServer.reply(caller, {:ok, error_message})

            # Depois lidamos com o timer
            Process.cancel_timer(timer_ref)

            # Notificamos o GenServer de forma assíncrona
            session_id = find_session_id_from_port(port)
            if session_id do
              GenServer.cast(Process.whereis(__MODULE__), {:clear_safety_timer, session_id})
              Logger.debug("Limpeza assíncrona do timer para sessão #{session_id} solicitada (após erro)")
            end

            # Não precisamos retornar nada, já respondemos ao caller
            :ok

          # Caso 3: Qualquer outra linha, continuamos coletando
          true ->
            collect_output(port, caller, marker, output_acc ++ [line], start_time, timer_ref)
        end
              # Obtém o ID da sessão a partir do port ou usa "desconhecida" como fallback
              session_id_str = case find_session_id_from_port(port) do
                id when is_binary(id) -> id
                _ -> "desconhecida"
              end
              Logger.debug("Limpeza assíncrona do timer para sessão #{session_id_str} solicitada (após erro)")
      # Processa outros tipos de mensagens do port
      {^port, other_data} ->
        Logger.debug("Dados não processados do port: #{inspect(other_data)}")
        collect_output(port, caller, marker, output_acc, start_time, timer_ref)

    after
      # Se atingirmos o timeout, avaliamos o que foi coletado até agora
      timeout ->
        # Calculamos o tempo decorrido desde o início da coleta
        elapsed_time = System.monotonic_time(:millisecond) - start_time
        # Verificamos quanto tempo resta no timer de segurança
        remaining_time = Process.read_timer(timer_ref)

        cond do
          # 1. Se não coletamos nada ainda e estamos nos primeiros 10 segundos
          Enum.empty?(output_acc) and elapsed_time < 10_000 and remaining_time != nil ->
            # Continuamos esperando por mais um período
            collect_output(port, caller, marker, output_acc, start_time, timer_ref)

          # 2. Se já temos algumas linhas que indicam erro
          Enum.any?(output_acc, fn line ->
            String.contains?(line, "UndefinedFunctionError") or
            String.contains?(line, "CompileError") or
            String.contains?(line, "** (")
          end) ->
            # Cancelamos o timer de segurança
            Process.cancel_timer(timer_ref)

            # Filtramos linhas do prompt e convertemos para string
            clean_acc = output_acc |> Enum.filter(fn l -> not String.contains?(l, "iex(") end)
            result = Enum.join(clean_acc, "\n")

            # Enviamos os dados parciais para o chamador, identificando como erro
            GenServer.reply(caller, {:ok, "ERRO DE EXECUÇÃO:\n" <> result})

          # 3. Se já coletamos alguma coisa mas não conseguimos identificar o fim
          not Enum.empty?(output_acc) ->
            # Filtramos linhas do prompt e convertemos para string
            clean_acc = output_acc |> Enum.filter(fn l -> not String.contains?(l, "iex(") end)
            result = Enum.join(clean_acc, "\n")

            # Se o tempo estiver quase acabando, cancelamos o timer e respondemos
            if remaining_time != nil and remaining_time < 2000 do
              Process.cancel_timer(timer_ref)
              GenServer.reply(caller, {:ok, result})
            else
              # Caso contrário, continuamos coletando
              collect_output(port, caller, marker, output_acc, start_time, timer_ref)
            end

          # 4. Fallback
          true ->
            collect_output(port, caller, marker, output_acc, start_time, timer_ref)
        end
    end
  end

  # Função para formatar mensagens de erro de forma amigável
  defp format_error_message(error_line, output_acc) do
    # Determina o tipo de erro baseado na linha
    error_type = cond do
      String.contains?(error_line, "UndefinedFunctionError") -> "ERRO: Função não definida"
      String.contains?(error_line, "CompileError") -> "ERRO: Falha na compilação"
      String.contains?(error_line, "ArithmeticError") -> "ERRO: Operação aritmética inválida"
      String.contains?(error_line, "ArgumentError") -> "ERRO: Argumento inválido"
      String.contains?(error_line, "Protocol.UndefinedError") -> "ERRO: Protocolo não implementado"
      String.contains?(error_line, "FunctionClauseError") -> "ERRO: Cláusula de função não encontrada"
      String.contains?(error_line, "SyntaxError") -> "ERRO: Sintaxe inválida"
      String.contains?(error_line, "KeyError") -> "ERRO: Chave não encontrada"
      String.contains?(error_line, "RuntimeError") -> "ERRO: Erro em tempo de execução"
      String.contains?(error_line, "ErlangError") -> "ERRO: Erro do Erlang"
      true -> "ERRO: Desconhecido"
    end

    # Adiciona dicas úteis para alguns erros comuns
    tip = cond do
      String.contains?(error_line, "undefined function IO.put/1") ->
        "\nDica: Talvez você quis dizer IO.puts/1 em vez de IO.put/1"
      String.contains?(error_line, "undefined function") ->
        "\nDica: Verifique o nome da função e se o módulo está disponível"
      String.contains?(error_line, "CompileError") ->
        "\nDica: Verifique a sintaxe do código"
      true -> ""
    end

    # Filtra o output para mostrar apenas linhas relevantes para o erro
    relevant_lines = output_acc
      |> Enum.filter(fn line ->
        String.contains?(line, "Error") or
        String.contains?(line, "(")
      end)
      |> Enum.take(3)  # Limita a quantidade de linhas para evitar sobrecarga
      |> Enum.join("\n")

    # Formata a mensagem final com tipo de erro, detalhes e dica
    "#{error_type}\n#{relevant_lines}\n#{error_line}#{tip}"
  end

  # Função auxiliar para esperar por mais linhas de detalhes de erro
  defp wait_for_error_details(port, acc, remaining_lines, timeout) do
    if remaining_lines <= 0 do
      acc
    else
      receive do
        {^port, {:data, {:eol, line}}} ->
          # Se encontrarmos o marcador de fim de comando ou uma nova linha de prompt,
          # significa que a mensagem de erro terminou
          if String.contains?(line, "__CMD_END_") or
             (String.contains?(line, "iex(") and String.contains?(line, ">")) do
            acc
          else
            # Adicionamos apenas linhas que contêm conteúdo relevante para o erro
            wait_for_error_details(port, acc ++ [line], remaining_lines - 1, timeout)
          end

        {^port, _other_data} ->
          wait_for_error_details(port, acc, remaining_lines, timeout)
      after
        # Se atingirmos o timeout, retornamos o que já coletamos
        timeout -> acc
      end
    end
  end
  defp wait_for_error_details(_port, acc, 0, _timeout), do: acc
end
