import Config

# Configure your database
# config :deeper_hub, DeeperHub.Core.Data.Repo,
#   database: "deeper_hub_dev.db",
#   pool_size: 10 # Or other dev-specific settings

# Set a more verbose log level for development
config :deeper_hub, DeeperHub.Core.Logger, level: :debug

# Do not print debug messages in production
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configurações de segurança para ambiente de desenvolvimento
config :deeper_hub, :security,
  # Proteção contra ataques de autenticação
  # 5 minutos em ambiente de desenvolvimento (900 em produção)
  block_duration: 300,
  # Limite menor para testes (10 em produção)
  max_auth_attempts: 5,
  # 1 minuto
  auth_period: 60,
  # Registrar todas as tentativas
  log_auth_attempts: true,

  # Política de senhas (mais flexível para desenvolvimento)
  # Menor que em produção (8)
  password_min_length: 6,
  # Desativado para facilitar testes
  password_require_uppercase: false,
  password_require_lowercase: true,
  # Desativado para facilitar testes
  password_require_numbers: false,
  # Desativado para facilitar testes
  password_require_special: false,
  # Sem expiração em desenvolvimento
  password_expiration_days: 0,

  # Tokens JWT
  # 24 horas (mais longo para desenvolvimento)
  access_token_ttl: 3600 * 24,
  # 30 dias
  refresh_token_ttl: 30 * 24 * 3600,

  # Configurações de sessão
  # 24 horas
  session_duration: 24 * 60 * 60,
  # 90 dias (mais longo para desenvolvimento)
  persistent_session_duration: 90 * 24 * 60 * 60,
  # 8 horas (mais longo para desenvolvimento)
  inactivity_timeout: 8 * 60 * 60,
  # Mais sessões permitidas em desenvolvimento
  max_concurrent_sessions: 10,

  # Verificação de email
  # Desativado para facilitar testes
  require_email_verification: false,
  # 7 dias (mais longo para desenvolvimento)
  email_verification_token_expiration: 7 * 24 * 60 * 60

# Path: config/dev.exs
