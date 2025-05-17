# Módulos Core do DeeperHub

Este diretório contém os módulos centrais da aplicação DeeperHub, incluindo funcionalidades de cache e métricas de desempenho.

## Cache

O módulo `Deeper_Hub.Core.Cache` fornece uma interface simplificada para operações de cache utilizando o Cachex. O cache é utilizado para armazenar resultados de consultas e outras operações frequentes, melhorando o desempenho da aplicação.

### Uso Básico

```elixir
alias Deeper_Hub.Core.Cache

# Armazenar um valor no cache
Cache.put("chave", "valor")

# Armazenar um valor com TTL personalizado (em milissegundos)
Cache.put("chave_com_ttl", "valor", :timer.minutes(5))

# Verificar se uma chave existe no cache
{:ok, exists?} = Cache.exists?("chave")

# Recuperar um valor do cache
{:ok, valor} = Cache.get("chave")

# Remover um valor do cache
Cache.delete("chave")

# Limpar todo o cache
Cache.clear()
```

### Uso Avançado

```elixir
# Buscar um valor do cache, executando uma função se não existir
{:ok, valor} = Cache.fetch("chave", fn -> 
  # Esta função será executada apenas se a chave não existir no cache
  # O resultado será armazenado no cache automaticamente
  {:commit, "valor_calculado"}
end)

# Obter estatísticas do cache
{:ok, stats} = Cache.stats()
```

### Uso com o Pool de Conexões

O módulo `Deeper_Hub.Core.Data.DBConnection.Pool` foi integrado com o cache para permitir o armazenamento automático de resultados de consultas:

```elixir
alias Deeper_Hub.Core.Data.DBConnection.Pool

# Executar uma consulta com cache
Pool.query("SELECT * FROM tabela WHERE id = ?", [1], cache: true)

# Executar uma consulta com cache e TTL personalizado
Pool.query("SELECT * FROM tabela", [], cache: true, cache_ttl: :timer.minutes(30))
```

## Métricas

O módulo `Deeper_Hub.Core.Metrics` fornece funcionalidades para coletar e reportar métricas de desempenho da aplicação utilizando o Telemetry.

### Eventos de Telemetria

Os seguintes eventos de telemetria são emitidos pela aplicação:

- `[:deeper_hub, :database, :query, :start]` - Início de uma consulta
- `[:deeper_hub, :database, :query, :stop]` - Fim de uma consulta
- `[:deeper_hub, :database, :transaction, :start]` - Início de uma transação
- `[:deeper_hub, :database, :transaction, :stop]` - Fim de uma transação
- `[:deeper_hub, :cache, :hit]` - Acerto no cache
- `[:deeper_hub, :cache, :miss]` - Falha no cache

### Métricas Coletadas

As seguintes métricas são coletadas e reportadas:

- **Consultas**
  - Duração das consultas
  - Número de linhas retornadas
  - Taxa de consultas por segundo
  - Consultas em execução

- **Transações**
  - Duração das transações
  - Taxa de transações por segundo
  - Transações em execução

- **Cache**
  - Taxa de acertos no cache
  - Taxa de falhas no cache
  - Tamanho do cache
  - Estatísticas de operações do cache

- **VM**
  - Número de processos
  - Uso de memória
  - Contadores do sistema

### Uso Manual de Métricas

```elixir
alias Deeper_Hub.Core.Metrics

# Iniciar medição de uma consulta
Metrics.start_query("SELECT * FROM tabela", [1, 2, 3])

# Finalizar medição de uma consulta
Metrics.stop_query("SELECT * FROM tabela", [1, 2, 3], {:ok, resultado})

# Registrar um acerto no cache
Metrics.cache_hit("chave_do_cache")

# Registrar uma falha no cache
Metrics.cache_miss("chave_do_cache")

# Iniciar medição de uma transação
Metrics.start_transaction("transaction_id")

# Finalizar medição de uma transação
Metrics.stop_transaction("transaction_id", :ok)
```

## Supervisor

O módulo `Deeper_Hub.Core.Supervisor` é responsável por iniciar e supervisionar os componentes centrais da aplicação, como o cache e o repórter de métricas. Este supervisor é iniciado automaticamente pela aplicação.

## Repórter de Métricas

O módulo `Deeper_Hub.Core.Metrics.Reporter` é responsável por coletar e reportar as métricas da aplicação. Ele configura os handlers de telemetria e define as métricas a serem coletadas.

### Visualização de Métricas

As métricas são reportadas no console durante o desenvolvimento. Em ambiente de produção, recomenda-se integrar com ferramentas como Prometheus, Grafana ou DataDog para visualização e alertas.
