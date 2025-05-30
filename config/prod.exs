import Config

# Configuração para produção
config :deeper_hub, DeeperHub.Core.Data.Repo,
  database: {:system, "DATABASE_PATH"},
  pool_size: {:system, :integer, "POOL_SIZE", 10},
  timeout: 15_000,
  ownership_timeout: 10_000

config :deeper_hub, DeeperHub.Core.HTTP.Endpoint,
  http: [
    port: {:system, :integer, "PORT", 4000},
    compress: true
  ],
  url: [host: {:system, "HOST", "localhost"}],
  force_ssl: true,
  secret_key_base: {:system, "SECRET_KEY_BASE"},
  server: true

config :logger,
  level: {:system, :atom, "LOG_LEVEL", :info},
  backends: [:console]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :session_id, :remote_ip]

# Configuração de email para produção
config :deeper_hub, DeeperHub.Core.Mail,
  adapter: :smtp,
  relay: {:system, "SMTP_SERVER"},
  port: {:system, :integer, "SMTP_PORT", 587},
  username: {:system, "SMTP_USERNAME"},
  password: {:system, "SMTP_PASSWORD"},
  tls: :always,
  auth: :always

# Configuração de cache para produção
config :deeper_hub, DeeperHub.Core.Cache,
  default_ttl: 300,
  cleanup_interval: 60_000,
  compressed: true

# Configuração de segurança rigorosa para produção
config :deeper_hub, :security,
  block_duration: 1800,  # 30 minutos
  max_auth_attempts: 5,
  auth_period: 300,  # 5 minutos
  password_min_length: 12,
  password_require_uppercase: true,
  password_require_lowercase: true,
  password_require_numbers: true,
  password_require_special: true,
  require_email_verification: true,
  enable_csrf_protection: true,
  enable_xss_protection: true,
  enable_clickjacking_protection: true,
  enable_hsts: true,
  hsts_max_age: 31536000,  # 1 ano
  hsts_include_subdomains: true

# Configuração do Guardian para produção
config :deeper_hub, DeeperHub.Accounts.Auth.Guardian,
  issuer: "deeper_hub",
  secret_key: {:system, "GUARDIAN_SECRET_KEY"},
  ttl: {1, :hour}

# Configuração de sessões para produção
config :deeper_hub, :session_policies,
  session_duration: 8 * 60 * 60,  # 8 horas
  persistent_session_duration: 7 * 24 * 60 * 60,  # 7 dias
  inactivity_timeout: 30 * 60,  # 30 minutos
  max_concurrent_sessions: 3,
  max_persistent_sessions: 2

# Configuração de telemetria para produção
config :deeper_hub, DeeperHub.Core.Telemetry,
  enabled: true,
  export_prometheus: true,
  metrics_port: {:system, :integer, "METRICS_PORT", 9090}
