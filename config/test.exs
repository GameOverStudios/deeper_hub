import Config

# Configurações específicas para ambiente de testes

# Configurações de Logger para ambiente de testes
config :logger,
  level: :warning,  # Menos verboso durante os testes
  compile_time_purge_matching: [
    [level_lower_than: :warning]
  ]

# Banco de dados com nome específico para ambiente de testes
config :deeper_hub, :database,
  database_name: "deeper_hub_test.db",
  pool_size: 2,
  database_path: "databases/test"

# Cache com TTL reduzido para testes mais rápidos
config :deeper_hub, :cache,
  default_ttl: 60,  # 1 minuto em segundos
  poll_interval: 5  # 5 segundos

# Telemetria com logging desabilitado para testes
config :deeper_hub, :telemetry,
  enabled: true,
  enable_logging: false
