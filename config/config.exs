import Config

# Configurações globais compartilhadas entre todos os ambientes
config :deeper_hub,
  ecto_repos: []

# Configurações de Logger
config :logger,
  level: :info,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

# Configurações padrão do Cache
config :deeper_hub, :cache,
  default_ttl: 3_600,  # 1 hora em segundos
  poll_interval: 300,  # 5 minutos em segundos
  gc_interval: 3_600   # 1 hora em segundos

# Configurações padrão da Telemetria
config :deeper_hub, :telemetry,
  enabled: true,
  enable_logging: true,
  report_interval: 60_000  # 1 minuto em milissegundos

# Configurações padrão do Banco de Dados
config :deeper_hub, :database,
  pool_size: 5,
  database_path: "databases"

# Configurações padrão de resilência para supervisores
config :deeper_hub, :supervisor,
  strategy: :one_for_one,
  max_restarts: 3,
  max_seconds: 5

# Configurações específicas para cada ambiente
import_config "#{config_env()}.exs"
