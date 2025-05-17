# WebSockets para DeeperHub

## Visão Geral

O módulo WebSockets do DeeperHub fornece uma implementação de alta performance de servidor WebSocket usando o Ranch como base. Ele permite comunicação bidirecional em tempo real entre o servidor e os clientes, com suporte para mensagens JSON.

## Arquitetura

O sistema de WebSockets é composto pelos seguintes componentes:

1. **WebSocketProtocol**: Implementação do protocolo WebSocket sobre o Ranch
2. **WebSocketListener**: Gerenciador de conexões TCP/SSL
3. **WebSocketSupervisor**: Supervisor para o servidor WebSocket
4. **WebSocketSubscriber**: Subscriber do EventBus para eventos do WebSocket

## Integração com EventBus

O servidor WebSocket está totalmente integrado com o sistema EventBus, publicando eventos para:

- `:websocket_connected` - Quando um cliente se conecta
- `:websocket_disconnected` - Quando um cliente se desconecta
- `:websocket_message_received` - Quando uma mensagem é recebida
- `:websocket_message_sent` - Quando uma mensagem é enviada
- `:websocket_binary_received` - Quando uma mensagem binária é recebida
- `:websocket_error` - Quando ocorre um erro no WebSocket

## Integração com Métricas

O sistema de WebSockets está integrado com o sistema de métricas, coletando:

- Número de conexões ativas
- Número de mensagens recebidas/enviadas
- Tamanho das mensagens
- Erros de conexão

## Como Usar

### Iniciar o Servidor

O servidor WebSocket é iniciado automaticamente como parte da árvore de supervisão do Core. A porta padrão é 8080, mas pode ser configurada.

### Enviar Mensagens para Clientes

```elixir
# Enviar uma mensagem para um cliente específico
client_id = "client_123"
message = %{type: "update", data: %{value: 42}}
Deeper_Hub.Core.WebSockets.send_to_client(client_id, message)

# Enviar uma mensagem para todos os clientes
Deeper_Hub.Core.WebSockets.broadcast(%{type: "notification", data: %{message: "Hello everyone!"}})
```

### Formato das Mensagens

As mensagens trocadas entre o servidor e os clientes são no formato JSON. Cada mensagem deve ter um campo `type` que indica o tipo de mensagem:

```json
{
  "type": "echo",
  "data": {
    "message": "Hello, server!"
  }
}
```

### Tipos de Mensagens Suportados

- `echo`: O servidor ecoa a mensagem de volta para o cliente
- `subscribe`: O cliente se inscreve em um tópico
- `unsubscribe`: O cliente cancela a inscrição em um tópico
- `publish`: O cliente publica uma mensagem em um tópico

## Exemplo de Cliente

### JavaScript

```javascript
// Conectar ao servidor WebSocket
const socket = new WebSocket('ws://localhost:8080');

// Manipular eventos
socket.onopen = () => {
  console.log('Conectado ao servidor');
  
  // Enviar uma mensagem
  socket.send(JSON.stringify({
    type: 'echo',
    data: {
      message: 'Hello, server!'
    }
  }));
};

socket.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Mensagem recebida:', message);
};

socket.onclose = () => {
  console.log('Desconectado do servidor');
};

socket.onerror = (error) => {
  console.error('Erro:', error);
};
```

## Considerações de Performance

O servidor WebSocket é construído sobre o Ranch, que é otimizado para alta performance e escalabilidade. Algumas considerações importantes:

1. **Número de Conexões**: O servidor pode lidar com milhares de conexões simultâneas
2. **Tamanho das Mensagens**: Mensagens menores são processadas mais rapidamente
3. **Frequência de Mensagens**: Evite enviar mensagens com muita frequência para não sobrecarregar o servidor

## Configuração

A configuração do servidor WebSocket é feita no arquivo `config/config.exs`:

```elixir
config :deeper_hub, Deeper_Hub.Core.WebSockets,
  port: 8080,
  max_connections: 1000
```

## Segurança

O servidor WebSocket implementa as seguintes medidas de segurança:

1. **Validação de Origem**: Verifica a origem das conexões
2. **Limitação de Taxa**: Limita o número de mensagens por cliente
3. **Validação de Mensagens**: Valida o formato das mensagens recebidas

## Próximos Passos

1. **SSL/TLS**: Adicionar suporte para conexões seguras
2. **Autenticação**: Implementar autenticação de clientes
3. **Compressão**: Adicionar suporte para compressão de mensagens
4. **Clustering**: Implementar suporte para clustering para maior escalabilidade
