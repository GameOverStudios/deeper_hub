import Config

# Configuração para desenvolvimento
config :deeper_hub, DeeperHub.Core.Data.Repo,
  database: "databases/deeper_hub_dev.db",
  pool_size: 5,
  show_sensitive_data_on_connection_error: true

config :deeper_hub, DeeperHub.Core.HTTP.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, :console,
  format: "[$level] $message\n",
  level: :debug

# Configuração de email para desenvolvimento (apenas logs)
config :deeper_hub, DeeperHub.Core.Mail,
  adapter: :test

# Configuração de cache para desenvolvimento
config :deeper_hub, DeeperHub.Core.Cache,
  default_ttl: 60,
  cleanup_interval: 30_000

# Configuração de segurança relaxada para desenvolvimento
config :deeper_hub, :security,
  block_duration: 60,
  max_auth_attempts: 20,
  auth_period: 60,
  password_min_length: 6,
  require_email_verification: false

# Configuração do Guardian para desenvolvimento
config :deeper_hub, DeeperHub.Accounts.Auth.Guardian,
  issuer: "deeper_hub_dev",
  secret_key: "dev_secret_key_change_in_production",
  ttl: {8, :hours}

# Habilitar live reload para desenvolvimento
config :deeper_hub, DeeperHub.Core.HTTP.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/deeper_hub/(web|views)/.*(ex)$",
      ~r"lib/deeper_hub/templates/.*(eex)$"
    ]
  ]
