defmodule DeeperHub.Accounts.SessionManager do
  @moduledoc """
  Módulo para gerenciamento de sessões de usuário no DeeperHub.

  Este módulo fornece funções para criar, atualizar, invalidar e gerenciar
  sessões de usuário, incluindo suporte a sessões persistentes ("lembrar-me")
  e aplicação de políticas de sessão (duração máxima, timeout por inatividade).
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.Auth.TokenBlacklist
  alias DeeperHub.Accounts.ActivityLog
  require DeeperHub.Core.Logger

  # Duração padrão de uma sessão não persistente (em segundos)
  @default_session_duration 24 * 60 * 60  # 24 horas

  # Duração padrão de uma sessão persistente (em segundos)
  @persistent_session_duration 30 * 24 * 60 * 60  # 30 dias

  # Timeout padrão por inatividade (em segundos)
  @default_inactivity_timeout 60 * 60  # 1 hora

  @doc """
  Cria uma nova sessão para um usuário.

  ## Parâmetros
    * `user` - Mapa com dados do usuário
    * `refresh_token_jti` - JTI do token de refresh associado à sessão
    * `opts` - Opções adicionais:
      * `:device_info` - Informações sobre o dispositivo (mapa)
      * `:ip_address` - Endereço IP do cliente
      * `:user_agent` - User-Agent do cliente
      * `:persistent` - Se a sessão deve ser persistente (lembrar-me)
      * `:session_duration` - Duração da sessão em segundos (substitui os padrões)

  ## Retorno
    * `{:ok, session_id}` - Se a sessão for criada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec create_session(map(), String.t(), Keyword.t()) :: {:ok, String.t()} | {:error, any()}
  def create_session(user, refresh_token_jti, opts \\ []) do
    # Extrai opções
    device_info = Keyword.get(opts, :device_info, %{})
    ip_address = Keyword.get(opts, :ip_address, "desconhecido")
    user_agent = Keyword.get(opts, :user_agent, "desconhecido")
    persistent = Keyword.get(opts, :persistent, false)

    # Determina a duração da sessão
    session_duration = case Keyword.get(opts, :session_duration) do
      nil -> if persistent, do: @persistent_session_duration, else: @default_session_duration
      duration -> duration
    end

    # Gera ID único para a sessão
    session_id = UUID.uuid4()

    # Calcula timestamps
    now = DateTime.utc_now()
    now_iso = DateTime.to_iso8601(now)
    expires_at = DateTime.add(now, session_duration, :second)
    expires_at_iso = DateTime.to_iso8601(expires_at)

    # Serializa device_info para JSON
    device_info_json = Jason.encode!(device_info)

    # SQL para inserir a sessão
    sql = """
    INSERT INTO user_sessions (
      id, user_id, refresh_token_jti, device_info, ip_address, user_agent,
      persistent, last_activity_at, expires_at, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """

    params = [
      session_id,
      user["id"],
      refresh_token_jti,
      device_info_json,
      ip_address,
      user_agent,
      persistent,
      now_iso,
      expires_at_iso,
      now_iso,
      now_iso
    ]

    case Repo.execute(sql, params) do
      {:ok, _} ->
        # Registra a atividade
        ActivityLog.log_activity(user["id"], :session_created, %{
          session_id: session_id,
          ip_address: ip_address,
          user_agent: user_agent,
          persistent: persistent
        }, ip_address)

        Logger.info("Sessão criada para usuário: #{user["id"]}",
          module: __MODULE__,
          session_id: session_id,
          persistent: persistent,
          ip: ip_address
        )

        {:ok, session_id}

      {:error, reason} ->
        Logger.error("Erro ao criar sessão: #{inspect(reason)}",
          module: __MODULE__,
          user_id: user["id"]
        )
        {:error, reason}
    end
  end

  @doc """
  Atualiza a última atividade de uma sessão.

  ## Parâmetros
    * `session_id` - ID da sessão

  ## Retorno
    * `:ok` - Se a sessão for atualizada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec update_last_activity(String.t()) :: :ok | {:error, any()}
  def update_last_activity(session_id) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    sql = """
    UPDATE user_sessions
    SET last_activity_at = ?, updated_at = ?
    WHERE id = ?;
    """

    case Repo.execute(sql, [now, now, session_id]) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Erro ao atualizar última atividade da sessão: #{inspect(reason)}",
          module: __MODULE__,
          session_id: session_id
        )
        {:error, reason}
    end
  end

  @doc """
  Verifica se uma sessão está ativa e válida.

  ## Parâmetros
    * `session_id` - ID da sessão
    * `opts` - Opções adicionais:
      * `:check_inactivity` - Se deve verificar timeout por inatividade
      * `:inactivity_timeout` - Timeout por inatividade em segundos

  ## Retorno
    * `{:ok, session}` - Se a sessão estiver ativa e válida
    * `{:error, :session_expired}` - Se a sessão expirou
    * `{:error, :session_inactive}` - Se a sessão está inativa por muito tempo
    * `{:error, :session_not_found}` - Se a sessão não for encontrada
    * `{:error, reason}` - Se ocorrer outro erro
  """
  @spec verify_session(String.t(), Keyword.t()) :: {:ok, map()} | {:error, any()}
  def verify_session(session_id, opts \\ []) do
    # Extrai opções
    check_inactivity = Keyword.get(opts, :check_inactivity, true)
    inactivity_timeout = Keyword.get(opts, :inactivity_timeout, @default_inactivity_timeout)

    sql = """
    SELECT id, user_id, refresh_token_jti, device_info, ip_address, user_agent,
           persistent, last_activity_at, expires_at, created_at, updated_at
    FROM user_sessions
    WHERE id = ?;
    """

    case Repo.query(sql, [session_id]) do
      {:ok, %{rows: [row], columns: columns}} ->
        session = Enum.zip(columns, row) |> Map.new()

        # Verifica se a sessão expirou
        case DateTime.from_iso8601(session["expires_at"]) do
          {:ok, expires_at, _} ->
            if DateTime.compare(DateTime.utc_now(), expires_at) == :gt do
              # Sessão expirou
              invalidate_session(session_id, "expired")
              {:error, :session_expired}
            else
              # Verifica timeout por inatividade, se solicitado
              if check_inactivity do
                case DateTime.from_iso8601(session["last_activity_at"]) do
                  {:ok, last_activity, _} ->
                    now = DateTime.utc_now()
                    diff = DateTime.diff(now, last_activity, :second)

                    if diff > inactivity_timeout do
                      # Sessão inativa por muito tempo
                      invalidate_session(session_id, "inactive")
                      {:error, :session_inactive}
                    else
                      # Sessão válida, atualiza última atividade
                      update_last_activity(session_id)
                      {:ok, session}
                    end

                  _ ->
                    # Erro ao parsear last_activity_at
                    {:error, :invalid_timestamp}
                end
              else
                # Não verificar inatividade, sessão válida
                {:ok, session}
              end
            end

          _ ->
            # Erro ao parsear expires_at
            {:error, :invalid_timestamp}
        end

      {:ok, %{rows: []}} ->
        {:error, :session_not_found}

      {:error, reason} ->
        Logger.error("Erro ao verificar sessão: #{inspect(reason)}",
          module: __MODULE__,
          session_id: session_id
        )
        {:error, reason}
    end
  end

  @doc """
  Invalida (encerra) uma sessão.

  ## Parâmetros
    * `session_id` - ID da sessão
    * `reason` - Motivo da invalidação (opcional)

  ## Retorno
    * `:ok` - Se a sessão for invalidada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec invalidate_session(String.t(), String.t() | nil) :: :ok | {:error, any()}
  def invalidate_session(session_id, reason \\ nil) do
    # Primeiro, busca informações da sessão
    sql = "SELECT user_id, refresh_token_jti FROM user_sessions WHERE id = ?;"

    case Repo.query(sql, [session_id]) do
      {:ok, %{rows: [[user_id, refresh_token_jti]]}} ->
        # Adiciona o token de refresh à blacklist
        TokenBlacklist.add_to_blacklist(
          refresh_token_jti,
          user_id,
          "refresh",
          DateTime.utc_now() |> DateTime.add(30 * 24 * 60 * 60, :second), # 30 dias
          reason || "session_invalidated"
        )

        # Remove a sessão do banco de dados
        delete_sql = "DELETE FROM user_sessions WHERE id = ?;"
        Repo.execute(delete_sql, [session_id])

        # Registra a atividade
        ActivityLog.log_activity(user_id, :session_terminated, %{
          session_id: session_id,
          reason: reason
        })

        Logger.info("Sessão invalidada: #{session_id}",
          module: __MODULE__,
          user_id: user_id,
          reason: reason
        )

        :ok

      {:ok, %{rows: []}} ->
        {:error, :session_not_found}

      {:error, reason} ->
        Logger.error("Erro ao invalidar sessão: #{inspect(reason)}",
          module: __MODULE__,
          session_id: session_id
        )
        {:error, reason}
    end
  end

  @doc """
  Invalida todas as sessões de um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `reason` - Motivo da invalidação (opcional)
    * `except_session_id` - ID da sessão a ser mantida (opcional)

  ## Retorno
    * `{:ok, count}` - Número de sessões invalidadas
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec invalidate_all_sessions(String.t(), String.t() | nil, String.t() | nil) :: {:ok, integer()} | {:error, any()}
  def invalidate_all_sessions(user_id, reason \\ nil, except_session_id \\ nil) do
    # Busca todas as sessões do usuário
    sql = "SELECT id FROM user_sessions WHERE user_id = ?"
    params = [user_id]

    # Adiciona exceção, se fornecida
    {sql, params} = if except_session_id do
      {sql <> " AND id != ?", params ++ [except_session_id]}
    else
      {sql, params}
    end

    case Repo.query(sql, params) do
      {:ok, %{rows: rows}} ->
        # Invalida cada sessão
        count = Enum.count(rows)

        Enum.each(rows, fn [session_id] ->
          invalidate_session(session_id, reason)
        end)

        # Registra a atividade
        ActivityLog.log_activity(user_id, :all_sessions_terminated, %{
          count: count,
          reason: reason,
          except_session_id: except_session_id
        })

        Logger.info("Todas as sessões do usuário #{user_id} foram invalidadas: #{count}",
          module: __MODULE__,
          reason: reason
        )

        {:ok, count}

      {:error, reason} ->
        Logger.error("Erro ao invalidar todas as sessões: #{inspect(reason)}",
          module: __MODULE__,
          user_id: user_id
        )
        {:error, reason}
    end
  end

  @doc """
  Lista todas as sessões ativas de um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * `{:ok, sessions}` - Lista de sessões ativas
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec list_active_sessions(String.t()) :: {:ok, [map()]} | {:error, any()}
  def list_active_sessions(user_id) do
    sql = """
    SELECT id, device_info, ip_address, user_agent, persistent,
           last_activity_at, expires_at, created_at
    FROM user_sessions
    WHERE user_id = ?
    ORDER BY created_at DESC;
    """

    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: rows, columns: columns}} ->
        sessions = Enum.map(rows, fn row ->
          session = Enum.zip(columns, row) |> Map.new()

          # Deserializa device_info
          device_info = case Jason.decode(session["device_info"]) do
            {:ok, info} -> info
            _ -> %{}
          end

          Map.put(session, "device_info", device_info)
        end)

        {:ok, sessions}

      {:error, reason} ->
        Logger.error("Erro ao listar sessões ativas: #{inspect(reason)}",
          module: __MODULE__,
          user_id: user_id
        )
        {:error, reason}
    end
  end

  @doc """
  Limpa sessões expiradas do banco de dados.

  ## Retorno
    * `{:ok, count}` - Número de sessões removidas
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec clean_expired_sessions() :: {:ok, integer()} | {:error, any()}
  def clean_expired_sessions do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    # Primeiro, busca sessões expiradas para registrar
    select_sql = """
    SELECT id, user_id
    FROM user_sessions
    WHERE expires_at < ?;
    """

    case Repo.query(select_sql, [now]) do
      {:ok, %{rows: rows}} ->
        # Registra cada sessão expirada
        Enum.each(rows, fn [session_id, user_id] ->
          ActivityLog.log_activity(user_id, :session_expired, %{
            session_id: session_id
          })
        end)

        # Remove sessões expiradas
        delete_sql = "DELETE FROM user_sessions WHERE expires_at < ?;"

        case Repo.execute(delete_sql, [now]) do
          {:ok, %{rows_affected: count}} ->
            Logger.info("Sessões expiradas removidas: #{count}", module: __MODULE__)
            {:ok, count}

          {:error, reason} ->
            Logger.error("Erro ao remover sessões expiradas: #{inspect(reason)}", module: __MODULE__)
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Erro ao buscar sessões expiradas: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Limpa sessões inativas por um período específico.

  ## Parâmetros
    * `inactivity_period` - Período de inatividade em segundos

  ## Retorno
    * `{:ok, count}` - Número de sessões removidas
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec clean_inactive_sessions(integer()) :: {:ok, integer()} | {:error, any()}
  def clean_inactive_sessions(inactivity_period) do
    # Calcula o timestamp limite
    limit = DateTime.utc_now()
            |> DateTime.add(-inactivity_period, :second)
            |> DateTime.to_iso8601()

    # Primeiro, busca sessões inativas para registrar
    select_sql = """
    SELECT id, user_id
    FROM user_sessions
    WHERE last_activity_at < ?;
    """

    case Repo.query(select_sql, [limit]) do
      {:ok, %{rows: rows}} ->
        # Registra cada sessão inativa
        Enum.each(rows, fn [session_id, user_id] ->
          ActivityLog.log_activity(user_id, :session_inactive, %{
            session_id: session_id
          })
        end)

        # Remove sessões inativas
        delete_sql = "DELETE FROM user_sessions WHERE last_activity_at < ?;"

        case Repo.execute(delete_sql, [limit]) do
          {:ok, %{rows_affected: count}} ->
            Logger.info("Sessões inativas removidas: #{count}", module: __MODULE__)
            {:ok, count}

          {:error, reason} ->
            Logger.error("Erro ao remover sessões inativas: #{inspect(reason)}", module: __MODULE__)
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Erro ao buscar sessões inativas: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
