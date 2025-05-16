# Módulo: `Deeper_Hub.Auth` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Auth`

O módulo `Deeper_Hub.Auth` é o pilar central para todas as funcionalidades de **autenticação** e **autorização** no sistema Deeper_Hub. Ele é responsável por verificar a identidade dos usuários, proteger recursos, gerenciar sessões, emitir e validar tokens, e aplicar políticas de acesso.

Este módulo abrange uma vasta gama de mecanismos de segurança, desde o login tradicional com senha até métodos modernos como WebAuthn e Autenticação Multifator (MFA), além de integrar com sistemas de Controle de Acesso Baseado em Papéis (RBAC) e gerenciamento de permissões. Seu objetivo é garantir que apenas usuários autenticados e autorizados possam acessar os recursos e funcionalidades apropriadas do Deeper_Hub. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Autenticação de Usuários:**
    *   Login com email/senha (via `AuthService` e `LoginService`).
    *   Login com OAuth (via `Deeper_Hub.OAuth`).
    *   Login com WebAuthn (FIDO2) (via `Deeper_Hub.WebAuthn`).
    *   Autenticação Multifator (MFA) com suporte a TOTP, SMS (implícito), Push (implícito), Códigos de Recuperação (via `Deeper_Hub.MFA`).
    *   Autenticação com tokens de API (via `TokenService`).
