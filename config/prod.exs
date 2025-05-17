import Config

# Configurações de log para produção
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:module],
  level: :info
