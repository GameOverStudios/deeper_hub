# DeeperHub

DeeperHub é um sistema de comunicação em tempo real construído com Elixir e OTP, projetado para fornecer canais de comunicação seguros e escaláveis. O sistema utiliza WebSockets para comunicação bidirecional em tempo real, autenticação JWT para segurança e SQLite para armazenamento de dados.

## Índice de Funcionalidades

- [Visão Geral](#visão-geral)
- [Arquitetura do Sistema](#arquitetura-do-sistema)
- [Sistema de Autenticação](#sistema-de-autenticação)
- [Sistema de Comunicação em Tempo Real](#sistema-de-comunicação-em-tempo-real)
- [Banco de Dados e Persistência](#banco-de-dados-e-persistência)
- [Sistema de Cache](#sistema-de-cache)
- [Sistema de Telemetria](#sistema-de-telemetria)
- [Sistema de Segurança](#sistema-de-segurança)
- [Sistema de Email](#sistema-de-email)
- [API HTTP](#api-http)
- [Instalação e Configuração](#instalação)
- [Documentação](#documentação)
- [Testes](#testes)

## Visão Geral

O DeeperHub oferece uma plataforma completa para comunicação em tempo real com foco em desempenho, segurança e escalabilidade. Construido com a plataforma Elixir/OTP, o sistema aproveita os recursos de concorrência e tolerância a falhas nativos do Erlang.

### Características Principais

- **Autenticação Segura**: Sistema completo de autenticação baseado em JWT
- **WebSockets em Tempo Real**: Comunicação bidirecional de baixa latência
- **Canais de Comunicação**: Sistema flexível de canais para mensagens em grupo
- **Presença de Usuários**: Rastreamento de usuários online em tempo real
- **Banco de Dados SQLite**: Armazenamento leve e portátil com migrações automáticas
- **Arquitetura OTP**: Processos leves e supervisores para alta concorrência e tolerância a falhas
- **Telemetria Avançada**: Monitoramento em tempo real de todos os componentes do sistema
- **Cache Otimizado**: Sistema de cache com política LRU e mecanismos de resiliência
- **Segurança Robusta**: Proteção contra ataques, detecção de anomalias e reputação de IPs

## Arquitetura do Sistema

O DeeperHub segue uma arquitetura modular com os seguintes componentes principais:

### Core

- **Network**: Gerenciamento de conexões WebSocket, canais e presença
- **Data**: Acesso a banco de dados, migrações e operações transacionais
- **HTTP**: Endpoints da API REST e middlewares
- **Security**: Proteção contra ataques e monitoramento de segurança
- **Cache**: Sistema de cache distribuído com políticas de expiração
- **Logger**: Sistema de logging centralizado com níveis configuráveis
- **Mail**: Sistema de envio de emails com filas e templates
- **Telemetry**: Coleta e exportação de métricas de todos os componentes

### Accounts

- **Auth**: Autenticação, autorização e gerenciamento de sessões
- **User**: Gerenciamento de usuários, perfis e preferências

### Web Interface

- **Rotas e Controllers**: Rotas HTTP e manipuladores de requisições
- **Plugs**: Middlewares para processamento de requisições

## Sistema de Autenticação

O DeeperHub implementa um sistema completo de autenticação e autorização:

- **Gestão de Usuários**: Registro, atualização e desativação de contas
- **Autenticação JWT**: Tokens de acesso e refresh com rotação segura
- **Autorização Baseada em Funções**: Controle de acesso granular a recursos
- **Autenticação em Duas Etapas (2FA)**: Camada adicional de segurança
- **Gerenciamento de Sessões**: Controle de sessões ativas com revogação
- **Bloqueio de Contas**: Proteção contra tentativas de força bruta
- **Verificação de Email**: Confirmação de identidade via email
- **Recuperação de Senha**: Fluxo seguro para redefinição de senhas

## Sistema de Comunicação em Tempo Real

A comunicação em tempo real é implementada através de:

- **WebSockets**: Conexões persistentes para comunicação bidirecional
- **Canais de Comunicação**: Espaços virtuais para mensagens em grupo
  - Canais públicos e privados
  - Controle de acesso por membro
  - Gerenciamento de papéis (admin, moderador, membro)
- **Mensagens Diretas**: Comunicação privada entre usuários
- **Sistema de Presença**: Rastreamento em tempo real de usuários online
  - Status personalizáveis (online, ausente, ocupado)
  - Notificações de mudança de status
- **PubSub**: Sistema de publicação-assinatura para distribuição de mensagens
- **Persistência de Mensagens**: Armazenamento de histórico de mensagens

## Banco de Dados e Persistência

O sistema de persistência de dados inclui:

- **Banco de Dados SQLite**: Armazenamento relacional leve e embarcado
- **Sistema de Migrações**: Evolução automática do esquema do banco de dados
- **Pool de Conexões**: Gerenciamento eficiente de conexões com o banco
- **Transações**: Garantia de consistência em operações complexas
- **Índices Otimizados**: Consultas de alto desempenho
- **Tabelas Principais**:
  - Usuários e perfis
  - Canais e membros
  - Mensagens
  - Eventos de segurança
  - Tokens revogados
  - Sessões de usuário
  - Verificações de email

## Sistema de Cache

O cache otimiza o desempenho e reduz a carga no banco de dados:

- **Política LRU**: Gerenciamento inteligente de memória (Least Recently Used)
- **Compressão**: Redução do espaço ocupado pelos dados em cache
- **Expiração Automática**: Remoção automática de dados antigos
- **Namespaces**: Organização de dados em grupos lógicos
- **Persistência em Disco**: Armazenamento opcional para itens importantes
- **Warmers**: Pré-carregamento de dados frequentemente acessados
- **Mecanismos de Resiliência**:
  - Stale: Uso de dados expirados durante falhas
  - Local: Cópias locais de dados frequentes
  - Degraded: Modo de funcionalidade reduzida
- **Monitoramento**: Coleta de métricas de desempenho

## Sistema de Telemetria

A telemetria fornece visão abrangente do desempenho do sistema:

- **Adaptadores Especializados**:
  - Cache: Métricas de uso e eficiência do cache
  - HTTP: Métricas de requisições, tempos de resposta e erros
  - Network: Métricas de conexões, mensagens e canais
  - Security: Métricas de eventos de segurança e ameaças
  - Database: Métricas de consultas, transações e desempenho
- **Coleta de Métricas**:
  - Contadores: Operações acumulativas
  - Medidores: Valores numéricos que mudam ao longo do tempo
  - Históricos: Distribuição de valores
  - Eventos: Registros de ocorrências específicas
- **Armazenamento de Métricas**: Retenção configurável para análise histórica
- **Exportadores**: Integração com sistemas externos como Prometheus
- **Relatórios**: Resumos periódicos de métricas importantes

## Sistema de Segurança

O DeeperHub implementa diversas camadas de segurança:

- **Proteção contra Ataques**:
  - Limite de taxa de requisições (Rate Limiting)
  - Proteção contra força bruta
  - Validação rigorosa de entradas
- **Detecção de Anomalias**: Identificação de padrões suspeitos
- **Reputação de IPs**: Classificação dinâmica de endereços IP
- **Registro de Eventos de Segurança**: Auditoria completa de atividades sensíveis
- **Sistema de Alertas**: Notificações em tempo real de incidentes
- **Criptografia**: Proteção de dados sensíveis em repouso e em trânsito

## Sistema de Email

O sistema de emails gerencia comunicações com os usuários:

- **Filas de Emails**: Processamento assíncrono para evitar bloqueios
- **Templates**: Modelos personalizados para diferentes tipos de emails
- **Retry com Backoff**: Tentativas automáticas em caso de falha
- **Persistência de Fila**: Recuperação de emails não enviados em caso de reinicialização
- **Tipos de Emails**:
  - Confirmação de registro
  - Verificação de email
  - Recuperação de senha
  - Notificações de segurança
  - Alertas de novas mensagens

## API HTTP

O DeeperHub expoe uma API RESTful para integração com clientes:

- **Endpoints Principais**:
  - Autenticação e gerenciamento de usuários
  - Gestão de canais e mensagens
  - Consulta de presença e status
  - Métricas e saúde do sistema
- **Versionamento da API**: Suporte a múltiplas versões para compatibilidade
- **Documentação Interativa**: Especificação OpenAPI/Swagger
- **CORS**: Suporte a requisições de origens cruzadas
- **Compressão**: Redução do tamanho das respostas

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
