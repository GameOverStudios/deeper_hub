import Config

# Configure your database
# config :deeper_hub, DeeperHub.Core.Data.Repo,
#   database: "deeper_hub_dev.db",
#   pool_size: 10 # Or other dev-specific settings

# Set a more verbose log level for development
config :deeper_hub, DeeperHub.Core.Logger,
  level: :debug

# Do not print debug messages in production
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Path: config/dev.exs
