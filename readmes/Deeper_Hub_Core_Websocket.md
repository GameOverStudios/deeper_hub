# Deeper_Hub.Core.Websocket

## Visão Geral

O módulo `Deeper_Hub.Core.Websocket` implementa um sistema completo de comunicação WebSocket de alta performance para o Deeper_Hub, permitindo comunicação bidirecional em tempo real entre o servidor e clientes C++. Este módulo foi projetado com foco em performance, resiliência e observabilidade.

## Características Principais

- **🔄 Comunicação Bidirecional**: Suporte completo a comunicação em tempo real
- **📦 Protocol Buffers**: Serialização/deserialização eficiente usando protobuf
- **🛡️ Circuit Breaker**: Proteção contra falhas em cascata
- **💾 Cache Integrado**: Otimização de performance para operações frequentes
- **📊 Telemetria**: Instrumentação completa para observabilidade
- **🔔 EventBus**: Integração com sistema de eventos
- **🔒 Autenticação**: Suporte a autenticação de conexões
- **❤️ Heartbeat**: Detecção de conexões inativas
- **👥 Presence**: Rastreamento de usuários conectados

## Componentes

### 1. Handler

O `Handler` gerencia o ciclo de vida das conexões WebSocket, processando mensagens recebidas e enviando respostas.

**Responsabilidades**:
- Autenticação e autorização
- Serialização/deserialização de mensagens
- Integração com Circuit Breaker
- Integração com Cache
- Emissão de eventos de telemetria e EventBus

### 2. Channel

O `Channel` implementa o canal de comunicação Phoenix, gerenciando a comunicação bidirecional.

**Responsabilidades**:
- Gerenciamento de tópicos
- Broadcast de mensagens
- Integração com Presence

### 3. Endpoint

O `Endpoint` configura o servidor WebSocket, definindo opções de conexão e segurança.

**Responsabilidades**:
- Configuração de SSL/TLS
- Configuração de timeouts
- Configuração de compressão

### 4. Presence

O `Presence` rastreia usuários conectados e seus estados.

**Responsabilidades**:
- Rastreamento de conexões
- Broadcast de mudanças de estado
- Detecção de desconexões

### 5. ConnectionMonitor

O `ConnectionMonitor` monitora conexões ativas e detecta conexões zumbis.

**Responsabilidades**:
- Monitoramento de conexões
- Detecção de conexões zumbis
- Emissão de métricas de conexão

### 6. Messages

O `Messages` define as estruturas de mensagens Protocol Buffers para comunicação.

**Responsabilidades**:
- Definição de mensagens
- Serialização/deserialização
- Integração com Protocol Buffers

## Integração com Outros Módulos

### 1. Circuit Breaker

O WebSocket utiliza o `CircuitBreaker` para proteger contra falhas em cascata:

```elixir
CircuitBreaker.call(
  :websocket_handler,
  fn -> do_handle_in(payload, socket) end,
  [],
  threshold: 5,
  timeout_sec: 30,
  match_error: fn
    {:error, _} -> true
    _ -> false
  end
)
```

### 2. Cache

O WebSocket utiliza o `CacheManager` para otimizar performance:

```elixir
# Verifica cache para ações frequentes
cache_key = "ui_action:#{action.action_type}:#{action.request_id}"
case CacheManager.get(:default_cache, cache_key) do
  {:ok, cached_response} when not is_nil(cached_response) ->
    # Emite métrica de cache hit
    TelemetryEvents.execute_cache_hit(...)
    {:ok, cached_response}
  _ ->
    # Processa e armazena em cache
    response = process_action(...)
    CacheManager.put(:default_cache, cache_key, response, ttl: @cache_ttl)
    {:ok, response}
end
```

### 3. EventBus

O WebSocket emite eventos para o `EventBus`:

```elixir
EventDefinitions.emit(
  EventDefinitions.websocket_connection(),
  %{
    socket_id: socket.id,
    user_id: user_id,
    client_info: params["client_info"]
  },
  source: "#{__MODULE__}"
)
```

### 4. Telemetria

O WebSocket emite métricas para o sistema de `Telemetria`:

```elixir
TelemetryEvents.execute_websocket_connection(
  %{duration: duration, count: 1},
  %{status: :success, module: __MODULE__}
)
```

## Protocol Buffers

O WebSocket utiliza Protocol Buffers para serialização/deserialização eficiente:

```protobuf
message ClientMessage {
  oneof message_type {
    UiAction ui_action = 1;
    DataRequest data_request = 2;
    EventAck event_ack = 3;
    Heartbeat heartbeat = 4;
  }
}
```

## Exemplo de Uso

### 1. Inicialização

```elixir
# Em application.ex
children = [
  # ...
  {DeeperHub.Core.Websocket.Supervisor, []}
]
```

### 2. Conexão de Cliente

```elixir
# No cliente C++
websocket_client.connect("ws://server:4000/socket", {
  auth_token: "user_token",
  client_info: {
    version: "1.0.0",
    platform: "windows"
  }
})
```

### 3. Envio de Mensagem

```elixir
# No cliente C++
message = ClientMessage.new();
message.set_ui_action(UiAction.new());
message.mutable_ui_action()->set_action_type("button_click");
message.mutable_ui_action()->set_request_id("req_123");
websocket_client.send(message.SerializeAsString());
```

## Considerações de Performance

1. **Serialização Eficiente**: Protocol Buffers oferece serialização/deserialização de alta performance
2. **Cache**: Respostas frequentes são cacheadas para reduzir processamento
3. **Heartbeat**: Mantém conexões ativas e detecta conexões zumbis
4. **Circuit Breaker**: Protege contra falhas em cascata
5. **Compressão**: Reduz o tamanho das mensagens

## Considerações de Segurança

1. **Autenticação**: Todas as conexões são autenticadas
2. **SSL/TLS**: Suporte a comunicação criptografada
3. **Rate Limiting**: Proteção contra abuso
4. **Validação**: Todas as mensagens são validadas antes do processamento
5. **Timeout**: Conexões inativas são encerradas automaticamente

## Observabilidade

1. **Telemetria**: Métricas detalhadas para todas as operações
2. **EventBus**: Eventos para todas as ações importantes
3. **Logging**: Logs estruturados para depuração
4. **Monitoramento**: Detecção de conexões zumbis e problemas de performance

## Conclusão

O módulo `Deeper_Hub.Core.Websocket` fornece uma solução completa e robusta para comunicação em tempo real entre o servidor Deeper_Hub e clientes C++, com foco em performance, resiliência e observabilidade.
