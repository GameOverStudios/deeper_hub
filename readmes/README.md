**Parte 1: Introdução e Funcionalidades Centrais**

```markdown
# DeeperHub - Sistema Integrado de Gerenciamento e API

Bem-vindo ao DeeperHub! Este documento descreve as funcionalidades completas oferecidas pelo sistema, com base na documentação dos seus módulos. O DeeperHub é uma plataforma robusta projetada para gerenciar usuários, APIs, segurança, notificações, e muito mais, com foco em modularidade e extensibilidade.

## Sumário de Funcionalidades

1.  [Gerenciamento da Aplicação](#1-gerenciamento-da-aplicação)
2.  [Sistema de Logging](#2-sistema-de-logging)
3.  [Gerenciamento de Configuração](#3-gerenciamento-de-configuração)
4.  [Sistema de Eventos (Pub/Sub)](#4-sistema-de-eventos-pubsub)
5.  [Funcionalidades da API REST](#5-funcionalidades-da-api-rest)
6.  [Gerenciamento de Contas de Usuário](#6-gerenciamento-de-contas-de-usuário)
7.  [Autenticação e Autorização](#7-autenticação-e-autorização)
8.  [Autenticação Multifator (MFA)](#8-autenticação-multifator-mfa)
9.  [Autenticação OAuth](#9-autenticação-oauth)
10. [Autenticação WebAuthn (FIDO2)](#10-autenticação-webauthn-fido2)
11. [Recuperação de Contas](#11-recuperação-de-contas)
12. [Políticas de Sessão](#12-políticas-de-sessão)
13. [Sistema de Segurança Abrangente](#13-sistema-de-segurança-abrangente)
14. [Gerenciamento de Feature Flags](#14-gerenciamento-de-feature-flags)
15. [Sistema de Auditoria](#15-sistema-de-auditoria)
16. [Notificações](#16-notificações)
17. [Webhooks](#17-webhooks)
18. [Tarefas em Segundo Plano](#18-tarefas-em-segundo-plano)
19. [Serviços de Domínio](#19-serviços-de-domínio)
    *   [Serviços de Servidores (Servers)](#191-serviços-de-servidores-servers)
    *   [Pacotes de Servidores (ServerPackages)](#192-pacotes-de-servidores-serverpackages)
    *   [Eventos de Servidores (ServerEvents)](#193-eventos-de-servidores-serverevents)
    *   [Alertas de Servidores (ServerAlerts)](#194-alertas-de-servidores-serveralerts)
    *   [Tags de Servidores (ServerTags)](#195-tags-de-servidores-servertags)
    *   [Mensagens de Atualização de Servidores (ServerUpdateMessages)](#196-mensagens-de-atualização-de-servidores-serverupdatemessages)
    *   [Avaliações de Servidores (ServerReviews)](#197-avaliações-de-servidores-serverreviews)
    *   [Conquistas (Achievements)](#198-conquistas-achievements)
    *   [Desafios (Challenges)](#199-desafios-challenges)
    *   [Listas Genéricas (Lists)](#1910-listas-genéricas-lists)
    *   [Recompensas (Rewards)](#1911-recompensas-rewards)
    *   [Interações de Usuários (UserInteractions)](#1912-interações-de-usuários-userinteractions)
    *   [Suporte ao Cliente (Support)](#1913-suporte-ao-cliente-support)
20. [Infraestrutura Compartilhada](#20-infraestrutura-compartilhada)
    *   [Cache](#201-cache)
    *   [Circuit Breaker](#202-circuit-breaker)
    *   [Criptografia](#203-criptografia)
    *   [Utilitários (Datas, Arquivos, Listas, Mapas, Segurança)](#204-utilitários)
21. [Ferramentas de Desenvolvedor e Administração](#21-ferramentas-de-desenvolvedor-e-administração)
    *   [Console Interativo (CLI)](#211-console-interativo-cli)
    *   [Inspetor de Módulos](#212-inspetor-de-módulos)

---

## 1. Gerenciamento da Aplicação

O módulo `DeeperHub.ApplicationFacade` (e seu alias `DeeperHub.ApplicationModule`) oferece controle e visibilidade sobre o estado da aplicação DeeperHub.

*   **Verificar Versão:** Obter a versão atual da aplicação.
*   **Verificar Ambiente:** Identificar o ambiente de execução (ex: `:dev`, `:test`, `:prod`).
*   **Obter Informações Detalhadas:** Acessar um conjunto de informações sobre a aplicação, incluindo nome, versão, ambiente, versões do Elixir e OTP, e data de início. Pode opcionalmente incluir informações sobre dependências.
*   **Verificar Status:** Obter o status atual da aplicação e seus principais componentes (ex: banco de dados, API, tarefas em segundo plano), incluindo tempo de atividade (uptime).
*   **Gerenciar Modo de Depuração:**
    *   Verificar se o modo de depuração está ativo.
    *   Ativar ou desativar o modo de depuração, com rastreamento opcional do usuário que solicitou a alteração.
*   **Reiniciar Aplicação:** Solicitar o reinício da aplicação, com opções para reinício parcial (soft) ou completo (hard), e rastreamento opcional do solicitante.

---

## 2. Sistema de Logging

O DeeperHub possui um sistema de logging estruturado e centralizado, acessível principalmente através de `DeeperHub.Logger` e fachadas como `DeeperHub.Core.Services.LoggerFacade`.

*   **Logging Estruturado em Níveis:**
    *   `debug/2,3`: Registrar mensagens de depuração.
    *   `info/2,3`: Registrar mensagens informativas.
    *   `warn/2,3` (ou `warning/3`): Registrar avisos.
    *   `error/2,3`: Registrar erros.
    *   `critical/2,3`: Registrar erros críticos.
    *   `notice/2,3`: Registrar notificações.
    *   `emergency/2,3`: Registrar emergências.
*   **Contexto de Logging:**
    *   Definir e limpar metadados de contexto (`DeeperHub.Logger.Context`) que são automaticamente incluídos em todas as mensagens de log subsequentes dentro do mesmo processo.
    *   Definir e obter IDs de correlação para rastrear fluxos de requisições.
*   **Emojis Personalizáveis:** Configurar emojis para diferentes níveis de log para melhor legibilidade (`DeeperHub.Logger.Config`).
*   **Múltiplos Backends:** Suporte para adicionar e remover diferentes backends de logging (`DeeperHub.Logger.LoggerFacade`, `DeeperHub.Logger.StructuredLogger`).
*   **Integração com Phoenix:**
    *   Um plug (`DeeperHub.Logger.PhoenixIntegration.RequestLogger`) para registrar automaticamente informações sobre requisições HTTP, incluindo método, caminho, status, tempo de resposta, com opções para loggar headers, parâmetros e cookies (com mascaramento de dados sensíveis).
*   **Sanitização de Logs:**
    *   O módulo `DeeperHub.Security.LogSanitizer` (e seu alias `DeeperHub.Shared.Validation.InputSanitizer`) fornece funcionalidades para sanitizar mensagens de log e metadados, removendo informações sensíveis e prevenindo injeção de dados.
*   **Rastreamento Distribuído:**
    *   O módulo `DeeperHub.Shared.Logging.DistributedTracing` permite criar e gerenciar traces e spans para rastrear operações através de múltiplos componentes, integrando-se com o logging estruturado.
*   **Telemetria Interna:** O próprio sistema de logging possui telemetria para monitorar suas ações (`DeeperHub.Logger.Telemetry`).

---

## 3. Gerenciamento de Configuração

O `DeeperHub.Core.ConfigManager` atua como um ponto centralizado para todas as configurações do sistema.

*   **Acesso a Configurações:**
    *   Obter o valor de uma configuração por chave e escopo, com um valor padrão (`get/3`, `get_value/3`).
    *   Obter configurações aninhadas usando uma lista de chaves (`get_config/1`).
    *   Obter valores convertidos para inteiros (`get_integer/2,3`).
    *   Obter a estrutura completa de uma configuração (`get_setting/2`).
*   **Gerenciamento de Configurações:**
    *   Criar novas configurações com escopo, tipo de dado, descrição e sensibilidade (`set/3`).
    *   Excluir configurações (`delete/3`).
*   **Listagem de Configurações:**
    *   Listar configurações com filtros por escopo, prefixo de chave e sensibilidade (`list/1`).
    *   Listar configurações específicas para um cliente ou usuário, com opção de incluir configurações globais (`list_for_client/2`, `list_for_user/2`).
*   **Observabilidade de Mudanças:**
    *   Registrar coordenadores de eventos para serem notificados sobre criação, atualização ou exclusão de configurações (`on_config_change/2`).
    *   Cancelar o registro de coordenadores de eventos (`off_config_change/2`).
*   **Inicialização:** O sistema de configuração é inicializado com um cache (`DeeperHub.Core.ConfigManager.Setting.init_cache/0`).
*   **Armazenamento:** As configurações são persistidas usando um schema Ecto (`DeeperHub.Core.ConfigManager.Schema.Setting`).

---

## 4. Sistema de Eventos (Pub/Sub)

O DeeperHub implementa um sistema de publicação e assinatura de eventos (`DeeperHub.Core.Event` e `DeeperHub.Core.Event.EventBus`) para comunicação assíncrona e desacoplada.

*   **Publicação de Eventos:**
    *   Publicar eventos com um nome, uma carga útil (payload) e opções (`publish/3`, `emit/3`).
    *   Opções de publicação incluem retenção no histórico, metadados, e configurações de retry.
*   **Assinatura de Eventos:**
    *   Processos podem assinar eventos específicos por nome (`subscribe/3`).
    *   Suporte a wildcards em tópicos de eventos para assinaturas flexíveis.
    *   Opção para receber eventos passados ao assinar.
*   **Cancelamento de Assinaturas:**
    *   Cancelar a assinatura de um evento específico (`unsubscribe/3`).
    *   Cancelar todas as assinaturas de um assinante (`unsubscribe_all/2`).
*   **Gerenciamento e Monitoramento:**
    *   Listar todas as assinaturas de eventos, opcionalmente filtradas por nome do evento (`list_subscriptions/1`).
    *   Obter a configuração atual do sistema de eventos, incluindo limites de histórico e configurações de retry (`get_config/0`).
    *   Obter métricas sobre o sistema de eventos, como contagem de eventos publicados, entregues e falhos (`get_metrics/0`).
*   **Resiliência:** O sistema inclui um supervisor (`DeeperHub.Core.EventSupervisor`) para garantir a disponibilidade do serviço de eventos.
*   **Configurabilidade:**
    *   Limite de histórico de eventos.
    *   Habilitação de retry para entrega de eventos.
    *   Número máximo de tentativas de retry.
    *   Intervalo entre tentativas de retry.
    (Todas configuráveis via `DeeperHub.Core.ConfigManager`)

```

---

**Parte 2: Funcionalidades da API REST e Gerenciamento de Contas**

