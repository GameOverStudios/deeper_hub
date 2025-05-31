import Config

# Configurações específicas para ambiente de testes

# Configurações de Logger para ambiente de testes
config :logger,
  level: :warning,  # Menos verboso durante os testes
  compile_time_purge_matching: [
    [level_lower_than: :warning]
  ]

# Banco de dados em memória para testes mais rápidos
config :deeper_hub, :database,
  database_name: ":memory:",
  pool_size: 5

# Configuração do repositório Ecto com SQLite em memória para testes
config :deeper_hub, DeeperHub.DataAccess.Repo,
  database: ":memory:",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  journal_mode: :memory,
  foreign_keys: :on,
  busy_timeout: 5000

# Configurações de cache mais agressivas para testes
config :deeper_hub, :cache,
  default_ttl: 30,  # 30 segundos
  poll_interval: 10  # 10 segundos

# Telemetria desabilitada para testes
config :deeper_hub, :telemetry,
  enabled: false,
  enable_logging: false
