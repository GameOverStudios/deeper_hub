import Config

config :deeper_hub, Deeper_Hub.Core.Data.Repo,
  database: "database/dev.db",
  pool_size: 5,
  show_sensitive_data_on_connection_error: true

# Configurações de log para desenvolvimento
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:module, :function, :line],
  level: :debug