```markdown
## 5. Funcionalidades da API REST

O módulo `DeeperHub.API` é responsável por definir, gerenciar e proteger a Interface de Programação de Aplicativos (API) RESTful do sistema DeeperHub. Ele serve como o principal ponto de interação para clientes externos (aplicações web, mobile, serviços de terceiros) consumirem as funcionalidades e dados do DeeperHub.

### 5.1. Responsabilidades e Funcionalidades Chave

* **Definição de Endpoints RESTful:**
  * Mapeamento de rotas HTTP para controllers e ações específicas.
  * Suporte aos verbos HTTP padrão (GET, POST, PUT, PATCH, DELETE).

* **Validação de Requisições:**
  * Validação de parâmetros de query, path e corpo da requisição via `DeeperHub.API.Validation.APIRequestValidator`.
  * Validação de tipos de dados, formatos e regras de negócio.
  * Criação de schemas de validação dinâmicos para endpoints da API.
  * Sanitização de dados de entrada para prevenir injeção de código.

* **Limitação de Taxa (Rate Limiting):**
  * Controle do número de requisições por cliente/IP/token em um determinado período.
  * Prevenção de abusos e sobrecarga da API.
  * Retorno de cabeçalhos HTTP padrão para rate limiting (`X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`).
  * Suporte a chaves de bypass para casos especiais.

* **Autenticação e Autorização:**
  * Integração com `DeeperHub.Auth` para autenticação via tokens de API ou JWTs de sessão.
  * Verificação de permissões para acessar recursos/endpoints específicos.

* **Versionamento da API:**
  * Suporte a diferentes versões da API (ex: `/api/v1/...`, `/api/v2/...`).
  * Permite evolução sem quebrar clientes existentes.

* **Formatação de Respostas:**
  * Padronização do formato das respostas JSON (sucesso, erro, validação) via `DeeperHub.Core.APIResponder`.
  * Inclusão de metadados e links relacionados (HATEOAS).

* **Documentação da API:**
  * Geração de documentação interativa (ex: OpenAPI/Swagger).
  * Documentação automática a partir de schemas de validação.

* **Tratamento de Erros:**
  * Conversão de erros internos em respostas HTTP padronizadas.
  * Mensagens de erro claras e úteis para desenvolvedores.

* **Gerenciamento de CORS:**
  * Configuração de políticas de CORS para permitir ou restringir acesso de diferentes origens.

* **Caching de Respostas:**
  * Integração com `DeeperHub.Core.Cache` para armazenar respostas em cache.
  * Redução da carga no servidor para dados pouco voláteis.

### 5.2. Arquitetura e Componentes Principais

#### 5.2.1. Router

* Define as rotas da API, mapeando URLs e métodos HTTP para os respectivos Controllers.
* Aplica middlewares para autenticação, rate limiting, validação, etc.

#### 5.2.2. Controllers

* Recebem requisições HTTP e extraem parâmetros.
* Chamam os módulos de serviço/fachadas de domínio apropriados.
* Formatam a resposta usando `DeeperHub.Core.APIResponder`.
* Implementam a lógica específica de cada endpoint.

#### 5.2.3. Schemas de Validação

* Definem a estrutura esperada e as regras de validação para os dados de entrada.
* Podem ser baseados em Ecto Changesets ou bibliotecas como `Params`.
* Garantem a integridade dos dados desde o início do processamento.

#### 5.2.4. Rate Limiting

* Gerencia limites de requisições por cliente/IP/token.
* Implementa políticas de bloqueio temporário para clientes que excedem os limites.
* Fornece cabeçalhos HTTP informativos sobre os limites de taxa.

### 5.3. Estrutura de Diretórios

```
lib/deeper_hub_web/
├── api/
│   ├── v1/                 # Versionamento da API
│   │   ├── user_controller.ex
│   │   ├── server_controller.ex
│   │   └── ...
│   └── v2/                 # Versões futuras
│       └── ...
│
├── plugs/                  # Middlewares personalizados
│   ├── auth_api_token_plug.ex
│   └── ...
│
└── router.ex              # Definição de rotas e pipelines

api/         # Lógica de negócio da API
├── rate_limit/             # Lógica de limitação de taxa
│   ├── rate_limiter_facade.ex
│   ├── registry.ex
│   └── supervisor.ex
│
├── validation/            # Validação de requisições
│   ├── api_request_validator.ex
│   └── schemas/
│       ├── user_schemas.ex
│       └── ...
└── ...
```

### 5.4. Decisões de Design Importantes

* **API Stateless:** Todas as requisições contêm todas as informações necessárias para seu processamento.
* **Versionamento no Path:** Facilita a evolução da API sem quebrar clientes existentes.
* **Validação Rigorosa:** Todas as entradas são validadas o mais cedo possível.
* **Padronização de Respostas:** Formato consistente para todas as respostas (sucesso e erro).
* **Segurança como Prioridade:** Autenticação, autorização e rate limiting robustos.
* **Documentação Automática:** Geração de documentação interativa a partir do código.
* **Métricas e Monitoramento:** Coleta de métricas sobre o uso da API.

### 5.5. Exemplos de Uso

#### 5.5.1. Cliente Web Obtém Lista de Servidores

1. Frontend envia: `GET /api/v1/servers?tag=pvp&page=2`
2. Requisição passa por middlewares de autenticação e rate limiting
3. `ServerController.index/2` é chamado
4. Parâmetros são validados
5. Serviço de domínio é chamado: `DeeperHub.Servers.list_servers(%{tag: "pvp", page: 2})`
6. Resposta é formatada e retornada

#### 5.5.2. Aplicativo Mobile Cria Novo Usuário

1. App envia: `POST /api/v1/users` com dados do usuário
2. Middleware de validação verifica os dados
3. `UserController.create/2` processa a requisição
4. Serviço de domínio cria o usuário
5. Resposta de sucesso é retornada com o novo usuário

### 5.6. Respostas Padronizadas

Todas as respostas seguem um formato padronizado:

**Sucesso (200 OK):**
```json
{
  "status": "success",
  "data": { ... },
  "meta": { ... },
  "links": { ... }
}
```

**Erro (400 Bad Request):**
```json
{
  "status": "error",
  "error": {
    "code": "validation_error",
    "message": "Erro de validação",
    "details": { ... }
  }
}
```

**Erro de Autenticação (401 Unauthorized):**
```json
{
  "status": "error",
  "error": {
    "code": "unauthorized",
    "message": "Token de autenticação inválido ou expirado"
  }
}
```

### 5.7. Segurança

* **Autenticação:** Tokens JWT ou chaves de API
* **HTTPS:** Todas as comunicações devem usar HTTPS
* **Rate Limiting:** Proteção contra abusos
* **Validação de Entrada:** Prevenção contra injeção
* **CORS:** Configuração cuidadosa de origens permitidas
* **Headers de Segurança:** HSTS, X-Content-Type-Options, etc.

### 5.8. Monitoramento e Métricas

O módulo `DeeperHub.API.Metrics` coleta e expõe métricas sobre o uso da API:

* Número de requisições por endpoint
* Tempo de resposta
* Taxas de erro
* Uso de rate limiting

As métricas podem ser acessadas em `/metrics` (protegido por autenticação básica) e exportadas para ferramentas como Prometheus.

### 5.9. Melhores Práticas para Desenvolvedores

* Sempre documentar novos endpoints usando anotações OpenAPI
* Manter a consistência no formato das respostas
* Implementar testes automatizados para todos os endpoints
* Seguir as convenções de nomenclatura e estrutura de diretórios
* Considerar o versionamento ao fazer mudanças quebradoras
* Monitorar métricas de desempenho e uso

---

## 6. Gerenciamento de Contas de Usuário

O módulo `DeeperHub.Accounts` (e seu antigo intermediário `DeeperHub.Accounts.AccountManager`, agora refatorado para delegação direta a serviços) é a fachada principal para todas as operações relacionadas a contas de usuário.

*   **Ciclo de Vida do Usuário:**
    *   **Criação de Usuário:** Criar um novo usuário com atributos básicos (`create_user/1`).
    *   **Registro Completo de Usuário:** Registrar um novo usuário com perfil completo (`register_user/1`).
    *   **Obtenção de Usuário:** Buscar um usuário por ID (`get_user/1`) ou por email (`get_user_by_email/1`).
    *   **Listagem de Usuários:** Listar usuários com opções de filtro (status, etc.), paginação e ordenação (`list_users/1`).
    *   **Confirmação de Email:**
        *   Confirmar o endereço de email de um usuário usando um token (`confirm_email/2`).
        *   Reenviar email de verificação (`resend_verification_email/1`).
    *   **Atualização de Senha:** Atualizar a senha de um usuário, requerendo a senha atual (`update_password/3`).
    *   **Limpeza de Sessões:** Forçar a limpeza de sessões expiradas (`cleanup_sessions/0`).
*   **Gerenciamento de Perfis:**
    *   **Criação de Perfil:** Criar um perfil para um usuário existente (`create_profile/2`).
    *   **Obtenção de Perfil:** Obter o perfil de um usuário (`get_profile/1`).
    *   **Atualização de Perfil:** Atualizar os atributos do perfil de um usuário (`update_profile/2`).
    *   **Funções de Perfil (`DeeperHub.Accounts.Profile`):**
        *   Calcular idade com base na data de nascimento (`age/1`).
        *   Formatar nome de exibição (`display_name/1`).
        *   Formatar localização (`format_location/1`).
        *   Obter nome completo (`full_name/1`).
        *   Verificar se o perfil possui informações de localização (`has_location?/1`).
        *   Verificar se um perfil está completo (nome, sobrenome, data de nascimento) (`is_complete?/1`).
*   **Contadores e Estatísticas (`DeeperHub.Accounts.AccountManager`):**
    *   Contar usuários ativos (`count_active_users/0`).
    *   Contar contas bloqueadas (`count_locked_accounts/0`).
    *   Contar registros recentes em um período (`count_recent_registrations/1`).
*   **Disponibilidade de Email:**
    *   Verificar se um email está disponível para uso, opcionalmente ignorando o usuário atual (`is_email_available?/2` em `AccountManager`).
*   **Integração com Eventos:**
    *   O `DeeperHub.Accounts.Integrations.EventIntegration` publica eventos para o sistema DeeperHub Core sobre:
        *   Criação de usuário (`publish_user_created/3`).
        *   Atualização de usuário (`publish_user_updated/3`).
        *   Verificação de email (`publish_email_verified/3`).
        *   Redefinição de senha (`publish_password_reset/3`).
        *   Desativação de conta (`publish_account_deactivated/3`).
        *   Reativação de conta (`publish_account_reactivated/2`).
*   **Feature Flags para Contas (`DeeperHub.Accounts.FeatureFlags`):**
    *   Verificar se funcionalidades específicas de contas estão habilitadas, como:
        *   Registro de novos usuários (`registration_enabled?/1`, `self_registration_enabled?/1`).
        *   Login por senha (`password_login_enabled?/1`).
        *   Login social (`social_login_enabled?/2`).
        *   Verificação de email (`email_verification_enabled?/1`).
        *   Recuperação de senha (`password_recovery_enabled?/1`).
        *   Bloqueio de conta (`account_lockout_enabled?/1`).
        *   Cadastro e login com MFA (`mfa_enrollment_enabled?/2`, `mfa_login_enabled?/2`).
        *   Funcionalidade \"Lembrar-me\" (`remember_me_enabled?/1`).
*   **Serviços Internos Detalhados:**
    *   `DeeperHub.Accounts.Services.UserService`: Gerencia CRUD de usuários, confirmação de email e contadores.
    *   `DeeperHub.Accounts.Services.ProfileService`: Gerencia CRUD de perfis, avatares e preferências.
    *   `DeeperHub.Accounts.Services.RegistrationService`: Orquestra o fluxo completo de registro.
    *   `DeeperHub.Accounts.Services.PasswordService`: Gerencia hashing, comparação e atualização de senhas.
    *   `DeeperHub.Accounts.Services.EmailVerificationWorker`: Processa reenvios e lembretes de verificação de email.
    *   `DeeperHub.Accounts.Services.SessionCleanupWorker`: Limpa sessões expiradas periodicamente.

```

---

**Parte 3: Autenticação, Autorização e Segurança**

