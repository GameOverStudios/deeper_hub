import Config

# Configure the DeeperHub application environment.
#
# Note that this file is executed as ElixirP script
# during compilation. Anything evaluated here will
# be written to the configuration cache.
#
# ## Configuring the Repo
# 
# The Repo module (DeeperHub.Core.Repo) needs to be configured.
# Here you define the adapter, database path, pool size, etc.
config :deeper_hub, DeeperHub.Core.Data.Repo,
  # Corrigido: Exqlite.Connection é o adaptador correto para DBConnection
  adapter: Exqlite.Connection,
  # Permite sobrescrever via variável de ambiente
  database: System.get_env("DEEPER_HUB_DB_PATH", "databases/deeper_hub_dev.db"),
  pool_name: DeeperHub.DBConnectionPool,
  pool_size: String.to_integer(System.get_env("DEEPER_HUB_DB_POOL_SIZE", "10")),
  # Write-Ahead Logging para melhor concorrência
  journal_mode: :wal,
  # Quanto tempo esperar se o banco de dados estiver bloqueado
  busy_timeout: 5000,
  # Mostra detalhes de erros de conexão para facilitar a depuração
  show_sensitive_data_on_connection_error: true,
  # Timeout para operações de banco de dados
  timeout: 15_000,
  # Intervalo para ping em conexões ociosas
  idle_interval: 15_000,
  # Removido after_connect que estava causando erro
  # Habilita chaves estrangeiras usando a configuração correta
  pragmas: [foreign_keys: "ON"]

# Configure the DeeperHub.Core.Logger
config :deeper_hub, DeeperHub.Core.Logger,
  # Default log level
  level: :debug

# Other logger specific configurations can go here

# Configurações gerais da aplicação
config :deeper_hub,
  ecto_repos: [DeeperHub.Core.Data.Repo]

# Configuração do Guardian para autenticação JWT
config :deeper_hub, DeeperHub.Accounts.Auth.Guardian,
  issuer: "deeper_hub",
  secret_key:
    System.get_env(
      "GUARDIAN_SECRET_KEY",
      "FnRMgZYZlnQWZ7jfLqaZL4yUwIhJ7MvgJSskg/zbC0UglEVWyqIJ3hWJrzJc5AuV"
    ),
  ttl: {1, :day}

# Configuração de email
config :deeper_hub, :mail,
  sender_email: System.get_env("MAIL_SENDER", "noreply@deeperhub.com"),
  support_email: System.get_env("MAIL_SUPPORT", "suporte@deeperhub.com"),
  test_mode: System.get_env("MAIL_TEST_MODE", "true") == "true",
  smtp: [
    server: System.get_env("SMTP_SERVER", "smtp.exemplo.com"),
    port: String.to_integer(System.get_env("SMTP_PORT", "587")),
    username: System.get_env("SMTP_USERNAME", ""),
    password: System.get_env("SMTP_PASSWORD", ""),
    ssl: System.get_env("SMTP_SSL", "false") == "true",
    tls: System.get_env("SMTP_TLS", "true") == "true",
    auth: System.get_env("SMTP_AUTH", "true") == "true"
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
