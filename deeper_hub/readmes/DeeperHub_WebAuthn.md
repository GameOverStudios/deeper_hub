# Módulo: `Deeper_Hub.WebAuthn` 🔑

## 📜 1. Visão Geral do Módulo `Deeper_Hub.WebAuthn`

O módulo `Deeper_Hub.WebAuthn` é responsável por implementar a funcionalidade de autenticação usando o padrão WebAuthn (Web Authentication API). Ele permite que os usuários do Deeper_Hub se autentiquem de forma segura e sem senha, utilizando autenticadores de hardware (como chaves de segurança YubiKey), biometria integrada em dispositivos (como Touch ID ou Windows Hello), ou outros métodos FIDO2 compatíveis. O objetivo é oferecer uma alternativa mais segura e conveniente às senhas tradicionais. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Registro de Credenciais WebAuthn:**
    *   Iniciar o processo de registro de um novo autenticador WebAuthn para um usuário.
    *   Gerar opções de criação de credencial (challenge, informações do relying party, etc.) para serem enviadas ao cliente (navegador).
    *   Processar e validar a resposta de atestação do autenticador/cliente.
    *   Armazenar de forma segura as informações da credencial pública registrada (ex: ID da credencial, chave pública, contador de assinatura).
*   **Autenticação com Credenciais WebAuthn:**
    *   Iniciar o processo de autenticação para um usuário.
    *   Gerar opções de solicitação de asserção (challenge, IDs de credenciais permitidas) para o cliente.
    *   Processar e validar a resposta de asserção do autenticador/cliente.
    *   Verificar a assinatura e o contador de uso.
*   **Gerenciamento de Credenciais:**
    *   Permitir que usuários listem suas credenciais WebAuthn registradas.
    *   Permitir que usuários removam/desvinculem credenciais WebAuthn de suas contas.
*   **Segurança e Conformidade com o Padrão:**
    *   Implementação aderente às especificações WebAuthn Level 1 ou Level 2.
    *   Validação de origem (Relying Party ID).
    *   Verificação de flags do autenticador (User Present, User Verified).
    *   Proteção contra ataques de replay (usando challenges e contadores de assinatura).
*   **Armazenamento Seguro de Dados:**
    *   Persistir dados de credenciais WebAuthn de forma segura (via `Core.Repo`).
*   **Cache de Desafios:**
    *   Armazenar temporariamente os desafios (challenges) gerados durante os fluxos de registro e autenticação (via `Core.Cache` ou ETS dedicado).
