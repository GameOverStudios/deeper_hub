# Módulo de Métricas do DeeperHub

## Visão Geral

O módulo de Métricas fornece funcionalidades para monitoramento e análise de desempenho da aplicação DeeperHub. Ele permite coletar, armazenar e consultar métricas relacionadas a operações do sistema, com foco especial em operações de banco de dados.

## Responsabilidades

- Coletar métricas de desempenho de operações do sistema
- Registrar tempos de execução de operações
- Contar operações por tipo e resultado
- Fornecer relatórios de desempenho
- Exportar métricas para diferentes formatos
- Analisar gargalos de desempenho
- Integrar com sistemas externos de monitoramento

## Estrutura do Módulo

```
Deeper_Hub/Core/Metrics/
├── metrics.ex             # Módulo principal de métricas
├── database_metrics.ex    # Métricas específicas para banco de dados
├── metrics_supervisor.ex  # Supervisor para inicialização das métricas
├── metrics_integration.ex # Integração com a aplicação principal
├── metrics_config.ex      # Configurações do sistema de métricas
├── metrics_viewer.ex      # Visualização e análise de métricas
├── metrics_exporter.ex    # Exportação de métricas para formatos externos
└── README.md              # Este arquivo
```

## Funcionalidades Principais

### Métricas Gerais (`metrics.ex`)

- Registro de tempo de execução de operações
- Contagem de operações por tipo
- Registro de valores de métricas
- Exportação de métricas para diferentes formatos (JSON, CSV, Prometheus)

### Métricas de Banco de Dados (`database_metrics.ex`)

- Tempo de execução de operações CRUD
- Contagem de operações por tabela e tipo
- Tamanho dos resultados de consultas
- Tempo médio de execução por operação
- Registro de tentativas de operações em tabelas inexistentes

### Inicialização e Supervisão (`metrics_supervisor.ex`)

- Inicialização automática do sistema de métricas
- Supervisão de processos relacionados a métricas
- Garantia de disponibilidade do sistema de métricas

### Integração com a Aplicação (`metrics_integration.ex`)

- Inicialização do sistema de métricas na inicialização da aplicação
- Exportação periódica de relatórios de métricas
- Geração de relatórios completos de desempenho

### Configuração (`metrics_config.ex`)

- Configurações padrão para o sistema de métricas
- Carregamento de configurações a partir do ambiente
- Personalização do comportamento do sistema de métricas

### Visualização e Análise (`metrics_viewer.ex`)

- Resumo das métricas de banco de dados por tabela
- Identificação das operações mais lentas
- Relatórios de desempenho com recomendações de otimização

### Exportação de Métricas (`metrics_exporter.ex`)

- Exportação de métricas para JSON, CSV e Prometheus
- Exportação seletiva de métricas de banco de dados
- Salvamento de métricas em arquivos

## Uso Básico

### Inicialização

O sistema de métricas é inicializado automaticamente pelo supervisor de métricas quando a aplicação é iniciada:

```elixir
# Normalmente incluído na árvore de supervisão da aplicação
children = [
  Deeper_Hub.Core.Metrics.MetricsSupervisor
]
```

Alternativamente, você pode usar o módulo de integração para inicializar o sistema de métricas com configurações personalizadas:

```elixir
alias Deeper_Hub.Core.Metrics.MetricsIntegration

# Inicializar com configurações personalizadas
MetricsIntegration.initialize(1_800_000, :json, "logs/custom_metrics")
```

### Registro de Métricas Gerais

```elixir
alias Deeper_Hub.Core.Metrics

# Registrar tempo de execução
Metrics.record_execution_time(:http, :request_time, 150.5)

# Incrementar contador
Metrics.increment_counter(:http, :request_count)

# Registrar valor (suporta tanto números quanto strings)
Metrics.record_value(:system, :memory_usage, 1024)
Metrics.record_value(:system, :last_error, "Tabela inexistente")
```

### Métricas de Banco de Dados

```elixir
alias Deeper_Hub.Core.Metrics.DatabaseMetrics

# Registrar início de operação
timestamp = DatabaseMetrics.start_operation(:users, :insert)

# Registrar conclusão de operação
DatabaseMetrics.complete_operation(:users, :insert, :success, timestamp)

# Registrar tamanho de resultado
DatabaseMetrics.record_result_size(:users, :all, 42)
```

### Consulta e Análise de Métricas

```elixir
alias Deeper_Hub.Core.Metrics
alias Deeper_Hub.Core.Metrics.DatabaseMetrics
alias Deeper_Hub.Core.Metrics.MetricsViewer

# Obter métricas de uma categoria
metrics = Metrics.get_metrics(:database)

# Obter valor específico
value = Metrics.get_metric_value(:database, :users_query_count)

# Obter relatório de tabela
report = DatabaseMetrics.get_table_metrics(:users)

# Obter resumo de métricas de banco de dados
summary = MetricsViewer.database_summary()

# Identificar operações mais lentas
slowest_ops = MetricsViewer.slowest_operations(10, 5)

# Gerar relatório de desempenho para uma tabela
performance_report = MetricsViewer.table_performance_report(:users)
```

### Exportação de Métricas

```elixir
alias Deeper_Hub.Core.Metrics.MetricsExporter

# Exportar todas as métricas para JSON
json = MetricsExporter.export_all_metrics(:json)

# Exportar métricas de banco de dados para CSV
csv = MetricsExporter.export_database_metrics(:users, :csv)

# Exportar todas as métricas para Prometheus
prometheus = MetricsExporter.export_all_metrics(:prometheus)

# Salvar métricas em um arquivo
MetricsExporter.save_to_file(json, :json, "logs/metrics")
```

### Configuração do Sistema de Métricas

```elixir
alias Deeper_Hub.Core.Metrics.MetricsConfig

# Obter configurações padrão
default_config = MetricsConfig.default_config()

# Carregar configurações do ambiente
config = MetricsConfig.load_config()
```

## Integração com Outros Módulos

O módulo de Métricas é projetado para ser facilmente integrado com outros módulos do sistema. A integração principal é com os módulos de acesso a dados:

- **Repository**: Para métricas de operações CRUD
- **Pagination**: Para métricas de paginação e tamanho de resultados

## Considerações de Desempenho

- As métricas são armazenadas em tabelas ETS para acesso rápido e baixo impacto no desempenho
- A coleta de métricas é projetada para ter o mínimo de sobrecarga possível
- Para sistemas de alta carga, considere a exportação periódica de métricas para evitar crescimento excessivo da tabela ETS

## Tratamento de Erros

- O sistema de métricas é projetado para ser resiliente a falhas
- Tentativas de acessar tabelas inexistentes são registradas como métricas específicas
- Valores de métricas podem ser tanto numéricos quanto strings, permitindo maior flexibilidade
- Erros durante a coleta de métricas não propagam falhas para o restante da aplicação
- Relatórios de métricas incluem informações sobre erros encontrados durante a coleta

## Extensão

Para adicionar novas métricas específicas para outros subsistemas:

1. Crie um novo módulo específico (ex: `Deeper_Hub.Core.Metrics.HttpMetrics`)
2. Defina funções específicas para o domínio
3. Utilize as funções do módulo `Metrics` para armazenamento
