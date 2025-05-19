# DeeperHub

DeeperHub é um sistema de comunicação em tempo real construído com Elixir e OTP, projetado para fornecer canais de comunicação seguros e escaláveis. O sistema utiliza WebSockets para comunicação bidirecional em tempo real, autenticação JWT para segurança e SQLite para armazenamento de dados.

## Características

- **Autenticação Segura**: Sistema completo de autenticação baseado em JWT
- **WebSockets em Tempo Real**: Comunicação bidirecional de baixa latência
- **Canais de Comunicação**: Sistema flexível de canais para mensagens em grupo
- **Presença de Usuários**: Rastreamento de usuários online em tempo real
- **Banco de Dados SQLite**: Armazenamento leve e portátil com migrações automáticas
- **Arquitetura OTP**: Processos leves e supervisores para alta concorrência e tolerância a falhas

## Requisitos

- Elixir 1.18 ou superior
- Erlang/OTP 26 ou superior
- SQLite 3.35.0 ou superior

## Instalação

### Desenvolvimento

1. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/deeper_hub.git
   cd deeper_hub
   ```

2. Instale as dependências:
   ```bash
   mix deps.get
   ```

3. Configure o ambiente:
   ```bash
   # Opcional: defina a chave secreta para JWT (ou use a padrão para desenvolvimento)
   export GUARDIAN_SECRET_KEY="sua_chave_secreta"
   ```

4. Compile o projeto:
   ```bash
   mix compile
   ```

5. Inicie o servidor:
   ```bash
   mix run --no-halt
   ```

### Produção

Para implantação em produção, consulte o [Guia de Produção](docs/PRODUCAO.md).

## Uso

### Autenticação

```elixir
# Registrar um novo usuário
{:ok, user} = DeeperHub.Accounts.Auth.register_user(%{
  username: "usuario",
  email: "usuario@exemplo.com",
  password: "Senha@123"
})

# Autenticar usuário e obter tokens
{:ok, user} = DeeperHub.Accounts.Auth.authenticate_user("usuario@exemplo.com", "Senha@123")
{:ok, tokens} = DeeperHub.Accounts.Auth.generate_tokens(user)
# tokens contém access_token e refresh_token
```

### Canais

```elixir
# Criar um novo canal
{:ok, channel} = DeeperHub.Core.Network.Channels.create("nome-do-canal", user_id)

# Inscrever um usuário em um canal
:ok = DeeperHub.Core.Network.Channels.subscribe("nome-do-canal", user_id)

# Enviar mensagem para um canal
:ok = DeeperHub.Core.Network.Channels.broadcast("nome-do-canal", %{
  content: "Olá, mundo!",
  sender_id: user_id
})
```

## Documentação

- [Arquitetura do Sistema](docs/ARQUITETURA.md)
- [Guia de Produção](docs/PRODUCAO.md)
- [Guia de Segurança](docs/SEGURANCA.md)

A documentação da API pode ser gerada com ExDoc:

```bash
mix docs
```

## Testes

Execute os testes com:

```bash
mix test
```

Para testes de carga:

```bash
mix run test/load/simple_load_test.exs
```

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para detalhes.

## Contribuição

Contribuições são bem-vindas! Por favor, sinta-se à vontade para enviar pull requests ou abrir issues para discutir melhorias ou reportar problemas.
