# EventBus para DeeperHub

## Visão Geral

O módulo EventBus do DeeperHub fornece uma implementação de comunicação baseada em eventos, permitindo que diferentes componentes da aplicação se comuniquem de forma desacoplada. Ele é construído sobre a biblioteca `event_bus` e oferece uma interface simplificada para publicação e assinatura de eventos.

## Funcionalidades

- Publicação de eventos em tópicos específicos
- Registro e gerenciamento de tópicos
- Assinatura e cancelamento de assinatura de eventos
- Integração com o sistema de cache
- Integração com o sistema de métricas

## Como Usar

### Publicar um Evento

```elixir
# Publicar um evento simples
Deeper_Hub.Core.EventBus.publish(:user_created, %{id: 123, username: "johndoe"})

# Publicar com opções adicionais
Deeper_Hub.Core.EventBus.publish(:query_executed, %{query: "SELECT * FROM users"}, 
  source: "user_service", 
  transaction_id: "tx_123"
)
```

### Registrar um Tópico

```elixir
# Registrar um novo tópico
Deeper_Hub.Core.EventBus.register_topic(:my_custom_topic)
```

### Criar um Subscriber

1. Crie um módulo com as funções necessárias:

```elixir
defmodule MyApp.MySubscriber do
  def process({:event, event}) do
    # Processar o evento
    IO.inspect(event, label: "Evento recebido")
    
    # Marcar o evento como processado
    EventBus.mark_as_completed({__MODULE__, event})
    
    :ok
  end
  
  # Função para lidar com erros durante o processamento
  def handle_error(event, error) do
    IO.inspect(error, label: "Erro ao processar evento")
    
    # Marcar o evento como pulado
    EventBus.mark_as_skipped({__MODULE__, event})
    
    :ok
  end
end
```

2. Registre o subscriber:

```elixir
# Assinar um tópico específico
Deeper_Hub.Core.EventBus.subscribe(MyApp.MySubscriber, ["user_created"])

# Assinar múltiplos tópicos usando regex
Deeper_Hub.Core.EventBus.subscribe(MyApp.MySubscriber, ["user_.*"])

# Assinar todos os tópicos
Deeper_Hub.Core.EventBus.subscribe(MyApp.MySubscriber, [".*"])
```

### Cancelar Assinatura

```elixir
# Cancelar a assinatura de um subscriber
Deeper_Hub.Core.EventBus.unsubscribe(MyApp.MySubscriber)
```

## Tópicos Padrão

O EventBus é inicializado com os seguintes tópicos padrão:

- `:user_created` - Quando um usuário é criado
- `:user_updated` - Quando um usuário é atualizado
- `:user_deleted` - Quando um usuário é excluído
- `:user_authenticated` - Quando um usuário é autenticado
- `:cache_hit` - Quando ocorre um hit no cache
- `:cache_miss` - Quando ocorre um miss no cache
- `:cache_put` - Quando um valor é armazenado no cache
- `:cache_delete` - Quando um valor é removido do cache
- `:cache_clear` - Quando o cache é limpo
- `:query_executed` - Quando uma consulta SQL é executada
- `:transaction_completed` - Quando uma transação é concluída
- `:error_occurred` - Quando ocorre um erro na aplicação

## Subscribers Padrão

O EventBus inclui os seguintes subscribers padrão:

- `Deeper_Hub.Core.EventBus.Subscribers.LoggerSubscriber` - Registra todos os eventos no log
- `Deeper_Hub.Core.EventBus.Subscribers.MetricsSubscriber` - Integra eventos com o sistema de métricas

## Integração com Cache

O módulo de cache foi integrado com o EventBus para publicar eventos automaticamente:

- `:cache_put` - Quando um valor é armazenado no cache
- `:cache_hit` - Quando um valor é encontrado no cache
- `:cache_miss` - Quando um valor não é encontrado no cache
- `:cache_delete` - Quando um valor é removido do cache
- `:cache_clear` - Quando o cache é limpo

## Configuração

A configuração do EventBus é feita no arquivo `config/event_bus.exs`. Você pode adicionar novos tópicos padrão neste arquivo.
