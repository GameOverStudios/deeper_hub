import Config

# ## Configuração Geral para Produção
#
# Configura a aplicação para implantação em produção.
# Recomenda-se substituir parâmetros sensíveis através de
# variáveis de ambiente ou um serviço de gerenciamento de segredos.

# Configuração do Guardian para autenticação JWT
config :deeper_hub, DeeperHub.Accounts.Auth.Guardian,
  issuer: "deeper_hub",
  # IMPORTANTE: Em produção, a chave secreta DEVE ser definida via variável de ambiente
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || raise("Variável de ambiente GUARDIAN_SECRET_KEY não definida"),
  ttl: {1, :day},
  token_ttl: %{
    "access" => {1, :hour},
    "refresh" => {30, :days}
  },
  # Configurações adicionais para segurança
  verify_issuer: true,
  allowed_algos: ["HS512"],
  token_verify_module: Guardian.Token.Jwt.Verify

# Configuração do Argon2 para hashing de senhas (mais seguro)
config :argon2_elixir,
  t_cost: 8,       # Número de iterações (maior = mais seguro, mais lento)
  m_cost: 16,      # Uso de memória (maior = mais seguro, mais lento)
  parallelism: 2,  # Número de threads paralelos (ajustar conforme CPU disponível)
  hashtype: 2      # Tipo de hash (2 = Argon2id, balanceado entre segurança e resistência)

# Configuração do PBKDF2 como alternativa para casos de recursos limitados
config :pbkdf2_elixir,
  rounds: 160_000, # Número de iterações (maior = mais seguro, mais lento)
  format: :modular # Formato modular para compatibilidade

# Configuração do DeeperHub.Core.Repo para produção
config :deeper_hub, DeeperHub.Core.Data.Repo,
  adapter: Exqlite.Connection,
  database: System.get_env("DEEPER_HUB_DB_PATH") || "databases/deeper_hub_prod.db",
  pool_name: DeeperHub.DBConnectionPool,
  pool_size: String.to_integer(System.get_env("DEEPER_HUB_DB_POOL_SIZE") || "20"),
  journal_mode: :wal,           # Write-Ahead Logging para melhor concorrência
  busy_timeout: 10_000,         # Tempo de espera maior em produção para evitar erros de bloqueio
  timeout: 30_000,              # Timeout maior para operações de banco de dados em produção
  idle_interval: 30_000,        # Intervalo maior para ping em conexões ociosas
  after_connect: {Exqlite.Connection, :execute, ["PRAGMA foreign_keys = ON;"]}, # Habilita chaves estrangeiras
  cache_size: -64000,           # Cache de 64MB para melhor desempenho
  synchronous: :normal,         # Balanceamento entre segurança e desempenho
  temp_store: :memory           # Armazenamento temporário em memória para melhor desempenho

# Configuração do DeeperHub.Core.Logger para produção
config :deeper_hub, DeeperHub.Core.Logger,
  level: :info,                       # Registra apenas info e níveis superiores em produção
  max_queue_size: 10_000,             # Limita o tamanho da fila de logs para evitar consumo excessivo de memória
  flush_interval_ms: 5_000,           # Intervalo para descarregar logs em disco
  metadata: [:module, :function, :line, :pid, :request_id] # Metadados importantes para depuração

# Configuração do Logger do Elixir para produção
config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  metadata: [:module, :request_id],
  colors: [enabled: false]            # Desativa cores em produção para melhor compatibilidade com ferramentas de log

# Configuração global do Logger
config :logger,
  level: :info,
  utc_log: true,                      # Usa UTC para timestamps de log (melhor para sistemas distribuídos)
  truncate: :infinity                 # Evita truncamento de mensagens longas

# ## Configurações de Resiliência para Produção

# Configurações para supervisores e processos
config :deeper_hub, :supervisor,
  # Estratégia de reinicialização mais agressiva para produção
  max_restarts: 10,             # Número máximo de reinicializações
  max_seconds: 60,              # Período de tempo para contar reinicializações
  strategy: :one_for_one        # Estratégia de supervisão

