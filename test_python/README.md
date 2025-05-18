# Cliente Python para Testes do DeeperHub

Este cliente Python foi desenvolvido para testar a comunicação WebSocket com o servidor DeeperHub, implementando todas as funcionalidades de autenticação JWT, gerenciamento de usuários, canais e mensagens.

## Estrutura do Projeto

O código foi organizado em módulos separados por funcionalidade:

```
test_python/
│
├── modules/
│   ├── client_base.py      # Funcionalidades básicas de conexão WebSocket
│   ├── auth_client.py      # Funcionalidades de autenticação JWT
│   ├── user_client.py      # Operações de gerenciamento de usuários
│   ├── messaging_client.py # Operações de canais e mensagens
│   └── test_suite.py       # Suite de testes automatizados
│
├── deeper_hub_client.py    # Aplicação principal com interface interativa
├── auth_jwt_README.md      # Documentação específica de autenticação JWT
└── README.md               # Este arquivo
```

## Como Usar

### Executar o Cliente Interativo

```bash
python deeper_hub_client.py --host localhost --port 4000
```

### Executar Testes Automatizados

```bash
python deeper_hub_client.py --host localhost --port 4000 --test
```

## Funcionalidades Disponíveis

### Autenticação
- Login com JWT
- Logout
- Refresh de tokens
- Recuperação de senha
- Redefinição de senha

### Gerenciamento de Usuários
- Criar usuário
- Listar usuários
- Atualizar usuário
- Excluir usuário

### Canais e Mensagens
- Criar canal
- Inscrever-se em canal
- Publicar mensagem em canal
- Enviar mensagem direta
- Ver histórico de mensagens

## Suite de Testes Automatizados

A suite de testes implementa uma sequência inteligente de testes que verifica todas as funcionalidades do sistema em uma ordem eficiente:

1. **Testes de usuário** (não requerem autenticação)
   - Criação de usuário
   - Listagem de usuários

2. **Testes de autenticação básica**
   - Login
   - Refresh de tokens

3. **Testes de canais e mensagens** (requerem autenticação)
   - Criação de canal
   - Inscrição em canal
   - Publicação de mensagem

4. **Testes de mensagens diretas**
   - Envio de mensagem direta
   - Obtenção de histórico

5. **Testes de logout e recuperação de senha**
   - Logout
   - Fluxo completo de recuperação e redefinição de senha

6. **Testes finais de limpeza**
   - Exclusão de usuário

## Menu Interativo

O cliente oferece um menu interativo com opções diferentes dependendo do estado de autenticação:

### Quando não autenticado:
- Criar usuário
- Listar usuários
- Login
- Solicitar recuperação de senha
- Redefinir senha
- Executar todos os testes automatizados

### Quando autenticado:
- Operações de usuário (criar, listar, atualizar, excluir)
- Operações de canal (criar, inscrever-se)
- Operações de mensagem (publicar, enviar direta, ver histórico)
- Operações de autenticação (atualizar tokens, logout)
- Executar todos os testes automatizados

## Exemplo de Uso em Código

```python
from modules.messaging_client import MessagingClient

async def exemplo():
    client = MessagingClient("localhost", 4000)
    await client.connect()
    
    # Criar um usuário
    await client.create_user("usuario_teste", "teste@email.com", "senha123")
    
    # Login
    await client.login("usuario_teste", "senha123")
    
    # Criar um canal
    await client.create_channel("canal_teste", {"descricao": "Canal para testes"})
    
    # Publicar mensagem
    await client.publish_message("canal_teste", "Olá, mundo!")
    
    # Logout
    await client.logout()
    
    await client.close()
```
