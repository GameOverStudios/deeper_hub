# Módulo de Telemetria do DeeperHub 🔍

## Visão Geral

O módulo de Telemetria fornece uma infraestrutura completa para rastreamento, monitoramento e análise de operações no sistema DeeperHub. Ele permite capturar spans de execução, publicar eventos e coletar métricas de desempenho e comportamento.

## Responsabilidades

- Rastrear o fluxo de execução de operações através do sistema
- Medir o tempo de execução de operações
- Capturar metadados contextuais sobre operações
- Registrar exceções e erros
- Integrar com o sistema de logging e métricas
- Fornecer uma interface unificada para telemetria em todo o sistema

## Estrutura do Módulo

```
Deeper_Hub/Core/Telemetry/
├── telemetry.ex              # Módulo principal de telemetria
├── telemetry_config.ex       # Configuração e inicialização
├── telemetry_supervisor.ex   # Supervisor para processos de telemetria
├── telemetry_integration.ex  # Integração com outros módulos
└── README.md                 # Este arquivo
```

## Funcionalidades Principais

### Spans de Telemetria (`telemetry.ex`)

- Rastreamento de início e fim de operações
- Captura de exceções e erros
- Coleta de metadados contextuais
- Sanitização de dados sensíveis

### Configuração e Inicialização (`telemetry_config.ex`)

- Configuração de eventos padrão
- Configuração de handlers
- Inicialização do sistema de telemetria

### Supervisão (`telemetry_supervisor.ex`)

- Inicialização e supervisão de processos de telemetria
- Integração com a árvore de supervisão da aplicação

### Integração com Outros Módulos (`telemetry_integration.ex`)

- Adição de telemetria a funções existentes
- Instrumentação automática de módulos
- Sanitização de argumentos e resultados

## Uso Básico

### Inicialização

O sistema de telemetria é inicializado automaticamente pelo supervisor de telemetria quando a aplicação é iniciada:

```elixir
# Normalmente incluído na árvore de supervisão da aplicação
children = [
  Deeper_Hub.Core.Telemetry.TelemetrySupervisor
]
```

### Rastreamento Manual de Operações

```elixir
alias Deeper_Hub.Core.Telemetry

# Usando a função span para rastrear uma operação
result = Telemetry.span "auth.user.login", %{user_id: user.id} do
  # Código da operação
  AuthService.login(user, password)
end

# Rastreamento manual com start_span e stop_span
span = Telemetry.start_span("data.repository.get", %{schema: User, id: user_id})
result = Repository.get(User, user_id)
Telemetry.stop_span(span, %{result: result})
```

### Integração com Módulos Existentes

```elixir
alias Deeper_Hub.Core.Telemetry.TelemetryIntegration

# Adicionar telemetria a uma chamada de função
result = TelemetryIntegration.with_telemetry(
  Repository, :get, [User, user_id],
  "data.repository.get_user"
)

# Usando a macro telemetry_span
import Deeper_Hub.Core.Telemetry.TelemetryIntegration, only: [telemetry_span: 2]

telemetry_span "auth.validate_token" do
  # Código a ser rastreado
  AuthService.validate_token(token)
end

# Instrumentação automática de um módulo
defmodule MyService do
  use Deeper_Hub.Core.Telemetry.TelemetryIntegration,
    prefix: "my_service",
    except: [:init, :terminate]
    
  # Funções do módulo
  def process_data(data) do
    # Esta função será automaticamente instrumentada
    # ...
  end
end
```

## Convenções de Nomenclatura

Os eventos de telemetria seguem a convenção de nomenclatura:

```
domínio.entidade.ação
```

Exemplos:
- `auth.user.login`
- `data.repository.get`
- `api.request.process`

Para cada evento, são emitidos três sub-eventos:
- `start` - Quando a operação inicia
- `stop` - Quando a operação é concluída com sucesso
- `exception` - Quando a operação falha com uma exceção

## Integração com Outros Módulos do Sistema

### Integração com o Sistema de Logging

O módulo de Telemetria se integra com o `Deeper_Hub.Core.Logger` para registrar logs relevantes:
- Início de operações (nível debug)
- Conclusão de operações (nível variável com base na duração)
- Exceções e erros (nível error)

### Integração com o Sistema de Métricas

O módulo de Telemetria se integra com o `Deeper_Hub.Core.Metrics` para registrar métricas:
- Tempo de execução de operações
- Contagem de operações por tipo
- Contagem de sucessos e erros
- Métricas específicas para erros

## Considerações de Desempenho

- A telemetria é projetada para ter o mínimo de sobrecarga possível
- A sanitização de dados sensíveis e grandes é automática
- Para operações de alto volume, considere usar telemetria seletiva

## Tratamento de Erros

- Exceções dentro de spans são capturadas e registradas
- A telemetria não interfere no fluxo normal de exceções
- Erros durante a telemetria não propagam falhas para o restante da aplicação

## Extensão

Para adicionar novos tipos de eventos de telemetria:

1. Defina o evento no `TelemetryConfig.default_events/0`
2. Adicione o evento aos módulos relevantes usando as funções de integração

Para adicionar novos handlers de telemetria:

1. Crie um módulo que implementa a função `handle_event/4`
2. Adicione o handler ao `TelemetryConfig.default_handlers/0`

## Exemplos de Integração com Módulos Existentes

### Integração com Repository

```elixir
# Em Repository.get/2
def get(schema, id) do
  Telemetry.span "data.repository.get", %{schema: schema, id: id} do
    # Código original
  end
end
```

### Integração com AuthService

```elixir
# Em AuthService.login/2
def login(user, password) do
  Telemetry.span "auth.user.login", %{user_id: user.id} do
    # Código original
  end
end
```

## Próximos Passos

1. Integrar telemetria com todos os módulos principais do sistema
2. Implementar visualização de dados de telemetria
3. Adicionar exportação de dados de telemetria para sistemas externos
4. Implementar rastreamento distribuído para operações que atravessam múltiplos serviços
