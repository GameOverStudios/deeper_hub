# Configurações para os componentes do repositório
#
# Este arquivo contém as configurações padrão para os componentes do repositório,
# como cache, circuit breaker, telemetria e métricas.
#
# As configurações podem ser sobrescritas nos arquivos de ambiente específicos
# (dev.exs, test.exs, prod.exs) conforme necessário.

import Config

# Configurações do repositório
config :deeper_hub, Deeper_Hub.Core.Data.RepositoryConfig,
  # Configurações de cache
  cache: [
    # Tempo de vida padrão dos itens em cache (5 minutos)
    ttl: 300_000,
    
    # Tamanho máximo do cache (número de entradas)
    max_size: 1000,
    
    # Tempo de vida para resultados de consultas (1 minuto)
    query_ttl: 60_000,
    
    # Habilita ou desabilita o cache
    enabled: true
  ],
  
  # Configurações do circuit breaker
  circuit_breaker: [
    # Número máximo de falhas antes de abrir o circuito
    max_failures: 5,
    
    # Tempo para resetar o circuito (30 segundos)
    reset_timeout: 30_000,
    
    # Número de sucessos necessários para fechar o circuito
    half_open_threshold: 2,
    
    # Habilita ou desabilita o circuit breaker
    enabled: true
  ],
  
  # Configurações de telemetria
  telemetry: [
    # Habilita ou desabilita a telemetria
    enabled: true,
    
    # Nível de log para eventos de telemetria
    log_level: :debug
  ],
  
  # Configurações de métricas
  metrics: [
    # Habilita ou desabilita as métricas
    enabled: true,
    
    # Prefixo para nomes de métricas
    prefix: "deeper_hub.core.data.repository"
  ],
  
  # Configurações de eventos
  events: [
    # Habilita ou desabilita a publicação de eventos
    enabled: true,
    
    # Habilita ou desabilita a publicação de eventos de inserção
    publish_insert: true,
    
    # Habilita ou desabilita a publicação de eventos de atualização
    publish_update: true,
    
    # Habilita ou desabilita a publicação de eventos de exclusão
    publish_delete: true,
    
    # Habilita ou desabilita a publicação de eventos de consulta
    # Por padrão, desabilitado para reduzir o volume de eventos
    publish_query: false
  ]

# Configurações específicas para ambiente de desenvolvimento
if config_env() == :dev do
  config :deeper_hub, Deeper_Hub.Core.Data.RepositoryConfig,
    # Em desenvolvimento, podemos usar configurações mais permissivas
    cache: [
      # Cache com TTL menor para facilitar o desenvolvimento
      ttl: 60_000,  # 1 minuto
      query_ttl: 30_000  # 30 segundos
    ],
    
    # Mais logs em desenvolvimento
    telemetry: [
      log_level: :debug
    ],
    
    # Habilita eventos de consulta em desenvolvimento para facilitar o debug
    events: [
      publish_query: true
    ]
end

# Configurações específicas para ambiente de teste
if config_env() == :test do
  config :deeper_hub, Deeper_Hub.Core.Data.RepositoryConfig,
    # Em testes, podemos desabilitar alguns componentes para acelerar a execução
    cache: [
      # Cache com TTL muito curto para testes
      ttl: 1_000,  # 1 segundo
      enabled: false  # Desabilita cache em testes por padrão
    ],
    
    # Circuit breaker com limites mais baixos para testes
    circuit_breaker: [
      max_failures: 2,
      reset_timeout: 1_000,  # 1 segundo
      enabled: false  # Desabilita circuit breaker em testes por padrão
    ],
    
    # Desabilita telemetria em testes para reduzir ruído
    telemetry: [
      enabled: false
    ],
    
    # Desabilita métricas em testes
    metrics: [
      enabled: false
    ],
    
    # Desabilita eventos em testes
    events: [
      enabled: false
    ]
end

# Configurações específicas para ambiente de produção
if config_env() == :prod do
  config :deeper_hub, Deeper_Hub.Core.Data.RepositoryConfig,
    # Em produção, usamos configurações mais restritivas
    cache: [
      # Cache com TTL maior em produção
      ttl: 3_600_000,  # 1 hora
      query_ttl: 300_000,  # 5 minutos
      max_size: 10_000  # Mais entradas em produção
    ],
    
    # Circuit breaker com limites mais altos em produção
    circuit_breaker: [
      max_failures: 10,
      reset_timeout: 60_000,  # 1 minuto
      half_open_threshold: 3
    ],
    
    # Menos logs em produção
    telemetry: [
      log_level: :info
    ]
end
