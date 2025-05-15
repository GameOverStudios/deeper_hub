# Integração de Módulos de Repositório

Este documento explica como utilizar os módulos de integração do repositório para melhorar a resiliência, observabilidade e desempenho das operações de banco de dados no DeeperHub.

## Visão Geral

Os módulos de integração do repositório fornecem as seguintes funcionalidades:

- **Telemetria**: Monitoramento de desempenho e comportamento das operações de banco de dados
- **Cache**: Armazenamento em cache de registros e resultados de consultas para melhorar o desempenho
- **Circuit Breaker**: Proteção contra falhas em cascata em caso de problemas no banco de dados
- **Métricas**: Coleta de métricas para monitoramento e alertas
- **Eventos**: Publicação de eventos relacionados a operações de banco de dados

## Inicialização

Para utilizar os módulos de integração, é necessário inicializá-los durante a inicialização da aplicação. O módulo `RepositoryIntegration` centraliza essa inicialização:

```elixir
# No arquivo application.ex
def start(_type, _args) do
  # Inicializa a integração do repositório com os schemas da aplicação
  Deeper_Hub.Core.Data.RepositoryIntegration.setup([
    Deeper_Hub.Schemas.User,
    Deeper_Hub.Schemas.Product,
    Deeper_Hub.Schemas.Order
  ])
  
  # ...
end
```

## Uso no RepositoryCrud

Os módulos de integração já estão integrados ao `RepositoryCrud`, então não é necessário utilizá-los diretamente na maioria dos casos. As funções do `RepositoryCrud` já utilizam telemetria, cache, circuit breaker e publicação de eventos automaticamente.

Exemplo de uso:

```elixir
# Busca um registro por ID (com cache e circuit breaker)
{:ok, user} = RepositoryCrud.get(Deeper_Hub.Schemas.User, 123)

# Insere um novo registro (com telemetria e publicação de eventos)
{:ok, new_user} = RepositoryCrud.insert(Deeper_Hub.Schemas.User, %{name: "John Doe", email: "john@example.com"})

# Atualiza um registro (com telemetria e publicação de eventos)
{:ok, updated_user} = RepositoryCrud.update(Deeper_Hub.Schemas.User, 123, %{name: "Jane Doe"})

# Exclui um registro (com telemetria e publicação de eventos)
{:ok, _} = RepositoryCrud.delete(Deeper_Hub.Schemas.User, 123)

# Lista registros (com cache e telemetria)
{:ok, users} = RepositoryCrud.list(Deeper_Hub.Schemas.User)

# Busca registros por condições (com cache e telemetria)
{:ok, active_users} = RepositoryCrud.find(Deeper_Hub.Schemas.User, %{status: "active"})
```

## Uso Direto dos Módulos

Em alguns casos, pode ser necessário utilizar os módulos de integração diretamente. Abaixo estão exemplos de como fazer isso:

### Telemetria

```elixir
alias Deeper_Hub.Core.Data.RepositoryTelemetry

# Executa uma função dentro de um span de telemetria
RepositoryTelemetry.span(
  [:deeper_hub, :core, :data, :repository, :custom_operation],
  %{schema: MySchema, id: 123},
  fn ->
    # Código a ser executado e monitorado
    {:ok, result}
  end
)
```

### Cache

```elixir
alias Deeper_Hub.Core.Data.RepositoryCache

# Obtém um registro do cache
case RepositoryCache.get_record(MySchema, 123) do
  {:ok, record} ->
    # Registro encontrado no cache
    record
    
  {:error, :not_found} ->
    # Registro não encontrado no cache, busca no banco de dados
    record = fetch_from_database(MySchema, 123)
    RepositoryCache.put_record(MySchema, 123, record)
    record
end

# Invalida o cache para um registro específico
RepositoryCache.invalidate_record(MySchema, 123)

# Invalida todo o cache para um schema
RepositoryCache.invalidate_schema(MySchema)
```

### Circuit Breaker

```elixir
alias Deeper_Hub.Core.Data.RepositoryCircuitBreaker

# Executa uma função protegida por um circuit breaker
RepositoryCircuitBreaker.run_read_protected(
  MySchema,
  fn ->
    # Código a ser executado com proteção
    {:ok, result}
  end,
  fn ->
    # Função de fallback a ser executada se o circuito estiver aberto
    {:ok, fallback_result}
  end
)

# Verifica o estado atual do circuit breaker
state = RepositoryCircuitBreaker.get_read_state(MySchema)
```

