defmodule DeeperHub.Core.Security.AuthAttack do
  @moduledoc """
  Configuração do Plug.Attack específica para endpoints de autenticação.

  Este módulo implementa proteções contra ataques de força bruta e outros
  ataques comuns contra endpoints de autenticação.
  """

  use Plug.Attack

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  # Obtém configurações de segurança do ambiente ou usa valores padrão
  @security_config Application.compile_env(:deeper_hub, :security, [])
  @auth_protection Keyword.get(@security_config, :auth_protection, [])

  # Tempo de bloqueio para tentativas de autenticação excessivas (em segundos)
  @block_duration Keyword.get(@auth_protection, :block_duration, 900)  # 15 minutos por padrão

  # Limite de tentativas de autenticação por IP
  @max_auth_attempts Keyword.get(@auth_protection, :max_auth_attempts, 10)  # 10 tentativas por padrão

  # Período de tempo para contar tentativas (em segundos)
  @auth_period Keyword.get(@auth_protection, :auth_period, 60)  # 1 minuto por padrão

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

  # Limita a taxa de requisições para endpoints de autenticação
  throttle "authentication",
    when_: &__MODULE__.is_auth_path/1,
    by: &__MODULE__.get_ip/1,
    period: @auth_period * 1000,
    limit: @max_auth_attempts,
    storage: {Plug.Attack.Storage.Ets, @ets_table}

  # Bloqueia IPs que excederam o limite de tentativas
  block "blocked authentication ips",
    when_: &__MODULE__.is_auth_path/1,
    by: &__MODULE__.get_ip/1,
    storage: {Plug.Attack.Storage.Ets, @ets_table},
    expires_in: @block_duration * 1000,
    ex_when: fn conn ->
      throttle_check = Plug.Attack.Storage.Ets.read(@ets_table, "authentication:#{get_ip(conn)}")
      case throttle_check do
        {:ok, attempts} when attempts > @max_auth_attempts ->
          Logger.warn("IP bloqueado por excesso de tentativas de autenticação",
            module: __MODULE__,
            ip: get_ip(conn),
            attempts: attempts
          )
          true
        _ ->
          false
      end
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

  # Manipulador para quando uma requisição é bloqueada
  def block_action(conn) do
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
    |> Plug.Conn.put_resp_header("retry-after", "#{@block_duration}")
    |> Plug.Conn.json(%{
      error: "too_many_requests",
      message: "Muitas tentativas de autenticação. Tente novamente mais tarde.",
      retry_after: @block_duration
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
