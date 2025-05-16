# Cliente WebSocket Python para Deeper_Hub

Este cliente Python permite testar a comunicação WebSocket com o servidor Deeper_Hub.

## Funcionalidades

- Conexão com o servidor WebSocket
- Autenticação
- Envio de heartbeats periódicos
- Envio de mensagens personalizadas
- Processamento de respostas do servidor

## Requisitos

- Python 3.7+
- Bibliotecas: websocket-client, protobuf

## Instalação

```bash
pip install -r requirements.txt
```

## Uso

1. Certifique-se de que o servidor Deeper_Hub está em execução
2. Execute o cliente:

```bash
python websocket_client.py
```

3. Siga as instruções no terminal para enviar mensagens

## Comandos disponíveis

1. **Enviar mensagem personalizada**: Permite enviar uma mensagem com evento e payload personalizados
2. **Enviar heartbeat**: Envia um heartbeat manual para o servidor
3. **Sair**: Encerra a conexão e sai do programa

## Exemplo de uso

Para enviar uma mensagem de dados, escolha a opção 1 e use:

- Tipo de evento: `message`
- Payload: `{"type": "data_request", "entity": "users", "filter": {"id": 1}}`
