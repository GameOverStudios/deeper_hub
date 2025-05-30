import Config

# Configuração para produção
config :deeper_hub, DeeperHub.Core.Data.Repo,
  database: {:system, "DATABASE_PATH"},
  pool_size: {:system, :integer, "POOL_SIZE", 10}

config :deeper_hub, DeeperHub.Core.HTTP.Endpoint,
  http: [port: {:system, :integer, "PORT", 4000}],
  url: [host: {:system, "HOST", "localhost"}],
  force_ssl: true,
  secret_key_base: {:system, "SECRET_KEY_BASE"}

config :logger,
  level: :info,
  backends: [:console]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :session_id]

# Configuração de email para produção
config :deeper_hub, DeeperHub.Core.Mail,
  adapter: :smtp,
  relay: {:system, "SMTP_SERVER"},
  port: {:system, :integer, "SMTP_PORT", 587},
  username: {:system, "SMTP_USERNAME"},
  password: {:system, "SMTP_PASSWORD"}