# Configurações de pool de conexões para alta disponibilidade
config :deeper_hub, :connection_pool,
  checkout_timeout: 15_000,     # Tempo limite para obter uma conexão do pool
  queue_target: 50,             # Tempo alvo para filas (ms)
  queue_interval: 1_000         # Intervalo para verificar filas (ms)

# Configurações de segurança para produção
config :deeper_hub, :security,
  # Proteção contra ataques de autenticação
  block_duration: 1800,                # 30 minutos em produção
  max_auth_attempts: 5,                # Limite restritivo para produção
  auth_period: 60,                     # 1 minuto
  log_auth_attempts: true,             # Registrar todas as tentativas
  
  # Lista de IPs bloqueados permanentemente (pode ser atualizada em tempo de execução)
  blocked_ips: [],
  
  # Política de senhas (rigorosa para produção)
  password_min_length: 10,             # Tamanho mínimo seguro
  password_require_uppercase: true,     # Exigir letras maiúsculas
  password_require_lowercase: true,     # Exigir letras minúsculas
  password_require_numbers: true,       # Exigir números
  password_require_special: true,       # Exigir caracteres especiais
  password_special_chars: "!@#$%^&*()-_=+[]{}|;:,.<>?/",
  password_expiration_days: 90,         # Expiração a cada 90 dias
  password_history_count: 5,            # Não permitir reutilização das 5 últimas senhas
  
  # Tokens JWT
  access_token_ttl: 3600,              # 1 hora (mais curto para produção)
  refresh_token_ttl: 7 * 24 * 3600,     # 7 dias (mais curto para produção)
  jwt_algorithm: "HS512",               # Algoritmo seguro
  jwt_include_default_claims: true,     # Incluir claims padrão
  
  # Configurações de sessão
  session_duration: 8 * 60 * 60,        # 8 horas
  persistent_session_duration: 7 * 24 * 60 * 60,  # 7 dias (mais curto para produção)
  inactivity_timeout: 30 * 60,          # 30 minutos de inatividade
  max_concurrent_sessions: 3,           # Limite de sessões simultâneas
  max_persistent_sessions: 2,           # Limite de sessões persistentes
  invalidate_on_password_change: true,  # Invalidar sessões ao mudar senha
  invalidate_on_suspicious_activity: true, # Invalidar sessões em caso de atividade suspeita
  require_reauth_for_sensitive_actions: true, # Reautenticação para ações sensíveis
  sensitive_action_reauth_timeout: 5 * 60, # 5 minutos para reautenticação
  
  # Verificação de email
  require_email_verification: true,     # Exigir verificação de email
  email_verification_token_expiration: 24 * 60 * 60, # 24 horas
  email_verification_max_resend: 3,     # Limite de reenvios por dia
  
  # Proteções gerais
  enable_csrf_protection: true,         # Proteção contra CSRF
  enable_xss_protection: true,          # Proteção contra XSS
  enable_clickjacking_protection: true, # Proteção contra clickjacking
  enable_hsts: true,                    # Ativar HSTS
  hsts_max_age: 31536000,               # 1 ano
  hsts_include_subdomains: true         # Incluir subdomínios

# ## IMPORTANTE: Gerenciamento de Segredos
#
# Não hardcode segredos neste arquivo. Use:
# - Variáveis de ambiente: `System.get_env("MINHA_CHAVE_SECRETA")`
# - `config/runtime.exs` do Elixir para configuração em tempo de execução (Elixir 1.11+)
# - Um serviço dedicado de gerenciamento de segredos.

# Finalmente, importe o arquivo de configuração de runtime que será carregado
# em cada inicialização para configurações mais dinâmicas e sensíveis.
# É fundamental que este arquivo seja carregado por último.
# Nota: runtime.exs é tipicamente usado para Elixir 1.11+ para segredos em tempo de execução.
# Se você estiver em uma versão mais antiga ou preferir uma abordagem diferente, ajuste adequadamente.
# import_config "runtime.exs"
