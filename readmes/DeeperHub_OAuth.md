# Módulo: `Deeper_Hub.OAuth` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.OAuth`

O módulo `Deeper_Hub.OAuth` é responsável por gerenciar a **autenticação e autorização de usuários através de provedores OAuth 2.0 externos** (como Google, Facebook, GitHub, Apple, etc.). Ele permite que os usuários do Deeper_Hub façam login ou registrem-se usando suas contas existentes nesses provedores, além de permitir que o Deeper_Hub (com consentimento do usuário) acesse certos dados ou execute ações em nome do usuário nesses serviços externos.

As principais funcionalidades incluem:
1.  Iniciar o fluxo de autorização OAuth com o provedor.
2.  Processar o callback do provedor após a autorização do usuário.
3.  Trocar o código de autorização por tokens de acesso e refresh.
4.  Buscar informações do perfil do usuário do provedor.
5.  Vincular contas OAuth a contas Deeper_Hub existentes ou criar novas contas.
6.  Gerenciar (armazenar, atualizar, revogar) os tokens OAuth obtidos.

Este módulo simplifica a integração com múltiplos provedores OAuth, oferecendo uma interface unificada para o restante da aplicação. 😊

*(Nota: A documentação original tem `Deeper_Hub.OAuth.Adapters.OAuthAdapterUnified`, `Behaviours.OAuthBehaviourUnified`, `Cache.UserInfoCache`, `Integrations.EventIntegration`, `Integrations.OAuthApiIntegration`, `OAuthCompatibility`, `OAuthFacadeUnified`, `Schema.OAuthToken`, e vários `Services`. Esta documentação tentará consolidar e organizar essas responsabilidades.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Início do Fluxo OAuth (`authorize_url/3`):**
    *   Gerar a URL de autorização correta para um provedor específico, incluindo `client_id`, `redirect_uri`, `scope`, `state`, e outros parâmetros necessários.
*   **Processamento de Callback (`process_oauth_callback/4` ou `authenticate_with_code/3`):**
    *   Receber e validar o código de autorização e o parâmetro `state` do provedor.
    *   Trocar o código de autorização por um token de acesso e, opcionalmente, um token de refresh (`exchange_code/3`).
*   **Obtenção de Informações do Usuário (`get_user_info/2`):**
    *   Usar o token de acesso para buscar informações do perfil do usuário do endpoint de userinfo do provedor.
*   **Gerenciamento de Contas Deeper_Hub:**
    *   Encontrar um usuário Deeper_Hub existente com base no email ou ID do provedor.
    *   Criar uma nova conta Deeper_Hub se o usuário não existir e o auto-registro via OAuth estiver habilitado.
    *   Vincular a identidade OAuth a uma conta Deeper_Hub existente (`link_account/4`).
    *   Desvincular uma conta OAuth (`unlink_account/2`).
*   **Gerenciamento de Tokens OAuth (`Deeper_Hub.OAuth.Schema.OAuthToken`):**
    *   Armazenar de forma segura os tokens de acesso e refresh obtidos dos provedores.
    *   Atualizar tokens de acesso usando tokens de refresh.
    *   Lidar com a revogação de tokens.
*   **Abstração de Provedores:**
    *   Suportar múltiplos provedores OAuth com configurações e fluxos específicos para cada um.
    *   Utilizar adaptadores por provedor ou uma biblioteca OAuth genérica (como `Assent`).
*   **Cache de Informações do Usuário (`Cache.UserInfoCache`):**
    *   Cachear informações do perfil do usuário obtidas dos provedores para reduzir chamadas de API.
*   **Segurança:**
    *   Uso do parâmetro `state` para prevenir ataques CSRF durante o fluxo OAuth.
    *   Validação rigorosa de `redirect_uri`.
    *   Armazenamento seguro de `client_secret` e tokens.
*   **Integração com `Deeper_Hub.Auth` e `Deeper_Hub.Accounts`:**
    *   Após a autenticação OAuth bem-sucedida, criar uma sessão Deeper_Hub e emitir tokens Deeper_Hub.
*   **Observabilidade e Auditoria:**
    *   Logar etapas do fluxo OAuth e quaisquer erros.
    *   Registrar métricas sobre autenticações OAuth.
    *   Auditar vinculação e desvinculação de contas.
*   **Proteção com Circuit Breaker (`Integrations.OAuthApiIntegration`):**
    *   Proteger chamadas para os endpoints dos provedores OAuth (token, userinfo) usando circuit breakers.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.OAuth` (Fachada Pública, ex-`OAuthFacadeUnified`):**
    *   Ponto de entrada para todas as operações OAuth.
    *   Delega para o `OAuthService`.
2.  **`Deeper_Hub.OAuth.Services.OAuthService` (ou `DefaultOAuthService`):**
    *   **Responsabilidade:** Orquestra o fluxo OAuth completo.
    *   **Interações:**
        *   `ProviderService` (ou adaptadores de provedor): Para obter URLs de autorização e trocar códigos por tokens.
        *   `CallbackService`: Para processar o callback, buscar informações do usuário e lidar com a conta Deeper_Hub.
        *   `Deeper_Hub.OAuth.Schema.OAuthToken` (via `Core.Repo`): Para armazenar e gerenciar tokens OAuth.
        *   `Deeper_Hub.Accounts`: Para encontrar/criar usuários Deeper_Hub.
        *   `Deeper_Hub.Auth.SessionManager` e `TokenService`: Para criar sessões Deeper_Hub após autenticação.
        *   `Cache.UserInfoCache`: Para cachear perfis de usuário OAuth.
        *   `Integrations.OAuthApiIntegration`: Para fazer chamadas HTTP seguras aos provedores.
3.  **`Deeper_Hub.OAuth.Services.ProviderService` (ou Adaptadores por Provedor):**
    *   **Responsabilidade:** Encapsular a lógica específica de cada provedor OAuth (endpoints, escopos padrão, formato de dados do usuário).
    *   Pode usar uma biblioteca como `Assent` internamente ou implementar chamadas HTTP diretas (protegidas por `OAuthApiIntegration`).
4.  **`Deeper_Hub.OAuth.Services.CallbackService`:**
    *   **Responsabilidade:** Lógica específica para o manuseio do callback do provedor, incluindo validação de `state`, troca de código, e conciliação com contas Deeper_Hub.
5.  **`Deeper_Hub.OAuth.Integrations.OAuthApiIntegration`:**
    *   Utiliza `Deeper_Hub.Core.CircuitBreaker` e `Core.HTTPClient` para fazer chamadas seguras aos endpoints dos provedores.
6.  **`Deeper_Hub.OAuth.Cache.UserInfoCache` (GenServer/ETS):**
    *   Armazena temporariamente os perfis de usuário obtidos dos provedores.
7.  **`Deeper_Hub.OAuth.Schema.OAuthToken` (Ecto Schema):**
    *   Armazena `user_id` (Deeper_Hub), `provider` (ex: \"google\"), `provider_user_id`, `access_token` (criptografado), `refresh_token` (criptografado), `expires_at`, `scopes`.
8.  **Configurações (via `Deeper_Hub.Core.ConfigManager`):**
    *   `client_id`, `client_secret`, `redirect_uri`, escopos padrão, URLs de endpoint para cada provedor OAuth configurado.

### 3.2. Estrutura de Diretórios (Proposta)

```
oauth/
├── oauth.ex                          # Fachada Pública (ex-OAuthFacadeUnified)
│
├── services/
│   ├── oauth_service.ex              # Serviço orquestrador principal
│   ├── provider_service.ex           # Lógica/adaptadores para interagir com provedores
│   └── callback_service.ex           # Lógica para processar callbacks
│
├── integrations/
│   ├── event_integration.ex
│   ├── audit_integration.ex          # (Se necessário, logar vinculações/desvinculações)
│   └── oauth_api_integration.ex      # Chamadas HTTP com Circuit Breaker
│
├── cache/
│   └── user_info_cache.ex
│
├── schemas/                          # (Ou schema/)
│   └── oauth_token.ex
│
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Abstração de Provedor:** O `ProviderService` ou o uso de uma biblioteca como `Assent` é crucial para adicionar novos provedores facilmente.
*   **Segurança do `state`:** O parâmetro `state` deve ser gerado, armazenado temporariamente (ex: na sessão do usuário ou em um cache de curta duração com ID na sessão) e validado no callback para prevenir CSRF.
*   **Armazenamento Seguro de Tokens:** `client_secret`s e `refresh_token`s/`access_token`s de usuário devem ser armazenados de forma criptografada em repouso (`Core.EncryptionService`).
*   **Fluxo de Vinculação de Conta:** Definir claramente como uma identidade OAuth é vinculada a uma conta Deeper_Hub nova ou existente (ex: por correspondência de email verificado, ou permitindo que o usuário escolha).
*   **Gerenciamento de Escopos:** Lidar corretamente com os escopos solicitados e concedidos.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Novo Registra-se com Google:**
    1.  Usuário clica em \"Registrar com Google\".
    2.  Frontend chama `GET /api/oauth/google/authorize_url`.
    3.  `OAuth.authorize_url(:google, ...)` gera a URL do Google.
    4.  Usuário é redirecionado para o Google, autoriza.
    5.  Google redireciona para `/api/oauth/google/callback?code=...&state=...`.
    6.  `OAuth.authenticate_with_code(:google, code, state, context)` é chamado.
    7.  Tokens são trocados, perfil do Google é buscado.
    8.  Como o usuário é novo, uma conta Deeper_Hub é criada, vinculada à identidade Google.
    9.  Uma sessão Deeper_Hub é criada, tokens Deeper_Hub são retornados.
*   **Usuário Existente Faz Login com Facebook:**
    *   Fluxo similar, mas no final, a identidade Facebook é vinculada a uma conta Deeper_Hub existente (ex: pelo email).
*   **Usuário Existente Vincula uma Nova Conta GitHub ao seu Perfil Deeper_Hub:**
    *   Usuário já logado no Deeper_Hub vai para \"Contas Vinculadas\".
    *   Clica em \"Vincular GitHub\".
    *   Fluxo OAuth similar, mas no final, a identidade GitHub é apenas adicionada ao `user_id` Deeper_Hub existente.

## 🌊 5. Fluxos Importantes

### Fluxo Completo de Autenticação OAuth 2.0 (Authorization Code Grant)

1.  **Início (Cliente Deeper_Hub -> Fachada OAuth):**
    *   O cliente (ex: frontend Deeper_Hub) solicita a URL de autorização para um provedor (ex: Google).
    *   `Deeper_Hub.OAuth.authorize_url(:google, configured_redirect_uri, generate_and_store_state_param())`.
    *   O `state` é gerado, armazenado na sessão do usuário ou cache com TTL curto, e incluído na URL.
    *   A URL do Google é retornada ao cliente.
2.  **Redirecionamento para o Provedor:**
    *   O navegador do usuário é redirecionado para a URL do Google.
3.  **Autorização pelo Usuário (no site do Provedor):**
    *   O usuário faz login no Google (se necessário) e concede as permissões solicitadas pelo Deeper_Hub.
4.  **Redirecionamento de Volta para Deeper_Hub (Callback):**
    *   Google redireciona o navegador do usuário para a `redirect_uri` configurada no Deeper_Hub, incluindo um `code` (código de autorização) e o `state` original.
    *   Ex: `https://app.Deeper_Hub.com/oauth/google/callback?code=AUTH_CODE_FROM_GOOGLE&state=STORED_STATE`.
5.  **Processamento do Callback (Controller API -> Fachada OAuth):**
    *   O controller do Deeper_Hub recebe o `code` e `state`.
    *   Chama `Deeper_Hub.OAuth.authenticate_with_code(:google, code, state, %{ip_address: ..., user_agent: ...})`.
6.  **`Deeper_Hub.OAuth.Services.OAuthService` e `CallbackService`:**
    *   **Validação do `state`:** Compara o `state` recebido com o armazenado na Etapa 1. Se diferente, aborta (CSRF).
    *   **Troca de Código por Tokens:** Chama `ProviderService` (ou `OAuthApiIntegration`) para enviar o `code` para o endpoint de token do Google (com `client_id`, `client_secret`, `redirect_uri`).
        *   `OAuthApiIntegration` faz a chamada HTTP POST protegida por Circuit Breaker.
    *   **Recebimento de Tokens:** Recebe `access_token`, `refresh_token` (se aplicável), `expires_in` do Google.
    *   **Busca de Informações do Usuário:** Chama `ProviderService` (ou `OAuthApiIntegration`) para usar o `access_token` e buscar o perfil do usuário do endpoint userinfo do Google.
        *   Perfil é cacheado no `UserInfoCache`.
    *   **Conciliação de Conta:**
        *   Tenta encontrar um usuário Deeper_Hub existente pelo `provider_user_id` (ex: Google ID) ou pelo email verificado do perfil Google.
        *   Se encontrado, vincula a identidade OAuth (se ainda não vinculada) ou atualiza os tokens OAuth.
        *   Se não encontrado, e auto-registro habilitado, cria uma nova conta Deeper_Hub e vincula a identidade OAuth.
        *   Armazena/Atualiza os tokens OAuth no `OAuthTokenSchema` (criptografados).
    *   **Criação de Sessão Deeper_Hub:** Se a conciliação for bem-sucedida (usuário Deeper_Hub identificado/criado):
        *   Chama `Deeper_Hub.Auth.SessionManager.create_session(...)`.
        *   Chama `Deeper_Hub.Auth.TokenService.generate_token_pair(...)`.
    *   Publica eventos (`account_linked`, `authentication_succeeded`) via `EventIntegration`.
    *   Audita a operação.
7.  **Resposta ao Cliente:** Retorna os tokens Deeper_Hub e informações do usuário para o frontend, que completa o login.

## 📡 6. API (Funções Públicas da Fachada `Deeper_Hub.OAuth`)

*(Baseado na documentação original de `OAuthFacadeUnified` e `OAuthCompatibility`)*

### 6.1. `Deeper_Hub.OAuth.authorize_url(provider :: atom(), redirect_uri_key :: atom() | String.t(), session_state_data :: map()) :: {:ok, %{authorize_url: String.t(), state_param_for_session: String.t()}} | {:error, term()}`

*   **Descrição:** Gera a URL de autorização para o `provider` e um `state` para proteção CSRF.
*   **`redirect_uri_key`:** Uma chave que mapeia para uma `redirect_uri` configurada (para evitar que o cliente envie URIs arbitrárias).
*   **`session_state_data`:** Dados a serem incluídos no `state` ou associados a ele na sessão.
*   **Retorno:** URL para redirecionamento e o `state` que o cliente deve armazenar (ex: em cookie de sessão) para verificar no callback.

### 6.2. `Deeper_Hub.OAuth.authenticate_with_code(provider :: atom(), code :: String.t(), received_state :: String.t(), context :: map()) :: {:ok, AuthResponse.t()} | {:error, OAuthError.t()}`

*   **Descrição:** Processa o callback do provedor OAuth, troca o código por tokens, busca info do usuário e autentica/registra o usuário no Deeper_Hub.
*   **`context`:** `%{ip_address: String.t(), user_agent: String.t(), expected_state_from_session: String.t()}`.
*   **`AuthResponse.t()`:** `%{user: Deeper_Hub.Accounts.Schema.User.t(), deeper_hub_access_token: String.t(), deeper_hub_refresh_token: String.t(), provider_info: %{provider: atom(), provider_user_id: String.t()}}`.
*   **`OAuthError.t()`:** Ex: `:invalid_state`, `:token_exchange_failed`, `:user_info_fetch_failed`, `:account_linking_failed`, `:user_creation_disabled`.

### 6.3. `Deeper_Hub.OAuth.link_account(deeper_hub_user_id :: String.t(), provider :: atom(), provider_code :: String.t(), received_state :: String.t(), context :: map()) :: {:ok, OAuthToken.t()} | {:error, OAuthError.t()}` (Nova Sugestão)

*   **Descrição:** Permite que um usuário já logado no Deeper_Hub vincule uma nova conta OAuth. O fluxo é similar ao `authenticate_with_code` mas focado em vincular a uma conta existente.

### 6.4. `Deeper_Hub.OAuth.unlink_account(deeper_hub_user_id :: String.t(), provider :: atom()) :: :ok | {:error, :not_linked | term()}`

*   **Descrição:** Desvincula uma conta OAuth de um usuário Deeper_Hub.

### 6.5. `Deeper_Hub.OAuth.list_linked_accounts(deeper_hub_user_id :: String.t()) :: {:ok, list(LinkedAccountInfo.t())}`

*   **Descrição:** Lista as contas OAuth vinculadas a um usuário Deeper_Hub.
*   **`LinkedAccountInfo.t()`:** `%{provider: atom(), provider_user_id: String.t(), provider_email: String.t() | nil, linked_at: DateTime.t()}`.

### 6.6. `Deeper_Hub.OAuth.get_user_info_from_provider(provider :: atom(), access_token :: String.t()) :: {:ok, ProviderUserProfile.t()} | {:error, term()}` (Para uso interno ou admin)

*   **Descrição:** Busca informações do usuário diretamente do provedor usando um token de acesso OAuth válido.
*   **`ProviderUserProfile.t()`:** Mapa com dados do perfil do provedor.

## ⚙️ 7. Configuração

Via `Deeper_Hub.Core.ConfigManager`:

*   **`[:oauth, :enabled_providers]`** (List de Atoms): Lista de provedores OAuth habilitados (ex: `[:google, :facebook, :github]`).
*   **Para cada provedor (ex: `[:oauth, :google, ...]`):**
    *   `... :client_id` (String)
    *   `... :client_secret` (String, DEVE ser de variável de ambiente ou cofre)
    *   `... :redirect_uris` (Map, ex: `%{default: \"https://app.Deeper_Hub.com/oauth/google/callback\", mobile: \"myapp://oauth/google\"}`)
    *   `... :authorize_url` (String)
    *   `... :token_url` (String)
    *   `... :user_info_url` (String)
    *   `... :default_scopes` (List de Strings)
    *   `... :user_id_path` (List de Strings/Atoms): Caminho para extrair o ID do usuário do provedor da resposta userinfo (ex: `[:id]`).
    *   `... :user_email_path` (List de Strings/Atoms): Caminho para o email.
    *   `... :user_name_path` (List de Strings/Atoms): Caminho para o nome.
*   **`[:oauth, :auto_register_new_users]`** (Boolean): Se deve criar automaticamente contas Deeper_Hub para novos usuários OAuth. (Padrão: `true`)
*   **`[:oauth, :link_by_verified_email]`** (Boolean): Se deve tentar vincular automaticamente a uma conta Deeper_Hub existente se o email do provedor OAuth for verificado e corresponder. (Padrão: `true`)
*   **`[:oauth, :state_param_ttl_seconds]`** (Integer): TTL para o parâmetro `state` armazenado na sessão. (Padrão: `300`)
*   **`[:oauth, :user_info_cache_ttl_seconds]`** (Integer): TTL para o cache de perfis de usuário OAuth. (Padrão: `3600`)
*   **`[:oauth, :api_integration, :circuit_breaker, <provider_name>]`** (Map): Configs do Circuit Breaker para cada provedor.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`, `Core.EventBus`, `Core.Logger`, `Core.Metrics`, `Core.Repo`, `Core.Cache`, `Core.HTTPClient`, `Core.EncryptionService`, `Core.CircuitBreaker`.
*   `Deeper_Hub.Accounts`: Para criar/encontrar/vincular usuários.
*   `Deeper_Hub.Auth`: Para criar sessões Deeper_Hub após autenticação OAuth.
*   `Deeper_Hub.Audit`: Para registrar eventos de vinculação/autenticação.

### 8.2. Bibliotecas Externas

*   `Assent` (altamente recomendado): Biblioteca Elixir popular para lidar com múltiplos provedores OAuth 2.0. Simplifica muito a implementação de `ProviderService`.
*   `Jason`: Para parsear respostas JSON dos provedores.
*   `HTTPoison` ou `Finch` (se não usar `Core.HTTPClient` que os encapsularia): Para fazer chamadas HTTP.

## 🤝 9. Como Usar / Integração

*   **Frontend/Cliente:**
    1.  Chamar um endpoint da API Deeper_Hub (ex: `/api/oauth/:provider/authorize`) que internamente chama `OAuth.authorize_url/3`.
    2.  A API Deeper_Hub retorna a `authorize_url` do provedor.
    3.  Frontend redireciona o usuário para essa URL.
    4.  Após o usuário autorizar, o provedor redireciona para a `redirect_uri` do Deeper_Hub (ex: `/api/oauth/:provider/callback`) com `code` e `state`.
    5.  O controller do callback no Deeper_Hub chama `OAuth.authenticate_with_code/4`.
    6.  Se bem-sucedido, a API Deeper_Hub retorna tokens Deeper_Hub para o frontend, que finaliza o login.
*   **Serviços Internos:** Podem usar `list_linked_accounts` ou `get_user_info_from_provider` (com cuidado e consentimento) para funcionalidades específicas.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o fluxo completo para cada provedor configurado usando mocks para as APIs dos provedores.
*   Testar a geração da `authorize_url` e a validação do `state`.
*   Testar a troca de código por token e a busca de userinfo.
*   Testar os cenários de usuário novo, usuário existente com conta não vinculada, e usuário existente com conta já vinculada.
*   Testar a lógica de desvinculação.
*   Testar o funcionamento do `UserInfoCache`.
*   Testar o Circuit Breaker para chamadas a APIs de provedores.
*   Localização: `test/deeper_hub/oauth/`.

### 10.2. Métricas

*   `deeper_hub.oauth.authentication.attempts.count` (tags: `provider`, `status` (`success`, `failure`))
*   `deeper_hub.oauth.authentication.duration_ms` (Histograma, tags: `provider`, `stage` (`code_exchange`, `user_info_fetch`))
*   `deeper_hub.oauth.accounts_linked.count` (tags: `provider`)
*   `deeper_hub.oauth.accounts_unlinked.count` (tags: `provider`)
*   `deeper_hub.oauth.user_info_cache.hit_ratio.gauge` (Gauge)
*   `deeper_hub.oauth.api_call.failure.count` (tags: `provider`, `endpoint_type` (`token`, `userinfo`)) (relacionado ao Circuit Breaker)

### 10.3. Logs

*   **Nível INFO:** Início e fim de um fluxo OAuth. Conta vinculada/desvinculada. Tokens trocados/atualizados.
*   **Nível WARNING:** Falha na validação do `state`. Falha na troca de código ou busca de userinfo (antes de retentativas do Circuit Breaker).
*   **Nível ERROR:** Falha persistente na comunicação com o provedor OAuth. Erro ao criar/vincular conta Deeper_Hub após autenticação OAuth.

### 10.4. Telemetria

*   `[:deeper_hub, :oauth, :authorize_url_generated]`
    *   Metadados: `%{provider: provider, redirect_uri_key: key}`
*   `[:deeper_hub, :oauth, :callback_received]`
    *   Metadados: `%{provider: provider, state_valid: boolean}`
*   `[:deeper_hub, :oauth, :token_exchange, :start | :stop | :exception]`
    *   Metadados: `%{provider: provider}`
*   `[:deeper_hub, :oauth, :user_info_fetch, :start | :stop | :exception]`
    *   Metadados: `%{provider: provider, from_cache: boolean}`
*   `[:deeper_hub, :oauth, :account_reconciliation, :stop]`
    *   Metadados: `%{provider: provider, action_taken: :linked_new | :linked_existing | :created_new_deeper_hub_user | :login_existing}`

## ❌ 11. Tratamento de Erros

*   Falhas na comunicação com provedores externos devem ser tratadas pelo `OAuthApiIntegration` (com Circuit Breaker), retornando erros claros para o `OAuthService`.
*   O `state` inválido no callback deve resultar em erro e impedir o prosseguimento.
*   Se o email de um usuário OAuth já existir em uma conta Deeper_Hub diferente e a vinculação automática não for clara, o usuário pode precisar ser guiado por um fluxo de \"conflito de contas\".

## 🛡️ 12. Considerações de Segurança

*   **Validação do `state`:** Essencial para prevenir CSRF no fluxo OAuth.
*   **Validação de `redirect_uri`:** O Deeper_Hub deve validar que a `redirect_uri` usada pelo provedor é uma das URIs pré-registradas e permitidas para evitar que códigos de autorização sejam enviados para endpoints maliciosos.
*   **Armazenamento Seguro de `client_secret`:** Tratar como um segredo de alta importância.
*   **Armazenamento Seguro de Tokens de Usuário:** Tokens de acesso e refresh OAuth de usuários devem ser criptografados em repouso.
*   **Escopos Mínimos:** Solicitar apenas os escopos estritamente necessários dos provedores OAuth.
*   **Atualização de Tokens:** Implementar corretamente o fluxo de atualização de tokens de acesso usando tokens de refresh para evitar que o usuário precise reautorizar frequentemente.
*   **Revogação de Tokens:** Quando um usuário desvincula uma conta ou sua conta Deeper_Hub é encerrada, os tokens OAuth associados devem ser revogados no lado do provedor, se a API do provedor permitir.

## 🧑‍💻 13. Contribuição

*   Ao adicionar um novo provedor OAuth:
    *   Registrar as configurações (client_id, secret, endpoints, escopos) no `ConfigManager`.
    *   Adicionar lógica específica do provedor no `ProviderService` (ou usar uma estratégia de `Assent`).
    *   Mapear os campos do perfil do usuário do provedor para o formato interno do Deeper_Hub.
    *   Testar o fluxo completo.
*   Manter as bibliotecas cliente OAuth (como Assent) atualizadas.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar o fluxo de revogação de tokens do lado do provedor quando uma conta é desvinculada.
*   [ ] Permitir que usuários vejam e gerenciem quais dados e permissões foram concedidos a cada provedor vinculado.
*   [ ] Suporte para OpenID Connect (OIDC) sobre OAuth 2.0 para um fluxo de autenticação mais padronizado.
*   [ ] Adicionar um fluxo para lidar com \"account linking conflicts\" de forma mais interativa com o usuário.
*   [ ] Permitir que administradores configurem dinamicamente novos provedores OAuth através de uma UI (armazenando client_id/secret de forma segura).

---

*Última atualização: 2025-05-12*

---

OAuth é um fluxo complexo com muitas partes móveis, mas essencial para a experiência moderna de login.

O que vem agora? Podemos detalhar o `Deeper_Hub.MFA` (Autenticação Multifator), que é outra peça chave do `Auth`, ou talvez o `Deeper_Hub.Webhooks` para variar um pouco?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Ótimo! Vamos prosseguir com o `Deeper_Hub.MFA` (Autenticação Multifator). Este é um componente de segurança cada vez mais indispensável para proteger contas de usuário.

---

