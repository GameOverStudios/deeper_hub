defmodule DeeperHub.Core.Telemetry.Adapters.SecurityAdapter do
  @moduledoc """
  Adaptador de telemetria para o subsistema de segurança do DeeperHub.
  
  Este adaptador é responsável por coletar e relatar métricas relacionadas a:
  - Tentativas de autenticação
  - Detecção de anomalias
  - Alertas de segurança
  - Reputação de IPs
  """
  
  alias DeeperHub.Core.Telemetry.Reporter
  alias DeeperHub.Core.Telemetry.Metrics
  
  @doc """
  Inicializa o adaptador de telemetria para o subsistema de segurança.
  
  ## Parâmetros
  
  - `opts` - Opções adicionais de configuração.
  
  ## Retorno
  
  - `{:ok, pid}` - Se o adaptador for inicializado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante a inicialização.
  
  ## Exemplos
  
      iex> DeeperHub.Core.Telemetry.Adapters.SecurityAdapter.setup()
      {:ok, #PID<0.123.0>}
  """
  @spec setup(keyword()) :: {:ok, pid()} | {:error, term()}
  def setup(opts \\ []) do
    component = :security
    
    try do
      DeeperHub.Core.Telemetry.Configurator.setup(component, opts)
    rescue
      e -> {:error, e}
    end
  end
  
  @doc """
  Relata uma tentativa de autenticação.
  
  ## Parâmetros
  
  - `username` - Nome de usuário utilizado na tentativa
  - `success` - Se a autenticação foi bem-sucedida ou não
  - `ip_address` - Endereço IP de origem
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_auth_attempt(String.t(), boolean(), String.t(), keyword()) :: :ok | {:error, term()}
  def report_auth_attempt(username, success, ip_address, opts \\ []) do
    Reporter.report_event([:deeper_hub, :security, :auth, :attempt], %{
      username: username,
      success: success,
      ip_address: ip_address,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata uma anomalia de segurança detectada.
  
  ## Parâmetros
  
  - `anomaly_type` - Tipo da anomalia (brute_force, unusual_traffic, etc)
  - `severity` - Nível de severidade (low, medium, high, critical)
  - `details` - Detalhes adicionais sobre a anomalia
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_anomaly(atom(), atom(), map(), keyword()) :: :ok | {:error, term()}
  def report_anomaly(anomaly_type, severity, details, opts \\ []) do
    Reporter.report_event([:deeper_hub, :security, :anomaly], %{
      anomaly_type: anomaly_type,
      severity: severity,
      details: details,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata uma ação de bloqueio de IP.
  
  ## Parâmetros
  
  - `ip_address` - Endereço IP bloqueado
  - `reason` - Motivo do bloqueio
  - `duration` - Duração do bloqueio em segundos
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_ip_block(String.t(), atom(), integer(), keyword()) :: :ok | {:error, term()}
  def report_ip_block(ip_address, reason, duration, opts \\ []) do
    Reporter.report_event([:deeper_hub, :security, :ip, :block], %{
      ip_address: ip_address,
      reason: reason,
      duration: duration,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata um alerta de segurança.
  
  ## Parâmetros
  
  - `alert_type` - Tipo do alerta
  - `severity` - Nível de severidade (low, medium, high, critical)
  - `details` - Detalhes adicionais sobre o alerta
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_alert(atom(), atom(), map(), keyword()) :: :ok | {:error, term()}
  def report_alert(alert_type, severity, details, opts \\ []) do
    Reporter.report_event([:deeper_hub, :security, :alert], %{
      alert_type: alert_type,
      severity: severity,
      details: details,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Define as métricas específicas para o subsistema de segurança.
  
  ## Retorno
  
  - `list()` - Lista de métricas definidas.
  """
  @spec metrics() :: list()
  def metrics do
    Metrics.definitions("deeper_hub.security")
    |> Enum.concat([
      # Métricas específicas de segurança
      Telemetry.Metrics.counter("deeper_hub.security.auth.attempt.count",
        tags: [:success],
        description: "Contador de tentativas de autenticação"),
        
      Telemetry.Metrics.counter("deeper_hub.security.anomaly.count",
        tags: [:anomaly_type, :severity],
        description: "Contador de anomalias detectadas por tipo e severidade"),
        
      Telemetry.Metrics.counter("deeper_hub.security.ip.block.count",
        tags: [:reason],
        description: "Contador de bloqueios de IP por motivo"),
        
      Telemetry.Metrics.counter("deeper_hub.security.alert.count",
        tags: [:alert_type, :severity],
        description: "Contador de alertas de segurança por tipo e severidade"),
        
      Telemetry.Metrics.last_value("deeper_hub.security.blocked_ips.count",
        description: "Número atual de IPs bloqueados")
    ])
  end
end
