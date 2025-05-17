import Config

# Configurações de log para testes
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:module, :function, :line],
  level: :warning