```markdown
## 7. Autenticação e Autorização

O `DeeperHub.Auth` (e sua fachada `DeeperHub.Auth.AuthFacade`) é o ponto central para autenticação e autorização.

*   **Autenticação de Usuário:**
    *   Autenticar um usuário com email/identificador e senha, com opções para IP, informações do dispositivo e metadados (`login/3`, `login/5`).
    *   Retorna dados do usuário e tokens de acesso/refresh.
*   **Gerenciamento de Sessão:**
    *   Criar uma nova sessão para um usuário, opcionalmente com IP e informações do dispositivo (`create_session/3`).
    *   Validar uma sessão existente pelo ID (`validate_session/1`).
    *   Encerrar uma sessão de usuário específica (`end_session/2`).
    *   Encerrar todas as sessões de um usuário (`logout/4` com `:revoke_all`).
*   **Gerenciamento de Token:**
    *   Atualizar tokens de acesso e refresh usando um token de refresh válido (`refresh_token/2`, `refresh_session_token/2`).
    *   Validar um token de acesso, retornando o ID do usuário se válido (`validate_token/1`).
    *   Validar um token de sessão (JWT), retornando ID da sessão, ID do usuário, papéis e claims (`validate_session_token/1` em `AuthFacade`).
    *   Revogar um token específico (`revoke_token/1`).
*   **Autorização (RBAC):**
    *   Verificar se um usuário tem permissão para acessar um recurso e realizar uma ação (`authorize/3`).
*   **Inicialização:** O módulo Auth pode ser inicializado para configurar caches e recursos (`init/0`).
*   **Adaptadores e Serviços Internos:**
    *   `DeeperHub.Auth.Adapters.AuthAdapterUnified`: GenServer unificado para autenticação, autorização e sessões.
    *   `DeeperHub.Auth.Adapters.AuthenticationAdapter`: Implementação padrão para autenticação.
    *   `DeeperHub.Auth.Adapters.AuthorizationAdapter`: Gerencia papéis e permissões (RBAC).
    *   `DeeperHub.Auth.Adapters.PasswordAdapter`: Lida com hashing e políticas de senha.
    *   `DeeperHub.Auth.Adapters.SessionAdapter`: Gerencia o ciclo de vida das sessões.
    *   `DeeperHub.Auth.Adapters.TokenAdapter`: Lida com geração e validação de JWTs.
    *   `DeeperHub.Auth.Services.LoginService`: Lógica de login primário.
    *   `DeeperHub.Auth.Services.SessionService`: Lógica de gerenciamento de sessões.
    *   `DeeperHub.Auth.Services.TokenService` (e `DeeperHub.Accounts.TokenService`): Gerencia tokens diversos (API, email, convite, reset de senha).
    *   `DeeperHub.Auth.PermissionService` e `DeeperHub.Auth.RoleService`: Gerenciam permissões e papéis detalhadamente.
*   **Integrações:**
    *   **Auditoria:** Eventos de autenticação são logados (`DeeperHub.Auth.Integrations.AuditIntegration`).
    *   **Eventos:** Publica eventos de login, logout, MFA, mudança de senha, criação/revogação de sessão/token (`DeeperHub.Auth.Integrations.EventIntegration`).
    *   **Rate Limiting:** Aplica limitação de taxa para endpoints de autenticação (`DeeperHub.Auth.RateLimitIntegration`).

---

## 8. Autenticação Multifator (MFA)

O `DeeperHub.MFA.MFAFacade` fornece a interface para o sistema de Autenticação Multifator.

*   **Gerenciamento de Métodos MFA:**
    *   Configurar um novo método MFA para um usuário (ex: TOTP, WebAuthn) (`setup_method/3`).
    *   Listar os métodos MFA habilitados para um usuário (`list_methods/1`).
    *   Remover um método MFA configurado (`remove_method/3`).
    *   Verificar se um método MFA específico está ativo para um usuário (`is_method_active?/2` no `MFAAdapter` ou `DefaultMFAService`).
*   **Verificação MFA:**
    *   Iniciar um processo de autenticação MFA, opcionalmente especificando um método (`start_authentication/3`).
    *   Verificar um código MFA fornecido pelo usuário (ex: código TOTP) (`verify_code/3`).
*   **Códigos de Recuperação:**
    *   Gerar novos códigos de recuperação para um usuário (`generate_recovery_codes/2`).
    *   Verificar um código de recuperação MFA (`verify_recovery_code/2`).
    *   Contar códigos de recuperação disponíveis/não utilizados (`RecoveryCodeService.count_available/1`, `count_unused_codes/1`).
    *   Invalidar todos os códigos de recuperação de um usuário (`RecoveryCodeService.invalidate_all_codes/1`).
*   **Status e Preferências:**
    *   Verificar se o MFA está globalmente habilitado para um usuário (`is_mfa_enabled?/1`).
    *   Obter e atualizar as preferências de MFA de um usuário (`get_user_preferences/1`, `update_user_preferences/2` nos serviços internos).
*   **Estatísticas e Conformidade:**
    *   Obter estatísticas de uso do MFA (`get_mfa_statistics/1`).
    *   Verificar o status de conformidade MFA de um usuário com as políticas (`check_compliance_status/2`).
    *   Verificar em lote a conformidade MFA de múltiplos usuários (`MFANotificationIntegration.batch_check_and_notify/2`).
    *   Agendar verificações periódicas de conformidade MFA (`MFANotificationIntegration.schedule_periodic_checks/1`).
*   **Integrações:**
    *   **Middleware HTTP:** `DeeperHub.MFA.MFAMiddleware` para integrar fluxos MFA em aplicações web.
    *   **Serviços Específicos:**
        *   `DeeperHub.MFA.Services.TOTPService`: Para autenticação TOTP.
        *   `DeeperHub.MFA.Services.WebAuthnService`: Para integração com WebAuthn.
        *   `DeeperHub.MFA.Services.PushVerificationService`: Para verificação via notificações push.
        *   `DeeperHub.MFA.Services.MFAPolicyService`: Para aplicar políticas de MFA.
    *   **Anomalias:** Integração com detector de anomalias para eventos MFA (`MFAAnomalyIntegration`).
    *   **Notificações:** Envio de notificações para eventos de conformidade MFA (`MFANotificationIntegration`).
    *   **Telemetria:** Monitoramento de desempenho e uso do sistema MFA (`DeeperHub.MFA.Telemetry`).

---

## 9. Autenticação OAuth

O sistema (`Elixir.DeeperHub.OAuth.OAuthFacadeUnified` e `Elixir.DeeperHub.OAuth.OAuthCompatibility`) permite integração com provedores OAuth externos.

*   **Fluxo de Autenticação OAuth:**
    *   Gerar a URL de autorização para um provedor OAuth (`authorize_url/2,3`).
    *   Trocar o código de autorização (recebido do provedor) por tokens de acesso e refresh (`exchange_code/3`).
    *   Obter informações do usuário do provedor OAuth usando o token de acesso (`get_user_info/2`).
    *   Autenticar um usuário no DeeperHub usando as informações e tokens do provedor (`authenticate/4`).
*   **Gerenciamento de Contas Vinculadas:**
    *   Vincular uma conta de provedor externo a um usuário DeeperHub existente (`link_account/4`).
    *   Listar todas as contas de provedores externos vinculadas a um usuário (`list_linked_accounts/1`).
    *   Remover a vinculação de uma conta externa (`unlink_account/2`).
*   **Infraestrutura:**
    *   **Cache:** Cache para informações de usuário obtidas de provedores OAuth (`DeeperHub.OAuth.Cache.UserInfoCache`).
    *   **Comunicação Segura com APIs OAuth:** Utiliza Circuit Breaker para chamadas aos endpoints dos provedores (`DeeperHub.OAuth.Integrations.OAuthApiIntegration`).
    *   **Eventos:** Publica eventos sobre vinculação/desvinculação de contas, autenticações e atualização de tokens (`DeeperHub.OAuth.Integrations.EventIntegration`).
    *   **Telemetria:** Monitoramento de eventos e métricas relacionadas ao OAuth (`DeeperHub.OAuth.Telemetry`).

---

## 10. Autenticação WebAuthn (FIDO2)

O `DeeperHub.WebAuthn.WebAuthnFacade` (e `DeeperHub.WebAuthn`) oferece suporte à autenticação sem senha usando o padrão WebAuthn.

*   **Registro de Credenciais:**
    *   Iniciar o processo de registro de uma nova credencial WebAuthn para um usuário, gerando opções para o cliente (navegador/dispositivo) (`begin_registration/3`).
    *   Completar o processo de registro após receber a resposta de atestação do cliente (`complete_registration/2`).
*   **Autenticação:**
    *   Iniciar o processo de autenticação WebAuthn para um usuário, gerando opções para o cliente (`begin_authentication/2`).
    *   Completar o processo de autenticação após receber a resposta de asserção do cliente (`complete_authentication/2`).
*   **Gerenciamento de Credenciais:**
    *   Listar todas as credenciais WebAuthn registradas por um usuário (`list_credentials/1`).
    *   Remover uma credencial WebAuthn específica de um usuário (`remove_credential/2`).
*   **Cache:** O sistema utiliza cache para otimizar operações WebAuthn (`init_cache/0`).
*   **Verificação de Prontidão:** Verificar se o módulo WebAuthn está pronto para uso (`ready?/0`).

```

---

**Parte 4: Recuperação de Contas, Políticas de Sessão e Segurança Abrangente**

