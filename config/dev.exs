import Config

# Configurações de log para desenvolvimento
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:module, :function, :line],
  level: :debug

# Filtrar logs específicos - aumentar o nível de log para módulos específicos
config :logger,
  compile_time_purge_matching: [
    [module: Deeper_Hub.Core.Cache, level_lower_than: :error],
    [module: Deeper_Hub.Core.Metrics.Reporter, level_lower_than: :error],
    [module: Telemetry.Metrics.ConsoleReporter, level_lower_than: :error]
  ]
