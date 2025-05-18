import Config

# Importa a configuração do EventBus
import_config "event_bus.exs"

# Importa a configuração de autenticação
import_config "auth.exs"

# Configurações específicas para cada ambiente
import_config "#{config_env()}.exs"
