defmodule DeeperHub.Core.Terminal.SessionManager do
  @moduledoc """
  Gerenciador de sessões de terminal interativo.
  """
  use GenServer
  require Logger

  # Nome completo usado para evitar referências cíclicas durante compilação
  alias DeeperHub.Core.Terminal.IExProcess
  alias DeeperHub.Core.Terminal.CommandFilter

  @command_safety_timeout 25_000

  # --- Client API ---
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def create_session() do
    GenServer.call(__MODULE__, :create_session)
  end

  def execute_command(session_id, command, client_pid) do
    GenServer.call(__MODULE__, {:execute_command, session_id, command, client_pid}, 5000)
  end

  def list_sessions() do
    GenServer.call(__MODULE__, :list_sessions)
  end

  def terminate_session(session_id) do
    GenServer.call(__MODULE__, {:terminate_session, session_id})
  end

  def terminate_all_sessions() do
    GenServer.call(__MODULE__, :terminate_all_sessions)
  end

  # --- GenServer Callbacks ---
  @impl true
  def init(:ok) do
    Process.flag(:trap_exit, true)
    {:ok, %{sessions: %{}}}
  end

  # --- Função auxiliar segura para fechar ports
  defp safe_close_port(port) do
    if port && Port.info(port) != nil do
      Port.close(port)
      :closed_now
    else
      :already_closed_or_invalid
    end
  rescue
    ArgumentError ->
      Logger.debug("SessionManager (safe_close_port): Tentativa de fechar port já fechado ou inválido: #{inspect(port)}")
      :already_closed_or_invalid
  end

  # --- Agrupando todos os handle_call juntos ---
  @impl true
  def handle_call(:create_session, _from, state) do
    session_id = UUID.uuid4()
    try do
      port = IExProcess.start_port() # Esta chamada pode levantar uma exceção se Port.open falhar

      # Se IExProcess.start_port() não levantar exceção, o port foi aberto (para o teste)
      # A lógica de flush_initial_output foi comentada/removida de IExProcess.start_port
      # durante os testes de isolamento, ou deve ser tratada pela Task de coleta.

      session = %DeeperHub.Core.Terminal.Session{
        id: session_id,
        port: port,
        created_at: DateTime.utc_now()
      }
      sessions = Map.put(state.sessions, session_id, session)
      Logger.info("Nova sessão de terminal criada: #{session_id} com port #{inspect(port)}")
      {:reply, {:ok, session_id}, %{state | sessions: sessions}}
    rescue
      # Captura qualquer exceção de IExProcess.start_port (ex: Port.open falhou)
      e ->
        Logger.error("Erro ao iniciar port IEx para nova sessão: #{inspect(e)}")
        # Retorna um erro para o TerminalResource/cliente
        {:reply, {:error, :port_initialization_failed}, state}
    end
  end

  @impl true
  def handle_call(:list_sessions, _from, state) do
    sessions_info =
      Enum.map(state.sessions, fn {id, session} ->
        %{
          id: id,
          created_at: session.created_at,
          last_command: session.last_command,
          # Adicionar status do port se útil para debug
          port_status: if(session.port && Port.info(session.port), do: "active", else: "inactive_or_closed")
        }
      end)
    {:reply, {:ok, sessions_info}, state}
  end

  @impl true
  def handle_call({:execute_command, session_id, command, client_pid}, from, state) do
    Logger.debug("SessionManager: Recebido execute_command para sessão #{session_id}")

    # Verificar se o comando está autorizado antes de prosseguir
    case CommandFilter.authorize(command, %{context: :api}) do
      {:ok, filtered_command} ->
        # Comando autorizado, prosseguir com a execução
        execute_authorized_command(session_id, filtered_command, client_pid, from, state)

      {:error, reason} ->
        # Comando não autorizado, retornar erro
        error_message = case reason do
          :blacklisted_term -> "Comando contém termos não permitidos"
          :unauthorized_module -> "Comando usa módulos não autorizados"
          :command_too_long -> "Comando excede o tamanho máximo permitido"
          _ -> "Comando não autorizado: #{inspect(reason)}"
        end

        # Se temos um cliente esperando, enviar mensagem de erro
        if client_pid && Process.alive?(client_pid) do
          send(client_pid, {:terminal_chunk, "\n[ERRO DE SEGURANÇA: #{error_message}]\n"})
          send(client_pid, {:terminal_eof, :security_error})
        end

        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:terminate_session, session_id}, _from, state) do
    case Map.get(state.sessions, session_id) do
      nil ->
        {:reply, {:error, :session_not_found}, state}
      %DeeperHub.Core.Terminal.Session{port: port, safety_timer_ref: timer_ref} ->
        if timer_ref, do: Process.cancel_timer(timer_ref)
        closing_status = safe_close_port(port)
        Logger.info("Sessão de terminal #{session_id} encerrada. Status do Port.close: #{closing_status}")
        sessions = Map.delete(state.sessions, session_id)
        {:reply, :ok, %{state | sessions: sessions}}
    end
  end

  @impl true
  def handle_call(:terminate_all_sessions, _from, state) do
    Logger.info("Encerrando todas as sessões de terminal")
    Enum.each(state.sessions, fn {_id, %DeeperHub.Core.Terminal.Session{port: port, safety_timer_ref: timer_ref}} ->
      if timer_ref, do: Process.cancel_timer(timer_ref)
      safe_close_port(port)
    end)
    {:reply, :ok, %{state | sessions: %{}}}
  end

  # Função auxiliar para executar comando autorizado
  defp execute_authorized_command(session_id, command, client_pid, from, state) do
    case Map.get(state.sessions, session_id) do
      nil ->
        Logger.warning("SessionManager: Tentativa de executar comando em sessão não encontrada: #{session_id}")
        {:reply, {:error, :session_not_found}, state}

      %DeeperHub.Core.Terminal.Session{port: nil} = session -> # Caso o port tenha sido explicitamente setado para nil
        Logger.error("SessionManager: Sessão #{session_id} existe mas não possui um port ativo (port é nil).")
        # Isso pode acontecer se o port falhou na criação mas a sessão foi parcialmente criada.
        # O ideal é que a criação da sessão falhe completamente se o port não puder ser aberto.
        # A lógica em :create_session com try/rescue ajuda a prevenir isso.
        # No entanto, se por algum motivo o port se tornar nil depois, esta é uma salvaguarda.
        updated_session = %{session | client_pid: nil, safety_timer_ref: nil } # Limpa refs
        updated_sessions = Map.put(state.sessions, session_id, updated_session)
        {:reply, {:error, :session_port_invalid_or_nil}, %{state | sessions: updated_sessions}}

      %DeeperHub.Core.Terminal.Session{port: port_obj} = session when is_port(port_obj) -> # Renomeado port para port_obj
        # Verifica se o port ainda está "vivo" antes de usar
        if Port.info(port_obj) != nil do
          safety_timer_ref = Process.send_after(self(), {:command_safety_timeout, from, session_id, client_pid}, @command_safety_timeout)
          updated_session = %{session |
            client_pid: client_pid,
            safety_timer_ref: safety_timer_ref,
            last_command: %{command: command, executed_at: DateTime.utc_now()}
          }
          updated_sessions = Map.put(state.sessions, session_id, updated_session)

          # IExProcess.execute_command_and_stream_output também verifica se o port é válido
          IExProcess.execute_command_and_stream_output(port_obj, command, client_pid, self(), session_id, safety_timer_ref)
          {:reply, {:ok, :streaming_started}, %{state | sessions: updated_sessions}}
        else
          Logger.warning("SessionManager: Tentativa de executar comando na sessão #{session_id}, mas o port #{inspect(port_obj)} não está mais ativo.")
          # Port não está mais ativo, notificar o cliente e limpar a sessão
          if client_pid && Process.alive?(client_pid) do
            send(client_pid, {:terminal_chunk, "\n[Erro: A porta do terminal para esta sessão não está mais ativa.]"})
            send(client_pid, {:terminal_eof, :port_inactive_on_execute})
          end
          # Limpa a sessão
          safe_close_port(port_obj) # Tenta fechar por segurança, mas já deve estar fechado.
          sessions = Map.delete(state.sessions, session_id)
          {:reply, {:error, :session_port_inactive}, %{state | sessions: sessions}}
        end

      %DeeperHub.Core.Terminal.Session{port: invalid_port_val} = _session -> # Port não é um port válido
        Logger.error("SessionManager: Sessão #{session_id} tem um valor de port inválido: #{inspect invalid_port_val}")
        {:reply, {:error, :session_port_invalid_or_nil}, state}
    end
  end







  # --- Agrupando todos os handle_info juntos ---
  @impl true
  def handle_info({:command_safety_timeout, _original_caller_from, session_id, client_pid_timed_out}, state) do
    case Map.get(state.sessions, session_id) do
      nil ->
        Logger.warning("Timeout de segurança para sessão #{session_id} que não existe mais.")
        {:noreply, state}
      %DeeperHub.Core.Terminal.Session{safety_timer_ref: nil} ->
        Logger.debug("Timeout de segurança para sessão #{session_id} ignorado, comando/timer já tratado.")
        {:noreply, state}
      %DeeperHub.Core.Terminal.Session{} = session ->
        Logger.warning("Timeout de segurança ACIONADO para sessão #{session_id}.")
        if client_pid_timed_out && Process.alive?(client_pid_timed_out) do
           send(client_pid_timed_out, {:terminal_chunk, "\n[SessionManager: Comando excedeu o tempo limite de segurança.]"})
           send(client_pid_timed_out, {:terminal_eof, :manager_timeout})
        end
        updated_session = %{session | safety_timer_ref: nil, client_pid: nil}
        updated_sessions = Map.put(state.sessions, session_id, updated_session)
        {:noreply, %{state | sessions: updated_sessions}}
    end
  end

  @impl true
  def handle_info({port_obj, {:exit_status, status}}, state) do # Renomeado port para port_obj
    case find_session_by_port(port_obj, state.sessions) do
      {session_id, %DeeperHub.Core.Terminal.Session{safety_timer_ref: timer_ref, client_pid: client_pid}} ->
        Logger.warning("Porta da sessão #{session_id} (port: #{inspect port_obj}) terminou com status: #{status}.")
        if timer_ref, do: Process.cancel_timer(timer_ref)

        if client_pid && Process.alive?(client_pid) do
          send(client_pid, {:terminal_chunk, "\n[Processo do terminal da sessão encerrou (status: #{status})]"}) 
          send(client_pid, {:terminal_eof, :port_terminated})
        end
        updated_sessions = Map.delete(state.sessions, session_id)
        {:noreply, %{state | sessions: updated_sessions}}
      nil ->
        # Isso pode acontecer se o port terminar muito rapidamente, antes mesmo da sessão ser totalmente registrada,
        # ou se já tiver sido limpo por outra razão.
        Logger.warning("Porta #{inspect(port_obj)} terminou, mas nenhuma sessão correspondente encontrada no estado atual.")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({port_obj, {:data, data_content}}, state) do # Renomeado port para port_obj, data para data_content
     Logger.warning("SessionManager: Recebida data órfã do port #{inspect port_obj}: #{inspect data_content}")
    # Geralmente indica que o flush_initial_output não pegou tudo, ou o port está enviando dados
    # inesperados após a Task de coleta ter terminado ou antes de começar.
    # Poderíamos tentar encontrar a sessão e encaminhar se um client_pid estiver ativo,
    # mas isso pode complicar. Por agora, apenas logar.
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("SessionManager: Mensagem não tratada: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:command_stream_completed, session_id}, state) do
    case Map.get(state.sessions, session_id) do
      nil -> {:noreply, state}
      %DeeperHub.Core.Terminal.Session{} = session ->
        Logger.debug("Comando completou stream para sessão #{session_id}. Limpando estado do client/timer.")
        updated_session = %{session | safety_timer_ref: nil, client_pid: nil}
        updated_sessions = Map.put(state.sessions, session_id, updated_session)
        {:noreply, %{state | sessions: updated_sessions}}
    end
  end







  @impl true
  def terminate(reason, state) do
    Logger.info("SessionManager terminando. Motivo: #{inspect reason}. Encerrando todas as sessões.")
    Enum.each(state.sessions, fn {_id, %DeeperHub.Core.Terminal.Session{port: port, safety_timer_ref: timer_ref}} ->
      if timer_ref, do: Process.cancel_timer(timer_ref)
      safe_close_port(port)
    end)
    :ok
  end

  # --- Funções Auxiliares ---
  defp find_session_by_port(port_to_find, sessions) do # Renomeado port para port_to_find
    Enum.find(sessions, fn {_id, %DeeperHub.Core.Terminal.Session{port: p}} -> p == port_to_find end)
  end
end
