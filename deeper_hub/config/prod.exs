import Config

config :deeper_hub, Deeper_Hub.Core.Data.Repo,
  database: "database/prod.db",
  pool_size: 10,
  show_sensitive_data_on_connection_error: false

# Configurações de log para produção
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:module],
  level: :info
