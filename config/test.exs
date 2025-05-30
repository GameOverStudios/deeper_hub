import Config

# Configuração para testes
config :deeper_hub, DeeperHub.Core.Data.Repo,
  database: ":memory:",
  pool_size: 1

config :deeper_hub, DeeperHub.Core.HTTP.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

# Configuração de email para testes
config :deeper_hub, DeeperHub.Core.Mail,
  adapter: :test

# Configuração de cache para testes
config :deeper_hub, DeeperHub.Core.Cache,
  default_ttl: 1,
  cleanup_interval: 100
