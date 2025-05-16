# Módulo: `DeeperHub.Security.AdminAuth` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.AdminAuth`

O módulo `DeeperHub.Security.AdminAuth` é dedicado especificamente à **autenticação e autorização de usuários administradores** que acessam as interfaces de gerenciamento e administração do sistema DeeperHub. Ele fornece um conjunto de funcionalidades de segurança mais rigorosas e adaptadas às necessidades de contas com privilégios elevados.

Isso pode incluir:
*   Autenticação de dois fatores (MFA/TOTP) obrigatória ou fortemente recomendada.
*   Políticas de senha mais estritas.
*   Monitoramento e auditoria detalhada de todas as ações administrativas.
*   Gerenciamento de sessões de administrador com timeouts mais curtos.
*   Controle de acesso granular às diferentes funcionalidades administrativas baseado em papéis e permissões específicas de administração.

O objetivo é proteger as áreas mais sensíveis do sistema DeeperHub contra acesso não autorizado e abuso de privilégios. 😊

*(Nota: Se a autenticação de administradores for gerenciada pelo mesmo sistema que usuários regulares (`DeeperHub.Auth`) mas com políticas diferentes, este módulo pode atuar como uma camada de especialização ou configuração sobre `DeeperHub.Auth`. Se for um sistema completamente separado, ele terá seus próprios componentes de login, sessão, etc.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Autenticação de Administradores (`authenticate_admin/3`):**
    *   Verificar credenciais (username/password) específicas para contas de administrador.
    *   Forçar ou gerenciar a verificação de Autenticação Multifator (MFA), especialmente TOTP (via `AdminTOTPService`).
*   **Gerenciamento de Contas de Administrador (`create_admin/1`, `update_admin/2`, etc.):**
    *   Criação, atualização, ativação/desativação de contas de administrador.
    *   Atribuição de papéis e permissões administrativas específicas (integrando com `DeeperHub.RBAC`).
*   **Políticas de Senha de Administrador:**
    *   Aplicar políticas de complexidade e expiração de senha mais rigorosas para administradores.
*   **Gerenciamento de Sessões de Administrador:**
    *   Criar sessões com durações e timeouts de inatividade potencialmente mais curtos.
    *   Invalidar sessões de administrador (ex: após mudança de senha, detecção de risco).
    *   Gerenciar tokens de sessão específicos para administradores (via `AdminTokenService`).
*   **Autorização de Ações Administrativas (`authorize_action/4`, `has_admin_permission?/2`):**
    *   Verificar se um administrador autenticado tem permissão para executar uma ação administrativa específica ou acessar uma funcionalidade do painel de controle.
    *   Potencialmente exigir verificação MFA adicional para ações administrativas de alto risco, mesmo se já logado (step-up authentication).
*   **Auditoria Detalhada (`AdminActionLog`):**
    *   Registrar todas as tentativas de login de administrador (sucesso e falha).
    *   Registrar todas as ações significativas realizadas por administradores autenticados.
*   **Gerenciamento de Tokens de Administrador (`AdminTokenService`):**
    *   Geração, validação e revogação de tokens de sessão para administradores.
*   **Proteção contra Força Bruta para Login de Admin:**
    *   Aplicar políticas de bloqueio mais estritas para tentativas falhas de login de administrador.

## 🏗️ 3. Arquitetura e Design

A arquitetura pode variar dependendo se é uma extensão do `DeeperHub.Auth` ou um subsistema mais independente. Assumindo uma especialização:

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.AdminAuth` (Fachada Pública):**
    *   Ponto de entrada para funcionalidades de autenticação e autorização de administradores.
    *   Delega para `AdminAuthService`.
2.  **`DeeperHub.Security.AdminAuth.Services.AdminAuthService`:**
    *   Serviço central que orquestra a autenticação, gerenciamento de contas e verificação de permissões de admin.
    *   Utiliza `AdminTOTPService`, `AdminTokenService`, `PermissionService` (específico para admin ou o RBAC geral), e `AdminActionAuthService`.
3.  **`DeeperHub.Security.AdminAuth.Services.AdminTOTPService`:**
    *   Gerencia a configuração e verificação de TOTP para administradores.
4.  **`DeeperHub.Security.AdminAuth.Services.AdminTokenService`:**
    *   Gerencia o ciclo de vida de tokens de sessão para administradores.
5.  **`DeeperHub.Security.AdminAuth.Services.AdminActionAuthService`:**
    *   Verifica se um admin está autorizado a realizar uma ação específica, possivelmente exigindo \"step-up authentication\" com MFA.
6.  **`DeeperHub.Security.AdminAuth.Services.PermissionService` (ou integração com `DeeperHub.RBAC`):**
    *   Define e verifica permissões granulares para o painel de administração (ex: \"gerenciar_usuarios\", \"ver_logs_auditoria\", \"configurar_sistema\").
7.  **Schemas Ecto:**
    *   `DeeperHub.Security.AdminAuth.Schema.AdminSchema`: Para dados da conta de administrador.
    *   `DeeperHub.Security.AdminAuth.Schema.AdminToken`: Para tokens de sessão de admin.
    *   `DeeperHub.Security.AdminAuth.Schema.AdminTOTP`: Para configurações TOTP de admin.
    *   `DeeperHub.Security.AdminAuth.Schema.AdminActionLog`: Para auditoria de ações de admin.
    *   `DeeperHub.Security.AdminAuth.Schema.AdminAction`, `AdminActionRisk`, `AdminActionVerification`: Para definir e controlar o risco de ações administrativas.
8.  **Integração com `DeeperHub.Core.ConfigManager` / `SecurityPolicyManager`:**
    *   Para políticas de senha de admin, duração de sessão de admin, políticas de MFA de admin.

### 3.2. Estrutura de Diretórios (Proposta)

```
security/admin_auth/
├── admin_auth.ex                     # Fachada Pública (AdminAuthAdapter da doc original)
│
├── services/
│   ├── admin_auth_service.ex         # Serviço orquestrador
│   ├── admin_totp_service.ex
│   ├── admin_token_service.ex
│   ├── admin_action_auth_service.ex
│   └── permission_service.ex         # (Ou usa DeeperHub.RBAC diretamente)
│
├── schemas/                          # (Ou schema/ singular)
│   ├── admin_schema.ex
│   ├── admin_token.ex
│   ├── admin_totp.ex
│   ├── admin_action_log.ex
│   ├── admin_action.ex
│   ├── admin_action_risk.ex
│   └── admin_action_verification.ex
│
├── supervisor.ex
└── telemetry.ex                      # (Se necessário, específico para AdminAuth)
```

### 3.3. Decisões de Design Importantes

*   **Isolamento (Parcial ou Total):** Decidir se a autenticação de admin usa um fluxo completamente separado ou se é uma variação do fluxo de usuário normal com políticas mais rígidas. Um fluxo separado pode oferecer maior segurança, mas também maior complexidade.
*   **MFA Mandatório:** Para a maioria das contas de admin, MFA (especialmente TOTP ou Chaves de Segurança) deve ser mandatório ou altamente imposto.
*   **Princípio do Menor Privilégio:** Administradores devem ter apenas as permissões estritamente necessárias para suas funções. Evitar contas \"super admin\" genéricas, se possível.
*   **Step-up Authentication:** Para ações administrativas particularmente destrutivas ou sensíveis, exigir uma nova verificação MFA mesmo que o admin já esteja logado.

## 🛠️ 4. Casos de Uso Principais

*   **Administrador Faz Login no Painel:**
    *   Admin fornece username/senha na página de login do painel.
    *   `AdminAuth.authenticate_admin/3` é chamado.
    *   Credenciais são validadas.
    *   Se MFA estiver configurado, o fluxo de verificação TOTP (ou outro método) é iniciado.
    *   Se tudo ok, uma sessão de admin é criada e um token é emitido.
*   **Administrador Tenta Excluir um Usuário:**
    *   Admin clica em \"Excluir Usuário\" na interface.
    *   A interface chama um endpoint protegido.
    *   O backend verifica a sessão do admin.
    *   Chama `AdminAuth.authorize_action(admin_id, :delete_user, %{target_user_id: \"xyz\"}, mfa_code_if_required)`.
    *   `AdminActionAuthService` verifica se a ação `:delete_user` requer MFA \"step-up\". Se sim, valida `mfa_code`.
    *   Verifica se o admin tem a permissão \"pode_excluir_usuarios\" (via `PermissionService` / RBAC).
    *   Se autorizado, a ação é permitida.
    *   `AdminActionLog` registra a ação.
*   **Administrador Altera uma Configuração de Segurança Crítica:**
    *   Similar ao caso acima, mas a ação pode ser, por exemplo, `:update_security_policy_mfa`.
    *   A autorização e a possível exigência de MFA step-up são verificadas.

## 🌊 5. Fluxos Importantes

### Fluxo de Autenticação de Administrador com TOTP

1.  **Interface de Login Admin:** Admin submete username e password.
2.  **Backend Controller:** Chama `DeeperHub.Security.AdminAuth.authenticate_admin(username, password, context)`.
3.  **`AdminAuthService`:**
    *   Valida credenciais primárias (username/password).
    *   Se falhar, retorna erro e registra tentativa falha (considerando `BruteForceProtection` para admin).
    *   Se sucesso, verifica se o admin tem TOTP configurado e ativo (via `AdminTOTPService.is_enabled?(admin_id)`).
    *   **Se TOTP Ativo:** Retorna `{:error, :mfa_totp_required, %{admin_id: admin.id}}` para o controller.
    *   **Se TOTP Não Ativo (e não mandatório):** Procede para criar sessão e token (via `AdminTokenService`).
4.  **Interface de Login Admin:** Se `:mfa_totp_required`, exibe campo para código TOTP. Admin submete o código.
5.  **Backend Controller:** Chama `DeeperHub.Security.AdminAuth.Services.AdminTOTPService.verify(admin_id, totp_code)`.
6.  **`AdminTOTPService`:**
    *   Verifica o código TOTP.
    *   Se válido, retorna `{:ok, :valid}`.
    *   Se inválido, retorna erro e registra tentativa falha de MFA.
7.  **Backend Controller (após TOTP válido):**
    *   Chama `AdminAuthService` (ou diretamente `AdminTokenService` e `SessionManager`) para criar a sessão de admin e emitir tokens.
    *   Registra login bem-sucedido no `AdminActionLog`.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Security.AdminAuth`)

### 6.1. `DeeperHub.Security.AdminAuth.authenticate_admin(username :: String.t(), password :: String.t(), opts :: keyword()) :: {:ok, %{admin: AdminSchema.t(), token: String.t()}} | {:error, :invalid_credentials | :account_locked | :mfa_required | :mfa_invalid}`

*   **Descrição:** Autentica um administrador.
*   **`opts`:** `:ip_address`, `:device_info`, `:mfa_code` (se o fluxo de MFA for em uma única etapa).

### 6.2. `DeeperHub.Security.AdminAuth.verify_admin_mfa(admin_id :: String.t(), mfa_method :: atom(), code :: String.t(), opts :: keyword()) :: {:ok, %{admin: AdminSchema.t(), token: String.t()}} | {:error, :mfa_invalid | :max_attempts_reached}` (Nova Sugestão)

*   **Descrição:** Verifica um código MFA para um admin que já passou pela autenticação primária. Se sucesso, finaliza o login e retorna tokens.
*   **`mfa_method`:** Ex: `:totp`.

### 6.3. `DeeperHub.Security.AdminAuth.has_admin_permission?(admin_id :: String.t(), permission :: String.t() | atom(), resource_details :: map() | nil) :: boolean()`

*   **Descrição:** Verifica se um administrador possui uma permissão específica.
*   **`permission`:** Ex: `\"users:delete\"`, `:view_audit_logs`.

### 6.4. `DeeperHub.Security.AdminAuth.authorize_action(admin_id :: String.t(), action_atom :: atom(), action_params :: map() | nil, verification_data :: map() | nil) :: :ok | {:error, :unauthorized | :mfa_required_for_action | :mfa_invalid}` (Nova Sugestão)

*   **Descrição:** Autoriza uma ação administrativa, possivelmente exigindo \"step-up authentication\" (MFA).
*   **`action_atom`:** Identificador único da ação administrativa (ex: `:admin_update_user_role`).
*   **`verification_data`:** `%{mfa_code: \"123456\"}` se MFA for exigido pela política da ação.

### 6.5. Funções CRUD para Admins (ex: `create_admin/1`, `get_admin/1`, `list_admins/1`, `update_admin/2`, `deactivate_admin/2`)

*   Estas funções gerenciariam as contas dos administradores.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :admin_auth, :password_policy, :min_length]`** (Integer): Comprimento mínimo da senha de admin. (Padrão: `12`)
*   **`[:security, :admin_auth, :password_policy, :expiry_days]`** (Integer): Dias para expiração da senha de admin. (Padrão: `90`)
*   **`[:security, :admin_auth, :mfa, :is_mandatory]`** (Boolean): Se MFA é obrigatório para todos os admins. (Padrão: `true`)
*   **`[:security, :admin_auth, :mfa, :allowed_methods]`** (List de Atoms): Métodos MFA permitidos para admins (ex: `[:totp, :security_key]`).
*   **`[:security, :admin_auth, :session, :max_duration_seconds]`** (Integer): Duração máxima da sessão de admin. (Padrão: `28800` - 8 horas)
*   **`[:security, :admin_auth, :session, :idle_timeout_seconds]`** (Integer): Timeout de inatividade para sessão de admin. (Padrão: `900` - 15 minutos)
*   **`[:security, :admin_auth, :brute_force, :max_login_attempts]`** (Integer): Máximo de tentativas de login admin antes do bloqueio. (Padrão: `3`)
*   **`[:security, :admin_auth, :brute_force, :lockout_duration_minutes]`** (Integer): Duração do bloqueio de conta admin. (Padrão: `60`)
*   **`[:security, :admin_auth, :actions, <action_name>, :requires_mfa_step_up]`** (Boolean): Define se uma ação admin específica requer re-autenticação MFA.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`, `Core.Logger`, `Core.Metrics`, `Core.Repo`.
*   `DeeperHub.Auth` (potencialmente para a base de hashing de senha, gerenciamento de sessão, se não for totalmente separado).
*   `DeeperHub.MFA`: Para a lógica de TOTP e outros métodos MFA.
*   `DeeperHub.RBAC`: Para gerenciamento de papéis e permissões administrativas.
*   `DeeperHub.Audit`: Essencial para registrar todas as ações administrativas.
*   `DeeperHub.Security.BruteForceProtection`: Para proteger o login de admin.
*   `DeeperHub.Tokens`: Para gerenciamento de tokens de sessão de admin.

### 8.2. Bibliotecas Externas

*   As mesmas de `DeeperHub.Auth` (Joken, Argon2, etc.) se compartilhar a base.
*   Bibliotecas TOTP (ex: `ex_totp`).

## 🤝 9. Como Usar / Integração

*   **Interface de Administração (Web ou Console):**
    *   Usar `AdminAuth.authenticate_admin/3` para o fluxo de login.
    *   Antes de executar qualquer ação administrativa, chamar `AdminAuth.has_admin_permission?/3` ou `AdminAuth.authorize_action/4`.
*   **Proteção de Rotas (Phoenix):**
    ```elixir
    # Em lib/deeper_hub_web/router.ex
    pipeline :admin_auth do
      plug MyAppWeb.Plugs.VerifyAdminSessionPlug # Verifica token de sessão de admin
      plug MyAppWeb.Plugs.VerifyAdminPermissionPlug, permission: :access_admin_panel # Permissão genérica para painel
    end

    scope \"/admin\", DeeperHubWeb.Admin do
      pipe_through [:browser, :admin_auth]
      # ... rotas do painel admin ...
    end
    ```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o fluxo de login de admin com e sem MFA.
*   Testar a criação e gerenciamento de contas de admin.
*   Testar a lógica de autorização de ações (com e sem permissão, com e sem step-up MFA).
*   Testar a aplicação de políticas de senha e sessão específicas para admin.
*   Verificar se todas as ações administrativas são corretamente auditadas.
*   Localização: `test/deeper_hub/security/admin_auth/`.

### 10.2. Métricas

*   `deeper_hub.security.admin_auth.login.attempts.count` (tags: `status` (`success`, `failure`, `mfa_required`))
*   `deeper_hub.security.admin_auth.actions.authorized.count` (tags: `action_name`, `status` (`granted`, `denied_permission`, `denied_mfa`))
*   `deeper_hub.security.admin_auth.accounts.created.count`
*   `deeper_hub.security.admin_auth.sessions.active.gauge`

### 10.3. Logs

*   **Nível INFO:** Login de admin bem-sucedido, ação administrativa autorizada e executada.
*   **Nível WARNING:** Tentativa de login de admin falha, tentativa de ação não autorizada, MFA falhou para ação step-up.
*   **Nível ERROR:** Erros internos no `AdminAuthService` ou seus componentes.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :admin_auth, :login, :start | :stop | :exception]`
    *   Metadados: `%{username: username, ip_address: ip}`
*   `[:deeper_hub, :security, :admin_auth, :action_authorization, :start | :stop | :exception]`
    *   Metadados: `%{admin_id: id, action: action_name, permission_check_result: res, mfa_step_up_result: res}`
*   `[:deeper_hub, :security, :admin_auth, :account_management, :stop]`
    *   Metadados: `%{action: :create | :update | :deactivate, target_admin_id: id, performed_by_admin_id: id}`

## ❌ 11. Tratamento de Erros

*   Falhas de autenticação ou autorização devem ser tratadas de forma segura, negando o acesso e registrando a tentativa.
*   Erros internos devem ser logados e não expor informações sensíveis.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Proteção das Credenciais de Admin:** As senhas de admin devem ser tratadas com o mais alto nível de segurança.
*   **MFA Forte:** Incentivar ou obrigar o uso de métodos MFA fortes (TOTP, Chaves de Segurança) em vez de SMS para admins.
*   **Auditoria Imutável:** Os logs de `AdminActionLog` são críticos e devem ser protegidos.
*   **Revisão de Acesso:** Realizar revisões periódicas das contas de administrador e suas permissões.

## 🧑‍💻 13. Contribuição

*   Qualquer nova funcionalidade administrativa deve ter suas permissões de acesso claramente definidas no `PermissionService` (ou RBAC).
*   Ações de alto risco devem ser consideradas para \"step-up authentication\" com MFA.
*   Garanta que todas as ações de modificação de estado sejam auditadas.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar suporte para Chaves de Segurança (WebAuthn) como método MFA para administradores.
*   [ ] Adicionar \"sessões de administrador com privilégios elevados\" que expiram mais rapidamente ou exigem re-autenticação para certas operações.
*   [ ] Desenvolver alertas para atividades administrativas suspeitas (ex: login de admin de novo IP/dispositivo, múltiplas ações de alto risco em curto período).
*   [ ] Integrar com um sistema de gerenciamento de identidade centralizado (IdP) para administradores, se aplicável em ambientes corporativos maiores.
*   [ ] Permitir configuração de \"horários de acesso permitidos\" para contas de administrador.

---

*Última atualização: 2025-05-12*

---

A segurança administrativa é uma área densa, mas fundamental.

Agora, qual o próximo módulo? Talvez `DeeperHub.Core.Cache` para variar um pouco e sair da camada de segurança, ou prefere continuar com os outros módulos de segurança como `DdosProtection`?"""),
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
                types.Part.from_text(text="""Ok, vamos então detalhar o `DeeperHub.Core.Cache`. Este é um módulo de infraestrutura crucial para o desempenho de toda a aplicação.

---

