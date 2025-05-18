defmodule Deeper_Hub.Core.WebSockets.Auth.Session.SessionManager do
  @moduledoc """
  Gerenciador de sessões de usuário.

  Este módulo coordena o ciclo de vida das sessões de usuário,
  incluindo criação, validação, renovação e encerramento.
  """

  use GenServer

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionService
  alias Deeper_Hub.Core.WebSockets.Auth.JwtService
  alias Deeper_Hub.Core.Data.DBConnection.Repositories.UserRepository

  # API Pública

  @doc """
  Inicia o gerenciador de sessões.
  """
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Cria uma nova sessão para um usuário.

  ## Parâmetros

    - `user_id`: ID do usuário
    - `remember_me`: Flag para sessão persistente
    - `metadata`: Metadados adicionais (user-agent, IP, etc.)

  ## Retorno

    - `{:ok, session}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def create_session(user_id, remember_me \\ false, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:create_session, user_id, remember_me, metadata})
  end

  @doc """
  Valida uma sessão.

  ## Parâmetros

    - `access_token`: Token de acesso

  ## Retorno

    - `{:ok, user}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def validate_session(access_token) do
    GenServer.call(__MODULE__, {:validate_session, access_token})
  end

  @doc """
  Renova uma sessão.

  ## Parâmetros

    - `refresh_token`: Token de refresh

  ## Retorno

    - `{:ok, new_tokens, session}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def renew_session(refresh_token) do
    GenServer.call(__MODULE__, {:renew_session, refresh_token})
  end

  @doc """
  Encerra uma sessão.

  ## Parâmetros

    - `access_token`: Token de acesso
    - `refresh_token`: Token de refresh

  ## Retorno

    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def end_session(access_token, refresh_token) do
    GenServer.call(__MODULE__, {:end_session, access_token, refresh_token})
  end

  @doc """
  Encerra todas as sessões de um usuário.

  ## Parâmetros

    - `user_id`: ID do usuário

  ## Retorno

    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def end_all_user_sessions(user_id) do
    GenServer.call(__MODULE__, {:end_all_user_sessions, user_id})
  end

  @doc """
  Lista todas as sessões ativas de um usuário.

  ## Parâmetros

    - `user_id`: ID do usuário

  ## Retorno

    - Lista de sessões
  """
  def list_user_sessions(user_id) do
    GenServer.call(__MODULE__, {:list_user_sessions, user_id})
  end

  # Callbacks do GenServer

  @impl true
  def init(:ok) do
    Logger.info("Iniciando gerenciador de sessões", %{module: __MODULE__})

    # Inicia o serviço de sessão
    SessionService.start_link()

    {:ok, %{}}
  end

  @impl true
  def handle_call({:create_session, user_id, remember_me, metadata}, _from, state) do
    result = SessionService.create_session(user_id, remember_me, metadata)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:validate_session, access_token}, _from, state) do
    result = with {:ok, claims} <- JwtService.verify_token(access_token),
                 user_id = Map.get(claims, "user_id"),
                 {:ok, user} <- UserRepository.get_by_id(user_id) do

      # Atualiza a atividade da sessão
      session_id = Map.get(claims, "session_id")
      if session_id, do: SessionService.update_activity(session_id)

      {:ok, user}
    else
      error -> error
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:renew_session, refresh_token}, _from, state) do
    result = SessionService.refresh_session(refresh_token)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:end_session, access_token, refresh_token}, _from, state) do
    # Primeiro verifica o token para obter o ID da sessão
    result = with {:ok, claims} <- JwtService.verify_token(access_token),
                 session_id = Map.get(claims, "session_id") do

      if session_id do
        SessionService.end_session(session_id, access_token, refresh_token)
      else
        # Se não tiver ID de sessão, apenas revoga os tokens
        JwtService.revoke_token(access_token)
        JwtService.revoke_token(refresh_token)
        :ok
      end
    else
      # Se o token for inválido, tenta revogar mesmo assim
      _ ->
        JwtService.revoke_token(access_token)
        JwtService.revoke_token(refresh_token)
        :ok
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:end_all_user_sessions, user_id}, _from, state) do
    result = SessionService.end_all_user_sessions(user_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:list_user_sessions, user_id}, _from, state) do
    sessions = SessionService.get_user_sessions(user_id)

    # Filtra apenas sessões ativas
    active_sessions = Enum.filter(sessions, fn session ->
      {:ok, is_active} = SessionService.is_session_active?(session.id)
      is_active
    end)

    {:reply, active_sessions, state}
  end
end
