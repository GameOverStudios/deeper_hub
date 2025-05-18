# Camada de Acesso a Banco de Dados com DBConnection 🚀

## Introdução

Este módulo implementa uma camada otimizada de acesso a banco de dados usando `DBConnection` para o projeto DeeperHub. Esta implementação substitui o uso direto do Ecto Repo, fornecendo maior controle sobre as conexões, melhor performance e recursos avançados de monitoramento.

## Arquitetura

A camada de acesso a banco de dados com DBConnection segue uma arquitetura modular:

```
DBConnection/
├── connection.ex      # Implementação do comportamento DBConnection
├── config.ex          # Configurações para o DBConnection
├── facade.ex          # Interface simplificada para o sistema
├── migrations.ex      # Gerenciamento de migrações
├── optimizer.ex       # Otimizador de consultas SQL
├── pool.ex            # Gerenciamento do pool de conexões
├── query.ex           # Implementação do protocolo DBConnection.Query
├── schema_adapter.ex  # Adaptador para schemas Ecto
└── telemetry.ex       # Monitoramento de performance
```

## Componentes Principais

### Connection

Implementa o comportamento `DBConnection` para fornecer conexões otimizadas com o banco de dados SQLite3. Gerencia o ciclo de vida da conexão, incluindo:

- Conexão e desconexão
- Verificação de saúde (ping)
- Gerenciamento de transações
- Preparação e execução de consultas
- Cache de statements preparados

### Config

Fornece configurações para o DBConnection, incluindo:

- Configurações do pool de conexões
- Configurações de conexão
- Configurações específicas para cada ambiente (dev, test, prod)

### Facade

Interface simplificada para as operações de banco de dados, facilitando a migração do Repo para o DBConnection. Expõe funções como:

- `query/3`: Executa uma consulta SQL
- `transaction/2`: Executa operações dentro de uma transação
- `insert/3`, `get/3`, `update/3`, `delete/2`: Operações CRUD para schemas Ecto

### Migrations

Gerenciamento de migrações para o banco de dados, mantendo compatibilidade com o sistema de migrações do Ecto. Fornece funções como:

- `run_migrations/0`: Executa todas as migrações pendentes
- `rollback/0`: Reverte a última migração
- `reset_migrations/0`: Reverte e reaplicada todas as migrações

### Optimizer

Otimizador de consultas SQL, melhorando a performance do sistema. Fornece funções como:

- `analyze/1`: Analisa uma consulta SQL e sugere otimizações
- `optimize/1`: Otimiza uma consulta SQL automaticamente
- `add_index_hint/3`: Adiciona dicas de índice a uma consulta SQL

### Pool

Gerenciamento do pool de conexões, fornecendo:

- Configuração otimizada do pool
- Controle de conexões ociosas
- Gerenciamento de overflow
- Monitoramento de métricas do pool

### Query

Implementação do protocolo `DBConnection.Query` para consultas SQL, permitindo:

- Uso direto de strings SQL
- Consultas estruturadas com parâmetros
- Validação de parâmetros
- Codificação e decodificação de resultados

### SchemaAdapter

Adaptador para usar schemas Ecto com o DBConnection, fornecendo:

- Conversão de schemas Ecto para consultas SQL
- Conversão de resultados SQL para schemas Ecto
- Operações CRUD para schemas Ecto
- Suporte a filtros e paginação

### Telemetry

Monitoramento de performance para o DBConnection, fornecendo:

- Métricas de tempo de execução de consultas
- Métricas de tempo de fila
- Métricas de tempo de conexão
- Métricas de uso do pool de conexões

## Uso Básico

```elixir
alias Deeper_Hub.Core.Data.DBConnection.Facade, as: DB

# Executar uma consulta simples
{:ok, result} = DB.query("SELECT * FROM users WHERE username = ?", ["john"])

# Executar uma consulta dentro de uma transação
{:ok, result} = DB.transaction(fn conn ->
  DB.query("INSERT INTO users (username, email) VALUES (?, ?)", ["jane", "jane@example.com"])
end)

# Operações com schemas Ecto
{:ok, user} = DB.insert(User, %{username: "john", email: "john@example.com"})
{:ok, user} = DB.get(User, user.id)
{:ok, user} = DB.update(user, %{email: "new_email@example.com"})
{:ok, user} = DB.delete(user)
```

## Configuração

A configuração da camada DBConnection é feita através do módulo `Config`. As principais configurações incluem:

- `pool_size`: Número máximo de conexões no pool
- `max_overflow`: Número máximo de conexões extras permitidas
- `idle_interval`: Intervalo para verificar conexões ociosas
- `queue_target`: Tempo alvo para espera na fila
- `queue_interval`: Intervalo para verificar o tempo de fila

## Otimização de Performance

Esta implementação inclui várias otimizações para melhorar a performance:

1. **Cache de Statements Preparados**: Reutiliza statements preparados para consultas frequentes
2. **Pool de Conexões Otimizado**: Configuração otimizada do pool para balancear recursos e performance
3. **Telemetria**: Monitoramento detalhado para identificar gargalos de performance
4. **Otimizador de Consultas**: Análise e otimização automática de consultas SQL
5. **Configuração SQLite Otimizada**: Uso de WAL, configurações de sincronização otimizadas

## Compatibilidade com Ecto

Esta implementação mantém compatibilidade com schemas Ecto através do módulo `SchemaAdapter`, permitindo:

- Uso de changesets para validação
- Operações CRUD com schemas Ecto
- Suporte a associações
- Migrações compatíveis com Ecto

## Considerações de Segurança

1. **Validação de Parâmetros**: Todos os parâmetros são validados antes de serem usados em consultas
2. **Prevenção de SQL Injection**: Uso de consultas parametrizadas para prevenir SQL injection
3. **Tratamento de Erros**: Tratamento adequado de erros para evitar vazamento de informações sensíveis

## Contribuição

Ao contribuir para esta camada, siga as diretrizes de codificação do projeto DeeperHub:

1. Leia completamente este README antes de iniciar qualquer implementação
2. Mantenha a separação de responsabilidades conforme definido na arquitetura
3. Não crie novos módulos que não estejam previamente especificados
4. Siga as convenções de nomenclatura do Elixir
5. Documente todas as funções públicas
6. Escreva testes para todas as funcionalidades implementadas
7. Revise o código para remover código não utilizado e corrigir problemas de tipagem
