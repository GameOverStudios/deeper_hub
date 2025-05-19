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
  }

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
