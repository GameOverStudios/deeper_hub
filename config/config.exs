import Config

config :deeper_hub, Deeper_Hub.Core.Data.Repo,
  database: "database/dev.db",
  pool_size: 5,
  show_sensitive_data_on_connection_error: true

config :deeper_hub, ecto_repos: [Deeper_Hub.Core.Data.Repo]

# Configurações do Scrivener
config :scrivener_ecto,
  # Número padrão de itens por página
  page_size: 10,
  # Número máximo de itens por página permitido
  max_page_size: 100,
  # Campo padrão para ordenação
  default_sort_field: :inserted_at,
  # Direção padrão da ordenação (asc ou desc)
  default_sort_order: :desc

# Configurações específicas de paginação por módulo
config :deeper_hub, :pagination,
  # Configurações para usuários
  users: [
    page_size: 15,
    max_page_size: 50,
    default_sort_field: :username,
    default_sort_order: :asc
  ],
  # Configurações para perfis
  profiles: [
    page_size: 20,
    max_page_size: 75,
    default_sort_field: :user_id,
    default_sort_order: :asc
  ]

# Configurações específicas para cada ambiente
import_config "#{config_env()}.exs"