### Métricas

```elixir
alias Deeper_Hub.Core.Data.RepositoryMetrics

# Mede a duração e resultado de uma função
RepositoryMetrics.measure(
  :custom_operation,
  MySchema,
  fn ->
    # Código a ser executado e medido
    {:ok, result}
  end
)

# Incrementa um contador de operações
RepositoryMetrics.increment_operation_count(:custom_operation, MySchema, :success)

# Registra a duração de uma operação
RepositoryMetrics.observe_operation_duration(:custom_operation, 150, MySchema, :success)
```

### Eventos

```elixir
alias Deeper_Hub.Core.Data.RepositoryEventIntegration

# Publica um evento de inserção de registro
RepositoryEventIntegration.publish_record_inserted(MySchema, 123, record)

# Publica um evento de atualização de registro
RepositoryEventIntegration.publish_record_updated(MySchema, 123, record, changes)

# Publica um evento de exclusão de registro
RepositoryEventIntegration.publish_record_deleted(MySchema, 123)

# Publica um evento de erro
RepositoryEventIntegration.publish_repository_error(MySchema, :insert, :validation_error, details)
```

## Monitoramento e Diagnóstico

Para monitorar o estado dos componentes do repositório, você pode utilizar a função `get_status` do módulo `RepositoryIntegration`:

```elixir
# Obtém o estado atual de todos os componentes para um schema específico
status = Deeper_Hub.Core.Data.RepositoryIntegration.get_status(MySchema)

# Exemplo de saída:
# %{
#   schema: MySchema,
#   circuit_breaker: %{
#     read: :closed,
#     write: :closed
#   },
#   cache: %{
#     records: 100,
#     queries: 50,
#     total: 150
#   }
# }
```

## Configuração

Os módulos de integração podem ser configurados através do arquivo de configuração da aplicação:

```elixir
# No arquivo config.exs ou ambiente específico (dev.exs, prod.exs, etc.)

# Configuração do Circuit Breaker
config :deeper_hub, Deeper_Hub.Core.Data.RepositoryCircuitBreaker,
  max_failures: 5,
  reset_timeout: 30_000,
  half_open_threshold: 2

# Configuração do Cache
config :deeper_hub, Deeper_Hub.Core.Data.RepositoryCache,
  ttl: 300_000,  # 5 minutos
  max_size: 1000
```

## Melhores Práticas

1. **Inicialize os módulos de integração no início da aplicação** para garantir que todas as operações de banco de dados sejam protegidas.

2. **Use o `RepositoryCrud` sempre que possível** em vez de acessar o banco de dados diretamente, para aproveitar as funcionalidades de resiliência e observabilidade.

3. **Monitore as métricas coletadas** para identificar problemas de desempenho e comportamentos anômalos.

4. **Configure os parâmetros do circuit breaker e cache** de acordo com as características da sua aplicação e carga de trabalho.

5. **Utilize os eventos publicados** para implementar lógica de negócio assíncrona e integrações com outros sistemas.

## Solução de Problemas

### Circuit Breaker Aberto

Se o circuit breaker estiver aberto para um schema específico, você pode resetá-lo manualmente:

```elixir
Deeper_Hub.Core.Data.RepositoryCircuitBreaker.reset(MySchema)
```

### Cache Inconsistente

Se o cache estiver inconsistente com o banco de dados, você pode invalidá-lo:

```elixir
Deeper_Hub.Core.Data.RepositoryCache.invalidate_schema(MySchema)
```

### Reinicialização Completa

Para reiniciar todos os componentes de integração para um conjunto de schemas:

```elixir
Deeper_Hub.Core.Data.RepositoryIntegration.restart([
  MySchema1,
  MySchema2
])
```

## Conclusão

Os módulos de integração do repositório fornecem uma camada robusta de resiliência, observabilidade e desempenho para as operações de banco de dados no DeeperHub. Ao utilizá-los corretamente, você pode garantir que sua aplicação seja mais confiável, escalável e fácil de monitorar.
