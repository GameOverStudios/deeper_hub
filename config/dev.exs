import Config

# Configurações específicas para ambiente de desenvolvimento

# Configurações de Logger mais detalhadas para desenvolvimento
config :logger,
  level: :debug,
  compile_time_purge_matching: [
    [level_lower_than: :debug]
  ]

# Banco de dados com nome específico para ambiente de desenvolvimento
config :deeper_hub, :database,
  database_name: "deeper_hub_dev.db",
  pool_size: 5,
  show_sensitive_data_on_connection_error: true

# Cache com tamanho maior para desenvolvimento, permitindo mais experimentação
config :deeper_hub, :cache,
  default_ttl: 300,  # 5 minutos em segundos
  poll_interval: 60  # 1 minuto em segundos

# Telemetria com logging habilitado para facilitar desenvolvimento
config :deeper_hub, :telemetry,
  enabled: true,
  enable_logging: true,
  report_interval: 30_000  # 30 segundos em milissegundos
