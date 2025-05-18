# Sistema de Comunicação do DeeperHub

Este diretório contém a implementação do sistema de comunicação do DeeperHub, responsável por gerenciar mensagens diretas entre usuários e canais de comunicação.

## Estrutura

O sistema de comunicação está organizado da seguinte forma:

```
Communications/
├── connection_manager.ex       # Gerenciador de conexões WebSocket
├── Messages/
│   ├── message_manager.ex      # Gerenciador de mensagens diretas
│   └── message_storage.ex      # Armazenamento persistente de mensagens
└── Channels/
    ├── channel_manager.ex      # Gerenciador de canais
    └── channel_storage.ex      # Armazenamento persistente de canais
```

## Componentes Principais

### ConnectionManager

O `ConnectionManager` é responsável por:

- Registrar e gerenciar conexões WebSocket de usuários
- Encaminhar mensagens para usuários conectados
- Monitorar conexões para detectar desconexões

### MessageManager

O `MessageManager` é responsável por:

- Enviar mensagens diretas entre usuários
- Armazenar mensagens para entrega posterior
- Gerenciar o histórico de conversas
- Marcar mensagens como lidas

### MessageStorage

O `MessageStorage` é responsável por:

- Armazenar mensagens no banco de dados
- Recuperar histórico de conversas
- Contar mensagens não lidas

### ChannelManager

O `ChannelManager` é responsável por:

- Criar e gerenciar canais de comunicação
- Gerenciar inscrições de usuários em canais
- Publicar mensagens em canais
- Entregar mensagens aos inscritos

### ChannelStorage

O `ChannelStorage` é responsável por:

- Armazenar canais e mensagens no banco de dados
- Recuperar histórico de mensagens de canais
- Gerenciar inscrições persistentes

## Integração com WebSockets

O sistema de comunicação se integra com o módulo WebSockets através dos seguintes handlers:

- `MessageHandler`: Processa mensagens WebSocket relacionadas a mensagens diretas
- `ChannelHandler`: Processa mensagens WebSocket relacionadas a canais

## Tipos de Mensagens WebSocket

### Mensagens Diretas

```json
{
  "type": "message.send",
  "payload": {
    "recipient_id": "user_id",
    "content": "Conteúdo da mensagem",
    "metadata": { "opcional": "valor" }
  }
}
```

```json
{
  "type": "message.mark_read",
  "payload": {
    "message_id": "id_da_mensagem"
  }
}
```

```json
{
  "type": "message.history",
  "payload": {
    "user_id": "id_do_outro_usuário",
    "limit": 50,
    "offset": 0
  }
}
```

```json
{
  "type": "message.recent",
  "payload": {
    "limit": 20
  }
}
```

```json
{
  "type": "message.unread_count",
  "payload": {}
}
```

### Canais

```json
{
  "type": "channel.create",
  "payload": {
    "name": "nome-do-canal",
    "metadata": { "description": "Descrição do canal" }
  }
}
```

```json
{
  "type": "channel.subscribe",
  "payload": {
    "name": "nome-do-canal"
  }
}
```

```json
{
  "type": "channel.unsubscribe",
  "payload": {
    "name": "nome-do-canal"
  }
}
```

```json
{
  "type": "channel.publish",
  "payload": {
    "channel_name": "nome-do-canal",
    "content": "Conteúdo da mensagem",
    "metadata": { "opcional": "valor" }
  }
}
```

```json
{
  "type": "channel.list",
  "payload": {
    "filter": { "opcional": "valor" }
  }
}
```

```json
{
  "type": "channel.info",
  "payload": {
    "name": "nome-do-canal"
  }
}
```

```json
{
  "type": "channel.subscribers",
  "payload": {
    "name": "nome-do-canal"
  }
}
```

## Autenticação

Para autenticar um usuário na conexão WebSocket, envie:

```json
{
  "auth": {
    "user_id": "id_do_usuário"
  }
}
```

## Integração com EventBus

O sistema de comunicação publica eventos no EventBus para:

- Conexões estabelecidas e encerradas
- Mensagens enviadas e recebidas
- Canais criados
- Inscrições em canais
- Mensagens publicadas em canais

## Testes

Os testes para o sistema de comunicação estão em `test/Deeper_Hub/Core/Communications/communications_test.exs`.