```markdown
## 11. Recuperação de Contas

O `DeeperHub.Recovery.RecoveryFacade` (e sua versão unificada) gerencia os processos de recuperação de conta.

*   **Recuperação de Senha:**
    *   Iniciar o processo de recuperação de senha para um email, enviando um token de recuperação (`forgot_password/1`, `request_password_reset/1,2`).
    *   Verificar se um token de recuperação de senha é válido (`verify_reset_token/1`).
    *   Redefinir a senha de um usuário usando um token de recuperação válido e a nova senha (`reset_password/3`).
*   **Verificação de Email:**
    *   Enviar um email de verificação para um usuário contendo um token (`send_verification_email/1,3`).
    *   Verificar um email usando um token de verificação válido (`verify_email/1`).
*   **Disponibilidade de Email:**
    *   Verificar se um endereço de email já está registrado no sistema (`is_email_available?/1,2`).
*   **Monitoramento e Segurança:**
    *   Obter a idade de tokens de verificação/recuperação (`EmailVerificationAdapter.get_token_age/1`, `PasswordResetAdapter.get_token_age/1`).
    *   **Auditoria:** Eventos de recuperação (solicitações, redefinições, validação de tokens, bloqueios) são logados (`DeeperHub.Recovery.Integrations.AuditIntegration`).
    *   **Eventos:** Publicação de eventos sobre geração de tokens, verificação de tokens e conclusão de redefinição de senha (`DeeperHub.Recovery.Integrations.EventIntegration`).
    *   **Rate Limiting:** Aplica limitação de taxa para endpoints de recuperação de conta e verificação de email (`DeeperHub.Recovery.RateLimitIntegration`).
    *   **Telemetria:** Monitoramento de eventos e métricas relacionadas à recuperação de contas (`DeeperHub.Recovery.Telemetry`).

---

## 12. Políticas de Sessão

O `DeeperHub.SessionPolicy.SessionPolicyFacade` (e sua versão unificada) gerencia as políticas de sessão para controlar o comportamento das sessões de usuário.

*   **Gerenciamento de Políticas:**
    *   Obter a política de sessão padrão global do sistema (`get_default_policy/1`).
    *   Definir a política de sessão padrão global (`set_default_policy/2`).
    *   Obter a política de sessão para uma entidade específica (usuário, grupo) (`get_policy/3`).
    *   Definir uma política de sessão para uma entidade específica (`set_policy/4`).
*   **Validação de Sessão:**
    *   Validar se uma sessão está de acordo com as políticas aplicáveis (duração máxima, inatividade, MFA, IPs/países permitidos, etc.) (`validate_session/2`).
*   **Tempo de Sessão:**
    *   Calcular o tempo restante de uma sessão com base nas políticas (`calculate_remaining_time/2`).
*   **Exceções de Política:**
    *   Criar uma exceção a uma política para um usuário específico, permitindo configurações personalizadas temporárias ou permanentes (`create_exception/4`).
*   **Gerenciamento de Sessões Concorrentes (`DeeperHub.SessionPolicy.SessionPolicyService`):**
    *   Adicionar ou atualizar uma exceção de política de sessão para um usuário (`add_exception/2`).
    *   Aplicar estratégias de gerenciamento quando o limite de sessões é atingido (ex: bloquear nova, terminar mais antiga) (`apply_strategy/3`).
    *   Verificar se uma nova sessão é permitida para um usuário com base no limite de sessões concorrentes (`check_session_allowed/2`).
    *   Listar e remover exceções de política (`get_exception/1`, `list_exceptions/0`, `remove_exception/1`).
    *   Listar estratégias de gerenciamento de sessões disponíveis (`list_strategies/0`).
*   **Inicialização:** Configurar o serviço de política de sessão (`setup/0`).

---

## 13. Sistema de Segurança Abrangente

O DeeperHub possui um módulo de Segurança (`DeeperHub.Security`) robusto e multifacetado, gerenciado centralmente pelo `DeeperHub.Security.SecurityManager` e exposto pela `DeeperHub.Security.SecurityFacade`.

### 13.1. Gerenciamento de Dispositivos e Localização

*   **Gerenciamento de Dispositivos (`DeeperHub.Security.SecurityManager.Services.DeviceService`, `DeeperHub.Security.DeviceFingerprint`):**
    *   Registrar um novo dispositivo para um usuário, incluindo informações de fingerprint (`register_device/2`).
    *   Listar dispositivos registrados para um usuário (`list_devices/1`).
    *   Marcar um dispositivo como confiável (`trust_device/2`).
    *   Verificar se um dispositivo é confiável (`is_trusted_device?/2`).
    *   Remover a marcação de confiável de um dispositivo (`untrust_device/2`).
    *   Bloquear um dispositivo específico (`block_device/3`).
    *   Desbloquear um dispositivo (`unblock_device/1` no `DeviceService`).
    *   Atualizar informações de último uso (IP, timestamp) de um dispositivo.
    *   Gerar e comparar fingerprints de dispositivos.
    *   Detectar anomalias comparando fingerprints atuais com históricos.
*   **Verificação de Localização (`DeeperHub.Security.GeoLocationService`, `DeeperHub.LoginLocation`):**
    *   Obter informações de geolocalização a partir de um endereço IP (`get_location/1,2`).
    *   Avaliar o risco de uma localização com base em fatores de segurança (`assess_location_risk/3`).
    *   Detectar \"viagens impossíveis\" comparando localizações e tempos (`is_impossible_travel?/3`).
    *   Registrar localizações de login de usuários para análise (`register_user_location/2`, `track_login/3`).
    *   Listar localizações de login de um usuário (`list_user_locations/2`).
    *   Marcar localizações como confiáveis (`mark_trusted/2`).
    *   Analisar padrões de login de um usuário (`analyze_pattern/2`).
    *   Verificar se uma localização é suspeita (`check_suspicious/2`).
    *   Integração com serviços de GeoIP com Circuit Breaker (`GeoIPServiceWithCircuitBreaker`).

### 13.2. Firewall de IP (`DeeperHub.Security.Services.IpFirewallService`, `DeeperHub.Security.Config.IPFirewallConfig`)

*   **Bloqueio e Permissão de IPs:**
    *   Bloquear IPs temporária ou permanentemente, com motivo (`block_ip/3,4`).
    *   Permitir IPs temporária ou permanentemente (`allow_ip/4`).
    *   Verificar se um IP está bloqueado ou permitido (`is_ip_blocked?/1`, `is_allowed?/1`).
    *   Listar IPs bloqueados e permitidos (temporários e permanentes).
    *   Remover IPs das listas de bloqueio/permissão.
*   **Configuração e Automação:**
    *   Configurar duração padrão para bloqueios/permissões e intervalo de limpeza.
    *   Habilitar/desabilitar bloqueio automático.
    *   Definir número máximo de tentativas falhas antes do bloqueio automático e duração do bloqueio.
*   **Integração com Phoenix:**
    *   Um Plug (`DeeperHub.Security.Plugs.IPFirewallPlug`) para aplicar o firewall de IP diretamente no pipeline do router Phoenix.
*   **Cache:** Utiliza cache para verificações rápidas (`DeeperHub.Security.Cache.SecurityCache`).
*   **Telemetria:** Eventos de bloqueio/permissão de IP são registrados (`DeeperHub.Security.Telemetry.IPFirewallTelemetry`).

### 13.3. Proteção Contra Ataques Específicos

*   **Proteção Contra Força Bruta (`DeeperHub.Security.BruteForceProtection`, `DefaultBruteForceProtectionService`):**
    *   Verificar se uma tentativa de acesso é permitida, requer CAPTCHA ou está bloqueada (`check_attempt/2`).
    *   Registrar tentativas de acesso falhas e bem-sucedidas (`record_failed_attempt/2`, `record_successful_attempt/1`).
    *   Limpar o histórico de tentativas para um identificador (`clear_attempts/1`).
    *   Verificar se um identificador está bloqueado ou requer CAPTCHA.
    *   Obter estatísticas sobre tentativas e bloqueios.
    *   Limpeza periódica de dados antigos de tentativas (`BruteForceProtection.Workers.CleanupWorker`).
*   **Proteção Contra CSRF (`DeeperHub.Security.CsrfProtection`, `CSRFProtectionCompatibility`):**
    *   Gerar tokens CSRF para sessões (`generate_token/2`).
    *   Gerar campos de formulário HTML com tokens CSRF (`form_field/2`).
    *   Gerar cabeçalhos de segurança com tokens CSRF (`security_headers/2`).
    *   Validar tokens CSRF para sessões (`validate_token/3`).
    *   Verificar se uma requisição HTTP tem proteção CSRF válida (`verify_request/3`).
    *   Invalidar tokens CSRF para uma sessão (`invalidate_tokens/1`, `invalidate_all_tokens/2`).
    *   Registrar e obter estatísticas de tentativas de CSRF.
*   **Proteção Contra Injeção de SQL (`DeeperHub.Security.SqlInjectionProtection`, `SQLInjectionProtectionCompatibility`):**
    *   Verificar se uma consulta SQL ou uma string contém padrões de injeção (`check_query/2`, `check_string/2`).
    *   Sanitizar strings e consultas SQL para remover padrões de injeção (`sanitize_string/2`).
    *   Parametrizar consultas SQL para evitar injeção (`parameterize/3`).
    *   Gerar consultas SQL seguras a partir de especificações (`generate_safe_query/2`).
    *   Validar parâmetros para uso seguro em consultas SQL (`validate_params/2`).
    *   Registrar e obter estatísticas de tentativas de injeção SQL.
*   **Proteção Contra Path Traversal (`DeeperHub.Security.PathTraversalProtection`):**
    *   Verificar se um caminho contém tentativas de path traversal (`check_path/2`).
    *   Sanitizar caminhos removendo tentativas de path traversal (`sanitize_path/2`).
    *   Normalizar caminhos removendo redundâncias (`normalize_path/2`).
    *   Verificar se um caminho está dentro de um diretório base permitido (`verify_path_in_base/3`).
    *   Configurar diretórios base permitidos (`configure_allowed_dirs/1`).
    *   Registrar e obter estatísticas de tentativas de path traversal.
*   **Proteção Contra XSS (`DeeperHub.Security.XssProtection`):**
    *   Verificar se uma string contém padrões de XSS (`check_string/2`).
    *   Sanitizar strings e conteúdo HTML para remover scripts e atributos perigosos (`sanitize_string/2`, `sanitize_html/2`).
    *   Gerar cabeçalhos de segurança para proteção contra XSS (`security_headers/1`).
    *   Validar parâmetros para uso seguro em saídas HTML (`validate_params/2`).
    *   Registrar e obter estatísticas de tentativas de XSS.
*   **Proteção Contra DDoS (`DeeperHub.Security.DdosProtection`):**
    *   Registrar requisições para controle de taxa (`record_request/3`).
    *   Verificar se uma requisição deve ser permitida, limitada ou bloqueada (`check_request/3`).
    *   Bloquear/desbloquear IPs (`block_ip/3`, `unblock_ip/1`).
    *   Configurar limites de taxa por caminho (`configure_rate_limit/3`).
    *   Obter estatísticas de requisições e bloqueios.
    *   Ativar/desativar modo de proteção avançada (`set_advanced_protection/2`).

### 13.4. Detecção de Fraude (`DeeperHub.Security.FraudDetection`, `FraudDetection.Core`)

*   **Análise de Risco em Operações:**
    *   Analisar tentativas de login (`analyze_login/1`).
    *   Analisar mudanças de perfil de usuário (`analyze_profile_change/1`).
    *   Analisar transações financeiras ou críticas (`analyze_transaction/1`).
    *   Analisar uso de API (`analyze_api_usage/1`).
    *   Analisar anomalias biométricas (`analyze_biometric_anomaly/1`).
*   **Gerenciamento de Detecções:**
    *   Obter detalhes de uma detecção específica (`get_detection/1`).
    *   Listar detecções com filtros avançados (tipo, nível de risco, status, usuário, datas) (`list_detections/1`).
    *   Atualizar o status de uma detecção (ex: revisado, resolvido) e adicionar notas (`update_detection_status/4`, `add_detection_notes/3`).
*   **Gerenciamento de Regras (`DeeperHub.Security.FraudDetection.Services.RulesManagerService`):**
    *   Adicionar, remover e atualizar regras de detecção de fraude por tipo de operação.
    *   Obter todas as regras ou regras para um tipo específico.
    *   Exportar e importar regras em formatos como JSON/YAML.
    *   Resetar regras para os valores padrão.
*   **Cálculo de Risco (`DeeperHub.Security.FraudDetection.Services.RiskCalculatorService`):**
    *   Calcular níveis de risco para diferentes tipos de operações (login, mudança de perfil, transação, uso de API, anomalia biométrica).
    *   Atualizar regras de cálculo de risco.
*   **Notificações de Fraude (`DeeperHub.Security.FraudDetection.Services.FraudNotifierService`):**
    *   Notificar sobre detecções específicas, com base no nível de risco.
    *   Notificar equipe de segurança e usuários afetados.
    *   Enviar resumos diários de atividades de fraude.
*   **Estatísticas e Relatórios:**
    *   Obter estatísticas de detecção (`get_detection_statistics/1`).
    *   Gerar relatórios de segurança com base nas detecções.
*   **Workers de Suporte:**
    *   `AnalysisWorker`: Executa análises periódicas de padrões de fraude.
    *   `CleanupWorker`: Limpa dados antigos do sistema de detecção de fraude.
*   **Telemetria:** Monitoramento de eventos e métricas relacionadas à detecção de fraude (`DeeperHub.Security.FraudDetection.Telemetry`).

### 13.5. Avaliação de Risco (`DeeperHub.Security.RiskAssessment.RiskAssessmentFacade`)

*   **Avaliação de Risco de Operações:**
    *   Avaliar o risco de uma operação genérica, login, transação, mudança de perfil, requisição API ou sessão (`evaluate_risk/3`, `assess_action_risk/4`, etc.).
    *   Realizar uma verificação rápida de risco, retornando apenas o nível (`quick_risk_check/3`).
*   **Gerenciamento de Perfil de Risco:**
    *   Obter e atualizar o perfil de risco de um usuário (`get_risk_profile/2`, `update_risk_profile/3`).
    *   Obter histórico de avaliações de risco (`get_risk_assessment_history/3`).
*   **Ações e Recomendações:**
    *   Verificar se uma operação é permitida com base no nível de risco (`is_operation_allowed/4`).
    *   Recomendar ações de segurança com base na avaliação de risco (`recommend_actions/3` no `RiskActionRecommender`).
*   **Configuração e Calibração:**
    *   Configurar fatores de risco avançados (`configure_advanced_factors/1`).
    *   Calibrar pesos dos fatores de risco com base no histórico (`calibrate_risk_weights/2` no `RiskWeightCalibrator`).
*   **Relatórios e Estatísticas:**
    *   Gerar relatórios de risco (`generate_risk_report/3`).
    *   Obter estatísticas de risco (`get_risk_statistics/2`, `get_stats/0`).
    *   Obter relatórios de métricas de risco (`get_metrics_report/1`).
*   **Telemetria:** Monitoramento de eventos e métricas relacionadas à avaliação de risco (`DeeperHub.Security.RiskAssessment.Telemetry`).

### 13.6. Análise Comportamental (`DeeperHub.Security.BehavioralAnalysis.Adapters.BehavioralAnalysisAdapter`)

*   **Análise de Comportamento:**
    *   Analisar o comportamento recente de um usuário em busca de anomalias (`analyze_user_behavior/2`).
    *   Comparar o comportamento atual com o perfil comportamental estabelecido (`compare_with_profile/3`).
    *   Detectar anomalias em tempo real com base em eventos (`detect_realtime_anomaly/3`).
*   **Detecção de Padrões:**
    *   Detectar padrões temporais (horários de login, duração de sessão) no comportamento do usuário (`detect_temporal_patterns/2`).
    *   Detectar padrões de dispositivos, localização, navegação e transações (`PatternAnalysisService`).
*   **Gerenciamento de Perfil Comportamental:**
    *   Obter e atualizar o perfil comportamental de um usuário (`get_user_profile/2`, `update_user_profile/2`).
    *   Registrar eventos de comportamento do usuário para análise (`record_behavior_event/4`).
*   **Relatórios e Estatísticas:**
    *   Gerar relatórios de análise comportamental (`generate_behavior_report/2`).
    *   Obter estatísticas sobre análises comportamentais (`get_statistics/1`).
*   **Telemetria:** Monitoramento de eventos e métricas relacionadas à análise comportamental (`DeeperHub.Security.BehavioralAnalysis.Telemetry`).

### 13.7. Outras Funcionalidades de Segurança

*   **Autenticação de Administradores (`DeeperHub.Security.AdminAuth.AdminAuthAdapter`):**
    *   Autenticação, gerenciamento de senhas, contas, permissões e tokens para administradores.
    *   Suporte a TOTP para ações administrativas (`AdminTOTPService`).
    *   Log de ações administrativas (`AdminActionAuthService`).
*   **Criptografia em Repouso (`DeeperHub.Security.AtRestEncryptionService`):**
    *   Criptografar e descriptografar dados sensíveis armazenados.
    *   Rotação de chaves e recriptografia de dados.
*   **Mascaramento de Dados (`DeeperHub.Security.DataMasking.DataMaskingFacade`):**
    *   Mascarar dados sensíveis (CPF, cartão de crédito, email, telefone) para logs e exibição.
*   **Monitoramento de Segurança (`DeeperHub.Security.Monitoring.SecurityMonitoringFacade`):**
    *   Registrar eventos de segurança, gerar alertas e configurar canais de notificação para ameaças.
*   **Validação de Entradas de Segurança (`DeeperHub.Security.Validation.SecurityInputValidation`):**
    *   Validar configurações de políticas de segurança (firewall de IP, MFA, senha, rate limit).
*   **Políticas de Segurança (`DeeperHub.Security.Policy.SecurityPolicyManager`):**
    *   Gerenciar centralmente todas as configurações de segurança com controle de acesso RBAC.
*   **Integrações de Segurança:**
    *   Integração com Cache, Eventos e RBAC para diversos módulos de segurança.
    *   Integração entre Risco, Autenticação e Fraude (`RiskAuthIntegration`, `RiskFraudIntegration`, `RiskNotificationIntegration`).
*   **Telemetria Geral de Segurança:** O `DeeperHub.Security.Telemetry` registra métricas de diversos componentes de segurança.
*   **Feature Flags de Segurança:** `DeeperHub.Security.FeatureFlags` permite habilitar/desabilitar dinamicamente proteções.
```

