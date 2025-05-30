import Config

# Configuração para desenvolvimento
config :deeper_hub, DeeperHub.Core.Data.Repo,
  database: "databases/deeper_hub_dev.db",
  pool_size: 5

config :deeper_hub, DeeperHub.Core.HTTP.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

config :logger, :console,
  format: "[$level] $message\n",
  level: :debug

# Configuração de email para desenvolvimento (apenas logs)
config :deeper_hub, DeeperHub.Core.Mail,
  adapter: :test
