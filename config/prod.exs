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
  secret_key:
    System.get_env("GUARDIAN_SECRET_KEY") ||
      raise("Variável de ambiente GUARDIAN_SECRET_KEY não definida"),
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
  # Número de iterações (maior = mais seguro, mais lento)
  t_cost: 8,
  # Uso de memória (maior = mais seguro, mais lento)
  m_cost: 16,
  # Número de threads paralelos (ajustar conforme CPU disponível)
  parallelism: 2,
  # Tipo de hash (2 = Argon2id, balanceado entre segurança e resistência)
  hashtype: 2

# Configuração do PBKDF2 como alternativa para casos de recursos limitados
config :pbkdf2_elixir,
  # Número de iterações (maior = mais seguro, mais lento)
  rounds: 160_000,
  # Formato modular para compatibilidade
  format: :modular

# Configuração do DeeperHub.Core.Repo para produção
config :deeper_hub, DeeperHub.Core.Data.Repo,
  adapter: Exqlite.Connection,
  database: System.get_env("DEEPER_HUB_DB_PATH") || "databases/deeper_hub_prod.db",
  pool_name: DeeperHub.DBConnectionPool,
  pool_size: String.to_integer(System.get_env("DEEPER_HUB_DB_POOL_SIZE") || "20"),
  # Write-Ahead Logging para melhor concorrência
  journal_mode: :wal,
  # Tempo de espera maior em produção para evitar erros de bloqueio
  busy_timeout: 10_000,
  # Timeout maior para operações de banco de dados em produção
  timeout: 30_000,
  # Intervalo maior para ping em conexões ociosas
  idle_interval: 30_000,
  # Habilita chaves estrangeiras
  after_connect: {Exqlite.Connection, :execute, ["PRAGMA foreign_keys = ON;"]},
  # Cache de 64MB para melhor desempenho
  cache_size: -64000,
  # Balanceamento entre segurança e desempenho
  synchronous: :normal,
  # Armazenamento temporário em memória para melhor desempenho
  temp_store: :memory

# Configuração do DeeperHub.Core.Logger para produção
config :deeper_hub, DeeperHub.Core.Logger,
  # Registra apenas info e níveis superiores em produção
  level: :info,
  # Limita o tamanho da fila de logs para evitar consumo excessivo de memória
  max_queue_size: 10_000,
  # Intervalo para descarregar logs em disco
  flush_interval_ms: 5_000,
  # Metadados importantes para depuração
  metadata: [:module, :function, :line, :pid, :request_id]

# Configuração do Logger do Elixir para produção
config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  metadata: [:module, :request_id],
  # Desativa cores em produção para melhor compatibilidade com ferramentas de log
  colors: [enabled: false]

# Configuração global do Logger
config :logger,
  level: :info,
  # Usa UTC para timestamps de log (melhor para sistemas distribuídos)
  utc_log: true,
  # Evita truncamento de mensagens longas
  truncate: :infinity

# ## Configurações de Resiliência para Produção

# Configurações para supervisores e processos
config :deeper_hub, :supervisor,
  # Estratégia de reinicialização mais agressiva para produção
  # Número máximo de reinicializações
  max_restarts: 10,
  # Período de tempo para contar reinicializações
  max_seconds: 60,
  # Estratégia de supervisão
  strategy: :one_for_one

# Configurações de pool de conexões para alta disponibilidade
config :deeper_hub, :connection_pool,
  # Tempo limite para obter uma conexão do pool
  checkout_timeout: 15_000,
  # Tempo alvo para filas (ms)
  queue_target: 50,
  # Intervalo para verificar filas (ms)
  queue_interval: 1_000

# Configurações de segurança para produção
config :deeper_hub, :security,
  # Proteção contra ataques de autenticação
  # 30 minutos em produção
  block_duration: 1800,
  # Limite restritivo para produção
  max_auth_attempts: 5,
  # 1 minuto
  auth_period: 60,
  # Registrar todas as tentativas
  log_auth_attempts: true,

  # Lista de IPs bloqueados permanentemente (pode ser atualizada em tempo de execução)
  blocked_ips: [],

  # Política de senhas (rigorosa para produção)
  # Tamanho mínimo seguro
  password_min_length: 10,
  # Exigir letras maiúsculas
  password_require_uppercase: true,
  # Exigir letras minúsculas
  password_require_lowercase: true,
  # Exigir números
  password_require_numbers: true,
  # Exigir caracteres especiais
  password_require_special: true,
  password_special_chars: "!@#$%^&*()-_=+[]{}|;:,.<>?/",
  # Expiração a cada 90 dias
  password_expiration_days: 90,
  # Não permitir reutilização das 5 últimas senhas
  password_history_count: 5,

  # Tokens JWT
  # 1 hora (mais curto para produção)
  access_token_ttl: 3600,
  # 7 dias (mais curto para produção)
  refresh_token_ttl: 7 * 24 * 3600,
  # Algoritmo seguro
  jwt_algorithm: "HS512",
  # Incluir claims padrão
  jwt_include_default_claims: true,

  # Configurações de sessão
  # 8 horas
  session_duration: 8 * 60 * 60,
  # 7 dias (mais curto para produção)
  persistent_session_duration: 7 * 24 * 60 * 60,
  # 30 minutos de inatividade
  inactivity_timeout: 30 * 60,
  # Limite de sessões simultâneas
  max_concurrent_sessions: 3,
  # Limite de sessões persistentes
  max_persistent_sessions: 2,
  # Invalidar sessões ao mudar senha
  invalidate_on_password_change: true,
  # Invalidar sessões em caso de atividade suspeita
  invalidate_on_suspicious_activity: true,
  # Reautenticação para ações sensíveis
  require_reauth_for_sensitive_actions: true,
  # 5 minutos para reautenticação
  sensitive_action_reauth_timeout: 5 * 60,

  # Verificação de email
  # Exigir verificação de email
  require_email_verification: true,
  # 24 horas
  email_verification_token_expiration: 24 * 60 * 60,
  # Limite de reenvios por dia
  email_verification_max_resend: 3,

  # Proteções gerais
  # Proteção contra CSRF
  enable_csrf_protection: true,
  # Proteção contra XSS
  enable_xss_protection: true,
  # Proteção contra clickjacking
  enable_clickjacking_protection: true,
  # Ativar HSTS
  enable_hsts: true,
  # 1 ano
  hsts_max_age: 31_536_000,
  # Incluir subdomínios
  hsts_include_subdomains: true

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
