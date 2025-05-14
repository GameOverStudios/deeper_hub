import Config

config :deeper_hub, Deeper_Hub.Core.Data.Repo,
  database: "database/test.db",
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# Configurações de log para testes
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:module, :function, :line],
  level: :warning
