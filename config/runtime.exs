import Config

# Configurações em tempo de execução, que são aplicadas após a compilação
# e podem depender do ambiente de execução

# Configuração do endpoint WebSocket
config :deeper_hub, Deeper_Hub.Core.Websocket.Endpoint,
  url: [host: "localhost", port: 4000],
  http: [port: 4000],
  pubsub_server: Deeper_Hub.PubSub,
  websocket: [timeout: 45_000, compress: true],
  longpoll: false

if config_env() == :prod do
  # Configurações específicas para produção em tempo de execução
  database_path = System.get_env("DATABASE_PATH") || "database/prod.db"

  config :deeper_hub, Deeper_Hub.Core.Data.Repo,
    database: database_path

  # Configurações de log para produção
  log_level = System.get_env("LOG_LEVEL") || "info"

  config :logger, :console,
    level: String.to_atom(log_level)
end