---

**Parte 5: Feature Flags, Auditoria, Notificações e Webhooks**

```markdown
## 14. Gerenciamento de Feature Flags

O DeeperHub utiliza um sistema de Feature Flags (`DeeperHub.FeatureFlags.FeatureFlagFacade`, `FeatureFlagUnifiedFacade`, e adaptadores) para controlar o lançamento de funcionalidades de forma dinâmica.

*   **Gerenciamento de Flags:**
    *   Registrar novas feature flags com descrição e opções (`register_feature/3`).
    *   Remover o registro de feature flags (`unregister_feature/2`).
    *   Listar todas as features registradas (`list_features/1`).
    *   Obter informações sobre uma flag específica (`get_flag/1`).
*   **Controle de Estado das Flags:**
    *   Habilitar ou desabilitar uma feature flag para um contexto específico (usuário, grupo, etc.) (`enable/3`, `disable/3`).
    *   Habilitar ou desabilitar uma feature flag globalmente, com rastreamento do administrador (`enable_globally/3`, `disable_globally/3`).
*   **Verificação de Flags:**
    *   Verificar se uma feature está habilitada para um contexto específico (`enabled?/3`, `is_enabled?/3`).
    *   Verificar se uma feature está habilitada globalmente (`enabled_globally?/1`).
    *   Verificar se uma feature está habilitada para um usuário específico (`FeatureFlagExtensions.enabled_for_user?/3`).
*   **Execução Condicional:**
    *   Executar uma função apenas se uma feature estiver habilitada para um contexto ou usuário, com opção de fallback (`FeatureFlagExtensions.with_feature/4`, `with_feature_for_user/5`).
*   **Integrações e Extensões:**
    *   **Cache:** Cache otimizado para acesso rápido a flags (`DeeperHub.FeatureFlags.Cache.FlagCache`).
    *   **RBAC:** Integrar controle de acesso a features com base em papéis de usuário (`DeeperHub.FeatureFlags.Integrations.RBACIntegration`).
        *   Conceder/revogar acesso a features para papéis.
        *   Conceder/revogar acesso temporário a features para usuários.
    *   **Auditoria:** Registrar eventos de gerenciamento de flags (criação, habilitação/desabilitação, etc.) (`DeeperHub.FeatureFlags.Integrations.AuditIntegration`).
    *   **Eventos:** Publicar eventos quando flags são criadas, atualizadas ou regras são modificadas (`DeeperHub.FeatureFlags.Integrations.EventIntegration`).
    *   **Domínio:** Flags específicas para módulos de domínio (`DeeperHub.Domain.FeatureFlags` e seus submódulos).
*   **Telemetria:** Monitorar uso, desempenho e erros do sistema de feature flags (`DeeperHub.FeatureFlags.Telemetry`).
*   **Inicialização:** O sistema de feature flags possui um inicializador para registrar features padrão e configurar integrações (`DeeperHub.FeatureFlags.Initializer`).

---

## 15. Sistema de Auditoria

O `DeeperHub.Audit.AuditFacade` fornece uma interface para registrar e consultar eventos de auditoria, garantindo rastreabilidade das ações no sistema.

*   **Registro de Eventos:**
    *   Registrar um evento de auditoria genérico com ID do usuário, tipo de evento, detalhes e opções (IP, user agent, severidade) (`log_event/4`).
    *   Registrar um evento de segurança específico (`log_security_event/3`).
    *   Registrar um evento de sistema (ex: startup, shutdown) (`log_system_event/2`).
*   **Registro de Eventos de Negócio com Rastreamento (`DeeperHub.Audit.Integrations.AuditIntegration`):**
    *   Iniciar um trace para operações de negócio complexas (`start_business_trace/2`).
    *   Registrar operações de negócio dentro de um trace (`log_business_operation/5`).
    *   Finalizar um trace de operação de negócio (`end_business_trace/3`).
    *   Gerenciar o ID do trace atual no contexto do processo.
*   **Registro Detalhado por Módulo (`DeeperHub.Audit.Integrations.AuditIntegration.*`):**
    *   **API:** Log de requisições, respostas, erros, rate limiting e mudanças de configuração da API.
    *   **Contas:** Log de criação, desativação, atualização de contas e mudanças de perfil.
    *   **Aplicação:** Log de reinício da aplicação e mudanças no modo de depuração.
    *   **Autenticação:** Log de tentativas de login, logout, eventos MFA e alterações de senha.
    *   **Integrações Externas:** Log de conexões, sincronizações de dados, webhooks recebidos e erros.
    *   **Notificações:** Log de envio, entrega, leitura e falhas de notificações.
    *   **Recursos:** Log de criação, acesso, atualização e exclusão de recursos.
    *   **Segurança (RBAC):** Log de alterações de permissões, papéis e detecções de fraude.
    *   **Sistema:** Log de erros críticos, tarefas agendadas, inicialização e desligamento.
*   **Consulta e Exportação:**
    *   Buscar eventos de auditoria com base em filtros (usuário, tipo de evento, intervalo de datas) e opções de paginação/ordenação (`search_events/2`).
    *   Exportar eventos de auditoria para formatos como CSV ou JSON, com filtros e opções (`export_events/3`).
*   **Estatísticas:**
    *   Obter estatísticas de eventos de auditoria para um período, com filtros (`get_statistics/2`). Resultados cacheados para performance.
*   **Detecção de Anomalias (`DeeperHub.Audit.Services.AuditAnomalyDetector`, `AnomalyBatchProcessor`, `AnomalyEventIntegration`, `AnomalyNotificationIntegration`):**
    *   Analisar logs de auditoria para detectar anomalias de frequência, padrão e comportamentais (incluindo com ML).
    *   Processar anomalias detectadas em lote.
    *   Publicar eventos de anomalias detectadas.
    *   Integrar com o sistema de notificações para alertar sobre anomalias.
*   **Gerenciamento de Logs:**
    *   **Armazenamento:** Serviço para gerenciar armazenamento, compressão, arquivamento e limpeza de logs antigos (`DeeperHub.Audit.Services.AuditStorageService`).
    *   **Retenção:** Aplicar políticas de retenção para arquivar ou excluir logs antigos (`DeeperHub.Audit.Policies.RetentionPolicy`).
    *   **Agendamento:** Agendador para executar políticas de retenção periodicamente (`DeeperHub.Audit.Scheduler.RetentionScheduler`).
*   **Relatórios (`DeeperHub.Audit.Services.AuditReportingService`, `AuditReportFormatter`, `AuditReportWorker`):**
    *   Gerar relatórios de atividade de usuários, anomalias, segurança e atividade de recursos.
    *   Suporte a diferentes formatos (JSON, CSV, HTML, PDF).
    *   Geração assíncrona de relatórios.
*   **Feature Flags de Auditoria (`DeeperHub.Audit.FeatureFlags`):**
    *   Controlar tipos de detecção de anomalias, formatos de exportação e integrações.
*   **Telemetria:** Coletar métricas e instrumentar operações de auditoria (`DeeperHub.Audit.Telemetry`).
*   **Workers Internos:**
    *   `AuditLogWorker`: Processamento assíncrono de logs.
    *   `SecurityEventWorker`: Processamento e análise de eventos de segurança.

---

## 16. Notificações

O sistema de notificações (`DeeperHub.Notifications.NotificationFacade`, `DeeperHub.Core.NotificationsFacade`, e suas versões unificadas) permite enviar mensagens para usuários através de diversos canais.

*   **Envio de Notificações:**
    *   Enviar notificações para um usuário específico, com título, mensagem e opções (tipo, prioridade, metadados) (`send_notification/4`).
    *   Enviar notificações em massa para múltiplos usuários (`send_bulk_notification/4`).
    *   Agendar notificações para envio futuro (`schedule_notification/5`).
    *   Cancelar notificações agendadas (`cancel_scheduled_notification/1`).
*   **Tipos de Notificação Específicos (`DeeperHub.Notifications`):**
    *   Notificar sobre login na conta (`notify_login/3`).
    *   Notificar sobre acesso de novo dispositivo (`notify_new_device/3`).
    *   Notificar sobre acesso de nova localização (`notify_new_location/3`).
    *   Notificar sobre mudança de senha (`notify_password_change/3`).
    *   Notificar sobre mudança de email (`notify_email_change/3`).
    *   Notificar sobre ativação/desativação de MFA (`notify_mfa_enabled/3`, `notify_mfa_disabled/3`, `notify_mfa_change/3`).
    *   Notificar sobre bloqueio de conta (`notify_account_locked/3`).
    *   Notificar sobre alertas de segurança (`notify_security_alert/5`).
*   **Gerenciamento de Notificações do Usuário:**
    *   Obter notificações não lidas de um usuário (`get_unread_notifications/2`).
    *   Marcar uma notificação como lida (`mark_notification_as_read/2`).
    *   Obter histórico de notificações de um usuário com filtros e paginação (`HistoryService.get_notification_history/4`).
    *   Exportar histórico de notificações (`HistoryService.export_notification_history/4`).
    *   Obter estatísticas de notificações de um usuário (`HistoryService.get_notification_stats/2`).
*   **Preferências de Notificação (`DeeperHub.Notifications.Services.PreferencesService`):**
    *   Obter e atualizar as preferências de notificação de um usuário (`get_notification_preferences/1`, `update_notification_preferences/2`).
    *   Desativar ou ativar todas as notificações para um usuário (`disable_all_notifications/1`, `enable_all_notifications/2`).
    *   Verificar se um usuário deve receber um tipo específico de notificação (`should_receive_notification?/3`).
*   **Canais de Notificação (`DeeperHub.Notifications.Channels.*`):**
    *   Suporte a múltiplos canais: Email, In-App, Push.
    *   Lógica específica para cada canal (ex: `InAppChannel.list_unread/2`).
*   **Templates e Internacionalização:**
    *   Gerenciamento de templates para emails e outras notificações (`DeeperHub.Notifications.Templates.TemplateManager`).
    *   Suporte a traduções para templates (`DeeperHub.Notifications.Templates.I18n.Translator`).
*   **Infraestrutura e Integrações:**
    *   **Cache:** Cache para preferências de usuário e templates (`PreferencesCache`, `TemplateCache`).
    *   **Auditoria:** Log de envio, leitura e falhas de notificações (`DeeperHub.Notifications.Integrations.AuditIntegration`).
    *   **Eventos:** Publicação de eventos sobre envio, leitura, falhas e atualização de preferências (`DeeperHub.Notifications.Integrations.EventIntegration`).
    *   **Tarefas em Segundo Plano:** Notificações para eventos de tarefas em segundo plano (`BackgroundTasksNotificationIntegration`).
    *   **Feature Flags:** Notificações para eventos de gerenciamento de feature flags (`FeatureFlagsNotificationIntegration`).
    *   **Fraude:** Notificações para detecções de fraude e ações relacionadas (`FraudNotificationIntegration`).
    *   **Recuperação de Conta:** Notificações para eventos de recuperação de senha e verificação de email (`RecoveryNotificationIntegration`).
    *   **Webhooks:** Notificações para eventos de gerenciamento de webhooks (`WebhooksNotificationIntegration`).
    *   **Tokens:** Notificações para eventos relacionados a tokens de autenticação (`TokenNotifications`).
*   **Workers:**
    *   `EmailWorker`, `InAppWorker`, `PushWorker`: Processamento assíncrono para cada canal.
    *   `MetricsWorker`: Coleta periódica de métricas de notificação.
    *   `RetentionWorker`: Limpeza de notificações antigas.
    *   `ScheduledNotificationWorker`: Processamento de notificações agendadas.
*   **Telemetria:** Coleta de métricas de desempenho do sistema de notificações (`DeeperHub.Notifications.Telemetry`).

---

## 17. Webhooks

O `DeeperHub.Webhooks.WebhooksFacade` (e `DeeperHub.Webhooks`) gerencia webhooks para integrações externas.

*   **Gerenciamento de Webhooks:**
    *   Registrar um novo webhook para um tipo de evento, URL de destino, headers e segredo opcionais (`register_webhook/5`, `register_client_webhook/4`).
    *   Atualizar um webhook existente (`update_webhook/2`).
    *   Remover um webhook (`delete_webhook/1`).
    *   Obter um webhook pelo ID (`get_webhook/1`).
    *   Listar webhooks, opcionalmente por tipo de evento ou com filtros (`list_webhooks/2`).
*   **Disparo de Webhooks:**
    *   Disparar todos os webhooks registrados para um tipo de evento com um payload (`trigger_event/3`).
    *   Disparar manualmente um webhook específico (`trigger_webhook/3`).
    *   Funções específicas para disparar eventos de API, usuário, segurança ou customizados.
*   **Segurança e Confiabilidade:**
    *   Verificar a assinatura de um payload recebido usando um segredo compartilhado (`verify_signature/3`).
    *   Gerar cabeçalhos de assinatura para payloads de webhooks (`PayloadSigner.generate_signature_headers/3`).
    *   **Dispatcher com Circuit Breaker:** Envio de webhooks para endpoints externos com proteção contra falhas (`DispatcherWithCircuitBreaker`).
        *   Verificar e resetar o estado do circuit breaker para endpoints.
        *   Enfileirar para retry em caso de falha.
    *   **Monitoramento de Saúde:**
        *   Verificar o status de saúde de um webhook (`check_webhook_health/1`).
        *   Listar webhooks problemáticos (`Monitor.list_problematic_webhooks/0`).
        *   Worker para verificações periódicas de saúde (`HealthCheckWorker`).
        *   Worker para tentar \"curar\" webhooks com falhas (`AutoHealing`).
*   **Processamento de Eventos:**
    *   Módulo `DeeperHub.Webhooks.Event` para definir eventos suportados e filtrar dados sensíveis de payloads.
    *   Agendador para verificar e disparar eventos de webhook pendentes (`Scheduler`).
    *   Dispatcher para gerenciar tentativas de entrega e status (`Dispatcher`).
*   **Armazenamento e Auditoria:**
    *   Armazenamento de definições de webhooks e eventos de webhook (tentativas, status) (`DeeperHub.Webhooks.Storage`, `Schema.Webhook`, `Schema.WebhookEvent`).
    *   Log de eventos de webhook (criação, desativação, entregas, falhas) no sistema de auditoria (`DeeperHub.Webhooks.Integrations.AuditIntegration`).
*   **Workers:**
    *   `CleanupWorker`: Limpeza periódica de eventos de webhook antigos.
    *   `DeliveryWorker`: Processamento assíncrono de entrega de webhooks.
*   **Telemetria:** Coleta de métricas sobre entregas, falhas e desempenho de webhooks (`DeeperHub.Webhooks.Telemetry`).

```

