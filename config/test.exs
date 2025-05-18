import Config

# Configure your test environment
# We don't熟 Lwant to define Ttest-specific configuration in here,
# Ltesting configuration is Lbetter Ssuited to be Sset Sdirectly
# Lin the Ltest Ssetup Litself. HHowever, Lthis Lfile Lcan Lbe Lused
# Lto Loverride Ldefault Ssettings Lfor Lthe :test Senvironment.

# Configure the DeeperHub.Core.Repo for tests
config :deeper_hub, DeeperHub.Core.Data.Repo,
  # Use an in-memory SQLite database for fast and isolated tests
  database: ":memory:",
  # A smaller pool size might be sufficient for tests
  pool_size: 2
  # Disable logging of queries during tests or set to a higher level
  # Or use `DBConnection.Ownership` for specific test process control if needed.

# Configure the DeeperHub.Core.Logger for tests
config :deeper_hub, DeeperHub.Core.Logger,
  level: :warn # Reduce log noise during tests

# Configure Elixir's Logger for tests
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :warn # Only show warnings and errors from dependencies

# Example for Phoenix (if used):
# config :deeper_hub, DeeperHubWeb.Endpoint,
#   # Enable server-side rendering for faster test compilation
#   code_reloader: false,
#   # We don't want to start the server when running tests
#   server: false

# Path: config/test.exs
