import Config

config :deeper_hub, Deeper_Hub.Core.Data.Repo,
  database: "database/dev.db",
  pool_size: 5,
  show_sensitive_data_on_connection_error: true

config :deeper_hub, ecto_repos: [Deeper_Hub.Core.Data.Repo]

# Configurações específicas para cada ambiente
import_config "#{config_env()}.exs"