---

**Parte 6: Tarefas em Segundo Plano, Serviços de Domínio e Infraestrutura Compartilhada**

```markdown
## 18. Tarefas em Segundo Plano

O `DeeperHub.BackgroundTasks.BackgroundTasksFacade` (e suas versões unificadas) gerencia a execução de tarefas assíncronas.

*   **Enfileiramento e Agendamento:**
    *   Enfileirar uma nova tarefa para execução, com nome, argumentos e opções (prioridade, atraso, timeout, retries) (`enqueue_task/3`).
    *   Enfileirar múltiplas tarefas em lote (`BackgroundTasksFacadeUnified.enqueue_batch/2`).
    *   Agendar uma tarefa para execução recorrente usando expressão cron ou intervalo (`schedule_recurring_task/4`).
*   **Gerenciamento de Tarefas:**
    *   Cancelar uma tarefa pendente ou em execução, com motivo opcional (`cancel_task/2`).
    *   Cancelar uma tarefa recorrente (`cancel_recurring_task/2`).
*   **Monitoramento e Status:**
    *   Obter o status de uma tarefa específica (`get_task_status/2`).
    *   Obter detalhes de uma tarefa específica (`get_task_details/1`).
    *   Listar tarefas com filtros (status, nome, data) (`list_tasks/1`).
    *   Obter estatísticas sobre o sistema de tarefas (total enfileirado, concluído, falho, tempo médio de execução, etc.) (`get_statistics/1`, `get_stats/1`).
*   **Gerenciamento de Workers:**
    *   Registrar um novo worker para processar tipos específicos de tarefas (`register_worker/2`).
*   **Controle de Execução (`BackgroundTasksFacadeUnified`):**
    *   Pausar e retomar a execução de tarefas em segundo plano (`pause_execution/1`, `resume_execution/1`).
    *   Limpar tarefas antigas do sistema (`cleanup_old_tasks/2`).
*   **Infraestrutura:**
    *   **Cache:** Cache para metadados de tarefas (`DeeperHub.BackgroundTasks.Cache.BackgroundTasksCache`).
    *   **Integrações:**
        *   **Auditoria:** Log de eventos de tarefas (agendamento, início, conclusão, falha, cancelamento) (`DeeperHub.BackgroundTasks.Integrations.AuditIntegration`).
        *   **Eventos:** Publicação de eventos sobre o ciclo de vida das tarefas (`BackgroundTasksEventIntegration`).
        *   **Métricas:** Registro de métricas de desempenho do sistema de tarefas (`BackgroundTasksMetricsIntegration`).
        *   **Notificações:** Envio de notificações sobre eventos de tarefas (`BackgroundTasksNotificationIntegration`).
    *   **Configuração:** Função de setup para inicializar o sistema de tarefas (`setup/0`).

---

## 19. Serviços de Domínio

O DeeperHub organiza funcionalidades de negócio em \"Serviços de Domínio\".

### 19.1. Serviços de Servidores (Servers)

Gerenciado por `DeeperHub.Services.Servers`.

*   **CRUD de Servidores:**
    *   Criar um novo servidor com atributos (nome, descrição, endereço, etc.) (`create_server/1`).
    *   Obter um servidor pelo ID (`get_server/1`).
    *   Atualizar um servidor existente (`update_server/2`).
    *   Excluir um servidor (`delete_server/1`).
    *   Listar servidores com filtros (região, status, proprietário) (`list_servers/1`).
*   **Gerenciamento de Tags de Servidor:**
    *   Adicionar uma tag a um servidor (`add_server_tag/2`).
    *   Remover uma tag de um servidor (`remove_server_tag/2`).
    *   Listar tags de um servidor (`list_server_tags/1`).
*   **Convites para Servidor:**
    *   Criar um convite para um servidor, com opções de usos máximos e data de expiração (`create_server_invite/1`).
    *   Listar convites de um servidor, com filtros (`list_server_invites/2`).
*   **Avaliações de Servidor:**
    *   Criar uma avaliação para um servidor (rating, título, conteúdo) (`create_server_review/1`).
    *   Listar avaliações de um servidor, com filtros (`list_server_reviews/2`).
*   **Integrações:**
    *   **Rate Limiting:** `DeeperHub.Services.Servers.RateLimitIntegration` para limitar a frequência de operações como criação de servidor, adição de tags, etc.
    *   **Telemetria:** `DeeperHub.Services.Servers.Telemetry` para monitorar operações de servidores.

### 19.2. Pacotes de Servidores (ServerPackages)

Gerenciado por `DeeperHub.Services.ServerPackages.ServerPackagesAdapter` e `CachedAdapter`.

*   **CRUD de Pacotes:**
    *   Criar um novo pacote de servidor (nome, preço, duração, etc.) (`create_server_package/1`).
    *   Obter um pacote pelo ID (`get_server_package/1`, `get_server_package!/1`).
    *   Atualizar um pacote existente (`update_server_package/2`).
    *   Excluir um pacote (`delete_server_package/1`).
*   **Listagem:**
    *   Listar todos os pacotes com filtros (`list_server_packages/1`).
    *   Listar pacotes de um servidor específico (`list_server_packages_by_server/2`).
    *   Obter pacotes ativos de um servidor (`Storage.get_active_server_packages/1`).
*   **Cache:** O `CachedAdapter` utiliza cache para otimizar operações de leitura.
*   **Telemetria:** `DeeperHub.Services.ServerPackages.Telemetry` para monitorar operações de pacotes.

### 19.3. Eventos de Servidores (ServerEvents)

Gerenciado por `DeeperHub.Services.ServerEvents.ServerEventsAdapter` e `CachedAdapter`.

*   **CRUD de Eventos:**
    *   Criar um novo evento de servidor (título, horários, etc.) (`create_event/1`).
    *   Obter um evento pelo ID (`get_event/1`, `get_event!/1`).
    *   Atualizar um evento existente (`update_event/2`).
    *   Excluir um evento (`delete_event/1`).
*   **Listagem:**
    *   Listar todos os eventos com filtros (ativo, futuro, passado) (`list_events/1`).
    *   Listar eventos de um servidor específico (`list_events_by_server/2`).
    *   Listar eventos que estão ocorrendo atualmente (`list_current_events/2`).
    *   Listar eventos futuros (`list_upcoming_events/1` no `CachedAdapter`).
*   **Cache:** O `CachedAdapter` utiliza cache para otimizar operações de leitura.
*   **Telemetria:** `DeeperHub.Services.ServerEvents.Telemetry` para monitorar operações de eventos.

### 19.4. Alertas de Servidores (ServerAlerts)

Gerenciado por `DeeperHub.Services.ServerAlerts.ServerAlertsAdapter` e `CachedAdapter`.

*   **CRUD de Alertas:**
    *   Criar um novo alerta de servidor (mensagem, servidor, usuário) (`create_alert/1`).
    *   Obter um alerta pelo ID (`get_alert/1`, `get_alert!/1`).
    *   Atualizar um alerta existente (`update_alert/2`).
    *   Excluir um alerta (`delete_alert/1`).
*   **Listagem:**
    *   Listar todos os alertas com filtros (`list_alerts/1`).
    *   Listar alertas de um servidor específico (`list_alerts_by_server/2`).
    *   Listar alertas para um usuário específico (`list_alerts_by_user/2`).
    *   Listar alertas ativos (`list_active_alerts/1` no `CachedAdapter`).
*   **Broadcast:** Enviar um alerta para todos os usuários de um servidor (`broadcast_alert/3`).
*   **Cache:** O `CachedAdapter` utiliza cache para otimizar operações de leitura.
*   **Telemetria:** `DeeperHub.Services.ServerAlerts.Telemetry` para monitorar operações de alertas.

### 19.5. Tags de Servidores (ServerTags)

Gerenciado por `DeeperHub.Services.ServerTags.ServerTagsAdapter` e `CachedAdapter`.

*   **Gerenciamento de Tags:**
    *   Criar uma nova tag (`create_tag/1`).
    *   Obter uma tag pelo ID ou nome (`get_tag/1`, `get_tag!/1`, `get_tag_by_name/1`).
    *   Atualizar uma tag existente (`update_tag/2`).
    *   Excluir uma tag (`delete_tag/1`).
*   **Associação de Tags a Servidores:**
    *   Adicionar uma tag a um servidor (criando a tag se não existir) (`add_tag_to_server/2`).
    *   Remover uma tag de um servidor (`remove_tag_from_server/2`).
    *   Obter uma tag específica de um servidor (`get_server_tag/2`).
*   **Listagem:**
    *   Listar todas as tags com filtros (`list_tags/1`).
    *   Listar tags de um servidor específico (`list_tags_by_server/1`).
    *   Listar servidores que possuem uma tag específica (`list_servers_by_tag/2`).
    *   Listar tags populares (`list_popular_tags/1` no `CachedAdapter`).
*   **Cache:** O `CachedAdapter` utiliza cache para otimizar operações de leitura.
*   **Telemetria:** `DeeperHub.Services.ServerTags.Telemetry` para monitorar operações de tags.

### 19.6. Mensagens de Atualização de Servidores (ServerUpdateMessages)

Gerenciado por `DeeperHub.Services.ServerUpdateMessages.ServerUpdateMessagesAdapter` e `CachedAdapter`.

*   **CRUD de Mensagens de Atualização:**
    *   Criar uma nova mensagem de atualização (notas, versão, etc.) (`create_update_message/1`).
    *   Obter uma mensagem de atualização pelo ID (`get_update_message/1`, `get_update_message!/1`).
    *   Atualizar uma mensagem existente (`update_update_message/2`).
    *   Excluir uma mensagem (`delete_update_message/1`).
*   **Listagem:**
    *   Listar todas as mensagens de atualização com filtros (`list_update_messages/1`).
    *   Listar mensagens de atualização de um servidor específico (`list_update_messages_by_server/2`).
    *   Obter a última mensagem de atualização de um servidor (`get_latest_update_message/2`).
*   **Cache:** O `CachedAdapter` utiliza cache para otimizar operações de leitura.
*   **Telemetria:** `DeeperHub.Services.ServerUpdateMessages.Telemetry` para monitorar operações de mensagens.

### 19.7. Avaliações de Servidores (ServerReviews)

Gerenciado por `DeeperHub.Services.ServerReviews.ServerReviewsAdapter` e `CachedAdapter`.

*   **CRUD de Avaliações:**
    *   Criar uma nova avaliação de servidor (rating, comentários) (`create_review/1`).
    *   Obter uma avaliação pelo ID (`get_review/1`, `get_review!/1`).
    *   Atualizar uma avaliação existente (`update_review/2`).
    *   Excluir uma avaliação (`delete_review/1`).
*   **Listagem e Agregação:**
    *   Listar todas as avaliações com filtros (`list_reviews/1`).
    *   Listar avaliações de um servidor específico (`list_reviews_by_server/2`).
    *   Listar avaliações de um usuário específico (`list_reviews_by_user/2`).
    *   Obter a avaliação de um usuário para um servidor específico (`get_user_review_for_server/2`).
    *   Calcular a média de avaliação de um servidor (`get_server_rating_average/1`).
*   **Segurança e Validação:**
    *   Sanitizar conteúdo de avaliações para prevenir XSS (`SecurityIntegration.sanitize_review_content/2`).
    *   Validar e sanitizar completamente uma avaliação (`SecurityIntegration.validate_and_sanitize_review/2`).
*   **Rate Limiting:** Limitar a frequência de submissão, edição, e outras operações de reviews (`RateLimitIntegration`).
*   **Cache:** O `CachedAdapter` utiliza cache para otimizar operações de leitura.
*   **Telemetria:** `DeeperHub.Services.ServerReviews.Telemetry` para monitorar operações de avaliações.

### 19.8. Conquistas (Achievements)

Gerenciado por `DeeperHub.Services.Achievements.Adapters.DefaultAchievementsService`. (Nota: `AchievementsAdapter` está obsoleto).

O módulo `DeeperHub.Achievements` é responsável por gerenciar o sistema de conquistas (achievements) da plataforma, permitindo a definição de várias conquistas, rastreamento do progresso dos usuários e concessão de recompensas quando os critérios são atendidos.

*   **Funcionalidades Principais:**
    *   **Definição de Conquistas:** CRUD para Conquistas (`Schema.Achievement`) com nome, descrição, ícone, critérios e pontos associados.
    *   **Tipos de Conquistas:** Suporte a diferentes categorias (baseadas em contagem de ações, marcos específicos, participação em eventos).
    *   **Rastreamento de Progresso:** Monitoramento das ações dos usuários e atualização do progresso em direção às conquistas.
    *   **Desbloqueio Automático:** Verificação automática de critérios e concessão de conquistas quando os requisitos são atendidos.
    *   **Notificações:** Integração com `DeeperHub.Notifications` para alertar usuários sobre conquistas desbloqueadas.

*   **Componentes Principais:**
    *   `DeeperHub.Achievements.AchievementsFacade`: Ponto de entrada principal para interação com o módulo.
    *   `DeeperHub.Achievements.Services.AchievementsService`: Implementação da lógica de negócio.
    *   `DeeperHub.Achievements.Schema.Achievement`: Define a estrutura de uma conquista.
    *   `DeeperHub.Achievements.Schema.UserAchievement`: Rastreia o progresso e o status de desbloqueio por usuário.

*   **APIs Principais:**
    *   `list_achievements/1`: Lista todas as conquistas disponíveis.
    *   `get_user_achievements/2`: Obtém o progresso de um usuário nas conquistas.
    *   `record_user_action/3`: Registra uma ação do usuário que pode contribuir para o progresso de conquistas.

*   **Integrações:**
    *   **EventBus:** Escuta eventos de outros módulos para atualizar o progresso das conquistas.
    *   **Notificações:** Envia notificações quando conquistas são desbloqueadas.
    *   **Recompensas:** Pode ser integrado com `DeeperHub.Rewards` para conceder recompensas ao desbloquear conquistas.

*   **Configuração:**
    *   URL de ícone padrão para conquistas sem ícone específico.
    *   Controle de notificações ao desbloquear conquistas.
    *   Configurações de cache para otimização de desempenho.

*   **Telemetria:** `DeeperHub.Services.Achievements.Telemetry` para monitorar métricas como conquistas desbloqueadas e atualizações de progresso.

*   **Observação:** O `AchievementsAdapter` está obsoleto em favor do `DefaultAchievementsService`.

### 19.9. Desafios (Challenges)

Gerenciado por `DeeperHub.Services.Challenges.Adapters.DefaultChallengesService`.

*   **Funcionalidades não detalhadas na documentação, mas inferidas pelo nome e schemas:**
    *   Definição de Desafios (`Schema.Challenge`): Gerenciar desafios (nome, descrição, critério, recompensa, data de início/fim).
    *   Participação de Usuário em Desafios (`Schema.UserChallenge`): Rastrear participação e progresso de usuários em desafios.
*   **Telemetria:** (Não há um módulo de telemetria específico para Challenges nos arquivos fornecidos, mas provavelmente seguiria o padrão dos outros serviços).

### 19.10. Listas Genéricas (Lists)

O módulo `DeeperHub.Services.Lists.Storage` fornece um CRUD genérico para diversas entidades de \"listas\" que são usadas como tipos ou categorias em outros módulos.

*   **Entidades Gerenciadas (Schemas em `DeeperHub.Services.Lists.Schema`):**
    *   `AchievementType`: Tipos de conquistas.
    *   `Category`: Categorias gerais.
    *   `ContentType`: Tipos de conteúdo.
    *   `Engine`: Motores de jogos ou frameworks.
    *   `FeedbackType`: Tipos de feedback.
    *   `Language`: Idiomas.
    *   `Network`: (Schema não detalhado).
    *   `Platform`: (Schema não detalhado).
    *   `Reputation`: (Schema não detalhado).
    *   `Status`: (Schema não detalhado).
    *   `Tag`: (Schema não detalhado).
*   **Operações CRUD Genéricas:**
    *   Criar, obter, listar e atualizar itens dessas listas.
*   **Telemetria:** `DeeperHub.Services.Lists.Telemetry` para monitorar o serviço de listas.

### 19.11. Recompensas (Rewards)

Gerenciado por `DeeperHub.Services.Rewards.Adapters.DefaultRewardsService` e `RewardsAdapter`.

*   **Funcionalidades (baseadas no `Storage` e `Schema`):**
    *   Definição de Recompensas (`Schema.Reward`): Gerenciar recompensas (nome, descrição, tipo, valor, critério para obtenção).
    *   Resgate de Recompensas por Usuário (`Schema.UserReward`): Rastrear quais usuários resgataram quais recompensas e quando.
    *   Verificar se um usuário já resgatou uma recompensa (`Storage.has_claimed_reward?/2`).
*   **Telemetria:** `DeeperHub.Services.Rewards.Telemetry` para monitorar o serviço de recompensas.

### 19.12. Interações de Usuários (UserInteractions)

Gerenciado por `DeeperHub.Services.UserInteractions.UserInteractionsAdapter` e `DefaultUserInteractionsService`.

*   **Favoritos:**
    *   Adicionar/remover um servidor aos favoritos de um usuário (`add_favorite/2`, `remove_favorite/2`).
    *   Verificar se um servidor é favorito de um usuário (`is_favorite?/2`).
    *   Listar servidores favoritos de um usuário (`list_favorites/2`).
*   **Chat:**
    *   Enviar mensagens de chat entre usuários (`send_chat_message/1`).
    *   Listar mensagens de chat entre dois usuários com paginação e ordenação (`list_chat_messages/3`).
*   **Recomendações:**
    *   Criar ou atualizar uma recomendação de servidor para um usuário (`create_or_update_recommendation/1`).
    *   Listar recomendações para um usuário, com filtros (`list_recommendations_for_user/2`).
*   **Feedback:**
    *   Enviar feedback sobre o sistema (`submit_feedback/1`).
    *   Listar feedback enviado pelos usuários com filtros (`list_feedback/1`).
*   **Denúncias (Reports):**
    *   Criar uma nova denúncia sobre conteúdo ou usuário (`create_report/1`).
    *   Listar denúncias com filtros (`list_reports/1`).
*   **Telemetria:** `DeeperHub.Services.UserInteractions.Telemetry` para monitorar interações de usuários.

### 19.13. Suporte ao Cliente (Support)

Gerenciado por `DeeperHub.Services.Support.SupportAdapter` e `DefaultSupportService`.

*   **Gerenciamento de Tickets:**
    *   Criar um novo ticket de suporte (assunto, descrição, usuário, prioridade) (`create_ticket/1`).
    *   Obter um ticket pelo ID (`get_ticket/1`).
    *   Atualizar um ticket existente (`update_ticket/2`).
    *   Atualizar o status de um ticket (`update_ticket_status/2`).
*   **Listagem e Contagem:**
    *   Listar tickets com filtros (status, prioridade) (`list_tickets/1`).
    *   Listar tickets de um usuário específico (`list_user_tickets/2`).
    *   Contar tickets por status (`count_tickets_by_status/0`).
*   **Integrações:**
    *   **Notificações:** Envio de notificações sobre criação de tickets, respostas, lembretes e atualizações de status (`NotificationIntegration`).
    *   **Rate Limiting:** Limitar a frequência de criação de tickets, adição de mensagens, etc. (`RateLimitIntegration`).
*   **Telemetria:** `DeeperHub.Services.Support.Telemetry` para monitorar o sistema de suporte.

---

## 20. Infraestrutura Compartilhada

Módulos de infraestrutura e utilitários compartilhados por todo o sistema.

### 20.1. Cache (`DeeperHub.Shared.Cache`, `CacheAdapter`, `CacheService`, `EtsCache`)

*   **Operações de Cache:**
    *   Armazenar (`put/3,4`), obter (`get/1,3`), e deletar (`delete/1,2`) valores no cache.
    *   Obter um valor ou armazenar o resultado de uma função se não existir (`get_or_store/4`).
    *   Limpar todo o cache ou um namespace específico (`clear/0,1`).
    *   Deletar entradas por padrão (`delete_pattern/2`).
*   **Contadores Atômicos:**
    *   Incrementar e decrementar valores numéricos no cache (`increment/3,4`, `decrement/3,4`).
*   **Conjuntos (Sets):**
    *   Adicionar/remover membros de um conjunto e obter membros (`CacheInterface.add_to_set/3`, `remove_from_set/3`, `set_members/2`).
*   **Gerenciamento e Monitoramento:**
    *   Obter estatísticas do cache (hits, misses, tamanho) (`get_stats/0`, `stats/0`).
    *   Coletor e relator de métricas do cache, com histórico (`MetricsReporter`).
    *   Inicialização do cache com implementações específicas (ex: `EtsCache`).
*   **Telemetria:** Emissão de eventos de telemetria para operações de cache (`DeeperHub.Shared.Cache.Telemetry`).

### 20.2. Circuit Breaker (`DeeperHub.Shared.CircuitBreaker`, `CircuitBreakerFacade`)

*   **Proteção de Chamadas:**
    *   Executar funções com proteção contra falhas repetitivas (`call/3,4`).
    *   Executar funções com retry automático e fallback (`call_with_retry/4`).
*   **Gerenciamento de Circuit Breakers:**
    *   Registrar novos circuit breakers para serviços específicos com configurações (threshold, timeout) (`register/2`).
    *   Remover o registro de um circuit breaker (`unregister/1`).
    *   Listar todos os circuit breakers e seus estados (`list_all/0`).
    *   Resetar um circuit breaker para o estado fechado (`reset/1`).
    *   Obter o estado (`:closed`, `:open`, `:half_open`) e informações detalhadas de um circuit breaker (`state/1`, `get_info/1`).
    *   Atualizar a configuração de um circuit breaker dinamicamente (`update_config/2`).
*   **Implementação:** Utiliza GenServer para gerenciar o estado de cada circuit breaker.

### 20.3. Criptografia (`DeeperHub.Shared.Encryption`, `AtRestEncryptionService`, `EncryptionService`, `KeyManagementService`)

*   **Criptografia e Descriptografia:**
    *   Criptografar dados usando a chave ativa do sistema (`encrypt/2`).
    *   Descriptografar dados previamente criptografados (`decrypt/2`).
    *   Criptografar dados especificamente para armazenamento em repouso (at-rest) (`encrypt_for_storage/2`).
    *   Descriptografar dados de armazenamento em repouso (`decrypt_from_storage/2`).
    *   Verificar se um valor já está criptografado (`is_encrypted?/1`).
*   **Gerenciamento de Chaves (`KeyManagementService`):**
    *   Gerar novas chaves de criptografia (`generate_key/1`).
    *   Obter a chave de criptografia atual do sistema (`get_current_key/0`).
    *   Obter uma chave específica pelo ID (`get_key_by_id/1`).
    *   Listar metadados de chaves disponíveis.
    *   Revogar chaves, impedindo seu uso futuro.
*   **Rotação de Chaves:**
    *   Rotacionar a chave ativa, gerando uma nova (`rotate_key/0` no `KeyManagementService`).
    *   Verificar se a chave atual precisa de rotação (`needs_rotation?/0`).
    *   Realizar rotação de chaves e recriptografar dados existentes com a nova chave (`rotate_and_reencrypt/1`).
    *   Configurar e executar tarefas de rotação automática de chaves (`setup_key_rotation_task/0`, `perform_scheduled_rotation/0`).
*   **Integração com Ecto:**
    *   Tipo Ecto personalizado (`EncryptedType`) para criptografar/descriptografar campos automaticamente ao persistir/carregar do banco de dados.
*   **Compatibilidade:** Módulo `EncryptionCompatibility` para interfaces legadas.
*   **Status:** Verificar o status do serviço de criptografia, incluindo informações sobre chaves (`check_status/0`).

### 20.4. Utilitários

*   **Datas e Horas (`DeeperHub.Shared.Utils.DateUtils`):**
    *   Adicionar/subtrair intervalos de tempo a datas/horas (`add/3`).
    *   Calcular a diferença entre duas datas/horas em diferentes unidades (`diff/3`).
    *   Formatar datas/horas em strings legíveis com diferentes formatos e locales (`format_datetime/3`).
    *   Formatar durações em segundos para strings legíveis (`format_duration/2`).
    *   Verificar se uma data/hora está entre duas outras (`is_between/3`).
*   **Arquivos (`DeeperHub.Shared.Utils.FileUtils`):**
    *   Verificar existência de arquivos (`file_exists?/1`).
    *   Ler conteúdo de arquivos de texto (`read_text_file/1`).
    *   Escrever conteúdo em arquivos de texto, com opções de append e criação de diretórios (`write_text_file/3`).
    *   Copiar arquivos (`copy_file/3`).
    *   Obter informações de arquivos (tamanho, tipo, timestamps) (`get_file_info/1`).
    *   Calcular hash de arquivos (MD5, SHA1, SHA256, SHA512) (`calculate_file_hash/2`).
    *   Determinar tipo MIME de arquivos pela extensão (`get_mime_type/1`).
*   **Listas (`DeeperHub.Shared.Utils.ListUtils`):**
    *   Dividir listas em chunks (`chunk/2`).
    *   Calcular diferença entre listas, com função de chave opcional (`diff/3`).
    *   Agrupar elementos por uma função chave (`group_by/2`).
    *   Intercalar elementos de duas listas (`interleave/2`).
    *   Paginar listas em memória (`paginate/3`).
    *   Particionar listas com base em um predicado (`partition/2`).
    *   Ordenar listas de mapas/structs por múltiplas chaves e direções (`sort_by_keys/2`).
    *   Remover duplicatas, com função de chave opcional (`unique/2`).
*   **Mapas (`DeeperHub.Shared.Utils.MapUtils`):**
    *   Converter chaves de átomo para string e vice-versa, recursivamente (`atom_keys_to_strings/2`, `string_keys_to_atoms/2`).
    *   Remover entradas com valores `nil`, recursivamente (`compact/2`).
    *   Mesclar mapas profundamente (`deep_merge/2`).
    *   Filtrar mapas com base em um predicado (`filter_map/2`).
    *   Obter/atualizar valores aninhados usando um caminho de chaves (`get_in_path/3`, `update_in_path/3`).
    *   Aplicar uma função a todos os valores de um mapa, recursivamente (`map_values/3`).
    *   Converter um mapa para uma lista de mapas chave-valor (`to_key_value_list/3`).
*   **Métricas (`DeeperHub.Shared.Utils.MetricsUtils`):**
    *   Calcular estatísticas básicas (contagem, min, max, soma, média, mediana, variância, desvio padrão) (`calculate_stats/1`).
    *   Calcular percentis (`calculate_percentiles/2`).
    *   Detectar anomalias usando Z-score (`detect_anomalies/2`).
    *   Formatar valores métricos com unidades e precisão (`format_metric/3`).
    *   Agrupar métricas por intervalo de tempo com agregação (`group_by_time/5`).
    *   Calcular taxa de mudança entre valores (`rate_of_change/3`).
*   **Segurança (`DeeperHub.Shared.Utils.SecurityUtils`):**
    *   Gerar IDs únicos seguros (UUID, hex, base64) (`generate_id/1`).
    *   Gerar tokens aleatórios (`generate_token/2`).
    *   Gerar códigos de recuperação (`generate_recovery_code/2`).
    *   Gerar chaves de assinatura seguras para tokens (`generate_signing_key/0`).
    *   Hash seguro de senhas (PBKDF2-SHA512) e verificação (`hash_password/2`, `verify_password/2`).
    *   Avaliar risco agregado de múltiplos fatores (`evaluate_risk/1`).
    *   (Stub) Verificar se um IP está bloqueado (`is_ip_blocked/2`).
*   **Validação e Sanitização (`DeeperHub.Shared.Validation.*`):**
    *   `InputSanitizer`: Verificar e sanitizar strings e mapas contra XSS, injeção de SQL e injeção de comando.
    *   `InputValidator`: Validar formatos de email, telefone, URL, datas, documentos (CPF/CNPJ), JSON, senhas e schemas de dados.
    *   `EmailValidator`: Validações de email mais profundas (domínio, MX, blacklist).
    *   `PasswordValidator`: Verificação de força de senha e geração de senhas seguras.

```

