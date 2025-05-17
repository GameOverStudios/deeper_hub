import Config

# Importa a configuração do EventBus
import_config "event_bus.exs"

# Configurações específicas para cada ambiente
import_config "#{config_env()}.exs"
