import Config

# Configurações em tempo de execução, que são aplicadas após a compilação
# e podem depender do ambiente de execução

if config_env() == :prod do
  # Configurações específicas para produção em tempo de execução
  _database_path = System.get_env("DATABASE_PATH") || "database/prod.db"

  # Configurações de log para produção
  log_level = System.get_env("LOG_LEVEL") || "info"

  config :logger, :console,
    level: String.to_atom(log_level)
end