---

**Parte 7: Ferramentas de Desenvolvedor e Administração, e Conclusão**

```markdown
## 21. Ferramentas de Desenvolvedor e Administração

### 21.1. Console Interativo (CLI)

O `DeeperHub.Console.ConsoleFacade` (e `DeeperHub.Console`) fornece uma interface de linha de comando para operações administrativas.

*   **Execução de Comandos:**
    *   Executar comandos com argumentos e opções (`execute/3`).
    *   Serviço interno para executar comandos (`CommandRunner.execute/3`).
*   **Gerenciamento de Comandos:**
    *   Registrar novos comandos no sistema (`register_command/1`).
    *   Listar todos os comandos disponíveis, opcionalmente por categoria (`list_commands/1`).
    *   Obter ajuda para um comando específico (`help/1`).
    *   Encontrar comandos pelo nome (`CommandRegistry.find_command/1`).
*   **Sessão Interativa e Scripts:**
    *   Iniciar uma sessão interativa do console (`start_interactive/1`).
    *   Executar scripts de console a partir de arquivos (`run_script/2`).
*   **Comandos Padrão:**
    *   `ExitCommand`: Para sair do console.
    *   `HelpCommand`: Para exibir ajuda.
    *   `ListCommand`: Para listar recursos.
    *   `StatusCommand`: Para verificar o status do sistema.
    *   `VersionCommand`: Para exibir informações de versão.
*   **Configuração do Console (`DeeperHub.Console.Config.ConsoleConfig`):**
    *   Gerenciar tamanho do histórico, prompt, sugestões automáticas, salvamento de histórico.
    *   Definir e verificar comandos críticos (que podem gerar notificações).
*   **Saída Formatada (`DeeperHub.Console.Services.OutputService`):**
    *   Formatar e imprimir resultados, erros, avisos, sucessos e tabelas.
*   **Integrações:**
    *   **Auditoria:** Registrar execução de comandos, erros e verificações de permissão (`DeeperHub.Console.Integrations.AuditIntegration`).
    *   **Notificações:** Enviar notificações para execução de comandos críticos ou tentativas não autorizadas (`DeeperHub.Console.Integrations.NotificationIntegration`).
*   **Telemetria:** Monitorar execução de comandos e verificações de permissão (`DeeperHub.Console.Telemetry`).

### 21.2. Inspetor de Módulos

O `DeeperHub.Inspector.InspectorFacade` (e `DeeperHub.ModuleInspectorSimple` para uma versão sem dependências complexas) permite analisar módulos Elixir.

*   **Inspeção de Elementos:**
    *   Inspecionar módulos, funções ou typespecs para extrair informações detalhadas (`inspect_element/2`).
    *   Detecta automaticamente o tipo de elemento.
*   **Inspetores Especializados:**
    *   `ModuleInspector`: Extrai funções, documentação, comportamentos, atributos e tipos de um módulo.
    *   `FunctionInspector`: Extrai aridade, documentação, especificações de tipo e código fonte (opcional) de uma função.
    *   `TypeSpecInspector`: Extrai informações sobre `@type`, `@spec`, `@callback`, etc.
*   **Gerenciamento de Inspetores:**
    *   Obter o inspetor apropriado para um tipo de elemento (`get_inspector_for/1`).
    *   Listar todos os inspetores disponíveis (`list_inspectors/0`).
    *   Verificar se um elemento é suportado por algum inspetor (`supported?/1`).
*   **Formatação de Resultados:**
    *   Formatar o resultado da inspeção para exibição em texto, JSON ou HTML (`format_result/2`).
*   **Persistência (Experimental):**
    *   `DeeperHub.InspectorRepo` sugere a capacidade de armazenar informações de inspeção em um banco de dados SQLite.
*   **Telemetria:** `DeeperHub.ModuleInspector.Telemetry` para monitorar operações de inspeção.
