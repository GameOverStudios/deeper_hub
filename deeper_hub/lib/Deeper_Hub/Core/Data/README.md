# Módulo de Repositório com Resiliência

Este módulo implementa uma camada de repositório resiliente para o Deeper_Hub, integrando funcionalidades de cache, circuit breaker, telemetria, métricas e eventos.

## Estrutura

O módulo de repositório é composto pelos seguintes componentes:

- **RepositoryIntegration**: Centraliza a inicialização e configuração de todos os componentes.
- **RepositoryConfig**: Gerencia as configurações de todos os componentes.
- **RepositoryCore**: Implementa as funcionalidades básicas do repositório.
- **RepositoryCrud**: Implementa as operações CRUD (Create, Read, Update, Delete).
- **RepositoryCache**: Gerencia o cache de registros e consultas.
- **RepositoryCircuitBreaker**: Fornece proteção contra falhas em cascata.
- **RepositoryTelemetry**: Centraliza eventos de telemetria para monitoramento.
- **RepositoryMetrics**: Coleta métricas para monitoramento e alertas.
- **RepositoryEventIntegration**: Publica eventos relacionados às operações de banco de dados.

## Configuração

As configurações do repositório são centralizadas no módulo `RepositoryConfig` e podem ser definidas no arquivo `config/repository.exs`:

```elixir
# No arquivo config.exs ou ambiente específico (dev.exs, prod.exs, etc.)
config :deeper_hub, Deeper_Hub.Core.Data.RepositoryConfig,
  cache: [
    ttl: 300_000,  # 5 minutos
    max_size: 1000,
    query_ttl: 60_000,  # 1 minuto para consultas
    enabled: true
  ],
  circuit_breaker: [
    max_failures: 5,
    reset_timeout: 30_000,  # 30 segundos
    half_open_threshold: 2,
    enabled: true
  ],
  telemetry: [
    enabled: true,
    log_level: :debug
  ],
  metrics: [
    enabled: true,
    prefix: "deeper_hub.core.data.repository"
  ],
  events: [
    enabled: true,
    publish_insert: true,
    publish_update: true,
    publish_delete: true,
    publish_query: false  # Por padrão, não publica eventos de consulta
  ]
```

## Uso

### Inicialização

Para inicializar o repositório com todos os seus componentes:

```elixir
# Lista de schemas Ecto que serão gerenciados pelo repositório
schemas = [
  MyApp.User,
  MyApp.Post,
  MyApp.Comment
]

# Inicializa todos os componentes
Deeper_Hub.Core.Data.RepositoryIntegration.setup(schemas)
```

### Operações CRUD

O módulo `RepositoryCrud` fornece operações CRUD com resiliência integrada:

```elixir
alias Deeper_Hub.Core.Data.RepositoryCrud

# Inserir um registro
{:ok, user} = RepositoryCrud.insert(MyApp.User, %{name: "João", email: "joao@example.com"})

# Obter um registro por ID
{:ok, user} = RepositoryCrud.get(MyApp.User, user.id)

# Atualizar um registro
{:ok, updated_user} = RepositoryCrud.update(MyApp.User, user.id, %{name: "João Silva"})

# Excluir um registro
{:ok, _} = RepositoryCrud.delete(MyApp.User, user.id)

# Listar registros
{:ok, users} = RepositoryCrud.list(MyApp.User)

# Buscar registros com filtros
{:ok, users} = RepositoryCrud.find(MyApp.User, [name: "João"])
```

### Monitoramento

O módulo `RepositoryIntegration` fornece uma função para obter o status dos componentes:

```elixir
# Obter status dos componentes para um schema específico
status = Deeper_Hub.Core.Data.RepositoryIntegration.get_status(MyApp.User)

# O status inclui informações sobre:
# - Estado do circuit breaker (aberto, fechado, semi-aberto)
# - Tamanho do cache (registros e consultas)
# - Configurações ativas
```

## Componentes

### Cache

O cache é implementado usando o módulo `Deeper_Hub.Core.Cache.CacheFacade` e é configurado para armazenar:

- Registros individuais: Armazenados por ID
- Resultados de consultas: Armazenados usando um hash da consulta como chave

O TTL (Time To Live) é configurável e por padrão é:
- 5 minutos para registros individuais
- 1 minuto para resultados de consultas

### Circuit Breaker

O circuit breaker é implementado usando o módulo `Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade` e protege:

- Operações de leitura (get, list, find)
- Operações de escrita (insert, update, delete)

Quando o circuit breaker está aberto, as operações falham rapidamente com um erro `:circuit_open` em vez de tentar acessar o banco de dados.

### Telemetria

A telemetria é implementada usando o módulo `Deeper_Hub.Core.Telemetry` e registra eventos para todas as operações do repositório, incluindo:

- Início e fim de operações
- Duração das operações
- Erros e exceções

### Métricas

As métricas são coletadas usando o módulo `Deeper_Hub.Core.Metrics.MetricsFacade` e incluem:

- Contadores para operações bem-sucedidas e falhas
- Histogramas para duração de operações
- Gauges para estado do circuit breaker e tamanho do cache

### Eventos

Os eventos são publicados usando o módulo `Deeper_Hub.Core.EventBus.EventBusFacade` e incluem:

- Eventos de inserção, atualização e exclusão de registros
- Eventos de consulta (opcional, desabilitado por padrão)
- Eventos de transação

## Benefícios

- **Resiliência**: Proteção contra falhas em cascata com circuit breaker
- **Performance**: Cache para reduzir a carga no banco de dados
- **Observabilidade**: Telemetria e métricas para monitoramento
- **Extensibilidade**: Eventos para integração com outros sistemas
- **Configurabilidade**: Configurações centralizadas e específicas por ambiente
