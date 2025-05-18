# Cliente WebSocket para Testes do DeeperHub

Este cliente Python permite testar todas as funcionalidades do sistema WebSocket do DeeperHub, incluindo o novo sistema de autenticação JWT.

## Requisitos

- Python 3.7+
- Pacotes: `websockets`, `asyncio`

## Instalação

Instale as dependências necessárias:

```bash
pip install websockets asyncio
```

## Uso

O cliente pode ser executado de duas formas:

### 1. Modo Interativo

Este modo apresenta um menu interativo que permite testar todas as funcionalidades do sistema:

```bash
python test_websocket_client.py
```

### 2. Teste Automatizado

Este modo executa um teste automatizado das principais funcionalidades:

```bash
python test_websocket_client.py --test
```

### Parâmetros Opcionais

- `--host`: Endereço do servidor (padrão: localhost)
- `--port`: Porta do servidor (padrão: 4000)

Exemplo:
```bash
python test_websocket_client.py --host 192.168.1.100 --port 4000
```

## Funcionalidades Testáveis

### Autenticação
- Login com username/password
- Logout
- Refresh de tokens JWT

### Usuários
- Criar usuário
- Listar usuários
- Atualizar perfil
- Excluir usuário

### Canais
- Criar canal
- Inscrever-se em canal
- Publicar mensagem em canal

### Mensagens Diretas
- Enviar mensagem direta
- Ver histórico de mensagens

## Fluxo de Autenticação

1. Faça login com username e password
2. O sistema retorna tokens JWT (access_token e refresh_token)
3. Todas as operações subsequentes usam o estado autenticado
4. Quando o token expirar, use a opção "Atualizar tokens"
5. Para encerrar a sessão, use a opção "Logout"

## Notas

- O cliente verifica automaticamente se você está autenticado antes de permitir operações restritas
- Todas as mensagens são formatadas conforme o novo padrão esperado pelo servidor
- O teste automatizado cria usuários e canais com nomes únicos para evitar conflitos
