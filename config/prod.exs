import Config

# ## General Production Configuration
#
# Configures the application for production deployment.
# It's recommended to override sensitive parameters through
# environment variables or a secrets management service.

# Configure the DeeperHub.Core.Repo for production
config :deeper_hub, DeeperHub.Core.Data.Repo,
  # Example: Use environment variables for database path and pool size
  database: System.get_env("DEEPER_HUB_DB_PATH") || "databases/deeper_hub_prod.db",
  pool_size: String.to_integer(System.get_env("DEEPER_HUB_DB_POOL_SIZE") || "20")
  # Consider adding SSL configuration if connecting to a remote database
  # ssl: true,
  # ssl_opts: [
  #   cacertfile: System.get_env("SSL_CERT_PATH"),
  #   server_name_indication: System.get_env("DB_HOST") # For SNI
  # ],
  # Set a higher timeout for database operations in production if necessary
  # timeout: 15_000, # milliseconds
  # idle_timeout: 30_000 # milliseconds

# Configure the DeeperHub.Core.Logger for production
config :deeper_hub, DeeperHub.Core.Logger,
  level: :info # Log only info and above in production

# Configure Elixir's Logger for production
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  level: :info

# ## IMPORTANT: Secrets Management
#
# Do not hardcode secrets in this file. Use:
# - Environment variables: `System.get_env("MY_SECRET_KEY")`
# - Elixir's `config/runtime.exs` for runtime configuration (Elixir 1.11+)
# - A dedicated secrets management service.

# Example for Phoenix endpoint (if you were using Phoenix):
# config :deeper_hub, DeeperHubWeb.Endpoint,
#   url: [host: "example.com", port: 80],
#   cache_static_manifest: "priv/static/cache_manifest.json",
#   secret_key_base: System.get_env("SECRET_KEY_BASE")

# Finally import the runtime configuration file that will be loaded
# on every boot for more dynamic and sensitive configurations.
# It is critical that this file is loaded last.
# Note: runtime.exs is typically used for Elixir 1.11+ for runtime secrets.
# If you are on an older version or prefer a different approach, adjust accordingly.
# import_config "runtime.exs"
