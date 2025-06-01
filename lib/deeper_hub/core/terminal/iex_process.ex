defmodule DeeperHub.Core.Terminal.IExProcess do
  @moduledoc """
  Gerencia a interação com um processo IEx individual via Port.
  Coleta a saída e a envia para um `client_pid`.
  """
  require Logger
  alias DeeperHub.Core.Terminal.OutputFormatter

  # Timeout para cada `receive` ao coletar output, para permitir envio de chunks.
  @receive_timeout 100 # milissegundos
  # Quantas linhas acumular antes de enviar um chunk (aproximadamente)
  @chunk_line_threshold 1

  @doc """
  Inicia um novo processo IEx e retorna o port.
  """
  def start_port() do
    iex_executable_path =
      System.find_executable("iex") || System.find_executable("iex.bat")

    unless iex_executable_path do
      Logger.error("IExProcess: Executável 'iex' ou 'iex.bat' não encontrado.")
      raise "Executável 'iex' ou 'iex.bat' não encontrado. Verifique seu PATH."
    end
    Logger.debug("IExProcess: Executável: #{iex_executable_path}")

    # Abordagem simplificada para identificar o problema
    # Vamos testar com opções mínimas e aumentar gradativamente
    
    # Testes prévios mostraram que estas opções funcionavam individualmente
    port_options = [:binary, :exit_status]
    
    # Configuração da variável de ambiente para Windows
    # Comentado para simplificar e identificar o problema
    # env_vars = [{"IEX_WITH_WERL", "false"}] # Evita que o Windows use WERL
    
    # Argumentos para o IEx
    # Comentado para simplificar e identificar o problema
    # args = ["--no-halt", "--no-pry"]

    Logger.debug("IExProcess: Testando com opções básicas: #{inspect(port_options)}")


    Logger.debug("IExProcess: Iniciando IEx com opções: #{inspect(port_options)}")

    case Port.open({:spawn_executable, iex_executable_path}, port_options) do
      port when is_port(port) ->
        Logger.info("IEXProcess: Port aberto com sucesso: #{inspect(port)}")
        port
      error_reason ->
        Logger.error("IExProcess: Falha ao abrir port com opções #{inspect(port_options)}: #{inspect(error_reason)}")
        raise "Falha ao abrir port IEx: #{inspect(error_reason)}"
    end
  end

  @doc """
  Limpa o buffer de saída inicial do port (ex: prompt inicial).
  """
  def flush_initial_output(port) do
    # Esta função pode não ser chamada ou não funcionar corretamente durante os testes de
    # isolamento de Port.open, pois o iex pode não estar configurado para permanecer aberto
    # ou para interagir da maneira esperada.
    receive do
      {^port, {:data, {:eol, _line}}} ->
        # Logger.debug("IExProcess: Flushed initial line: #{line}")
        flush_initial_output(port)
      {^port, {:data, _data}} ->
        # Logger.debug("IExProcess: Flushed initial data: #{inspect(data)}")
        flush_initial_output(port)
    after
      500 ->
        # Logger.debug("IExProcess: Initial flush complete for port #{inspect(port)}")
        :ok
    end
  end

  @doc """
  Envia um comando para o processo IEx e coleta a saída de forma assíncrona,
  enviando chunks para `client_pid`.
  """
  def execute_command_and_stream_output(port, command, client_pid, manager_pid, session_id, safety_timer_ref) do
    marker = "__CMD_END_#{:rand.uniform(1_000_000)}__"
    command_with_marker = """
    resultado_temp = try do
      #{command}
    rescue
      e in RuntimeError -> e
      e in ArgumentError -> e
      e in CompileError -> e
      e -> e
    catch
      :exit, valor -> {:exit, valor}
      :throw, valor -> {:throw, valor}
      tipo, valor -> {tipo, valor}
    end
    IO.puts("#{marker}")
    resultado_temp
    """

    # Verifica se o port é válido antes de enviar o comando
    # Port.info(port) retorna informações se o port estiver ativo, nil caso contrário.
    if port && Port.info(port) != nil do
      Port.command(port, command_with_marker <> "\n")
      Logger.debug("IExProcess: Sent command to port #{inspect(port)}")

      # Criamos uma Task para coletar a saída sem vinculação (:link) com o processo atual
      # para evitar que o port seja fechado quando a Task terminar
      task_pid = Process.spawn(fn ->
        Logger.debug("IExProcess: Task de coleta iniciada para sessão #{session_id} com PID #{inspect(self())}")
        # IMPORTANTE: Fazemos uma conexão temporária do port com a Task
        # para que as mensagens do port sejam enviadas para esta Task durante a execução do comando
        old_port_owner = Port.info(port)[:connected]
        true = Port.connect(port, self())
        Logger.debug("IExProcess: Conexão temporária da Task com o port #{inspect(port)} estabelecida. Owner anterior: #{inspect(old_port_owner)}")
        
        # Coleta a saída do comando
        result = collect_and_stream(port, client_pid, marker, [], System.monotonic_time(:millisecond), safety_timer_ref, manager_pid, session_id)
        
        # IMPORTANTE: Devolvemos a propriedade do port para o processo original (SessionManager)
        # para manter o port aberto entre os comandos
        if is_pid(old_port_owner) and Process.alive?(old_port_owner) do
          Logger.debug("IExProcess: Devolvendo conexão do port #{inspect(port)} para #{inspect(old_port_owner)}")
          Port.connect(port, old_port_owner)
        end
        
        result
      end, []) # Sem :link para evitar que a Task feche o port ao terminar
      
      Logger.debug("IExProcess: Task de coleta #{inspect(task_pid)} iniciada para sessão #{session_id}")
      Process.monitor(task_pid) # Monitor para receber notificação se a task terminar
    else
      Logger.error("IExProcess: Tentativa de enviar comando para port inválido ou fechado: #{inspect(port)} para sessão #{session_id}")
      # Notifica o cliente que o port não está disponível
      send_chunk(client_pid, "[Erro Interno: A porta do terminal não está mais disponível]")
      send_eof(client_pid, :port_unavailable)
      # Notifica o manager para limpar, se necessário (embora já deva ter sido limpo se o port fechou)
      cleanup_after_command(safety_timer_ref, manager_pid, session_id)
      {:error, :port_unavailable} # Retorna um erro para a chamada se síncrona
    end
  end

  # Função recursiva para coletar saída e enviar chunks
  defp collect_and_stream(port, client_pid, marker, output_acc, start_time, safety_timer_ref, manager_pid, session_id) do
    collection_timeout_ms = 20_000

    receive do
      # Padrão específico para quando usamos {:line, N} como opção do port
      {^port, {:data, {:eol, line}}} ->
        Logger.debug("IExProcess: Received line with :eol format: '#{String.slice(line, 0, 50)}#{if String.length(line) > 50, do: "...", else: ""}' for session #{session_id}")
        cond do
          String.contains?(line, marker) ->
            Logger.debug("IExProcess: Marker found in line: '#{line}' for session #{session_id}")
            clean_acc = OutputFormatter.clean_lines(output_acc, marker)
            final_chunk = Enum.join(clean_acc, "\n")
            if String.trim(final_chunk) != "" do
              send_chunk(client_pid, final_chunk)
            end
            send_eof(client_pid, :ok)
            cleanup_after_command(safety_timer_ref, manager_pid, session_id)
            :ok

          String.match?(line, ~r/\*\* \((.+Error)\)/) or String.match?(line, ~r/Error:/) ->
            Logger.warning("IExProcess: Error line detected: '#{line}' for session #{session_id}")
            error_details = gather_error_details(port, [line], marker, 3, 100)
            full_error_output = Enum.join(output_acc ++ error_details, "\n")
            formatted_error = OutputFormatter.format_error_message(full_error_output)
            send_chunk(client_pid, formatted_error)
            send_eof(client_pid, :error)
            cleanup_after_command(safety_timer_ref, manager_pid, session_id)
            :ok

          true ->
            new_acc = output_acc ++ [line]
            if length(new_acc) >= @chunk_line_threshold do
              chunk_to_send = OutputFormatter.clean_lines(new_acc, marker) |> Enum.join("\n")
              send_chunk(client_pid, chunk_to_send)
              collect_and_stream(port, client_pid, marker, [], start_time, safety_timer_ref, manager_pid, session_id)
            else
              collect_and_stream(port, client_pid, marker, new_acc, start_time, safety_timer_ref, manager_pid, session_id)
            end
        end

      # Padrão para dados binários quando usamos apenas :binary sem {:line, N}
      {^port, {:data, data_block}} when is_binary(data_block) ->
        Logger.debug("IExProcess: Received binary data block of size #{byte_size(data_block)} for session #{session_id}")
        lines = String.split(data_block, "\n", trim: false)
        process_lines_recursively(port, client_pid, marker, output_acc, start_time, safety_timer_ref, manager_pid, session_id, lines)

      {^port, {:exit_status, status}} ->
        Logger.warning("IExProcess (collect_and_stream): Port #{inspect(port)} for session #{session_id} exited with status #{status}.")
        send_chunk(client_pid, "\n[Terminal process (monitored by Task) exited with status: #{status}]")
        send_eof(client_pid, :port_terminated_in_task)
        cleanup_after_command(safety_timer_ref, manager_pid, session_id) # Garante limpeza
        :ok # Task termina

      other_message ->
        Logger.debug("IExProcess (collect_and_stream): Received other message: #{inspect(other_message)} for session #{session_id}")
        collect_and_stream(port, client_pid, marker, output_acc, start_time, safety_timer_ref, manager_pid, session_id)

    after
      @receive_timeout ->
        elapsed_time = System.monotonic_time(:millisecond) - start_time
        if elapsed_time > collection_timeout_ms do
          Logger.warning("IExProcess (collect_and_stream): Collection timeout for command on port #{inspect(port)} for session #{session_id}. Elapsed: #{elapsed_time}ms")
          remaining_output = if Enum.empty?(output_acc), do: "[Command timed out in Task without further output]", else: Enum.join(OutputFormatter.clean_lines(output_acc, marker), "\n") <> "\n[Command timed out in Task]"
          send_chunk(client_pid, remaining_output)
          send_eof(client_pid, :task_timeout)
          cleanup_after_command(safety_timer_ref, manager_pid, session_id)
          :ok
        else
          unless Enum.empty?(output_acc) do
            chunk_to_send = OutputFormatter.clean_lines(output_acc, marker) |> Enum.join("\n")
            send_chunk(client_pid, chunk_to_send)
          end
          collect_and_stream(port, client_pid, marker, [], start_time, safety_timer_ref, manager_pid, session_id)
        end
    end
  end

  defp process_lines_recursively(port, client_pid, marker, acc, start_time, timer_ref, manager_pid, session_id, [head | tail]) do
    new_acc =
      cond do
        String.contains?(head, marker) ->
          Logger.debug("IExProcess: Marker found in processed line: '#{head}'")
          clean_acc_local = OutputFormatter.clean_lines(acc, marker) # Variável local
          final_chunk = Enum.join(clean_acc_local, "\n")
          if String.trim(final_chunk) != "" do
            send_chunk(client_pid, final_chunk)
          end
          send_eof(client_pid, :ok)
          cleanup_after_command(timer_ref, manager_pid, session_id)
          :marker_found

        String.match?(head, ~r/\*\* \((.+Error)\)/) or String.match?(head, ~r/Error:/) ->
          Logger.warning("IExProcess: Error line detected in processed line: '#{head}'")
          error_details = [head]
          full_error_output = Enum.join(acc ++ error_details, "\n")
          formatted_error = OutputFormatter.format_error_message(full_error_output)
          send_chunk(client_pid, formatted_error)
          send_eof(client_pid, :error)
          cleanup_after_command(timer_ref, manager_pid, session_id)
          :marker_found

        true -> acc ++ [head]
      end

    if new_acc == :marker_found do
      :ok
    else
      current_acc_for_chunking = if is_list(new_acc), do: new_acc, else: acc
      if length(current_acc_for_chunking) >= @chunk_line_threshold do
        chunk_to_send = OutputFormatter.clean_lines(current_acc_for_chunking, marker) |> Enum.join("\n")
        send_chunk(client_pid, chunk_to_send)
        process_lines_recursively(port, client_pid, marker, [], start_time, timer_ref, manager_pid, session_id, tail)
      else
        process_lines_recursively(port, client_pid, marker, current_acc_for_chunking, start_time, timer_ref, manager_pid, session_id, tail)
      end
    end
  end
  defp process_lines_recursively(port, client_pid, marker, acc, start_time, timer_ref, manager_pid, session_id, []) do
    collect_and_stream(port, client_pid, marker, acc, start_time, timer_ref, manager_pid, session_id)
  end

  defp gather_error_details(port, collected_lines, marker, lines_to_gather, timeout_ms) do
    if lines_to_gather <= 0 do
      Enum.reverse(collected_lines)
    else
      receive do
        {^port, {:data, {:eol, line}}} ->
          Logger.debug("IExProcess: gather_error_details received line: '#{String.slice(line, 0, 50)}#{if String.length(line) > 50, do: "...", else: ""}' for error context")
          if String.contains?(line, marker) || (String.starts_with?(line, "iex(") && String.ends_with?(line, "> ")) do
            Enum.reverse(collected_lines)
          else
            gather_error_details(port, [line | collected_lines], marker, lines_to_gather - 1, timeout_ms)
          end
        {^port, {:data, data_block}} when is_binary(data_block) ->
          Logger.debug("IExProcess: gather_error_details received binary data block of size #{byte_size(data_block)} for error context")
          # Processar linhas do bloco binário para coletar erros
          lines = String.split(data_block, "\n", trim: false)
          # Processar as linhas e verificar se encontramos o final do erro
          {should_continue, final_lines} = Enum.reduce_while(lines, collected_lines, fn line, acc ->
            if String.contains?(line, marker) || (String.starts_with?(line, "iex(") && String.ends_with?(line, "> ")) do
              # Encontramos o fim do erro, parar processamento
              {:halt, acc}
            else
              # Continuar processando
              {:cont, [line | acc]}
            end
          end)
          
          if should_continue == :halt do
            # Se encontramos o fim do erro, retornar as linhas coletadas
            Enum.reverse(final_lines)
          else
            # Continuar coletando com as novas linhas adicionadas
            gather_error_details(port, final_lines, marker, lines_to_gather - length(lines), timeout_ms)
          end
      after
        timeout_ms ->
          Logger.debug("IExProcess: Timeout gathering error details.")
          Enum.reverse(collected_lines)
      end
    end
  end

  defp send_chunk(client_pid, data) do
    if client_pid && Process.alive?(client_pid) && String.trim(data) != "" do
      # Logger.debug("IExProcess: Sending chunk to #{inspect client_pid}: #{byte_size(data)} bytes")
      send(client_pid, {:terminal_chunk, data})
    else
      # Logger.debug("IExProcess: Not sending chunk, client_pid invalid or data empty. Client: #{inspect client_pid}")
    end
  end

  defp send_eof(client_pid, reason) do
    if client_pid && Process.alive?(client_pid) do
      Logger.debug("IExProcess: Sending EOF to #{inspect client_pid} with reason: #{reason}")
      send(client_pid, {:terminal_eof, reason})
    else
      # Logger.debug("IExProcess: Not sending EOF, client_pid invalid. Client: #{inspect client_pid}")
    end
  end

  defp cleanup_after_command(safety_timer_ref, manager_pid, session_id) do
    if safety_timer_ref, do: Process.cancel_timer(safety_timer_ref)
    if manager_pid && Process.alive?(manager_pid) do
      GenServer.cast(manager_pid, {:command_stream_completed, session_id})
    end
  end
end
