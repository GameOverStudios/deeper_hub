# Arquitetura do Sistema DeeperHub

Este documento descreve a arquitetura do sistema DeeperHub, incluindo seus componentes principais, fluxo de dados e decisões de design.

## Índice

1. [Visão Geral](#visão-geral)
2. [Componentes Principais](#componentes-principais)
3. [Fluxo de Dados](#fluxo-de-dados)
4. [Decisões de Design](#decisões-de-design)
5. [Escalabilidade](#escalabilidade)
6. [Extensibilidade](#extensibilidade)

## Visão Geral

O DeeperHub é um sistema de comunicação em tempo real construído com Elixir e OTP, projetado para fornecer canais de comunicação seguros e escaláveis. A arquitetura segue os princípios de programação funcional e concorrência baseada em processos leves, aproveitando ao máximo as capacidades da plataforma BEAM.

### Filosofia de Design

- **Concorrência**: Utilização extensiva de processos leves para máxima escalabilidade
- **Tolerância a Falhas**: Árvores de supervisão para isolamento e recuperação de falhas
- **Imutabilidade**: Dados imutáveis para facilitar o raciocínio sobre o código
- **Modularidade**: Componentes bem definidos com interfaces claras

## Componentes Principais

### Camada de Dados

#### Repositório (`DeeperHub.Core.Data.Repo`)

- Interface de baixo nível para operações de banco de dados
- Implementa conexão direta com SQLite via DBConnection
- Gerencia pool de conexões e transações

#### CRUD (`DeeperHub.Core.Data.Crud`)

- Abstração para operações CRUD comuns
- Construção dinâmica de consultas SQL
- Mapeamento de resultados para estruturas de dados Elixir

#### Migrações (`DeeperHub.Core.Data.Migrations`)

- Sistema de migrações automáticas para evolução do esquema
- Controle de versão de esquema via tabela `schema_migrations`
- Inicialização automática do banco de dados

### Camada de Autenticação

#### Usuário (`DeeperHub.Accounts.User`)

- Gerenciamento de dados de usuário
- Validação de dados e hashing de senhas
- Operações de CRUD específicas para usuários

#### Autenticação (`DeeperHub.Accounts.Auth`)

- Autenticação de usuários com email/senha
- Geração e validação de tokens JWT
- Gerenciamento de sessões e refresh tokens

#### Guardian (`DeeperHub.Accounts.Auth.Guardian`)

- Implementação do Guardian para tokens JWT
- Configuração de TTL e tipos de token
- Geração de JTI para rastreamento de tokens

### Camada de Rede

#### Socket Autenticado (`DeeperHub.Core.Network.Socket.AuthSocket`)

- Socket WebSocket com autenticação JWT
- Controle de limites de taxa e validação de mensagens
- Gerenciamento de estado de conexão

#### Canais (`DeeperHub.Core.Network.Channels`)

- Sistema de canais para comunicação em grupo
- Subscrição, cancelamento e broadcast de mensagens
- Persistência de mensagens e estado de canal

#### PubSub (`DeeperHub.Core.Network.PubSub`)

- Sistema de publicação/assinatura para distribuição de mensagens
- Implementação baseada em processos para alta concorrência
- Suporte para padrões de mensagens locais e distribuídas

#### Presença (`DeeperHub.Core.Network.Presence`)

- Rastreamento de usuários online
- Detecção de desconexões e timeout
- Sincronização de estado entre nós (para futuro suporte distribuído)

### Camada de Aplicação

#### Supervisor Principal (`DeeperHub.Application`)

- Árvore de supervisão principal
- Inicialização ordenada de componentes
- Estratégias de reinicialização para tolerância a falhas

#### Logger (`DeeperHub.Core.Logger`)

- Sistema de logging centralizado
- Níveis de log configuráveis
- Formatação e destinos de log

## Fluxo de Dados

### Autenticação de Usuário

1. Cliente envia credenciais (email/senha) via HTTP
2. `DeeperHub.Accounts.Auth` valida as credenciais
3. Se válidas, gera tokens JWT (acesso e refresh)
4. Tokens são retornados ao cliente

### Conexão WebSocket

1. Cliente conecta ao WebSocket com token JWT
2. `AuthSocket` extrai e valida o token
3. Se válido, estabelece a conexão e associa ao usuário
4. Estado da conexão é inicializado com limites de taxa

### Mensagens em Canais

1. Cliente envia mensagem para um canal
2. `AuthSocket` valida a mensagem e verifica limites de taxa
3. `Channels` processa a mensagem e a distribui
4. `PubSub` entrega a mensagem a todos os assinantes
5. Mensagem é armazenada no banco de dados (se configurado)

## Decisões de Design

### Banco de Dados SQLite

Optamos por SQLite com acesso direto via DBConnection em vez de Ecto por:

- **Simplicidade**: Redução da complexidade para casos de uso iniciais
- **Portabilidade**: Facilidade de implantação sem dependências externas
- **Desempenho**: Adequado para cargas de trabalho moderadas

### Autenticação JWT

Escolhemos JWT para autenticação por:

- **Stateless**: Não requer armazenamento de sessão no servidor
- **Escalabilidade**: Funciona bem em sistemas distribuídos
- **Flexibilidade**: Suporta diferentes tipos de tokens e claims

### WebSockets para Comunicação em Tempo Real

Implementamos WebSockets como principal mecanismo de comunicação por:

- **Baixa Latência**: Comunicação bidirecional em tempo real
- **Eficiência**: Menor overhead comparado a polling
- **Compatibilidade**: Suportado pela maioria dos clientes modernos

## Escalabilidade

O sistema foi projetado para escalar de várias maneiras:

### Vertical

- Pool de conexões de banco de dados configurável
- Utilização eficiente de recursos via processos leves
- Limites de taxa para prevenir sobrecarga

### Horizontal (Preparação Futura)

- Arquitetura pronta para distribuição via BEAM
- PubSub projetado para suportar comunicação entre nós
- Estado compartilhado via CRDT ou ETS replicado

## Extensibilidade

O sistema foi projetado para ser facilmente estendido:

### Novos Tipos de Canais

- Implementação modular permite adicionar novos tipos de canais
- Interface consistente para diferentes comportamentos de canal

### Plugins e Hooks

- Pontos de extensão em operações críticas
- Sistema de eventos para reagir a mudanças de estado

### API Pública

- Interfaces bem definidas entre componentes
- Documentação clara de funções públicas
- Separação de preocupações para facilitar substituições

---

Este documento é um guia vivo e deve ser atualizado conforme a arquitetura evolui.
