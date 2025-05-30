# Módulo: `DeeperHub.MFA` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.MFA`

O módulo `DeeperHub.MFA` é responsável por gerenciar e aplicar a **Autenticação Multifator (MFA)**, também conhecida como autenticação de dois fatores (2FA), para os usuários do sistema DeeperHub. O MFA adiciona uma camada extra de segurança ao processo de login, exigindo que o usuário forneça duas ou mais formas de verificação de identidade antes de conceder acesso.

Este módulo suporta diversos métodos MFA, como:
*   **TOTP (Time-based One-Time Password):** Usando aplicativos autenticadores como Google Authenticator, Authy, etc.
*   **WebAuthn (FIDO2):** Usando chaves de segurança físicas, biometria em dispositivos compatíveis (integrado com `DeeperHub.WebAuthn`).
*   **Códigos de Recuperação:** Códigos de uso único para acesso em caso de perda de outros métodos.
*   **Notificações Push (Opcional):** Aprovação de login via notificação em um dispositivo móvel registrado.
*   **SMS/Email OTP (Opcional, menos seguro):** Envio de códigos de uso único por SMS ou email.

O objetivo é dificultar significativamente o acesso não autorizado a contas, mesmo que a senha principal do usuário seja comprometida. 😊

*(Nota: A documentação original tem `DeeperHub.MFA.Adapters.DefaultMFAService`, `MFAAdapter`, `MFABehaviour`, `Integrations`, `Schema`, `Services` como `TOTPService`, `WebAuthnService` (que delega para `DeeperHub.WebAuthn`), `RecoveryCodeService`, `PushVerificationService`, e `MFAPolicyService`. Esta documentação consolida sob a fachada `DeeperHub.MFA` e organiza os componentes internos.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento de Métodos MFA por Usuário:**
    *   Permitir que usuários registrem (configurem) múltiplos métodos MFA (`setup_method/3`).
    *   Listar os métodos MFA configurados por um usuário (`list_methods/1`).
    *   Permitir que usuários removam métodos MFA configurados (`remove_method/3`).
    *   Verificar se um método específico está ativo para um usuário (`is_method_active?/2`).
*   **Verificação de Código/Fator MFA:**
    *   Verificar códigos TOTP (`verify_code/3` para TOTP).
    *   Processar e verificar asserções WebAuthn (delegado para `DeeperHub.WebAuthn`).
    *   Verificar códigos de recuperação (`verify_recovery_code/2`).
    *   Processar respostas de notificações push (`PushVerificationService.process_verification_response/3`).
    *   Verificar códigos OTP enviados por email/SMS (se implementado).
*   **Geração de Códigos e Desafios:**
    *   Gerar segredos TOTP e URIs de configuração.
    *   Gerar desafios para WebAuthn (delegado para `DeeperHub.WebAuthn`).
    *   Gerar um conjunto de códigos de recuperação únicos (`generate_recovery_codes/2`).
    *   Gerar e enviar códigos OTP para email/SMS (`send_code/4`).
*   **Gerenciamento de Preferências MFA do Usuário:**
    *   Permitir que usuários definam um método MFA preferencial.
    *   Armazenar e consultar preferências (`get_user_preferences/1`, `update_user_preferences/2`).
*   **Políticas de MFA (`Services.MFAPolicyService`):**
    *   Determinar quando o MFA é obrigatório para um usuário ou operação (`requires_mfa?/2`).
    *   Gerenciar períodos de carência para configuração de MFA.
    *   Rastrear se uma sessão atual já passou por uma verificação MFA recente (`has_recent_verification?/2`).
*   **Proteção contra Força Bruta em Verificações MFA:**
    *   Limitar o número de tentativas falhas de verificação de código.
*   **Observabilidade e Auditoria:**
    *   Registrar logs e métricas para todas as operações MFA.
    *   Auditar a configuração, remoção e uso de métodos MFA.
*   **Integração com o Fluxo de Login (`DeeperHub.Auth`):**
    *   Ser chamado pelo `AuthService` quando MFA é necessário após a autenticação primária.
*   **Interface para \"Step-up Authentication\":**
    *   Permitir que operações de alto risco exijam uma nova verificação MFA, mesmo que o usuário já esteja logado.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.MFA` (Fachada Pública, ex-`MFAFacade`):**
    *   Ponto de entrada para todas as funcionalidades MFA.
    *   Delega para o `MFAService` ou diretamente para serviços de métodos específicos.
2.  **`DeeperHub.MFA.Services.MFAService` (ou `DefaultMFAService` - GenServer/Coordenador):**
    *   **Responsabilidade:** Orquestra as operações MFA.
    *   **Interações:**
        *   `TOTPService`, `RecoveryCodeService`, `PushVerificationService`.
        *   `DeeperHub.WebAuthn` (para operações WebAuthn).
        *   `MFAPolicyService`: Para verificar se MFA é mandatório.
        *   `DeeperHub.Core.Repo` (via schemas): Para persistir configurações MFA do usuário.
        *   `DeeperHub.Notifications`: Para enviar códigos OTP ou notificações sobre MFA.
        *   `DeeperHub.Core.ConfigManager`: Para configurações.
        *   `DeeperHub.Security.BruteForceProtection`: Para limitar tentativas de verificação.
3.  **Serviços por Método MFA:**
    *   **`DeeperHub.MFA.Services.TOTPService`:** Lógica para setup e verificação de TOTP. Usa `DeeperHub.MFA.TOTP` schema.
    *   **`DeeperHub.MFA.Services.RecoveryCodeService`:** Lógica para geração, armazenamento (hashes) e verificação de códigos de recuperação. Usa `DeeperHub.MFA.RecoveryCode` schema.
    *   **`DeeperHub.MFA.Services.PushVerificationService`:** Lógica para gerenciar registro de dispositivos push e o fluxo de verificação via push. Usa `DeeperHub.MFA.Schema.PushDevice`.
    *   *(`WebAuthnService` está em `DeeperHub.WebAuthn` mas é usado como um método MFA)*.
4.  **`DeeperHub.MFA.Services.MFAPolicyService`:**
    *   Determina se MFA é necessário para um usuário/operação e gerencia o estado de verificação MFA recente na sessão.
5.  **Schemas Ecto:**
    *   `DeeperHub.MFA.TOTP`: Armazena segredo TOTP (criptografado), status.
    *   `DeeperHub.MFA.RecoveryCode`: Armazena hashes dos códigos de recuperação e seu status de uso.
    *   `DeeperHub.MFA.Schema.PushDevice`: Armazena tokens de dispositivos para notificações push.
    *   `DeeperHub.MFA.Schema.UserMFAPreferences` (Novo Sugerido): Armazena o método preferido do usuário, se o MFA está habilitado por ele, etc.
6.  **Integrações (`AuditIntegration`, `EventIntegration`, `MFAAnomalyIntegration`, `MFANotificationIntegration`):**
    *   Para auditoria, eventos de domínio, análise de anomalias e notificações específicas de MFA.

### 3.2. Estrutura de Diretórios (Proposta)

```
mfa/
├── mfa.ex                              # Fachada Pública
│
├── services/
│   ├── mfa_service.ex                  # Serviço orquestrador principal
│   ├── totp_service.ex
│   ├── recovery_code_service.ex
│   ├── push_verification_service.ex
│   └── mfa_policy_service.ex
│
├── schemas/                            # (Ou schema/ singular)
│   ├── totp.ex
│   ├── recovery_code.ex
│   ├── push_device.ex
│   └── user_mfa_preferences.ex       # Novo
│
├── integrations/
│   ├── audit_integration.ex
│   ├── event_integration.ex
│   ├── mfa_anomaly_integration.ex
│   └── mfa_notification_integration.ex
│
├── supervisor.ex
└── telemetry.ex
```
*(O `DeeperHub.WebAuthn` seria um módulo irmão, mas conceitualmente um método MFA)*

### 3.3. Decisões de Design Importantes

*   **Segurança dos Segredos MFA:** Segredos TOTP e outros dados sensíveis de MFA devem ser criptografados em repouso (`Core.EncryptionService`).
*   **Experiência do Usuário:** O fluxo de configuração e uso de MFA deve ser o mais simples e intuitivo possível.
*   **Códigos de Recuperação:** Sempre fornecer códigos de recuperação ao habilitar MFA, pois são cruciais se o usuário perder acesso ao seu dispositivo MFA principal.
*   **Múltiplos Métodos:** Permitir que os usuários configurem múltiplos métodos MFA aumenta a resiliência.
*   **Rate Limiting em Verificações:** Proteger contra a adivinhação de códigos TOTP ou OTPs.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Habilita TOTP:**
    *   Usuário navega para configurações de segurança e escolhe adicionar TOTP.
    *   `MFA.setup_method(user_id, :totp)` é chamado.
    *   `TOTPService` gera um segredo, cria um QR code URI.
    *   Usuário escaneia com seu app autenticador e insere o primeiro código para confirmar.
    *   `MFA.verify_code(user_id, totp_code, %{method: :totp, context: :setup_confirmation})` é chamado.
    *   Se válido, TOTP é marcado como ativo para o usuário. Códigos de recuperação são gerados e exibidos.
*   **Login com MFA:**
    *   `DeeperHub.Auth` determina que MFA é necessário após a senha.
    *   Frontend solicita ao usuário seu método MFA preferido ou o próximo fator.
    *   Usuário insere código TOTP.
    *   Frontend envia para `DeeperHub.Auth.verify_second_factor(user_id, :totp, code, context)`.
    *   `Auth` delega para `MFA.verify_code(user_id, code, %{method: :totp, context: :login})`.
    *   Se válido, login prossegue; senão, erro.
*   **Usuário Perde Dispositivo TOTP e Usa Código de Recuperação:**
    *   No fluxo de login, após a senha, usuário escolhe \"Usar código de recuperação\".
    *   Insere um de seus códigos.
    *   `MFA.verify_recovery_code(user_id, recovery_code)` é chamado.
    *   Se válido, o código é marcado como usado, e o login prossegue. O sistema deve incentivar o usuário a configurar um novo método MFA e gerar novos códigos de recuperação.

## 🌊 5. Fluxos Importantes

### Fluxo de Configuração de Novo Método MFA (Ex: TOTP)

1.  **Usuário (UI):** Inicia o processo de adicionar TOTP.
2.  **Frontend -> Backend API Controller:** Chama um endpoint que leva a `DeeperHub.MFA.setup_method(user_id, :totp, %{issuer_name: \"DeeperHub\"})`.
3.  **`MFAService` (ou `TOTPService` diretamente):**
    *   Gera um novo segredo TOTP (ex: 160 bits de aleatoriedade).
    *   Cria uma URI `otpauth://` contendo o segredo, nome do emissor, e email/username do usuário.
    *   Armazena temporariamente o segredo (ou um hash dele) associado ao `user_id` e um status \"pendente de verificação\".
    *   Retorna a URI (para QR code) e o segredo em formato texto (para entrada manual) para o frontend.
4.  **Frontend:** Exibe o QR code e o campo para o usuário inserir o primeiro código TOTP gerado pelo seu app autenticador.
5.  **Usuário (UI):** Escaneia o QR code, vê o código no app, e o insere na UI.
6.  **Frontend -> Backend API Controller:** Chama um endpoint que leva a `DeeperHub.MFA.verify_code(user_id, submitted_totp_code, %{method: :totp, context: :setup_confirmation})`.
7.  **`MFAService` (ou `TOTPService`):**
    *   Recupera o segredo TOTP pendente para o `user_id`.
    *   Valida o `submitted_totp_code` contra o segredo (considerando janelas de tempo).
    *   **Se Válido:**
        *   Marca o método TOTP como ativo para o usuário (persiste o segredo criptografado).
        *   Chama `RecoveryCodeService.generate_and_store(user_id, default_count)` para gerar códigos de recuperação.
        *   Retorna `{:ok, %{recovery_codes: [...]}}` (ou apenas `:ok` e o frontend busca os códigos depois).
        *   Publica evento `mfa_method_added`. Audita.
    *   **Se Inválido:** Retorna erro, incrementa contador de falhas (para brute force).

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.MFA`)

*(Baseado na documentação original de `MFAFacade` e serviços relacionados)*

### 6.1. `DeeperHub.MFA.setup_method(user_id :: String.t(), method :: :totp | :webauthn | :push | :sms_otp, details :: map() | nil) :: {:ok, SetupData.t()} | {:error, term()}`

*   **Descrição:** Inicia o processo de configuração para um novo método MFA.
*   **`details`:** Específico do método (ex: para `:totp`, `%{issuer_name: \"MyApp\"}`; para `:push`, `%{device_name: \"My iPhone\"}`).
*   **`SetupData.t()`:** Varia por método.
    *   Para `:totp`: `%{secret_key: String.t(), otpauth_uri: String.t()}`.
    *   Para `:webauthn`: Opções de registro do `DeeperHub.WebAuthn.start_registration`.
    *   Para `:push`: Confirmação do registro do dispositivo.

### 6.2. `DeeperHub.MFA.verify_code(user_id :: String.t(), code :: String.t(), verification_context :: map()) :: {:ok, :verified} | {:error, :invalid_code | :max_attempts_reached | term()}`

*   **Descrição:** Verifica um código MFA (TOTP, SMS OTP, ou um token de contexto de uma verificação push/webauthn já iniciada).
*   **`verification_context`:** `%{method: :totp | :sms_otp, operation: :login | :setup_confirmation | :critical_action, ...}`.

### 6.3. `DeeperHub.MFA.generate_recovery_codes(user_id :: String.t(), opts :: keyword()) :: {:ok, list(String.t())} | {:error, term()}`

*   **Descrição:** Gera um novo conjunto de códigos de recuperação, invalidando os antigos.
*   **`opts`:** `:count` (integer, Padrão: `10`).

### 6.4. `DeeperHub.MFA.verify_recovery_code(user_id :: String.t(), recovery_code :: String.t()) :: {:ok, :verified} | {:error, :invalid_code | :code_already_used | term()}`

*   **Descrição:** Verifica um código de recuperação. Se válido, marca-o como usado.

### 6.5. `DeeperHub.MFA.list_user_methods(user_id :: String.t()) :: {:ok, list(MethodInfo.t())}`

*   **Descrição:** Lista os métodos MFA configurados e ativos para um usuário.
*   **`MethodInfo.t()`:** `%{method_type: :totp | :webauthn | :push | :recovery_codes_active, id: String.t() | nil, name: String.t() | nil, added_at: DateTime.t()}`.

### 6.6. `DeeperHub.MFA.remove_method(user_id :: String.t(), method_type :: atom(), method_id :: String.t() | nil, verification_code_or_password :: String.t()) :: :ok | {:error, term()}`

*   **Descrição:** Remove um método MFA configurado. Requer verificação (senha ou outro fator MFA) para segurança.
*   **`method_id`:** Necessário para WebAuthn (ID da credencial) ou Push (ID do dispositivo).

### 6.7. `DeeperHub.MFA.get_user_mfa_preferences(user_id :: String.t()) :: {:ok, UserMFAPreferences.t()}`

*   **Descrição:** Obtém as preferências MFA do usuário (ex: método preferido, se MFA está habilitado por ele).

### 6.8. `DeeperHub.MFA.update_user_mfa_preferences(user_id :: String.t(), preferences :: map()) :: {:ok, UserMFAPreferences.t()} | {:error, Ecto.Changeset.t()}`

*   **Descrição:** Atualiza as preferências MFA do usuário.

### 6.9. `DeeperHub.MFA.Services.MFAPolicyService` (Funções expostas via `MFA` ou chamadas internamente por `Auth`):

*   `requires_mfa?(user_id, operation_context)`
*   `has_recent_mfa_verification?(user_id, session_id, operation_context)`
*   `register_mfa_verification_in_session(session_id, user_id, method_used)`

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:mfa, :enabled]`** (Boolean): Habilita/desabilita o sistema MFA globalmente. (Padrão: `true`)
*   **`[:mfa, :allowed_methods]`** (List de Atoms): Métodos MFA suportados e permitidos no sistema (ex: `[:totp, :webauthn, :recovery_code, :push]`).
*   **`[:mfa, :policy, :require_mfa_for_roles]`** (List de Strings): Papéis de usuário que sempre exigem MFA. (Ex: `[\"admin\", \"moderator\"]`).
*   **`[:mfa, :policy, :grace_period_days_for_new_users]`** (Integer | nil): Período para novos usuários configurarem MFA.
*   **`[:mfa, :policy, :session_mfa_validity_seconds]`** (Integer): Por quanto tempo uma verificação MFA na sessão é considerada válida para pular verificações subsequentes (step-up).
*   **`[:mfa, :totp, :issuer_name]`** (String): Nome do emissor exibido em apps autenticadores. (Padrão: \"DeeperHub\")
*   **`[:mfa, :totp, :secret_length_bytes]`** (Integer): Comprimento do segredo TOTP.
*   **`[:mfa, :totp, :verification_window]`** (Integer): Quantos códigos passados/futuros são válidos. (Padrão: `1` - ou seja, atual, anterior e próximo).
*   **`[:mfa, :recovery_code, :default_count]`** (Integer): Número de códigos de recuperação gerados. (Padrão: `10`)
*   **`[:mfa, :recovery_code, :hash_algorithm]`** (Atom): Algoritmo para hashear códigos de recuperação.
*   **`[:mfa, :push_verification, :default_timeout_seconds]`** (Integer).
*   **`[:mfa, :brute_force, :max_verify_attempts]`** (Integer): Tentativas de verificação de código antes de bloqueio/delay.
*   **`[:mfa, :brute_force, :lockout_duration_seconds]`** (Integer).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`: Todos os módulos Core.
*   `DeeperHub.Auth`: Para integrar no fluxo de login e obter informações do usuário.
*   `DeeperHub.Accounts`: Para dados do usuário.
*   `DeeperHub.WebAuthn`: Para a funcionalidade WebAuthn.
*   `DeeperHub.Notifications`: Para enviar códigos OTP por email/SMS e notificações sobre MFA.
*   `DeeperHub.Security.BruteForceProtection`: Para proteger contra adivinhação de códigos.
*   `DeeperHub.Core.EncryptionService`: Para criptografar segredos TOTP.

### 8.2. Bibliotecas Externas

*   `ex_totp` (ou similar): Para lógica TOTP.
*   Bibliotecas para WebAuthn (se não usar a interna `DeeperHub.WebAuthn`).
*   Bibliotecas cliente para serviços de SMS/Push (se esses canais forem implementados).

## 🤝 9. Como Usar / Integração

*   **Fluxo de Login (`DeeperHub.Auth`):**
    *   Após a senha ser verificada, `AuthService` chama `MFAPolicyService.requires_mfa?`.
    *   Se `true`, `AuthService` retorna `{:error, :mfa_required, ...}`.
    *   O frontend guia o usuário pelo fluxo MFA, chamando os endpoints da API MFA (que usam `DeeperHub.MFA` fachada).
*   **Configurações de Segurança do Usuário (UI):**
    *   Permitir que o usuário liste, adicione e remova métodos MFA usando os endpoints da API MFA.
*   **Step-up Authentication:**
    *   Antes de uma operação crítica, um serviço pode chamar `MFAPolicyService.requires_mfa?(user_id, %{operation: :delete_account, session_mfa_verified: session.mfa_verified_at})`.
    *   Se `true`, redirecionar para verificação MFA.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o fluxo de setup e verificação para cada método MFA suportado (TOTP, Recovery Code, WebAuthn, Push).
*   Testar a lógica de `MFAPolicyService` (quando MFA é obrigatório, validade da sessão MFA).
*   Testar a geração e invalidação de códigos de recuperação.
*   Testar a remoção de métodos e o impacto no status MFA do usuário.
*   Testar a proteção contra força bruta nas verificações de código.
*   Localização: `test/deeper_hub/mfa/`.

### 10.2. Métricas

*   `deeper_hub.mfa.setup_attempt.count` (tags: `method`, `status` (`success`, `failure`))
*   `deeper_hub.mfa.verification_attempt.count` (tags: `method`, `context` (`login`, `step_up`), `status` (`success`, `failure`))
*   `deeper_hub.mfa.users_with_mfa_enabled.gauge` (Gauge, tags: `method_count` (`one_method`, `multi_method`))
*   `deeper_hub.mfa.recovery_codes_used.count`
*   `deeper_hub.mfa.method_removed.count` (tags: `method`)

### 10.3. Logs

*   **Nível INFO:** Método MFA configurado/removido. Verificação MFA bem-sucedida.
*   **Nível WARNING:** Tentativa de verificação MFA falhou. Usuário usou código de recuperação.
*   **Nível ERROR:** Falha crítica no setup de MFA. Erro ao enviar código OTP.

### 10.4. Telemetria

*   `[:deeper_hub, :mfa, :setup, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, method: method}`
*   `[:deeper_hub, :mfa, :verify, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, method: method, context: context, result: :success | :failure}`
*   `[:deeper_hub, :mfa, :policy_check]`
    *   Metadados: `%{user_id: id, operation: op, result_requires_mfa: boolean}`

## ❌ 11. Tratamento de Erros

*   Falhas na verificação de código devem retornar erros claros (código inválido, expirado, máximo de tentativas).
*   Problemas com serviços externos (ex: envio de SMS) devem ser tratados com retentativas e fallbacks (ex: sugerir outro método MFA).
*   Se o usuário perder todos os seus métodos MFA e códigos de recuperação, um processo de recuperação de conta manual e seguro (via suporte) deve existir.

## 🛡️ 12. Considerações de Segurança

*   **Segurança dos Segredos TOTP:** Devem ser criptografados em repouso.
*   **Segurança dos Códigos de Recuperação:** Devem ser exibidos apenas uma vez para o usuário e armazenados como hashes.
*   **Proteção contra Replay:** Códigos OTP e desafios WebAuthn devem ser de uso único.
*   **Rate Limiting:** Essencial para todas as operações de verificação de código.
*   **Não Confiar no Cliente:** Todas as validações devem ocorrer no servidor.
*   **Políticas de MFA Fortes:** Encorajar ou obrigar o uso de MFA para todos os usuários, especialmente administradores.

## 🧑‍💻 13. Contribuição

*   Ao adicionar um novo método MFA, criar um novo serviço em `services/` e integrá-lo com `MFAService`.
*   Garantir que todos os fluxos de configuração e verificação sejam testados exaustivamente.
*   Considerar a usabilidade dos fluxos MFA.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar suporte para mais métodos MFA (ex: Chaves de Segurança baseadas em Hardware diferentes de WebAuthn padrão, como YubiKey OTP).
*   [ ] Permitir que usuários definam \"dispositivos confiáveis\" onde o MFA pode ser pulado por um período. (Isso interage com `DeviceService` e `MFAPolicyService`).
*   [ ] Implementar MFA adaptativo, onde a necessidade de MFA é determinada dinamicamente pelo `RiskAssessment`.
*   [ ] Interface administrativa para ajudar usuários bloqueados de seus métodos MFA (com verificação de identidade rigorosa).
*   [ ] Melhorar as opções de notificação push para serem mais interativas (ex: botões \"Aprovar\"/\"Negar\" diretamente na notificação).

---

*Última atualização: 2025-05-12*

---

MFA é um grande passo para a segurança de contas!

Onde vamos a seguir? Já cobrimos muitos módulos Core e de Segurança. Podemos continuar com os módulos de segurança restantes (`HashingService`, `AtRestEncryptionService` se quisermos detalhá-los mais do que no `Core.EncryptionService`, `ResponseSanitizer`), ou começar a explorar os módulos de domínio que foram originalmente listados em `Services` (como `ServerPackages`, `ServerEvents`, `Achievements`, etc.)?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue"""),
                types.Part.from_text(text="""continue
"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Entendido! Dado que já cobrimos uma gama bem ampla dos módulos de segurança e infraestrutura Core, e que os módulos de \"Serviços\" da documentação original (`Achievements`, `Challenges`, `Lists`, `Rewards`, `ServerAdvertisements`, `ServerAlerts`, `ServerEvents`, `ServerPackages`, `ServerReviews`, `ServerTags`, `ServerUpdateMessages`, `Support`, `UserInteractions`) representam os **domínios de negócio específicos** da plataforma DeeperHub, vamos abordar a estrutura e a abordagem para documentá-los, e então detalhar um deles como exemplo.

**Abordagem Geral para Módulos de Domínio (Ex-\"Services\"):**

A ideia principal da refatoração de namespaces sugerida anteriormente era elevar cada um desses \"Serviços\" a um contexto de domínio de primeiro nível dentro do DeeperHub. Por exemplo:

*   `DeeperHub.Services.Achievements` se tornaria `DeeperHub.Achievements`
*   `DeeperHub.Services.ServerReviews` se tornaria `DeeperHub.ServerReviews` (como já fizemos)
*   `DeeperHub.Services.Support` se tornaria `DeeperHub.Support`

Cada um desses módulos de domínio seguiria uma estrutura interna similar, contendo:

1.  **Fachada Pública (ex: `DeeperHub.Achievements.AchievementsFacade` ou apenas `DeeperHub.Achievements`):** O ponto de entrada para o domínio.
2.  **Serviço(s) de Domínio (ex: `DeeperHub.Achievements.Services.AchievementsService`):** Contém a lógica de negócio principal.
3.  **Schemas Ecto (ex: `DeeperHub.Achievements.Schemas.AchievementSchema`, `UserAchievementSchema`):** Define as entidades do domínio.
4.  **Storage/Repositório (ex: `DeeperHub.Achievements.Storage`):** Módulo que encapsula as queries Ecto, chamando `DeeperHub.Core.Repo`.
5.  **Integrações (Opcional, ex: `DeeperHub.Achievements.Integrations.EventIntegration`):** Para interagir com `Core.EventBus` ou outros sistemas.
6.  **Workers (Opcional):** Para tarefas de background específicas do domínio.
7.  **Supervisor:** Para os GenServers do domínio.
8.  **Telemetry/Metrics:** Para observabilidade específica do domínio.
9.  **CachedAdapter (Opcional):** Se o domínio se beneficia de uma camada de cache específica e granular, além do `Core.Cache` genérico.

Vamos escolher um para detalhar, talvez `DeeperHub.Achievements` como um bom exemplo de um módulo de domínio.

---

