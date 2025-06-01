
# DeeperHub

DeeperHub é um backend Elixir/OTP para comunicação em tempo real, com foco em canais seguros, terminal remoto, API REST e arquitetura modular. O sistema é extensível, seguro e pronto para produção.

## Principais Funcionalidades

- **Autenticação JWT**: Registro, login e geração de tokens de acesso e refresh.
- **WebSockets e Canais**: Comunicação bidirecional, broadcast, presença de usuários e gerenciamento de canais.
- **Terminal Interativo Remoto**: API REST para criar sessões, executar comandos Elixir remotamente e receber respostas em streaming.
- **API RESTful**: Endpoints para status, informações do servidor, rotas e terminal.
- **Banco de Dados SQLite**: Persistência leve, migrações automáticas e acesso via módulo `DeeperHub.Core.Data.Repo`.
- **Arquitetura OTP**: Supervisores, processos isolados, tolerância a falhas.
- **Logging Centralizado**: Módulo de logger customizado, com formatação colorida e metadados.
- **Testes e Documentação**: Estrutura para ExDoc, testes unitários e de carga.

## Estrutura de Diretórios

- `lib/deeper_hub/`: Código principal (core, web_interface, terminal, data, logger, console, etc).
- `config/`: Configurações de ambiente.
- `test/`: Testes automatizados.
- `docs/`: Documentação detalhada por módulo e funcionalidade.
- `gemini/`: Histórico de desenvolvimento, migrações e documentação auxiliar.

## Principais Módulos e Responsabilidades

### WebInterface.Router
- Roteador principal da API REST.
- Rotas:
  - `/api/status` — Status do sistema
  - `/api/info` — Informações do servidor
  - `/api/routes` — Lista de rotas disponíveis
  - `/api/terminal` — Terminal interativo remoto

### Terminal Interativo (TerminalResource, SessionManager, IExProcess)
- Criação, listagem e encerramento de sessões de terminal via API REST.
- Execução de comandos Elixir em sandbox, com streaming de saída para o cliente.
- Filtro de comandos para segurança (CommandFilter): apenas módulos e funções permitidas podem ser executados.
- Formatação e limpeza da saída do terminal (OutputFormatter).
- Gerenciamento de processos IEx isolados por sessão (IExProcess).
- Timeout de segurança para comandos longos ou travados.

### Data.Repo
- Abstração para queries SQL, transações, migrações e conexão com SQLite.
- Supervisor dedicado para pool de conexões.
- Configuração flexível via variáveis de ambiente.

### Logger
- Logging estruturado, colorido e com metadados.
- Integração com Plug.Logger e níveis configuráveis.

### Console/Command Registry
- Registro e gerenciamento de comandos customizados para o console do sistema.

## Exemplo de Uso

### Autenticação
```elixir
{:ok, user} = DeeperHub.Accounts.Auth.register_user(%{username: "usuario", email: "usuario@exemplo.com", password: "Senha@123"})
{:ok, user} = DeeperHub.Accounts.Auth.authenticate_user("usuario@exemplo.com", "Senha@123")
{:ok, tokens} = DeeperHub.Accounts.Auth.generate_tokens(user)
```

### Canais
```elixir
{:ok, channel} = DeeperHub.Core.Network.Channels.create("nome-do-canal", user_id)
:ok = DeeperHub.Core.Network.Channels.subscribe("nome-do-canal", user_id)
:ok = DeeperHub.Core.Network.Channels.broadcast("nome-do-canal", %{content: "Olá, mundo!", sender_id: user_id})
```

### Terminal Interativo (API REST)
- Criar sessão: `POST /api/terminal/sessions`
- Listar sessões: `GET /api/terminal/sessions`
- Executar comando: `POST /api/terminal/sessions/:id/execute` (body: `{ "command": "IO.puts(\"Hello\")" }`)
- Fechar sessão: `DELETE /api/terminal/sessions/:id`

### Cliente Python
Veja `terminal_client_README.md` para uso do cliente Python interativo.

## Instalação

```powershell
git clone https://github.com/seu-usuario/deeper_hub.git
cd deeper_hub
mix deps.get
mix compile
mix run --no-halt
```

## Testes

```powershell
mix test
```

## Documentação

- [Arquitetura do Sistema](docs/ARQUITETURA.md)
- [Guia de Produção](docs/PRODUCAO.md)
- [Guia de Segurança](docs/SEGURANCA.md)
- Gerar docs: `mix docs`

## Licença

MIT

---

Este README foi gerado automaticamente a partir da análise dos módulos do diretório `lib/` e da documentação do projeto. Para detalhes de cada módulo, consulte os arquivos `.ex` e a documentação em `docs/`.
