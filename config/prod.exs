import Config

# Configurações específicas para ambiente de produção

# Configurações de Logger otimizadas para produção
config :logger,
  level: :info,  # Menos verboso em produção, apenas informações importantes
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ],
  utc_log: true  # Usa UTC para timestamps em produção

# Banco de dados otimizado para produção
config :deeper_hub, :database,
  database_name: "deeper_hub_prod.db",
  pool_size: 10,  # Mais conexões para lidar com maior volume
  database_path: "/opt/deeper_hub/data",  # Caminho absoluto em produção
  show_sensitive_data_on_connection_error: false

# Configuração do repositório Ecto com SQLite para produção
config :deeper_hub, DeeperHub.DataAccess.Repo,
  database: Path.join(["/opt/deeper_hub/data", "deeper_hub_prod.db"]),
  pool_size: 10,
  journal_mode: :wal,
  foreign_keys: :on,
  busy_timeout: 10000,
  cache_size: -100000  # Aproximadamente 100MB de cache

# Cache otimizado para produção
config :deeper_hub, :cache,
  default_ttl: 3600,  # 1 hora em segundos
  poll_interval: 300,  # 5 minutos em segundos
  gc_interval: 3600,  # 1 hora em segundos
  warmup_on_start: true  # Pré-carrega dados comuns

# Telemetria com configurações para produção
config :deeper_hub, :telemetry,
  enabled: true,
  enable_logging: false,  # Desabilita logging de telemetria para reduzir ruído
  report_interval: 60_000  # 1 minuto em milissegundos

# Configurações de resiliência para supervisores em produção
config :deeper_hub, :supervisor,
  strategy: :one_for_one,
  max_restarts: 5,
  max_seconds: 60  # Valores mais altos para produção
