defmodule DeeperHub.Core.Security.AuthAttack do
  @moduledoc """
  Proteção contra ataques de força bruta em endpoints de autenticação.

  Este módulo implementa proteções contra ataques de força bruta e outros
  ataques comuns contra endpoints de autenticação usando uma implementação
  personalizada com ETS.
  """

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  # Tempo de bloqueio para tentativas de autenticação excessivas (em segundos)
  @block_duration 900  # 15 minutos por padrão

  # Limite de tentativas de autenticação por IP
  @max_auth_attempts 10  # 10 tentativas por padrão

  # Período de tempo para contar tentativas (em segundos)
  @auth_period 60  # 1 minuto por padrão

  # Se deve registrar tentativas de autenticação no log de segurança
  # @log_auth_attempts true

  # Tabela ETS para rastreamento de IPs bloqueados
  @ets_table :auth_attack_store

  @doc """
  Inicializa o módulo AuthAttack.

  Cria a tabela ETS para rastreamento de IPs bloqueados se ela não existir.
  """
  def init do
    if :ets.whereis(@ets_table) == :undefined do
      :ets.new(@ets_table, [:named_table, :set, :public, {:read_concurrency, true}])
      Logger.info("Tabela ETS para proteção de autenticação inicializada", module: __MODULE__)
    end

    :ok
  end

  @doc """
  Plug para limitar a taxa de requisições de autenticação.

  ## Parâmetros
    * `conn` - Conexão Plug
    * `_opts` - Opções (não utilizadas)

  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def rate_limit_auth(conn, _opts) do
    # Verifica se é um endpoint de autenticação
    if is_auth_path(conn) do
      ip = get_ip(conn)
      key = "authentication:#{ip}"
      now = :os.system_time(:millisecond)

      # Verifica se o IP está bloqueado
      case check_ip_blocked(ip) do
        {:blocked, expires_at} ->
          # Calcula o tempo restante de bloqueio
          retry_after = max(0, div(expires_at - now, 1000))

          # Bloqueia a requisição
          block_request(conn, retry_after)

        :not_blocked ->
          # Incrementa o contador de tentativas
          attempts = increment_attempts(key, now)

          # Verifica se excedeu o limite
          if attempts > @max_auth_attempts do
            # Bloqueia o IP
            block_ip(ip, now)

            Logger.warn("IP bloqueado por excesso de tentativas de autenticação",
              module: __MODULE__,
              ip: ip,
              attempts: attempts
            )

            # Bloqueia a requisição
            block_request(conn, @block_duration)
          else
            # Permite a requisição
            conn
          end
      end
    else
      # Não é um endpoint de autenticação, permite a requisição
      conn
    end
  end

  # Verifica se um IP está bloqueado
  defp check_ip_blocked(ip) do
    key = "blocked:#{ip}"
    now = :os.system_time(:millisecond)

    case :ets.lookup(@ets_table, key) do
      [{^key, expires_at}] when expires_at > now ->
        {:blocked, expires_at}

      _ ->
        :not_blocked
    end
  end

  # Bloqueia um IP
  defp block_ip(ip, now) do
    key = "blocked:#{ip}"
    expires_at = now + @block_duration * 1000
    :ets.insert(@ets_table, {key, expires_at})
  end

  # Incrementa o contador de tentativas
  defp increment_attempts(key, now) do
    period_start = now - @auth_period * 1000

    # Busca tentativas existentes
    attempts = case :ets.lookup(@ets_table, key) do
      [{^key, count, timestamp}] when timestamp > period_start ->
        # Incrementa contador existente
        count + 1

      _ ->
        # Inicia novo contador
        1
    end

    # Atualiza o contador
    :ets.insert(@ets_table, {key, attempts, now})

    attempts
  end

  # Verifica se a requisição é para um endpoint de autenticação
  def is_auth_path(conn) do
    path = conn.request_path
    String.starts_with?(path, "/api/auth/") ||
    String.starts_with?(path, "/api/login") ||
    String.starts_with?(path, "/api/register") ||
    String.starts_with?(path, "/api/reset-password")
  end

  # Obtém o IP da requisição
  def get_ip(conn) do
    conn.remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  # Bloqueia uma requisição
  defp block_request(conn, retry_after) do
    ip = get_ip(conn)
    path = conn.request_path

    # Registra a tentativa bloqueada
    Logger.warn("Requisição de autenticação bloqueada",
      module: __MODULE__,
      ip: ip,
      path: path,
      method: conn.method,
      user_agent: get_user_agent(conn)
    )

    # Registra no log de atividades de segurança, se disponível
    log_blocked_auth_attempt(ip, path, conn)

    conn
    |> Plug.Conn.put_status(429)
    |> Plug.Conn.put_resp_header("retry-after", "#{retry_after}")
    |> Plug.Conn.json(%{
      error: "too_many_requests",
      message: "Muitas tentativas de autenticação. Tente novamente mais tarde.",
      retry_after: retry_after
    })
    |> Plug.Conn.halt()
  end

  # Obtém o User-Agent da requisição
  defp get_user_agent(conn) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [user_agent | _] -> user_agent
      _ -> "desconhecido"
    end
  end

  # Registra tentativa bloqueada no log de atividades de segurança
  defp log_blocked_auth_attempt(ip, path, conn) do
    # Verifica se o módulo de log de atividades está disponível
    if Code.ensure_loaded?(DeeperHub.Accounts.ActivityLog) do
      # Extrai informações adicionais da requisição
      details = %{
        ip: ip,
        path: path,
        method: conn.method,
        user_agent: get_user_agent(conn),
        timestamp: DateTime.utc_now(),
        blocked_reason: "excesso_tentativas_autenticacao"
      }

      # Registra a atividade de segurança
      DeeperHub.Accounts.ActivityLog.log_security_event(
        "auth_attempt_blocked",
        nil,  # user_id (desconhecido neste ponto)
        details
      )
    end
  rescue
    # Garante que falhas no log não afetem o fluxo principal
    _ -> :ok
  end
end
