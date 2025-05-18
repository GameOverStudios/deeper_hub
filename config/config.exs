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
  adapter: Exqlite.Connection, # Corrigido: Exqlite.Connection é o adaptador correto para DBConnection
  database: System.get_env("DEEPER_HUB_DB_PATH", "databases/deeper_hub_dev.db"), # Permite sobrescrever via variável de ambiente
  pool_name: DeeperHub.DBConnectionPool,
  pool_size: String.to_integer(System.get_env("DEEPER_HUB_DB_POOL_SIZE", "10")),
  journal_mode: :wal, # Write-Ahead Logging para melhor concorrência
  busy_timeout: 5000, # Quanto tempo esperar se o banco de dados estiver bloqueado
  show_sensitive_data_on_connection_error: true, # Mostra detalhes de erros de conexão para facilitar a depuração
  timeout: 15_000, # Timeout para operações de banco de dados
  idle_interval: 15_000, # Intervalo para ping em conexões ociosas
  after_connect: {Exqlite.Connection, :execute, ["PRAGMA foreign_keys = ON;"]} # Habilita chaves estrangeiras

# Configure the DeeperHub.Core.Logger
config :deeper_hub, DeeperHub.Core.Logger,
  level: :debug # Default log level
  # Other logger specific configurations can go here

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