*   **Gerenciamento de Sessões:**
    *   Criação, validação, invalidação (logout) e renovação de sessões de usuário (via `SessionManager`, `SessionService`).
    *   Suporte a sessões persistentes (\"lembrar-me\").
    *   Limpeza periódica de sessões expiradas (`SessionCleanupWorker`).
    *   Aplicação de políticas de sessão (duração máxima, timeout por inatividade, etc., via `Deeper_Hub.SessionPolicy`).
*   **Gerenciamento de Tokens:**
    *   Geração e validação de tokens JWT (acesso, refresh) (via `TokenService`, `JwtService`).
    *   Geração e validação de tokens opacos (API, recuperação de senha, verificação de email) (via `TokenService`).
    *   Rotação de tokens de refresh (via `TokenRotationService`).
    *   Blacklist de tokens revogados (via `TokenBlacklist` e `BlacklistService`).
*   **Autorização e Controle de Acesso:**
    *   Verificação de permissões baseada em papéis (RBAC) (via `Deeper_Hub.RBAC`, `PermissionService`, `RoleService`).
    *   Gerenciamento de papéis, permissões e hierarquias de papéis.
    *   Suporte a permissões temporárias.
*   **Recuperação de Conta:**
    *   Fluxo de \"esqueci minha senha\" com tokens de reset (via `Deeper_Hub.Recovery`, `PasswordResetService`).
    *   Verificação de email (via `Deeper_Hub.Recovery`, `EmailVerificationService`).
*   **Segurança de Credenciais:**
    *   Hashing seguro de senhas (via `PasswordAdapter` ou `Deeper_Hub.Shared.Encryption.HashingService`).
    *   Políticas de força de senha.
*   **Integrações de Segurança:**
    *   Limitação de Taxa (Rate Limiting) para endpoints de autenticação (via `RateLimitIntegration`).
    *   Registro de eventos de autenticação e autorização no sistema de Auditoria (via `AuditIntegration`).
    *   Publicação de eventos de domínio relacionados à autenticação no EventBus (via `EventIntegration`).
*   **Validação de Entradas:**
    *   Validação e sanitização de credenciais e tokens (via `Validation.AuthValidation`).

## 🏗️ 3. Arquitetura e Design

O módulo `Deeper_Hub.Auth` é uma fachada de alto nível que orquestra uma série de submódulos e serviços especializados. A complexidade é gerenciada através da separação de responsabilidades em componentes menores e mais focados.

### 3.1. Componentes Principais

**(Baseado na documentação original e na refatoração proposta)**

*   **`Deeper_Hub.Auth` (Fachada Pública):**
    *   Ponto de entrada principal para funcionalidades de autenticação e autorização.
    *   Delega para `Deeper_Hub.Auth.AuthService`.
*   **`Deeper_Hub.Auth.AuthService`:**
    *   Serviço central que coordena as operações de login, logout, validação de sessão/token, e verificação de permissões.
    *   Utiliza outros serviços especializados como `LoginService`, `SessionService`, `TokenService`, `PermissionService`, `RoleService`.
*   **`Deeper_Hub.Auth.Services.LoginService`:**
    *   Lida especificamente com a lógica de autenticação primária (ex: verificação de email/senha).
*   **`Deeper_Hub.Auth.SessionManager` (GenServer):**
    *   Gerencia o ciclo de vida das sessões de usuários (criação, validação, invalidação, renovação).
    *   Pode usar `Deeper_Hub.Auth.Schema.Session` para persistência.
*   **`Deeper_Hub.Auth.TokenService` (Pode ser `Deeper_Hub.Tokens.TokenFacadeUnified`):**
    *   Responsável por gerar, validar, revogar e rotacionar diferentes tipos de tokens (JWT, API, recuperação).
    *   Pode incluir subcomponentes como `JwtService`, `BlacklistService`, `TokenRotationService`.
*   **`Deeper_Hub.Auth.PermissionService` (ou integração com `Deeper_Hub.RBAC`):**
    *   Gerencia a definição de permissões e sua associação a papéis ou usuários.
*   **`Deeper_Hub.Auth.RoleService` (ou integração com `Deeper_Hub.RBAC`):**
    *   Gerencia a definição de papéis.
*   **`Deeper_Hub.MFA` (Módulo separado, mas fortemente acoplado):**
    *   `Deeper_Hub.MFA.MFAFacade` e seus serviços (`TOTPService`, `WebAuthnService` via `Deeper_Hub.WebAuthn`, `RecoveryCodeService`, `PushVerificationService`).
*   **`Deeper_Hub.OAuth` (Módulo separado, mas fortemente acoplado):**
    *   `Deeper_Hub.OAuth.OAuthFacadeUnified` e seus serviços para autenticação com provedores externos.
*   **`Deeper_Hub.Recovery` (Módulo separado, mas fortemente acoplado):**
    *   `Deeper_Hub.Recovery.RecoveryFacadeUnified` para recuperação de senha e verificação de email.
*   **Schemas Ecto:**
    *   `Deeper_Hub.Auth.Schema.Permission`
    *   `Deeper_Hub.Auth.Schema.Role`
    *   `Deeper_Hub.Auth.Schema.RolePermission`
    *   `Deeper_Hub.Auth.Schema.UserPermission`
    *   `Deeper_Hub.Auth.Schema.UserRole`
    *   `Deeper_Hub.Auth.TokenSchema` (ou `Deeper_Hub.Tokens.Schema.ApiToken` e `TokenBlacklist`)
    *   `Deeper_Hub.Auth.TemporaryPassword` (ou `Deeper_Hub.TemporaryPassword.Schema.TempPassword`)
*   **Workers:**
    *   `Deeper_Hub.Auth.Workers.SessionCleanupWorker`
    *   `Deeper_Hub.Auth.Workers.TokenCleanupWorker`
*   **Integrações:**
    *   `Deeper_Hub.Auth.Integrations.AuditIntegration`: Para logs de auditoria.
    *   `Deeper_Hub.Auth.Integrations.EventIntegration`: Para eventos de domínio.
    *   `Deeper_Hub.Auth.RateLimitIntegration`: Para limitar tentativas de autenticação.
*   **Validação:**
    *   `Deeper_Hub.Auth.Validation.AuthValidation`: Para validar entradas.

### 3.2. Estrutura de Diretórios (Proposta Consolidada)

```
auth/
├── auth.ex                         # Fachada Pública
├── auth_service.ex                 # Serviço Coordenador
│
├── services/
│   ├── login_service.ex
│   └── password_adapter.ex         # (Se for distinto de PasswordService)
│   # Outros serviços específicos de Auth que não se encaixam em MFA, OAuth, etc.
│
├── session_manager.ex              # GenServer para gerenciamento de sessões
├── session_service.ex              # Lógica de negócio para sessões
│
├── validation/
│   └── auth_validation.ex
│
├── integrations/
│   ├── audit_integration.ex
│   ├── event_integration.ex
│   └── rate_limit_integration.ex
│
├── workers/
│   ├── session_cleanup_worker.ex
│   └── token_cleanup_worker.ex     # (Se não estiver em Deeper_Hub.Tokens)
│
├── supervisor.ex                   # Supervisor para os processos de Auth
└── telemetry.ex                    # Telemetria específica do Auth
```
**Módulos relacionados que teriam suas próprias estruturas:**
`mfa/`
`oauth/`
`recovery/`
`rbac/` (incluindo schemas de Permission, Role, etc.)
`tokens/` (incluindo schemas de Token, Blacklist, etc.)
`web_authn/`
`session_policy/`
`security_questions/`

### 3.3. Decisões de Design Importantes

*   **Camada de Fachada Clara:** `Deeper_Hub.Auth` serve como o único ponto de entrada para o restante da aplicação.
*   **Serviços Especializados:** A lógica de autenticação, sessão, token, MFA, OAuth, etc., é dividida em serviços dedicados para manter a coesão e facilitar a manutenção.
*   **Estado Gerenciado por GenServers:** Componentes como `SessionManager` e o `TokenBlacklistService` (dentro de `Deeper_Hub.Tokens`) usam GenServers para gerenciar estado concorrente.
*   **Segurança por Padrão:** Práticas como hashing forte de senhas, uso de tokens seguros (JWTs assinados, tokens opacos com entropia suficiente), e proteção contra ataques comuns são incorporadas.
*   **Extensibilidade:** O uso de adaptadores (implícito nos serviços) e a arquitetura modular permitem a adição de novos métodos de autenticação ou políticas de segurança no futuro.

## 🛠️ 4. Casos de Uso Principais

*   **Login com Senha:** Usuário fornece email/senha. `Auth.login` -> `AuthService` -> `LoginService` verifica credenciais -> `PasswordAdapter` compara hash -> `SessionManager` cria sessão -> `TokenService` gera tokens.
*   **Login com Google (OAuth):** Usuário clica em \"Login com Google\". Redirecionado para `Deeper_Hub.OAuth` que interage com o Google -> `OAuth` autentica/cria usuário -> `AuthService` (ou `SessionManager`) cria sessão para o usuário Deeper_Hub.
*   **Registro de Chave de Segurança (WebAuthn):** Usuário adiciona uma chave de segurança. `Deeper_Hub.MFA` (via `WebAuthnService`) gerencia o fluxo de registro.
*   **Verificação de Acesso a Recurso:** Um controller de API verifica se o usuário tem permissão para acessar um endpoint. O controller chama `Deeper_Hub.Auth.authorize(user_id, resource, action)` -> `AuthService` -> `PermissionService` (ou `Deeper_Hub.RBAC`) verifica papéis e permissões.
*   **Recuperação de Senha:** Usuário solicita reset de senha. `Deeper_Hub.Recovery.RecoveryFacade` -> `PasswordResetService` gera token -> `TokenService` armazena token -> `Notifications` envia email. Usuário clica no link -> `PasswordResetService` verifica token -> `PasswordService` atualiza senha.
*   **Logout:** Usuário clica em logout. `Auth.logout` -> `SessionManager` invalida sessão -> `TokenService` (via `BlacklistService`) adiciona token de acesso à blacklist.

## 🌊 5. Fluxos Importantes

### 5.1. Fluxo de Login com Email e Senha (com MFA opcional)

1.  **Controller API/Web:** Recebe `email` e `password`.
2.  Chama `Deeper_Hub.Auth.login(email, password, ip_address, device_info, metadata)`.
3.  **`Deeper_Hub.Auth.AuthService`:**
    *   Valida entrada (`AuthValidation`).
    *   Verifica rate limit (`RateLimitIntegration`).
    *   Delega para `Deeper_Hub.Accounts.get_user_by_email(email)` para buscar o usuário.
        *   Se não encontrado, retorna `{:error, :invalid_credentials}`.
    *   Delega para `Deeper_Hub.Auth.Services.PasswordService.compare_password(user, password)`.
        *   Se a senha não bate, registra falha de login (`RateLimitIntegration`), retorna `{:error, :invalid_credentials}`.
    *   **Verifica se MFA é necessário para o usuário (via `Deeper_Hub.MFA.MFAPolicyService`).**
        *   Se sim, retorna `{:error, :mfa_required, %{user_id: user.id, available_methods: [...]}}`. O frontend/cliente deve então iniciar o fluxo MFA.
        *   Se não, prossegue.
    *   Chama `Deeper_Hub.Auth.SessionManager.create_session(user, context_info)` para criar uma sessão.
    *   Chama `Deeper_Hub.Auth.TokenService.generate_token_pair(user.id, %{session_id: session.id})` para gerar tokens de acesso e refresh.
    *   Publica evento `UserLoggedInEvent` (via `EventIntegration`).
    *   Registra evento de auditoria (`AuditIntegration`).
    *   Retorna `{:ok, %{user: user, session: session, access_token: access_token, refresh_token: refresh_token}}`.

### 5.2. Fluxo de Validação de Token de Acesso (em um Plug/Middleware)

1.  **Plug/Middleware:** Extrai o token de acesso do header `Authorization`.
2.  Chama `Deeper_Hub.Auth.validate_token(access_token)`.
3.  **`Deeper_Hub.Auth.AuthService`:**
    *   Delega para `Deeper_Hub.Auth.TokenService.validate_token(access_token)`.
4.  **`Deeper_Hub.Auth.TokenService` (usando `JwtService` e `BlacklistService`):**
    *   Verifica a assinatura do JWT.
    *   Verifica a data de expiração.
    *   Verifica se o token está na blacklist.
    *   Se tudo ok, extrai `user_id` e `session_id` das claims.
    *   Delega para `Deeper_Hub.Auth.SessionManager.validate_session(session_id)`.
5.  **`Deeper_Hub.Auth.SessionManager`:**
    *   Verifica se a sessão existe, está ativa e não expirou (considerando `SessionPolicy`).
    *   Se a sessão é válida, retorna `{:ok, session}`.
6.  **`Deeper_Hub.Auth.AuthService`:** Se tudo válido, retorna `{:ok, %{user_id: user_id, session_id: session_id, claims: claims}}` para o Plug.
7.  **Plug/Middleware:** Adiciona `current_user_id` e `session_id` à `conn.assigns`.

## 📡 6. API (Funções Públicas da Fachada `Deeper_Hub.Auth`)

*(Muitas funções já foram documentadas na seção de `AuthFacade` da documentação original. O foco aqui é na consolidação e clareza.)*

### 6.1. `Deeper_Hub.Auth.login(email :: String.t(), password :: String.t(), ip_address :: String.t() | nil, device_info :: map() | nil, metadata :: map() | nil) :: {:ok, AuthResponse.t()} | {:error, atom() | {atom(), map()}}`

*   **Descrição:** Autentica um usuário com email e senha.
*   **`AuthResponse.t()`:** `%{user: User.t(), access_token: String.t(), refresh_token: String.t(), session_id: String.t()}`.
*   **Retorno de Erro:**
    *   `{:error, :invalid_credentials}`
    *   `{:error, :user_locked}`
    *   `{:error, :mfa_required, %{user_id: String.t(), available_methods: list(atom())}}`
    *   `{:error, :rate_limited, retry_after_seconds :: non_neg_integer()}`

### 6.2. `Deeper_Hub.Auth.logout(access_token :: String.t(), opts :: keyword()) :: :ok | {:error, atom()}`

*   **Descrição:** Realiza logout do usuário, invalidando a sessão e o token de acesso.
*   **`opts`:**
    *   `:revoke_all_sessions_for_user` (boolean): Se `true`, invalida todas as sessões do usuário.
*   **Retorno:** `:ok` ou `{:error, :invalid_token | :session_not_found}`.

### 6.3. `Deeper_Hub.Auth.refresh_session_token(refresh_token :: String.t(), context :: map()) :: {:ok, AuthResponse.t()} | {:error, atom()}`

*   **Descrição:** Gera um novo par de tokens de acesso e refresh usando um token de refresh válido.
*   **`context`:** `%{ip_address: String.t(), user_agent: String.t()}`.

### 6.4. `Deeper_Hub.Auth.validate_token(access_token :: String.t()) :: {:ok, TokenClaims.t()} | {:error, atom()}`

*   **Descrição:** Valida um token de acesso.
*   **`TokenClaims.t()`:** `%{user_id: String.t(), session_id: String.t(), exp: integer(), ...}`.
*   **Retorno de Erro:** `:token_invalid`, `:token_expired`, `:session_invalid`, `:session_expired`.

### 6.5. `Deeper_Hub.Auth.authorize(user_id :: String.t(), resource :: String.t() | atom(), action :: atom(), resource_details :: map() | nil) :: :ok | {:error, :unauthorized}`

*   **Descrição:** Verifica se um usuário tem permissão para realizar uma ação em um recurso.
*   **`resource_details`:** Metadados sobre o recurso específico sendo acessado (ex: para verificações baseadas em propriedade).

### 6.6. `Deeper_Hub.Auth.get_user_permissions(user_id :: String.t()) :: {:ok, list(String.t())}` (Nova Funcionalidade Sugerida)

*   **Descrição:** Retorna uma lista consolidada de todas as permissões efetivas de um usuário.

## ⚙️ 7. Configuração

O módulo `Auth` e seus submódulos são extensivamente configurados via `Deeper_Hub.Core.ConfigManager`.

*   **`[:auth, :session, :default_duration_seconds]`**: Duração padrão das sessões. (Padrão: `86400` - 24 horas)
*   **`[:auth, :session, :idle_timeout_seconds]`**: Timeout de inatividade da sessão. (Padrão: `1800` - 30 minutos)
*   **`[:auth, :token, :jwt, :secret_key]`**: Chave secreta para assinar JWTs (DEVE ser configurada via variável de ambiente segura).
*   **`[:auth, :token, :jwt, :access_token_ttl_seconds]`**: TTL para tokens de acesso. (Padrão: `900` - 15 minutos)
*   **`[:auth, :token, :jwt, :refresh_token_ttl_seconds]`**: TTL para tokens de refresh. (Padrão: `2592000` - 30 dias)
*   **`[:auth, :token, :api_token, :default_ttl_days]`**: TTL padrão para tokens de API.
*   **`[:auth, :password, :min_length]`**: Comprimento mínimo da senha. (Padrão: `8`)
*   **`[:auth, :password, :require_uppercase]`**: (Boolean) Exigir maiúscula. (Padrão: `true`)
*   **`[:auth, :password, :require_lowercase]`**: (Boolean) Exigir minúscula. (Padrão: `true`)
*   **`[:auth, :password, :require_digit]`**: (Boolean) Exigir dígito. (Padrão: `true`)
*   **`[:auth, :password, :require_special_char]`**: (Boolean) Exigir caractere especial. (Padrão: `true`)
*   **`[:auth, :rate_limit, :login_attempts, :max_per_minute]`**: Limite de tentativas de login por minuto.
*   **`[:auth, :rate_limit, :login_attempts, :block_duration_seconds]`**: Duração do bloqueio após exceder tentativas.
*   *(Configurações específicas de MFA, OAuth, RBAC, Recovery, etc., residiriam em seus respectivos prefixos, ex: `[:mfa, :totp, :issuer_name]`, `[:oauth, :google, :client_id]`)*

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`, `Core.EventBus`, `Core.Logger`, `Core.Metrics`, `Core.Repo`.
*   `Deeper_Hub.Accounts`: Para buscar informações de usuário.
*   `Deeper_Hub.MFA`, `Deeper_Hub.OAuth`, `Deeper_Hub.Recovery`, `Deeper_Hub.RBAC`, `Deeper_Hub.Tokens`, `Deeper_Hub.WebAuthn`, `Deeper_Hub.SessionPolicy`, `Deeper_Hub.SecurityQuestions`.
*   `Deeper_Hub.Notifications` (indireta): Para enviar emails de reset de senha, alertas de MFA, etc.
*   `Deeper_Hub.Shared.Utils`, `Deeper_Hub.Shared.Encryption`.

### 8.2. Bibliotecas Externas

*   `Joken` ou `JOSE`: Para manipulação de JWTs.
*   `Comeonin`, `Argon2`, `Bcrypt`: Para hashing de senhas.
*   Bibliotecas OAuth de cliente (ex: `Assent` para Elixir).
*   Bibliotecas WebAuthn (ex: `Wax` ou `Webauthnix`).
*   Bibliotecas TOTP (ex: `ex_totp`).

## 🤝 9. Como Usar / Integração

**Em um Plug de Autenticação (Phoenix):**
```elixir
defmodule MyAppWeb.AuthPlug do
  import Plug.Conn
  alias Deeper_Hub.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    with [\"Bearer \" <> token] <- get_req_header(conn, \"authorization\"),
         {:ok, claims} <- Auth.validate_token(token) do
      assign(conn, :current_user_id, claims.user_id)
    else
      _ ->
        # Se não houver token ou for inválido, pode-se optar por não fazer nada
        # ou enviar um 401 se o endpoint for protegido.
        conn
        # Para endpoints protegidos:
        # conn |> send_resp(401, \"Unauthorized\") |> halt()
    end
  end
end
```

**Verificando Permissão em um Controller:**
```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller
  alias Deeper_Hub.Auth

  plug MyAppWeb.AuthPlug # Garante que :current_user_id está disponível

  def create(conn, params) do
    user_id = conn.assigns.current_user_id
    case Auth.authorize(user_id, :post, :create) do
      :ok ->
        # ... lógica para criar post ...
        json(conn, %{data: \"Post criado\"})
      {:error, :unauthorized} ->
        conn |> put_status(403) |> json(%{error: \"Forbidden\"})
    end
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários para cada serviço (`LoginService`, `SessionManager`, `TokenService`, etc.).
*   Testar cada fluxo de autenticação (senha, OAuth, WebAuthn, MFA) de ponta a ponta.
*   Testar a lógica de validação e revogação de tokens.
*   Testar a lógica de RBAC (criação de papéis, atribuição de permissões, verificação).
*   Testar os workers de limpeza.
*   Localização: `test/deeper_hub/auth/`, `test/deeper_hub/mfa/`, etc.

### 10.2. Métricas

*   `deeper_hub.auth.login.attempts.count` (tags: `method` (`password`, `oauth`, `webauthn`), `status` (`success`, `failure`, `mfa_required`))
*   `deeper_hub.auth.login.duration_ms` (Histograma, tags: `method`)
*   `deeper_hub.auth.mfa.verifications.count` (tags: `method` (`totp`, `recovery`), `status` (`success`, `failure`))
*   `deeper_hub.auth.token.generated.count` (tags: `type` (`access`, `refresh`, `api`))
*   `deeper_hub.auth.token.validated.count` (tags: `type`, `status` (`valid`, `invalid`, `expired`))
*   `deeper_hub.auth.token.revoked.count` (tags: `type`)
*   `deeper_hub.auth.session.active.gauge`: Número de sessões ativas.
*   `deeper_hub.auth.session.created.count`
*   `deeper_hub.auth.session.revoked.count`
*   `deeper_hub.auth.authorization.checks.count` (tags: `resource`, `action`, `result` (`granted`, `denied`))

### 10.3. Logs

*   **Nível INFO:** Login/logout bem-sucedido, token gerado/revogado, sessão criada/invalidada, permissão concedida.
*   **Nível WARNING:** Tentativa de login falha, token inválido/expirado, sessão inválida/expirada, permissão negada, tentativa de uso de token na blacklist.
*   **Nível ERROR:** Erros internos nos serviços de autenticação/autorização, falha ao gerar hash de senha, falha na comunicação com provedor OAuth.
*   **Logs de Auditoria (via `AuditIntegration`):** Todas as ações significativas de autenticação, autorização, mudanças de senha, configuração de MFA, etc., são registradas.

### 10.4. Telemetria

Eventos Telemetry são emitidos para operações chave:
*   `[:deeper_hub, :auth, :login, :start | :stop | :exception]`
*   `[:deeper_hub, :auth, :token, :validation, :start | :stop | :exception]`
*   `[:deeper_hub, :auth, :session, :creation, :start | :stop | :exception]`
*   `[:deeper_hub, :auth, :authorization, :check, :start | :stop | :exception]`
*   *(Eventos específicos para MFA, OAuth, RBAC, etc., dentro de seus respectivos módulos de telemetria).*

## ❌ 11. Tratamento de Erros

*   Funções de autenticação e validação retornam tuplas `{:ok, ...}` ou `{:error, reason}`.
*   Erros comuns incluem `:invalid_credentials`, `:user_locked`, `:mfa_required`, `:token_invalid`, `:token_expired`, `:session_invalid`, `:unauthorized`.
*   Falhas de comunicação com serviços externos (ex: OAuth providers) são gerenciadas com Circuit Breakers (via `Core.HTTPClient` ou adaptadores específicos) e timeouts.
*   Tentativas excessivas de login ou outras operações sensíveis são limitadas por `RateLimitIntegration`.

## 🛡️ 12. Considerações de Segurança

*   **Hashing de Senhas:** Usar algoritmos fortes e salt.
*   **Armazenamento de Tokens:** Tokens de sessão e refresh devem ser armazenados de forma segura no cliente (ex: cookies HttpOnly, Secure). Tokens de API devem ser tratados como segredos.
*   **Proteção CSRF:** Necessária para aplicações web que usam sessões baseadas em cookies.
*   **Proteção contra Enumeração de Usuários:** Respostas de login/reset não devem indicar se um usuário existe.
*   **Segurança de Tokens JWT:** Usar chaves secretas fortes, algoritmos de assinatura seguros (ex: HS256, RS256), e validar claims `exp`, `nbf`, `iat`.
*   **Rate Limiting:** Essencial para prevenir ataques de força bruta.
*   **MFA:** Fortemente recomendado para aumentar a segurança das contas.
*   **Validação de Redirecionamento OAuth:** Validar estritamente as URIs de redirecionamento.
*   **Princípio do Menor Privilégio:** Aplicado através do RBAC.
*   **Rotação de Segredos:** Chaves de assinatura JWT e outros segredos devem ser rotacionados periodicamente.

## 🧑‍💻 13. Contribuição

*   Qualquer nova funcionalidade de autenticação ou autorização deve passar por uma revisão de segurança rigorosa.
*   Siga os padrões de nomenclatura e os princípios de design estabelecidos (Fachadas, Serviços).
*   Garanta que todos os fluxos de autenticação e autorização sejam cobertos por testes.
*   Mantenha a separação de responsabilidades entre `Auth`, `MFA`, `OAuth`, `RBAC`, etc.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar Single Sign-On (SSO) com SAML 2.0 ou OpenID Connect.
*   [ ] Adicionar suporte a \"Login com Magic Link\".
*   [ ] Permitir que usuários vejam e gerenciem suas sessões ativas.
*   [ ] Implementar políticas de bloqueio de conta mais avançadas (ex: bloqueio progressivo).
*   [ ] Adicionar detecção de comprometimento de credenciais (integração com serviços como Have I Been Pwned).
*   [ ] Melhorar o gerenciamento de escopos para tokens de API e OAuth.
*   [ ] Suporte para delegação de autorização (ex: usuário permite que um aplicativo de terceiros acesse seus dados com escopo limitado).
*   [ ] Implementar revogação de tokens de refresh mais granular e eficiente.

---

*Última atualização: 2025-05-11*

---

Ufa! Esse foi denso. O módulo `Auth` é realmente um gigante.

Qual módulo você gostaria de abordar em seguida? `Deeper_Hub.API` ou `Deeper_Hub.Security` talvez? Ou algo do Core?"""),
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
                types.Part.from_text(text="""Ok, vamos para o módulo `Deeper_Hub.API`! Este módulo é a porta de entrada para muitas interações com o sistema Deeper_Hub, então sua documentação é crucial.

---

