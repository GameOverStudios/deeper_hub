import Config

# Configurações de runtime para todos os ambientes
# Estas configurações são carregadas após a compilação e podem usar variáveis de ambiente

if config_env() == :prod do
  # Configurações específicas para o ambiente de produção
  
  # Configurações de banco de dados baseadas em variáveis de ambiente
  database_path = System.get_env("DEEPER_HUB_DB_PATH") || "/data/databases"
  database_name = System.get_env("DEEPER_HUB_DB_NAME") || "deeper_hub_prod.db"
  pool_size = System.get_env("DEEPER_HUB_DB_POOL_SIZE") || "10"

  config :deeper_hub, :database,
    database_path: database_path,
    database_name: database_name,
    pool_size: String.to_integer(pool_size)

  # Configurações de telemetria
  telemetry_enabled = System.get_env("DEEPER_HUB_TELEMETRY_ENABLED") || "true"
  report_interval = System.get_env("DEEPER_HUB_TELEMETRY_INTERVAL") || "60000"

  config :deeper_hub, :telemetry,
    enabled: telemetry_enabled == "true",
    report_interval: String.to_integer(report_interval)
end
