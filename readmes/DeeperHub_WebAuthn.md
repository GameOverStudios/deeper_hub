# Módulo: `DeeperHub.WebAuthn` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.WebAuthn`

O módulo `DeeperHub.WebAuthn` implementa a funcionalidade de autenticação usando o padrão **Web Authentication (WebAuthn)**, que é parte do conjunto de especificações FIDO2. Ele permite que os usuários se registrem e se autentiquem em DeeperHub usando autenticadores fortes, como chaves de segurança físicas (YubiKey, etc.), biometria embutida em dispositivos (Touch ID, Windows Hello, Android biometrics), ou outros métodos FIDO2.

Este módulo lida com:
*   O fluxo de registro de novas credenciais WebAuthn para um usuário.
*   O fluxo de autenticação de um usuário usando uma credencial WebAuthn previamente registrada.
*   O gerenciamento das credenciais WebAuthn associadas a cada usuário (listagem, remoção).

O objetivo é fornecer uma opção de login altamente segura, resistente a phishing e que pode eliminar a necessidade de senhas tradicionais. 😊

*(Nota: Na documentação original, `WebAuthnService` era um submódulo de `MFA`. Aqui, estamos tratando `DeeperHub.WebAuthn` como um módulo de primeiro nível, pois, embora possa ser usado como um fator MFA, também pode ser um método de login primário sem senha. Ele seria fortemente integrado com `DeeperHub.MFA` e `DeeperHub.Auth`.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Início do Registro de Credencial (`begin_registration/3`):**
    *   Gerar opções de criação de credencial (challenge, informações da Relying Party, informações do usuário, parâmetros de chave pública) para serem enviadas ao cliente/navegador.
    *   Armazenar temporariamente o challenge gerado para validação posterior.
*   **Conclusão do Registro de Credencial (`complete_registration/2`):**
    *   Receber a resposta de atestação do autenticador (enviada pelo cliente).
    *   Validar a resposta de atestação, incluindo o challenge, origem, assinatura e formato dos dados da chave pública.
    *   Se válida, armazenar a nova credencial pública (ID da credencial, chave pública, contador de assinatura, tipo de transporte) associada ao usuário.
*   **Início da Autenticação (`begin_authentication/2`):**
    *   Gerar opções de asserção (challenge, lista de IDs de credenciais permitidas para o usuário) para serem enviadas ao cliente/navegador.
    *   Armazenar temporariamente o challenge.
*   **Conclusão da Autenticação (`complete_authentication/2`):**
    *   Receber a resposta de asserção do autenticador (enviada pelo cliente).
    *   Validar a resposta de asserção, incluindo o challenge, origem, ID da credencial e a assinatura sobre os dados do cliente e o challenge.
    *   Verificar o contador de assinatura para prevenir clonagem de autenticador.
    *   Se válida, confirmar a identidade do usuário.
*   **Gerenciamento de Credenciais Registradas:**
    *   Listar as credenciais WebAuthn registradas por um usuário (`list_credentials/1`).
    *   Permitir que usuários removam credenciais WebAuthn registradas (`remove_credential/2`).
*   **Configuração da Relying Party (RP):**
    *   Configurar o ID da RP (geralmente o domínio da aplicação) e o nome da RP.
*   **Validação de Origem (Origin Validation):**
    *   Garantir que as respostas do autenticador se originem do domínio esperado.
*   **Armazenamento Seguro de Dados de Credencial:**
    *   Armazenar chaves públicas e contadores de assinatura de forma segura.
*   **Integração com `Auth` e `MFA`:**
    *   Ser chamado pelo `DeeperHub.Auth` como um método de login primário (sem senha).
    *   Ser chamado pelo `DeeperHub.MFA` como um segundo fator de autenticação.
*   **Observabilidade e Auditoria:**
    *   Logar operações de registro e autenticação.
    *   Auditar o registro e remoção de credenciais.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.WebAuthn` (Fachada Pública):**
    *   Ponto de entrada para todas as operações WebAuthn.
    *   Delega para o `WebAuthnService`.
2.  **`DeeperHub.WebAuthn.Services.WebAuthnService` (GenServer ou Módulo Funcional com Cache/Storage):**
    *   **Responsabilidade:** Orquestra os fluxos de registro e autenticação WebAuthn.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `CredentialSchema`.
        *   `DeeperHub.Accounts`: Para associar credenciais a `user_id`.
        *   `DeeperHub.Core.Cache`: Para armazenar challenges temporários durante os fluxos.
        *   `DeeperHub.Core.ConfigManager`: Para obter configurações da Relying Party (ID, nome).
        *   Biblioteca WebAuthn (Elixir): Para a lógica de baixo nível de validação e geração de estruturas WebAuthn.
3.  **Biblioteca WebAuthn para Elixir (Externa ou Interna):**
    *   Uma biblioteca como `Wax` (do Wistia) ou `Webauthnix` (do GitHub) ou uma implementação interna que lida com a complexidade do protocolo WebAuthn (parsing de CBOR, verificação de assinaturas criptográficas, validação de atestação/asserção). É altamente recomendável usar uma biblioteca bem testada.
4.  **`DeeperHub.WebAuthn.Schema.CredentialSchema` (ex-`Credential`):**
    *   Schema Ecto para armazenar as informações da credencial WebAuthn.
    *   Campos: `id` (ID da credencial, base64url), `user_id`, `public_key` (binário, formato COSE), `sign_count` (integer), `transports` (lista de strings/átomos, ex: `:usb`, `:nfc`, `:ble`, `:internal`), `name` (nome dado pelo usuário), `backed_up` (boolean), `created_at`, `last_used_at`.
5.  **Cache de Challenge (`DeeperHub.Core.Cache` ou ETS dedicado):**
    *   Armazena os challenges gerados durante os fluxos de registro/autenticação, associados a um ID de sessão ou usuário, com um TTL curto.
6.  **JavaScript do Lado do Cliente (Externo ao Backend):**
    *   O navegador do usuário executa JavaScript (usando a API WebAuthn do navegador `navigator.credentials.create()` e `navigator.credentials.get()`) para interagir com os autenticadores. Este módulo backend fornece as opções para essas chamadas JS e valida as respostas.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/web_authn/
├── web_authn.ex                      # Fachada Pública
│
├── services/
│   └── web_authn_service.ex          # Serviço principal com a lógica de fluxo
│
├── schemas/
│   └── credential_schema.ex
│
├── storage.ex                        # (Opcional) Módulo de queries Ecto
├── supervisor.ex                     # (Se WebAuthnService for GenServer para, por exemplo, limpar challenges)
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Escolha da Biblioteca WebAuthn:** Selecionar uma biblioteca Elixir para WebAuthn que seja mantida, segura e cubra as funcionalidades necessárias (atestação, asserção, diferentes formatos de chave).
*   **Armazenamento de Challenge:** Onde e como armazenar o challenge entre `begin_*` e `complete_*` é crucial. A sessão do usuário (se já existir) ou um cache de curta duração com um identificador de transação são comuns.
*   **Verificação do Contador de Assinatura (Sign Count):** Essencial para detectar clonagem de autenticadores. O `sign_count` enviado pelo autenticador deve ser maior que o último `sign_count` armazenado.
*   **Formatos de Chave Pública:** As chaves são geralmente armazenadas no formato COSE (CBOR Object Signing and Encryption).
*   **User Verification (UV):** Decidir a política para verificação do usuário pelo autenticador (ex: PIN, biometria no autenticador). WebAuthn permite `discouraged`, `preferred`, `required`.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Registra uma Nova Chave de Segurança (YubiKey):**
    1.  Na UI, usuário clica em \"Adicionar Chave de Segurança\".
    2.  Frontend chama API que leva a `WebAuthn.begin_registration(user_id, \"Minha YubiKey\")`.
    3.  Backend retorna `PublicKeyCredentialCreationOptions`.
    4.  Frontend passa essas opções para `navigator.credentials.create()`.
    5.  Usuário interage com a YubiKey (toca).
    6.  Navegador retorna `PublicKeyCredential` (com `attestationResponse`).
    7.  Frontend envia essa resposta para API que leva a `WebAuthn.complete_registration(user_id, attestation_response)`.
    8.  Backend valida e salva a nova credencial.
*   **Usuário Faz Login com Biometria do Laptop (Windows Hello / Touch ID):**
    1.  Na página de login, após digitar o username, usuário escolhe \"Login com Biometria\".
    2.  Frontend chama API que leva a `WebAuthn.begin_authentication(user_id_ou_username)`.
    3.  Backend retorna `PublicKeyCredentialRequestOptions`.
    4.  Frontend passa para `navigator.credentials.get()`.
    5.  Usuário autentica com biometria no laptop.
    6.  Navegador retorna `PublicKeyCredential` (com `assertionResponse`).
    7.  Frontend envia para API que leva a `WebAuthn.complete_authentication(user_id_ou_username, assertion_response)`.
    8.  Backend valida, e se ok, `DeeperHub.Auth` cria a sessão.

## 🌊 5. Fluxos Importantes

### Fluxo de Registro de Nova Credencial WebAuthn

1.  **Frontend:** Solicita opções de registro ao backend (`DeeperHub.WebAuthn.begin_registration`).
2.  **`WebAuthnService.begin_registration/3`:**
    *   Gera um `challenge` aleatório e seguro.
    *   Armazena o `challenge` e `user_id` no cache (associado a uma sessão temporária ou ID de transação) com TTL curto.
    *   Constrói `PublicKeyCredentialCreationOptions` incluindo:
        *   `rp`: ID e nome da Relying Party (DeeperHub).
        *   `user`: ID, nome e displayName do usuário DeeperHub.
        *   `challenge`: O challenge gerado.
        *   `pubKeyCredParams`: Algoritmos de chave pública suportados (ex: ES256, RS256).
        *   `authenticatorSelection`: Requisitos do autenticador (ex: `userVerification: \"preferred\"`).
        *   `attestation`: Preferência de atestação (ex: `\"none\"` ou `\"indirect\"`).
        *   `excludeCredentials`: Lista de `credential_id`s que o usuário já registrou para este RP (evita re-registro).
    *   Retorna as opções para o frontend.
3.  **Frontend:** Chama `navigator.credentials.create(optionsFromBackend)`.
4.  **Navegador/Autenticador:** Usuário interage com o autenticador. O autenticador gera um novo par de chaves, assina o challenge (e outros dados) com a chave privada, e retorna a chave pública e a atestação.
5.  **Frontend:** Envia a `PublicKeyCredential` (com a `attestationResponse`) para o backend (`DeeperHub.WebAuthn.complete_registration`).
6.  **`WebAuthnService.complete_registration/2`:**
    *   Recupera o `challenge` original do cache usando o ID de sessão/transação.
    *   **Usa a biblioteca WebAuthn para:**
        *   Parsear a `attestationResponse` (CBOR).
        *   Verificar a origem (origin).
        *   Verificar se o challenge na resposta corresponde ao challenge armazenado.
        *   Verificar a assinatura da atestação (se o tipo de atestação não for \"none\").
        *   Extrair a `credential_id`, `public_key` (COSE) e `sign_count` inicial (geralmente 0).
    *   Se todas as validações passarem:
        *   Cria e salva uma nova `CredentialSchema` no banco de dados com `user_id`, `credential_id`, `public_key`, `sign_count`, `transports`.
        *   Limpa o challenge do cache.
        *   Retorna `{:ok, credential_struct}`.
    *   Se falhar, retorna erro.

*(O fluxo de autenticação é similar, mas usa `begin_authentication` para obter um challenge e `complete_authentication` para verificar uma asserção, que envolve verificar a assinatura usando a chave pública armazenada e o `sign_count`.)*

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.WebAuthn`)

*(Baseado na documentação original e refinando)*

### 6.1. `DeeperHub.WebAuthn.begin_registration(user_id :: String.t(), user_display_name :: String.t(), opts :: keyword()) :: {:ok, PublicKeyCredentialCreationOptions.t()} | {:error, term()}`

*   **Descrição:** Inicia o processo de registro de uma nova credencial WebAuthn.
*   **`opts`:**
    *   `:key_name` (String.t): Nome amigável para a credencial.
    *   `:authenticator_selection` (map): Critérios para seleção do autenticador (ex: `%{userVerification: \"preferred\", authenticatorAttachment: \"cross-platform\"}`).
    *   `:attestation_preference` (atom): `:none`, `:indirect`, `:direct`.
*   **`PublicKeyCredentialCreationOptions.t()`:** Um mapa que pode ser serializado para JSON e passado para `navigator.credentials.create()`.

### 6.2. `DeeperHub.WebAuthn.complete_registration(user_id :: String.t(), attestation_response_from_client :: map()) :: {:ok, CredentialSchema.t()} | {:error, term()}`

*   **Descrição:** Completa o registro de uma credencial WebAuthn usando a resposta do autenticador.
*   **`attestation_response_from_client`:** O objeto `PublicKeyCredential` (geralmente como um mapa decodificado de JSON) retornado por `navigator.credentials.create()`.
*   **Retorno de Erro:** `:invalid_challenge`, `:invalid_origin`, `:invalid_signature`, `:credential_already_registered`, etc.

### 6.3. `DeeperHub.WebAuthn.begin_authentication(user_identifier :: String.t(), opts :: keyword()) :: {:ok, PublicKeyCredentialRequestOptions.t()} | {:error, :user_not_found | :no_credentials_for_user | term()}`

*   **Descrição:** Inicia o processo de autenticação WebAuthn para um usuário (identificado por ID ou username).
*   **`opts`:**
    *   `:user_verification` (atom): `:required`, `:preferred`, `:discouraged`.
*   **`PublicKeyCredentialRequestOptions.t()`:** Um mapa para ser passado para `navigator.credentials.get()`. Inclui um `challenge` e, opcionalmente, `allowCredentials`.

### 6.4. `DeeperHub.WebAuthn.complete_authentication(user_identifier :: String.t(), assertion_response_from_client :: map()) :: {:ok, %{user_id: String.t(), credential_id: String.t()}} | {:error, term()}`

*   **Descrição:** Completa a autenticação WebAuthn usando a resposta do autenticador.
*   **Retorno de Erro:** `:invalid_challenge`, `:invalid_origin`, `:invalid_signature`, `:credential_not_found`, `:sign_count_error`.

### 6.5. `DeeperHub.WebAuthn.list_credentials(user_id :: String.t()) :: {:ok, list(CredentialSchema.t())}`

*   **Descrição:** Lista todas as credenciais WebAuthn registradas para um usuário.

### 6.6. `DeeperHub.WebAuthn.remove_credential(user_id :: String.t(), credential_id_to_remove :: String.t()) :: :ok | {:error, :not_found | :unauthorized}`

*   **Descrição:** Remove uma credencial WebAuthn específica de um usuário. Requer que o `user_id` seja o proprietário.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:web_authn, :enabled]`** (Boolean): Habilita/desabilita WebAuthn globalmente. (Padrão: `true`)
*   **`[:web_authn, :relying_party, :id]`** (String): O ID da Relying Party (geralmente o domínio do site, ex: `\"deeperhub.com\"`). **Obrigatório.**
*   **`[:web_authn, :relying_party, :name]`** (String): Nome amigável da Relying Party (ex: \"DeeperHub\"). **Obrigatório.**
*   **`[:web_authn, :relying_party, :origins]`** (List de Strings): Lista de origens permitidas para as respostas WebAuthn (ex: `[\"https://app.deeperhub.com\", \"https://www.deeperhub.com\"]`). **Obrigatório e Crítico para Segurança.**
*   **`[:web_authn, :challenge_ttl_seconds]`** (Integer): Tempo de vida para os challenges armazenados no cache. (Padrão: `300` - 5 minutos)
*   **`[:web_authn, :default_user_verification]`** (Atom): Configuração padrão para `userVerification` em `authenticatorSelection` (ex: `:preferred`).
*   **`[:web_authn, :default_attestation_preference]`** (Atom): Preferência de atestação padrão (ex: `:none`).
*   **`[:web_authn, :supported_pub_key_cred_params_alg]`** (List de Integers): Algoritmos de chave pública suportados (ex: `[-7, -257]` para ES256 e RS256).
*   **`[:web_authn, :allow_untrusted_attestation]`** (Boolean): Se permite atestações de fontes não confiáveis (para depuração, geralmente `false` em produção).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.*`: ConfigManager, Logger, Metrics, Repo, Cache.
*   `DeeperHub.Accounts`: Para associar credenciais a `user_id`.
*   `DeeperHub.Auth` e `DeeperHub.MFA`: Para integrar nos fluxos de login e MFA.
*   `DeeperHub.Audit`: Para registrar eventos de gerenciamento de credenciais.
*   `DeeperHub.Core.EncryptionService`: Se algum metadado da credencial precisar ser criptografado (a chave pública em si não é secreta).

### 8.2. Bibliotecas Externas

*   Uma biblioteca Elixir WebAuthn/FIDO2 (ex: `Wax`, `Webauthnix`) é **altamente recomendada** devido à complexidade do protocolo.
*   `Jason` (ou similar) para decodificar as respostas JSON do cliente.
*   Biblioteca para manipulação de CBOR (geralmente incluída ou usada pela biblioteca WebAuthn).

## 🤝 9. Como Usar / Integração

*   **Fluxo de Registro de Usuário (`DeeperHub.Accounts`):** Após o registro inicial (ex: com email), oferecer ao usuário a opção de adicionar WebAuthn como método de login ou MFA.
*   **Fluxo de Login (`DeeperHub.Auth`):**
    *   Permitir que o usuário inicie o login via WebAuthn (login sem senha). O frontend chama `WebAuthn.begin_authentication(username)`, e o backend retorna o challenge.
    *   Se usado como segundo fator, `AuthService` (após validação da senha) chama `MFA.start_authentication(user_id, :webauthn)`, que por sua vez usa `WebAuthn.begin_authentication`.
*   **Configurações de Segurança do Perfil do Usuário:** UI para listar (`list_credentials`) e remover (`remove_credential`) chaves de segurança.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o fluxo completo de registro de credencial com diferentes tipos de autenticadores (mockeados ou reais, se possível em ambiente de teste).
*   Testar o fluxo completo de autenticação.
*   Testar a validação de challenges, origens, assinaturas e contadores de assinatura.
*   Testar a listagem e remoção de credenciais.
*   Testar cenários de erro (challenge expirado, credencial não encontrada, etc.).
*   Localização: `test/deeper_hub/web_authn/`.

### 10.2. Métricas

*   `deeper_hub.web_authn.registration.attempts.count` (tags: `status` (`success`, `failure`))
*   `deeper_hub.web_authn.registration.duration_ms` (Histograma)
*   `deeper_hub.web_authn.authentication.attempts.count` (tags: `status` (`success`, `failure`))
*   `deeper_hub.web_authn.authentication.duration_ms` (Histograma)
*   `deeper_hub.web_authn.credentials.registered.gauge` (Gauge)
*   `deeper_hub.web_authn.credentials.removed.count`

### 10.3. Logs

*   **Nível INFO:** Registro/autenticação bem-sucedida. Credencial removida.
*   **Nível WARNING:** Falha na validação de atestação/asserção com detalhes do motivo (ex: challenge inválido, assinatura incorreta, contador de assinatura inválido).
*   **Nível ERROR:** Erro crítico na biblioteca WebAuthn ou falha ao persistir credencial.

### 10.4. Telemetria

*   `[:deeper_hub, :web_authn, :registration, :begin | :complete, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, rp_id: id}`
    *   No `complete_stop`: `%{credential_id: id, result: :success | :failure, error_reason: reason}`
*   `[:deeper_hub, :web_authn, :authentication, :begin | :complete, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, rp_id: id}`
    *   No `complete_stop`: `%{credential_id: id, result: :success | :failure, error_reason: reason}`
*   `[:deeper_hub, :web_authn, :credential, :removed]`
    *   Metadados: `%{user_id: id, credential_id: id}`

## ❌ 11. Tratamento de Erros

*   Falhas de validação durante `complete_registration` ou `complete_authentication` devem retornar erros claros para o frontend para que o usuário possa ser informado.
*   Erros no armazenamento de challenges temporários devem ser tratados (ex: solicitar que o usuário reinicie o fluxo).

## 🛡️ 12. Considerações de Segurança

*   **Validação da Relying Party ID e Origin:** Crucial para prevenir ataques de phishing e garantir que as credenciais sejam usadas apenas no site correto.
*   **Proteção contra Replay:** O uso de challenges únicos para cada operação previne ataques de replay.
*   **Contador de Assinatura:** Fundamental para detectar clonagem de autenticadores.
*   **Armazenamento da Chave Pública:** A chave pública não é secreta, mas sua integridade deve ser garantida.
*   **Transportes Seguros:** Garantir que a comunicação entre cliente e servidor seja sempre sobre HTTPS.
*   **User Presence vs. User Verification:** `userVerification` (\"required\", \"preferred\", \"discouraged\") na seleção do autenticador determina se o autenticador deve verificar o usuário (ex: biometria no autenticador). `userPresence` (geralmente implícito) garante que o usuário estava presente (ex: tocou na chave).

## 🧑‍💻 13. Contribuição

*   A integração com bibliotecas WebAuthn requer um bom entendimento das especificações FIDO2/WebAuthn.
*   O fluxo no frontend (JavaScript) é uma parte significativa da implementação.
*   Manter as configurações da Relying Party (ID, origins) corretas e seguras.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Suporte para \"Resident Keys\" / \"Discoverable Credentials\" (permite login sem precisar digitar o username primeiro, o autenticador fornece a identidade).
*   [ ] Interface de usuário mais amigável para gerenciamento de múltiplos autenticadores.
*   [ ] Políticas mais granulares para quando WebAuthn pode ser usado como único fator vs. como segundo fator.
*   [ ] Melhorar o tratamento de diferentes tipos de atestação (se a política da RP exigir validação de atestação mais forte que \"none\").
*   [ ] Permitir que usuários exportem/importem metadados de credenciais para backup (com muitas ressalvas de segurança).
*   [ ] Monitoramento proativo de revogação de certificados raiz de atestação (para tipos de atestação mais fortes).

---

*Última atualização: 2025-05-12*

---

WebAuthn é uma tecnologia poderosa para o futuro da autenticação!

Com este, cobrimos os principais métodos de autenticação. Que tal agora irmos para um módulo de domínio que ainda não foi detalhado, como `DeeperHub.ServerPackages` ou `DeeperHub.Support` (que já fizemos)? Ou talvez o `DeeperHub.Console`?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue
"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Já detalhamos o `DeeperHub.Support`.

Vamos então para o `DeeperHub.ServerPackages`. Este módulo lida com a monetização ou ofertas de valor agregado que os servidores podem disponibilizar aos seus jogadores.

---

