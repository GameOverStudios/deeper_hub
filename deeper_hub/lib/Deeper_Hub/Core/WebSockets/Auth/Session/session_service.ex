defmodule Deeper_Hub.Core.WebSockets.Auth.Session.SessionService do
  @moduledoc """
  Serviço para gerenciamento de sessões de usuário.

  Este módulo fornece funções para criar, recuperar, atualizar e excluir sessões de usuário,
  incluindo suporte para sessões persistentes ("lembrar-me").
  """

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionPolicy
  alias Deeper_Hub.Core.WebSockets.Auth.JwtService
  alias Deeper_Hub.Core.WebSockets.Auth.Token.TokenRotationService

  # Estrutura para representar uma sessão
  defstruct [
    :id,
    :user_id,
    :access_token,
    :refresh_token,
    :remember_me,
    :created_at,
    :last_activity,
    :expires_at,
    :user_agent,
    :ip_address
  ]

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
    Logger.info("Criando sessão para usuário", %{
      module: __MODULE__,
      user_id: user_id,
      remember_me: remember_me
    })

    # Determina o tempo de expiração com base na política
    token_expiry = if remember_me do
      SessionPolicy.remember_me_expiry()
    else
      SessionPolicy.refresh_token_expiry()
    end

    # Gera tokens para a sessão
    case JwtService.generate_token_pair(user_id, token_expiry) do
      {:ok, access_token, refresh_token, claims} ->
        # Cria a estrutura de sessão
        session = %__MODULE__{
          id: UUID.uuid4(),
          user_id: user_id,
          access_token: access_token,
          refresh_token: refresh_token,
          remember_me: remember_me,
          created_at: DateTime.utc_now(),
          last_activity: DateTime.utc_now(),
          expires_at: DateTime.from_unix!(Map.get(claims.refresh, "exp")),
          user_agent: Map.get(metadata, :user_agent),
          ip_address: Map.get(metadata, :ip_address)
        }

        # Verifica se o usuário excedeu o limite de sessões
        enforce_session_limit(user_id)

        # Armazena a sessão (em memória por enquanto, poderia ser em banco de dados)
        store_session(session)

        {:ok, session}

      error ->
        Logger.error("Erro ao gerar tokens para sessão", %{
          module: __MODULE__,
          user_id: user_id,
          error: error
        })

        {:error, :token_generation_failed}
    end
  end

  @doc """
  Recupera uma sessão pelo ID.

  ## Parâmetros

    - `session_id`: ID da sessão

  ## Retorno

    - `{:ok, session}` em caso de sucesso
    - `{:error, :not_found}` se a sessão não existir
  """
  def get_session(session_id) do
    case :ets.lookup(:sessions, session_id) do
      [{^session_id, session}] -> {:ok, session}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Recupera todas as sessões de um usuário.

  ## Parâmetros

    - `user_id`: ID do usuário

  ## Retorno

    - Lista de sessões
  """
  def get_user_sessions(user_id) do
    # Usamos match_object com um padrão mais específico
    :ets.match_object(:sessions, {:_, %{user_id: user_id}})
    |> Enum.map(fn {_, session} -> session end)
  end

  @doc """
  Atualiza a atividade de uma sessão.

  ## Parâmetros

    - `session_id`: ID da sessão

  ## Retorno

    - `{:ok, updated_session}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def update_activity(session_id) do
    with {:ok, session} <- get_session(session_id) do
      updated_session = %{session | last_activity: DateTime.utc_now()}
      :ets.insert(:sessions, {session_id, updated_session})
      {:ok, updated_session}
    end
  end

  @doc """
  Renova os tokens de uma sessão.

  ## Parâmetros

    - `refresh_token`: Token de refresh atual

  ## Retorno

    - `{:ok, new_tokens, updated_session}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def refresh_session(refresh_token) do
    # Usa o serviço de rotação de tokens para renovar os tokens
    TokenRotationService.rotate_tokens(refresh_token)
  end

  @doc """
  Encerra uma sessão.

  ## Parâmetros

    - `session_id`: ID da sessão
    - `access_token`: Token de acesso
    - `refresh_token`: Token de refresh

  ## Retorno

    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def end_session(session_id, access_token, refresh_token) do
    # Revoga os tokens
    JwtService.revoke_token(access_token)
    JwtService.revoke_token(refresh_token)

    # Remove a sessão do armazenamento
    :ets.delete(:sessions, session_id)

    :ok
  end

  @doc """
  Encerra todas as sessões de um usuário.

  ## Parâmetros

    - `user_id`: ID do usuário

  ## Retorno

    - `:ok`
  """
  def end_all_user_sessions(user_id) do
    sessions = get_user_sessions(user_id)

    Enum.each(sessions, fn session ->
      end_session(session.id, session.access_token, session.refresh_token)
    end)

    :ok
  end

  @doc """
  Verifica se uma sessão está ativa.

  ## Parâmetros

    - `session_id`: ID da sessão

  ## Retorno

    - `{:ok, is_active}` com `is_active` sendo um booleano
    - `{:error, reason}` em caso de falha
  """
  def is_session_active?(session_id) do
    with {:ok, session} <- get_session(session_id) do
      now = DateTime.utc_now()

      is_active = DateTime.compare(session.expires_at, now) == :gt and
                  not SessionPolicy.should_timeout?(session.last_activity)

      {:ok, is_active}
    end
  end

  # Funções privadas

  # Inicializa o armazenamento de sessões
  defp init_session_storage do
    :ets.new(:sessions, [:set, :public, :named_table])
  end

  # Armazena uma sessão
  defp store_session(session) do
    :ets.insert(:sessions, {session.id, session})
  end

  # Aplica o limite de sessões por usuário
  defp enforce_session_limit(user_id) do
    sessions = get_user_sessions(user_id)
    max_sessions = SessionPolicy.max_sessions_per_user()

    if length(sessions) >= max_sessions do
      # Ordena as sessões por última atividade (mais antiga primeiro)
      sorted_sessions = Enum.sort_by(sessions, & &1.last_activity, DateTime)

      # Remove as sessões mais antigas que excedem o limite
      sessions_to_remove = Enum.take(sorted_sessions, length(sessions) - max_sessions + 1)

      Enum.each(sessions_to_remove, fn session ->
        end_session(session.id, session.access_token, session.refresh_token)
      end)
    end
  end

  # Inicializa o armazenamento na inicialização do módulo
  def start_link do
    init_session_storage()
    {:ok, self()}
  end
end