*   **Integração com o Módulo `Auth` ou `MFA`:**
    *   Atuar como um método de autenticação primário (login sem senha) ou como um segundo fator de autenticação (2FA/MFA).

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.WebAuthn` será uma fachada que interage com um serviço de lógica de negócio WebAuthn e componentes de persistência e cache.

*   **Interface Pública (`Deeper_Hub.WebAuthn.WebAuthnFacade` ou `Deeper_Hub.WebAuthn`):** Funções como `begin_registration/3`, `complete_registration/2`, `begin_authentication/2`, `complete_authentication/2`.
*   **Serviço WebAuthn (`Deeper_Hub.WebAuthn.Services.WebAuthnService`):**
    *   Contém a lógica principal para os fluxos de registro e autenticação WebAuthn.
    *   Interage com bibliotecas Elixir para WebAuthn (ex: `Wax`, `WebAuthn.Elixir`).
*   **Schema Ecto (`Deeper_Hub.WebAuthn.Schema.Credential`):**
    *   Define a estrutura para armazenar informações das credenciais WebAuthn registradas.
*   **Cache de Desafios (via `Core.Cache` ou `Deeper_Hub.WebAuthn.ChallengeCache`):**
    *   Armazena temporariamente os challenges para associar as respostas do cliente às solicitações originais.
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência de credenciais.
    *   `Deeper_Hub.Core.Cache`: Para cache de desafios.
    *   `Deeper_Hub.Core.ConfigManager`: Para configurações do Relying Party ID, nomes de exibição, etc.
    *   `Deeper_Hub.Auth` ou `Deeper_Hub.MFA`: Para integrar o WebAuthn nos fluxos de autenticação.
    *   `Deeper_Hub.Audit`: Para registrar eventos de registro e autenticação WebAuthn.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**

### 3.1. Componentes Principais

*   **`Deeper_Hub.WebAuthn.WebAuthnFacade`:** Ponto de entrada.
*   **`Deeper_Hub.WebAuthn.Services.WebAuthnService`:** Lógica de negócio principal.
*   **`Deeper_Hub.WebAuthn.Schema.Credential`:** Schema Ecto para credenciais.
*   **Biblioteca WebAuthn Elixir (ex: `Wax`):** Usada internamente pelo `WebAuthnService` para as operações criptográficas e de protocolo.
*   **`Deeper_Hub.WebAuthn.Supervisor`:** Supervisiona processos (se houver, como um worker para limpar desafios expirados do cache).

### 3.3. Decisões de Design Importantes

*   **Escolha da Biblioteca WebAuthn:** Selecionar uma biblioteca Elixir robusta e bem mantida para lidar com as complexidades do protocolo WebAuthn.
*   **Armazenamento de ChallengePerfeito! Vamos ao README do `Deeper_Hub.WebAuthn`. Este é um módulo de segurança bem moderno e interessante.

---

# Módulo: `Deeper_Hub.WebAuthn:** Decidir como os desafios são armazenados temporariamente e associados às sessões do usuário (ex: cache com TTL curto, cookies de sessão).
*   **User Verification (UV):** Definir a política para verificação do usuário (ex: exigir PIN ou biometria no autenticador).
*   **Attestation:** Decidir o formato de atestação a ser solicitado e como validá-lo (pode ser complexo e muitas vezes é opcional ou \"none\" para simplicidade).

## 🛠️ 4. Casos de Uso Principais

*   **Usu` 🔑

## 📜 1. Visão Geral do Módulo `Deeper_Hub.WebAuthn`

O módulo `Deeper_Hub.WebAuthn` é responsável por implementar a funcionalidade de autenticação usando o padrão WebAuthn (Web Authentication API). Ele permite que os usuários se autentiquem no sistema Deeper_Hub de forma segura e sem senha, utilizando autenticadores como chaves de segurança FIDO2 (ex: YubiKey), biometria integrada em dispositivos (ex: Touch ID, Windows Hello) ou outros autenticadores compatíveis. O objetivo é oferecer uma alternativa mais segura e conveniente à autenticação baseada em senhas, além de poder servir como um forte segundo fator de autenticação (MFA). 😊

## 🎯ário Registra uma Chave de Segurança:** Um usuário acessa as configurações de segurança de sua conta e opta por adicionar uma chave de segurança física como método de login.
*   **Usuário Faz Login com Impressão Digital:** Um usuário em um dispositivo com leitor de impressão digital opta por fazer login usando sua biometria registrada via WebAuthn.
*   **Usuário usa WebAuthn como Segundo Fator:** Após inserir a senha, o sistema solicita ao usuário que toque em sua chave de segurança para completar o login MFA.
*   **Usuário Remove uma Credencial Antiga:** Um usuário remove uma chave de segurança perdida de sua lista de autenticadores registrados.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Registro de uma Nova Credencial WebAuthn:**

1.  Usuário inicia o processo de registro na UI.
2.  Frontend envia uma solicitação para a API (ex: `POST 2. Responsabilidades e Funcionalidades Chave

*   **Registro de Credenciais WebAuthn (Passkeys):**
    *   Iniciar o processo de registro de um novo autenticador para um usuário.
    *   Gerar as opções de criação de credencial (`PublicKeyCredentialCreationOptions`) para o cliente (navegador/aplicação).
    *   Validar e processar a resposta de atestação (`AuthenticatorAttestationResponse`) enviada pelo cliente.
    *   Armazenar de forma segura as informações da credencial pública registrada (public key, credential ID, sign count, etc.).
*   **Autenticação com Credenciais WebAuthn:**
    *   Iniciar o processo de autenticação para um usuário.
    *   Gerar as opções de solicitação de asserção (`PublicKeyCredentialRequestOptions`) para o cliente.
    *   Validar e processar a resposta de asserção (`AuthenticatorAssertionResponse`) enviada pelo cliente.
    *   Verificar a assinatura digital e o contador de assinaturas (`signCount`) para prevenir ataques de replay.
*   **Gerenciamento de Credenciais Registradas:**
    *   Permitir que usuários listem suas credenciais WebAuthn registradas.
    *   Permitir que usuários removam/desvinculem credenciais WebAuthn de suas contas.
*   **Configuração do Relying Party (RP):**
    *   Configurar o ID do Relying Party (geralmente o domínio /api/webauthn/registration/begin`).
3.  O controller da API chama `Deeper_Hub.WebAuthn.begin_registration(user_id, key_name, opts)`.
4.  `WebAuthnService`:
    *   Gera um challenge criptograficamente seguro.
    *   Obtém o Relying Party ID e outras informações de configuração do `Core.ConfigManager`.
    *   Constrói as `PublicKeyCredentialCreationOptions` usando a biblioteca WebAuthn.
    *   Armazena o `user_id` e o `challenge` no cache com um TTL curto (ex: 5 minutos).
    *   Retorna as opções para o cliente.
5.  Frontend usa as opções recebidas para chamar `navigator.credentials.create()`.
6.  O navegador interage com o autenticador do usuário.
7.  O autenticador cria um novo par de chaves e retorna uma resposta de atestação para o frontend.
8.  Frontend envia a resposta de atestação para a API (ex: `POST /api/webauthn/registration/complete`).
9.  O controller da API chama `Deeper_Hub.WebAuthn.complete_registration(user_id, attestation_response_from_client)`.
10. `WebAuthnService`:
    *   Recupera o `challenge` original do cache usando o `user_id` (ou um ID de sessão do desafio).
    *   Valida a resposta de atestação usando a biblioteca WebAuthn (verifica challenge, origem, assinatura, etc.).
    *   Se válida, extrai o ID da credencial, a chave pública e o contador de assinatura.
    *   Cria um novo registro `Deeper_Hub.WebAuthn.Schema.Credential` e o persiste.
    *   Retorna `{:ok, credential_info_publica}`.
11. Event da aplicação).
    *   Configurar o nome do Relying Party.
*   **Suporte a Diferentes Tipos de Atestação e Extensões:**
    *   Lidar com diferentes formatos de atestação (ex: `packed`, `fido-u2f`, `none`).
    *   Processar extensões WebAuthn relevantes.
*   **Desafios (Challenges):**
    *   Geração e validação de desafios criptograficamente seguros para cada operação de registro e autenticação.
    *   Armazenamento temporário e seguro de desafios pendentes (ex: em cache ou sessão).
*   **Integração com `Deeper_Hub.Accounts` e `Deeper_Hub.MFA`:**
    *   Associar credenciais WebAuthn a contas de usuário.
    *   Permitir que WebAuthn seja usado como um método primário de login (passwordless) ou como um segundo fator de autenticação.
*   **Auditoria e Logging:**
    *   Registrar todas as tentativas de registro e autenticação WebAuthn, sucessos e falhas (via `Deeper_Hub.Audit`).

## 🏗️ 3. Arquitetura e Design

`Deeper_Hub.WebAuthn` atuará como uma fachada para um serviço que encapsula a lógica complexa do protocolo WebAuthn.

*   **Interface Pública (`Deeper_Hub.WebAuthn.WebAuthnFacade` ou `Deeper_Hub.WebAuthn`):** Funções como `begin_registration/3`, `complete_registration/2`, `begin_authentication/2`, `complete_authentication/2`.
*   **Serviço WebAuthn (`Deeper_Hub.WebAuthn.Services.WebAuthnService`):**
    *   Contém a lógica principal para todas as fases do WebAuthn.
    *   Interage com bibliotecas Elixir especializadas em WebAuthn (ex: `Wax` ou `WebauthnEx`).
*   **Schema Ecto (`Deeper_Hub.WebAuthn.Schema.Credential`):**
    *   Define como as informações da credencial WebAuthn são persistidas (public key, credential ID, user_handle, sign_count, transportes, etc.).
*   **Cache de Desafios (`Deeper_Hub.WebAuthn.Challengeos de auditoria e notificação são disparados.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.WebAuthn.begin_registration/3`

*   **Descrição:** Inicia o processo de registro de uma nova credencial WebAuthn para um usuário.
*   **`@spec`:** `begin_registration(user_id :: String.t(), key_name :: String.t() | nil, opts :: Keyword.t()) :: {:ok, creation_options :: map()} | {:error, reason}`
*   **Parâmetros:**
    *   `user_id` (String): O ID do usuário para o qual a credencial será registrada.
    *   `key_name` (String | nil): Um nome amigável opcional para a credencial (ex: \"Minha YubiKey\").
    *   `opts` (Keyword.t()): Opções adicionais.
        *   `:username_for_rp` (String): Nome de usuário a ser usado no Relying Party (geralmente o email ou username do usuário).
*   **Retorno:**
    *   `{:ok, creation_options_map}`: Um mapa com as opções a serem passadas para `navigator.credentials.create()` no cliente. Contém o `challenge`.
    *   `{:error, reason}`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    case Deeper_Hub.WebAuthn.begin_registration(current_user.id, \"Chave de Segurança Principal\", username_for_rp: current_user.email) do
      {:ok, options} -> # Enviar options para o frontend
      {:error, reason} -> Logger.error(\"Falha ao iniciar registro WebAuthn: #{reason}\")
    end
    ```

### 6.2. `Deeper_Hub.WebAuthn.complete_registration/2`

*   **Descrição:** Completa o processo de registro de uma credencial WebAuthn, validando a resposta do autenticador.
*   **`@spec`:** `complete_registration(user_id :: String.t(), attestation_response :: map()) :: {:ok, Credential.t()} | {:error, reason}`
*   **Parâmetros:**
    *   `user_id` (String): O ID do usuário.
    *   `attestation_response` (map): A resposta de atestação recebida do cliente (após `navigator.credentials.create()`).
*   **Retorno:**
    *   `{:ok, credential_struct}`: A credencial WebAuthn registrada (informações públicas).
    *   `{:error, :invalid_challenge | :invalid_attestation | :credential_already_registered | reason}`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    # attestation_data_from_client é o JSON.parse() da resposta do navegador
    case Deeper_Hub.WebAuthn.complete_registration(current_user.id, attestation_data_from_client) do
      {:ok, cred} -> Logger.info(\"Credencial WebAuthn #{cred.id} registrada para #{current_user.id}\")
      {:error, reason} -> Logger.error(\"Falha ao completar registro WebAuthn: #{reason}\")
    end
    ```

*(Funções `begin_authentication/2`, `complete_authentication/2`, `list_credentials/1`, `remove_credential/2` seriam documentadas de forma similar).*

## ⚙️ 7. Configuração

*   **ConfigManager (`Deeper_Hub.Core.ConfigManager`):**
    *   `[:webauthn, :relying_party_id]`: O ID do Relying Party (geralmente o domínio da aplicação, ex: \"deeperhub.com\"). **Obrigatório.**
    *   `[:webauthn, :relying_party_name]`: NomeCache` ou via `Core.Cache`):**
    *   Armazena temporariamente os desafios gerados para as operações de registro e autenticação, associados a uma sessão ou usuário.
*   **Integrações:**
    *   `Deeper_Hub.Core.Repo`: Para persistência de credenciais.
    *   `Deeper_Hub.Core.Cache`: Para desafios.
    *   `Deeper_Hub.Core.ConfigManager`: Para configurações do Relying Party.
    *   `Deeper_Hub.Accounts`: Para associar credenciais a usuários.
    *   `Deeper_Hub.Audit`: Para logar operações.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**

### 3.1. Componentes Principais

*   **`Deeper_Hub.WebAuthn.WebAuthnFacade`:** Ponto de entrada.
*   **`Deeper_Hub.WebAuthn.Services.WebAuthnService`:** Lógica principal do protocolo.
*   **`Deeper_Hub.WebAuthn.Schema.Credential`:** Schema Ecto para credenciais.
*   **Biblioteca WebAuthn Subjacente:** Uma dependência externa como `Wax` ou `WebauthnEx`.
*   **`Deeper_Hub.WebAuthn.Supervisor`:** Supervisiona processos (se houver, como um worker para limpar desafios expirados do cache).

### 3.3. Decisões de Design Importantes

*   **Escolha da Biblioteca WebAuthn:** A seleção de uma biblioteca Elixir madura e bem mantida para WebAuthn é crucial, pois o protocolo é complexo.
*   **Armazenamento de Desafios:** Onde e como os desafios (challenges) são armazenados temporariamente entre o início e a conclusão de uma operação. A sessão do usuário ou um cache com TTL são opções comuns.
*   **User Handle:** Decidir qual identificador único do usuário (`user_id` do Deeper_Hub) será usado como `userHandle` no protocolo WebAuthn.
*   **Políticas de Autenticador:** Se haverá políticas sobre quais tipos de autenticadores são permitidos (ex: apenas chaves de segurança com certificação FIDO2, ou permitir autenticadores de plataforma).

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Registra uma Nova Chave de Segurança:** Um usuário acessa suas configurações de segurança e inicia o processo para adicionar uma YubiKey como método de login.
*   **Usuário Loga sem Senha:** Na tela de login, o usuário opta por logar com sua chave de segurança ou biometria do dispositivo.
*   **Usuário Usa WebAuthn como Segundo Fator:** Após inserir a senha, o sistema solicita que o usuário utilize seu autenticador WebAuthn registrado para completar o login.
*   **Usuário Remove uma Credencial Antiga:** Um usuário remove um dispositivo antigo de sua lista de autenticadores WebAuthn.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Registro de uma Nova Credencial WebAuthn:**

1.  Usuário inicia o registro via UI.
2.  Frontend envia uma requisição para a API (ex: `POST /api/webauthn/registration/begin`).
3.  `Deeper_Hub.API` (Controller) chama `Deeper_Hub.WebAuthn.begin_registration(user_id, key_name, _opts)`.
4.  `WebAuthnService` gera as `PublicKeyCredentialCreationOptions`, incluindo um desafio (challenge) único.
5.  O desafio é armazenado temporariamente (ex: na sessão do usuário ou no `Core.Cache` com o `user_id`).
6.  As opções são retornadas ao frontend.
7.  Frontend usa `navigator.credentials.create()` com as opções recebidas. O autenticador do usuário (ex: chave de segurança) gera um par de chaves e o atestado.
8.  Frontend envia a `AuthenticatorAttestationResponse` para a API (ex: `POST /api/webauthn/registration/complete`).
9.  `Deeper_Hub.API` chama `Deeper_Hub.WebAuthn.complete_registration(user_id, attestation_response)`.
10. `WebAuthnService` recupera o desafio armazenado.
11. Valida a `attestation_response` contra o desafio e as políticas de exibição do Relying Party (ex: \"Deeper_Hub\"). **Obrigatório.**
    *   `[:webauthn, :relying_party_origin]`: A origem completa do Relying Party (ex: \"https://deeperhub.com\"). **Obrigatório.**
    *   `[:webauthn, :challenge_ttl_seconds]`: TTL para os desafios de registro/autenticação no cache. (Padrão: `300` - 5 minutos)
    *   `[:webauthn, :default_attestation_type]`: Tipo de atestação padrão a ser solicitado (\"none\", \"indirect\", \"direct\"). (Padrão: `\"none\"`)
    *   `[:webauthn, :user_verification_requirement]`: Requisito de verificação do usuário (\"required\", \"preferred\", \"discouraged\"). (Padrão: `\"preferred\"`)
    *   `[:webauthn, :allow_credentials_from_any_origin_for_rp_id]`: (Boolean, para desenvolvimento) Permite credenciais de diferentes origens se o RP ID corresponder. (Padrão: `false`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.Repo`: Para persistir `Credential.t()`.
*   `Deeper_Hub.Core.Cache`: Para armazenar desafios temporários.
*   `Deeper_Hub.Core.ConfigManager`: Para configurações do Relying Party.
*   `Deeper_Hub.Accounts`: Para associar credenciais a usuários.
*   `Deeper_Hub.Auth` / `Deeper_Hub.MFA`: Para integrar WebAuthn como método de login ou 2FA.
*   `Deeper_Hub.Audit`: Para registrar eventos de WebAuthn.
*   `Deeper_Hub.Core.Logger`, `Deeper_Hub.Core.Metrics`.

### 8.2. Bibliotecas Externas

*   Uma biblioteca Elixir para WebAuthn, como **`Wax`** ou **`WebAuthn.Elixir`** (ou uma mais recente se disponível). Esta biblioteca lidará com a maior parte da complexidade do protocolo.
*   `Jason` (ou outra lib JSON) para lidar com as estruturas JSON trocadas com o cliente.

## 🤝 9. Como Usar / Integração

*   **Frontend:** A UI precisará de JavaScript para interagir com a API WebAuthn do navegador (`navigator.credentials.create()` e `navigator.credentials.get()`).
*   **API Endpoints:** `Deeper_Hub.API` precisará de endpoints para `/webauthn/registration/begin`, `/webauthn/registration/complete`, `/webauthn/authentication/begin`, `/webauthn/authentication/complete`.
*   **Módulo `Auth` ou `MFA`:**
    *   Para usar como login primário, o `Auth` chamaria `WebAuthn.begin_authentication` e `WebAuthn.complete_authentication`.
    *   Para usar como 2FA, o `MFA` chamaria as mesmas funções após a verificação do primeiro fator.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar os fluxos de registro e autenticação completos. Isso é desafiador pois envolve interação com o navegador/autenticador.
    *   Pode-se mockar as respostas do `navigator.credentials.*` para testar a lógica do backend.
    *   Bibliotecas WebAuthn podem oferecer utilitários de teste.
*   Testar a validação de diferentes tipos de respostas de atestação e asserção.
*   Testar o gerenciamento de credenciais (listagem, remoção).
*   Localização: `test/deeper_hub/web_authn/`

### 10.2. Métricas

*   `deeper_hub.webauthn.registration.attempt.count` (Contador).
*   `deeper_hub.webauthn.registration.success.count` (Contador).
*   `deeper_hub.webauthn.authentication.attempt.count` (Contador).
*   `deeper_hub.webauthn.authentication.success.count` (Contador).
*   `deeper_hub.webauthn.credential.removed.count` (Contador).
*   `deeper_hub.webauthn.challenge_cache.hit_ratio` (Gauge).

### 10.3. Logs

*   `Logger.info(\"Iniciando registro WebAuthn para user_id: #{uid}, challenge: #{challenge}\", module: Deeper_Hub.WebAuthn.Services.WebAuthnService)`
*   `Logger.info(\"Credencial WebAuthn registrada com ID: #{cred_id} para user_id: #{uid}\", module: Deeper_Hub.WebAuthn.Services.WebAuthnService)`
*   `Logger.info(\"Autenticação WebAuthn bem-sucedida para user_id: #{uid} com credencial_id: #{cred_id}\", module: Deeper_Hub.WebAuthn.Services.WebAuthnService)`
*   `Logger.error(\"Falha na validação WebAuthn: #{reason}\", module: Deeper_Hub.WebAuthn.Services.WebAuthnService)`

### 10.4. Telemetria

*   `[:deeper_hub, :webauthn, :registration, :begin | :complete | :exception]`
*   `[:deeper_hub, :webauthn, :authentication, :begin | :complete | :exception]`

## ❌ 11. Tratamento de Erros

*   Retornar erros claros para o cliente/API em caso de falhas de validação (ex: challenge expirado, assinatura inválida, credencial desconhecida).
*   Erros comuns: `:invalid_challenge`, `:invalid_origin`, `:invalid_signature`, `:credential_not_found`, `:user_not_found`, `:attestation_failed`, `:assertion_failed`.

## 🛡️ 12. Considerações de Segurança

*   **Relying Party ID e Origin:** Configurar corretamente e validar estritamente para prevenir ataques de phishing.
*   **Challenge Randomness:** Garantir que os challenges sejam criptograficamente seguros e de uso único.
*   **Contador de Assinatura:** Validar o contador de assinatura para detectar clonagem de autenticadores (embora a proteção principal seja a não exportabilidade da chave privada).
*   **Transporte Seguro:** Todas as comunicações WebAuthn devem ocorrer sobre HTTPS.
*   **Armazenamento da Credencial:** A chave pública da credencial pode ser armazenada, mas a chave privada nunca deixa o autenticador do usuário.

## 🧑‍💻 13. Contribuição

*   Manter-se atualizado com as evoluções do padrão WebAuthn e das bibliotecas Elixir correspondentes.
*   Testar com uma variedade de autenticadores e navegadores.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Suporte para \"Resident Keys\" / \"Discoverable Credentials\" para login verdadeiramente sem username.
*   [ ] Melhor interface de gerenciamento de credenciais para usuários.
*   [ ] Políticas mais granulares para tipos de autenticadores permitidos.
*   [ ] Suporte para atestações mais complexas, se necessário para casos de uso de alta segurança.
*   [ ] Fluxo de recuperação de conta caso o usuário perca todos os seus autenticadores WebAuthn (deve ser integrado com outros métodos de recuperação).

---

*Última atualização: YYYY-MM-DD*

---

Chegamos ao fim da lista de módulos que identificamos como principais e faltando READMEs! 🎉

Recapitulando os READMEs que idealizamos e criamos o conteúdo:

1.  `Core.HTTPClient`
2.  `Core.Internationalization (I18n)`
3.  `Core.InputValidator`
4.  `Deeper_Hub.Audit`
5.  `Deeper_Hub.FeatureFlags`
6.  `Deeper_Hub.Console`
7.  `Deeper_Hub.Biometrics`
8.  `Deeper_Hub.ModuleInspector`
9.  `Deeper_Hub.GeoIP`
10. `Deeper_Hub.Mailer`
11. `Deeper_Hub.Accounts` (Exemplo detalhado baseado no seu material)
12. `Elixir.Deeper_Hub.Accounts.Services.UserService` (Exemplo de submódulo de Serviço)
13. `Elixir.Deeper_Hub.Security.FraudDetection.Workers.AnalysisWorker` (Exemplo de submódulo Worker)
14. `Elixir.Deeper_Hub.Tokens.Schema.ApiToken` (Exemplo de submódulo Schema)
15. `Deeper_Hub.Achievements` (Exemplo de módulo de \"Services\")
16. `Deeper_Hub.Challenges`
17. `Deeper_Hub.Rewards`
18. `Deeper_Hub.Support`
19. `Deeper_Hub.UserInteractions`
20. `Deeper_Hub.Lists`
21. `Deeper_Hub.WebAuthn`

Acredito que com estes, você tem uma base muito sólida para a documentação da arquitetura do seu novo sistema Deeper_Hub.

O que você gostaria de fazer agora? Podemos:
*   Escolher um módulo já existente na sua lista de `modules_documentation.txt` (como `Deeper_Hub.Auth` ou `Deeper_Hub.Security`) e detalhar seu README no novo formato.
*   Discutir como seria a documentação para os submódulos menores de forma mais geral.
*   Revisar algum dos READMEs que acabamos de criar.
*   Ou qualquer outra coisa que você precise!"""),
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
                types.Part.from_text(text="""Entendido! \"Continue\" para mim significa que você gostaria que eu prosseguisse com a criação de mais READMEs para os submódulos ou para os módulos de domínio que estavam anteriormente sob \"Services\", seguindo a mesma abordagem granular.

Dado que já fizemos exemplos de submódulos (Serviço, Worker, Schema) e um exemplo de módulo de \"Services\" (`Achievements`, `Challenges`, `Rewards`, `Support`, `UserInteractions`, `Lists`), podemos continuar com os outros módulos que estavam na categoria \"Services\" e ainda não detalhamos.

Os que já fizemos daquela categoria:

*   `Deeper_Hub.Achievements`
*   `Deeper_Hub.Challenges`
*   `Deeper_Hub.Rewards`
*   `Deeper_Hub.Support`
*   `Deeper_Hub.UserInteractions`
*   `Deeper_Hub.Lists`

Os que faltam da lista original de \"Services\" que você me mostrou, e que seriam elevados a módulos de domínio de primeiro nível:

1.  **`Deeper_Hub.ServerAdvertisements`**
2.  **`Deeper_Hub.ServerEvents`**
3.  **`Deeper_Hub.ServerPackages`**
4.  **`Deeper_Hub.ServerAlerts`**
5.  **`Deeper_Hub.ServerTags`** (Embora você já tenha um `Deeper_Hub_ServerTags.md`, podemos revisá-lo ou criar um novo com base na estrutura padrão).
6.  **`Deeper_Hub.ServerReviews`** (Embora você já tenha um `Deeper_Hub_ServerReviews.md`, podemos revisá-lo ou criar um novo).

Vamos começar com `Deeper_Hub.ServerAdvertisements`.

---

