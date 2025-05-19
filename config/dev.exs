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

# Configurações de segurança para ambiente de desenvolvimento
config :deeper_hub, :security,
  # Proteção contra ataques de autenticação
  block_duration: 300,                # 5 minutos em ambiente de desenvolvimento (900 em produção)
  max_auth_attempts: 5,               # Limite menor para testes (10 em produção)
  auth_period: 60,                    # 1 minuto
  log_auth_attempts: true,            # Registrar todas as tentativas
  
  # Política de senhas (mais flexível para desenvolvimento)
  password_min_length: 6,             # Menor que em produção (8)
  password_require_uppercase: false,  # Desativado para facilitar testes
  password_require_lowercase: true,
  password_require_numbers: false,    # Desativado para facilitar testes
  password_require_special: false,    # Desativado para facilitar testes
  password_expiration_days: 0,        # Sem expiração em desenvolvimento
  
  # Tokens JWT
  access_token_ttl: 3600 * 24,        # 24 horas (mais longo para desenvolvimento)
  refresh_token_ttl: 30 * 24 * 3600,   # 30 dias
  
  # Configurações de sessão
  session_duration: 24 * 60 * 60,      # 24 horas
  persistent_session_duration: 90 * 24 * 60 * 60,  # 90 dias (mais longo para desenvolvimento)
  inactivity_timeout: 8 * 60 * 60,     # 8 horas (mais longo para desenvolvimento)
  max_concurrent_sessions: 10,         # Mais sessões permitidas em desenvolvimento
  
  # Verificação de email
  require_email_verification: false,   # Desativado para facilitar testes
  email_verification_token_expiration: 7 * 24 * 60 * 60  # 7 dias (mais longo para desenvolvimento)

# Path: config/dev.exs
