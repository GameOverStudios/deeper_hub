defmodule DeeperHub.Core.Console.ConsoleManager do
  @moduledoc """
  Gerencia uma console interativa que executa comandos predefinidos.

  Ao contrário do módulo Terminal que executa código Elixir diretamente,
  este módulo oferece uma interface controlada para executar operações
  específicas através de comandos predefinidos, proporcionando segurança
  e facilidade de uso para operações comuns.
  """
  use GenServer
  require Logger

  # Estrutura para representar uma sessão de console
  defmodule Session do
    @moduledoc """
    Estrutura que representa o estado de uma sessão de console.
    """
    defstruct [
      :id,
      :created_at,
      :last_command,
      :client_pid,
      :context,
      history: []
    ]

    @type t :: %__MODULE__{
      id: String.t() | nil,
      created_at: DateTime.t() | nil,
      last_command: String.t() | nil,
      client_pid: pid() | nil,
      context: map() | nil,
      history: list(String.t())
    }
  end

  # Cliente API

  @doc """
  Inicia o gerenciador de console.
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Cria uma nova sessão de console.

  ## Parâmetros
    * `server` - PID ou nome registrado do servidor de console
    * `options` - Opções para a nova sessão (ex: contexto específico)

  ## Retorno
    * `{:ok, session_id}` - ID da sessão criada
    * `{:error, reason}` - Erro caso não seja possível criar a sessão
  """
  def create_session(server, options \\ %{}) do
    GenServer.call(server, {:create_session, options})
  end

  @doc """
  Executa um comando na sessão de console especificada.

  ## Parâmetros
    * `server` - PID ou nome registrado do servidor de console
    * `session_id` - ID da sessão
    * `command` - Comando a ser executado
    * `client_pid` - PID do cliente que receberá a resposta

  ## Retorno
    * `{:ok, result}` - Resultado do comando
    * `{:error, reason}` - Erro caso o comando não possa ser executado
  """
  def execute_command(server, session_id, command, client_pid) do
    GenServer.call(server, {:execute_command, session_id, command, client_pid})
  end
  def execute_command(server, session_id, command) do
    execute_command(server, session_id, command, nil)
  end



  @doc """
  Executa um comando em uma sessão de console (REST) sem client_pid.
  """
  def execute_command(session_id, command) do
    execute_command(session_id, command, nil)
  end

  @doc """
  Lista todas as sessões ativas.

  ## Parâmetros
    * `server` - PID ou nome registrado do servidor de console

  ## Retorno
    * `{:ok, sessions}` - Lista de IDs de sessão e suas informações
    * `{:error, reason}` - Erro caso não seja possível listar as sessões
  """
  def list_sessions(server) do
    GenServer.call(server, :list_sessions)
  end

  @doc """
  Encerra uma sessão de console.

  ## Parâmetros
    * `server` - PID ou nome registrado do servidor de console
    * `session_id` - ID da sessão a ser encerrada

  ## Retorno
    * `:ok` - Sessão encerrada com sucesso
    * `{:error, reason}` - Erro caso não seja possível encerrar a sessão
  """
  def terminate_session(server, session_id) do
    GenServer.call(server, {:terminate_session, session_id})
  end

  # Implementação do servidor (callbacks)

  @impl true
  def init(_opts) do
    Logger.info("ConsoleManager iniciado.")
    {:ok, %{sessions: %{}}}
  end

  @impl true
  def handle_call({:create_session, options}, _from, state) do
    session_id = generate_session_id()

    session = %Session{
      id: session_id,
      created_at: DateTime.utc_now(),
      context: options,
      history: []
    }

    updated_sessions = Map.put(state.sessions, session_id, session)

    # Enviar mensagem de boas-vindas se houver um client_pid
    if Map.has_key?(options, :client_pid) && options.client_pid do
      send_response(options.client_pid, get_welcome_message())
    end

    Logger.info("Nova sessão de console criada: #{session_id}")
    {:reply, {:ok, session_id}, %{state | sessions: updated_sessions}}
  end

  @impl true
  def handle_call({:execute_command, session_id, command, client_pid}, _from, state) do
    case Map.get(state.sessions, session_id) do
      nil ->
        Logger.warning("ConsoleManager: Tentativa de executar comando em sessão não encontrada: #{session_id}")
        {:reply, {:error, :session_not_found}, state}

      session ->
        # Atualiza a sessão com o último comando, timestamp e adiciona ao histórico
        updated_session = %{session |
          last_command: %{
            command: command,
            executed_at: DateTime.utc_now()
          },
          client_pid: client_pid || session.client_pid,
          history: [command | session.history]
        }

        # Processa o comando
        result = process_command(command, updated_session)

        # Envia a resposta ao cliente se um PID estiver disponível
        if updated_session.client_pid do
          send_response(updated_session.client_pid, result)
        end

        # Atualiza o estado com a sessão modificada
        updated_sessions = Map.put(state.sessions, session_id, updated_session)
        {:reply, {:ok, result}, %{state | sessions: updated_sessions}}
    end
  end

  @impl true
  def handle_call(:list_sessions, _from, state) do
    session_info =
      state.sessions
      |> Enum.map(fn {id, session} ->
        {id, %{
          created_at: session.created_at,
          last_command: session.last_command,
          history_count: length(session.history)
        }}
      end)
      |> Enum.into(%{})

    {:reply, {:ok, session_info}, state}
  end

  @impl true
  def handle_call({:terminate_session, session_id}, _from, state) do
    case Map.get(state.sessions, session_id) do
      nil ->
        {:reply, {:error, :session_not_found}, state}

      session ->
        # Notificar o cliente se houver um
        if session.client_pid && Process.alive?(session.client_pid) do
          send_response(session.client_pid, "Sessão encerrada: #{session_id}")
        end

        # Remover a sessão do estado
        updated_sessions = Map.delete(state.sessions, session_id)
        Logger.info("Sessão de console encerrada: #{session_id}")
        {:reply, :ok, %{state | sessions: updated_sessions}}
    end
  end

  # Funções privadas

  defp generate_session_id do
    random_part = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    timestamp_part = System.system_time(:millisecond) |> Integer.to_string(36)
    "console_#{timestamp_part}_#{random_part}"
  end

  defp process_command("help", _session) do
    """
    === CONSOLE DEEPER HUB ===

    Comandos disponíveis:

    help                - Exibe esta mensagem de ajuda
    info                - Exibe informações sobre a sessão atual
    clear               - Limpa o histórico de comandos da sessão
    history             - Mostra o histórico de comandos da sessão
    quit, exit          - Encerra a sessão atual

    Mais comandos serão implementados em versões futuras.
    """
  end

  defp process_command("info", session) do
    """
    === INFORMAÇÕES DA SESSÃO ===

    ID da Sessão: #{session.id}
    Criada em: #{DateTime.to_string(session.created_at)}
    Comandos executados: #{length(session.history)}
    Último comando: #{session.last_command || "Nenhum"}
    """
  end

  defp process_command("clear", _session) do
    "Histórico de comandos limpo."
  end

  defp process_command("history", session) do
    history_text =
      session.history
      |> Enum.reverse()
      |> Enum.with_index(1)
      |> Enum.map(fn {cmd, idx} -> "#{idx}. #{cmd}" end)
      |> Enum.join("\n")

    """
    === HISTÓRICO DE COMANDOS ===

    #{history_text}
    """
  end

  defp process_command(command, _session) when command in ["quit", "exit"] do
    "Encerrando sessão..."
  end

  defp process_command(unknown_command, _session) do
    "Comando desconhecido: '#{unknown_command}'. Digite 'help' para ver a lista de comandos disponíveis."
  end

  defp get_welcome_message do
    """
    ====================================
           CONSOLE DEEPER HUB
    ====================================

    Bem-vindo ao Console Interativo do Deeper Hub!
    Este console permite executar operações através de
    comandos predefinidos em um ambiente controlado.

    Digite 'help' para ver os comandos disponíveis.

    ====================================
    """
  end

  defp send_response(pid, message) when is_pid(pid) and is_binary(message) do
    if Process.alive?(pid) do
      send(pid, {:console_response, message})
    end
  end


  # --- Wrappers para integração REST (usando nome registrado do GenServer) ---
  @doc """
  """
  def create_session do
    create_session(__MODULE__)
  end

  @doc """

  end

  @doc """
  Lista todas as sessões ativas (REST).
  """
  def list_sessions do
    list_sessions(__MODULE__)
  end

  @doc """
  Encerra uma sessão de console (REST).
  """
  def terminate_session(session_id) do
    terminate_session(__MODULE__, session_id)
  end
end
