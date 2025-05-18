import Config

# Configuração do EventBus
config :event_bus, topics: [
  # Eventos relacionados a usuários
  :user_created,
  :user_updated,
  :user_deleted,
  :user_authenticated,
  
  # Eventos relacionados ao cache
  :cache_put,
  :cache_hit,
  :cache_miss,
  :cache_delete,
  :cache_clear,
  
  # Eventos relacionados ao banco de dados
  :query_executed,
  :transaction_completed,
  
  # Eventos relacionados a erros
  :error_occurred
]
