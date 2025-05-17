import Config

# Configurações de log para desenvolvimento
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:module, :function, :line],
  level: :debug
