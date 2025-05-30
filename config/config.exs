import Config

# Configuração geral da aplicação
config :deeper_hub,
  ecto_repos: []

# Configuração do Guardian para JWT
config :deeper_hub, DeeperHub.Accounts.Auth.Guardian,
  issuer: "deeper_hub",
  secret_key: {System, :get_env, ["GUARDIAN_SECRET_KEY", "dev_secret_key_change_in_production"]}

# Configuração de logging
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :session_id]

# Configuração do cache
config :deeper_hub, DeeperHub.Core.Cache,
  default_ttl: 300,
  cleanup_interval: 60_000

# Configuração de sessões
config :deeper_hub, :session_policies,
  session_duration: 24 * 60 * 60,
  persistent_session_duration: 30 * 24 * 60 * 60,
  inactivity_timeout: 60 * 60,
  max_concurrent_sessions: 5

# Configuração de supervisor
config :deeper_hub, :supervisor,
  strategy: :one_for_one,
  max_restarts: 3,
  max_seconds: 5

# Importa configurações específicas do ambiente
import_config "#{config_env()}.exs"
