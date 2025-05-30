import Config

# Configuração de runtime para produção
# Este arquivo é executado durante o runtime da aplicação

if config_env() == :prod do
  # Configuração do banco de dados
  database_path =
    System.get_env("DATABASE_PATH") ||
    raise """
    environment variable DATABASE_PATH is missing.
    For example: /app/data/deeper_hub.db
    """

  config :deeper_hub, DeeperHub.Core.Data.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # Configuração de segurança
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

  guardian_secret =
    System.get_env("GUARDIAN_SECRET_KEY") ||
    raise """
    environment variable GUARDIAN_SECRET_KEY is missing.
    You can generate one by calling: mix guardian.gen.secret
    """

  config :deeper_hub, DeeperHub.Accounts.Auth.Guardian,
    issuer: "deeper_hub",
    secret_key: guardian_secret

  # Configuração HTTP
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :deeper_hub, DeeperHub.Core.HTTP.Endpoint,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    url: [host: System.get_env("HOST") || "localhost", port: port],
    force_ssl: String.to_existing_atom(System.get_env("FORCE_SSL") || "true")

  # Configuração de email
  if smtp_server = System.get_env("SMTP_SERVER") do
    config :deeper_hub, DeeperHub.Core.Mail,
      adapter: :smtp,
      relay: smtp_server,
      port: String.to_integer(System.get_env("SMTP_PORT") || "587"),
      username: System.get_env("SMTP_USERNAME"),
      password: System.get_env("SMTP_PASSWORD"),
      tls: :always,
      auth: :always
  end

  # Configuração de cache Redis (opcional)
  if redis_url = System.get_env("REDIS_URL") do
    config :deeper_hub, DeeperHub.Core.Cache,
      adapter: :redis,
      url: redis_url
  end

  # Configuração de logging
  config :logger,
    level: String.to_existing_atom(System.get_env("LOG_LEVEL") || "info"),
    backends: [:console, LoggerFileBackend]

  config :logger, :console,
    format: "$time $metadata[$level] $message\n",
    metadata: [:request_id, :user_id, :session_id]

  config :logger, LoggerFileBackend,
    path: System.get_env("LOG_FILE_PATH") || "/var/log/deeper_hub/app.log",
    level: :info,
    format: "$time $metadata[$level] $message\n",
    metadata: [:request_id, :user_id, :session_id]
end

# Configuração para desenvolvimento
if config_env() == :dev do
  config :deeper_hub, DeeperHub.Core.Data.Repo,
    database: "databases/deeper_hub_dev.db",
    pool_size: 5

  config :deeper_hub, DeeperHub.Accounts.Auth.Guardian,
    issuer: "deeper_hub",
    secret_key: "dev_secret_key_change_in_production"

  config :deeper_hub, DeeperHub.Core.HTTP.Endpoint,
    http: [port: 4000],
    debug_errors: true,
    code_reloader: true,
    check_origin: false,
    watchers: []

  config :logger, :console,
    format: "[$level] $message\n"
end

# Configuração para testes
if config_env() == :test do
  config :deeper_hub, DeeperHub.Core.Data.Repo,
    database: ":memory:",
    pool_size: 1

  config :deeper_hub, DeeperHub.Accounts.Auth.Guardian,
    issuer: "deeper_hub",
    secret_key: "test_secret_key"

  config :deeper_hub, DeeperHub.Core.HTTP.Endpoint,
    http: [port: 4002],
    server: false

  config :logger, level: :warn
end
