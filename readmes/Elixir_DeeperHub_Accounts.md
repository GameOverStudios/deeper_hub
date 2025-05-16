# Módulo: `Elixir.Deeper_Hub.Accounts` 🚀

## 📜 1. Visão Geral do Módulo `Elixir.Deeper_Hub.Accounts`

O módulo `Deeper_Hub.Accounts` é a fachada principal e ponto de entrada para todas as operações relacionadas ao gerenciamento do ciclo de vida de contas de usuário e seus perfis associados no sistema Deeper_Hub. Ele orquestra funcionalidades como registro, autenticação (delegando para `Deeper_Hub.Auth`), gerenciamento de perfis, e outras operações pertinentes à conta do usuário. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento do Ciclo de Vida do Usuário:**
    *   Criação de novas contas de usuário (`create_user/1`).
    *   Registro completo de usuário com perfil (`register_user/1`).
    *   Busca de usuários por ID (`get_user/1`) ou email (`get_user_by_email/1`).
    *   Listagem de usuários com filtros e paginação (`list_users/1`).
    *   Contagem de usuários ativos, bloqueados e registros recentes (via `Deeper_Hub.Accounts.AccountManager` ou `Deeper_Hub.Accounts.Services.UserService`).
*   **Autenticação de Usuário (Delegação):**
    *   Autenticação com email e senha (`authenticate/5`).
    *   Início do processo de autenticação WebAuthn (`begin_webauthn_authentication/1`).
    *   Verificação de segundo fator de autenticação (`verify_second_factor/4`).
*   **Gerenciamento de Perfil do Usuário:**
    *   Criação de perfis de usuário (`create_profile/2`).
    *   Obtenção de perfis de usuário (`get_profile/1`).
    *   Atualização de perfis de usuário (`update_profile/2`).
    *   Gerenciamento de preferências de notificação (via `Deeper_Hub.Accounts.AccountManager`).
    *   Formatação de nomes e cálculo de idade (via `Deeper_Hub.Accounts.Profile`).
*   **Gerenciamento de Senha (Delegação):**
    *   Atualização de senha do usuário (`update_password/3`).
*   **Verificação de Email (Delegação):**
    *   Confirmação de endereço de email (`confirm_email/2`).
    *   Reenvio de email de verificação (`resend_verification_email/1`).
*   **Gerenciamento de Sessões (Delegação):**
    *   Limpeza de sessões expiradas (`cleanup_sessions/0`).
*   **Feature Flags Específicas de Contas:**
    *   Verificação de flags como `registration_enabled?`, `email_verification_enabled?` (via `Deeper_Hub.Accounts.FeatureFlags`).
*   **Integração de Eventos:**
    *   Publicação de eventos como `user_created`, `user_updated`, `email_verified` (via `Deeper_Hub.Accounts.Integrations.EventIntegration`).

## 🏗️ 3. Arquitetura e Design

O módulo `Deeper_Hub.Accounts` atua como uma **Fachada (Facade)**, simplificando a interface para um conjunto complexo de subsistemas e serviços relacionados a contas. Ele delega as responsabilidades para módulos de serviço mais específicos, como:

*   `Deeper_Hub.Accounts.Services.UserService`: Lida com operações CRUD de usuários.
*   `Deeper_Hub.Accounts.Services.ProfileService`: Gerencia perfis de usuários.
*   `Deeper_Hub.Auth.Services.AuthService` (via delegação): Lida com autenticação.
*   `Deeper_Hub.Auth.Services.PasswordService` (via delegação): Gerencia senhas.
*   `Deeper_Hub.Accounts.Services.RegistrationService`: Orquestra o processo de registro.
*   `Deeper_Hub.Accounts.Services.SessionCleanupWorker`: Limpeza de sessões.
*   `Deeper_Hub.Accounts.Services.EmailVerificationWorker`: Gerencia verificação de email.
*   `Deeper_Hub.Accounts.FeatureFlags`: Consulta feature flags.
*   `Deeper_Hub.Accounts.Integrations.EventIntegration`: Publica eventos de domínio.
*   `Deeper_Hub.Core.EventBus`: Para publicação de eventos.
*   `Deeper_Hub.Core.Logger`: Para logging.
*   `Deeper_Hub.Core.ConfigManager`: Para configurações.

A estrutura de diretórios típica seria:

```
accounts/
├── accounts.ex             # Fachada Principal
├── feature_flags.ex
├── profile.ex              # Lógica do Profile Struct (se não for só schema)
├── session.ex              # Lógica de Sessão (se não for só schema/manager)
├── user.ex                 # Lógica do User Struct (se não for só schema)
│
├── integrations/
│   └── event_integration.ex
│
├── schema/
│   ├── profile.ex
│   ├── session.ex
│   └── user.ex
│
├── services/
│   ├── user_service.ex
│   ├── profile_service.ex
│   ├── registration_service.ex
│   ├── email_verification_worker.ex
│   └── session_cleanup_worker.ex
│
└── supervisor.ex
```

### 3.1. Componentes Principais

*   **`Deeper_Hub.Accounts` (Este módulo):** Ponto de entrada para todas as funcionalidades de contas.
*   **`Deeper_Hub.Accounts.Services.UserService`:** Lógica de negócio para usuários.
*   **`Deeper_Hub.Accounts.Services.ProfileService`:** Lógica de negócio para perfis.
*   **`Deeper_Hub.Accounts.Services.RegistrationService`:** Orquestra o fluxo de registro de novos usuários.
*   **`Deeper_Hub.Accounts.Schema.User`:** Schema Ecto para a entidade Usuário.
*   **`Deeper_Hub.Accounts.Schema.Profile`:** Schema Ecto para a entidade Perfil.
*   **`Deeper_Hub.Accounts.Schema.Session`:** Schema Ecto para a entidade Sessão.
*   **`Deeper_Hub.Accounts.Integrations.EventIntegration`:** Publica eventos de domínio significativos para o `Core.EventBus`.
*   **`Deeper_Hub.Accounts.FeatureFlags`:** Verifica flags de funcionalidades específicas de contas.
*   **`Deeper_Hub.Accounts.Supervisor`:** Supervisiona os workers e GenServers do módulo Accounts.
*   **Workers (`EmailVerificationWorker`, `SessionCleanupWorker`):** Processos GenServer para tarefas assíncronas.

### 3.3. Decisões de Design Importantes

*   **Fachada Explícita:** O uso de `Deeper_Hub.Accounts` como fachada única para o exterior promove baixo acoplamento e clareza sobre o ponto de entrada do módulo.
*   **Serviços Especializados:** A divisão das responsabilidades em serviços menores (`UserService`, `ProfileService`, etc.) facilita a manutenção e o teste de unidades de lógica específicas.
*   **Separação de Schema e Lógica:** Manter Schemas Ecto separados da lógica de serviço ajuda a manter o código organizado.
*   **Workers para Tarefas Assíncronas:** O uso de GenServers para tarefas como limpeza de sessão e envio de emails de verificação melhora a responsividade das operações síncronas.
*   **Delegação para `Deeper_Hub.Auth`:** Funcionalidades puras de autenticação (verificação de senha, MFA, etc.) são delegadas ao módulo `Deeper_Hub.Auth`, mantendo o `Accounts` focado no ciclo de vida e dados do usuário.

## 🛠️ 4. Casos de Uso Principais

*   **Registro de Novo Usuário:** Um visitante se cadastra na plataforma. O `Deeper_Hub.Accounts` recebe os dados, utiliza o `RegistrationService` para criar o usuário e o perfil, e potencialmente dispara um email de verificação.
*   **Login de Usuário:** Um usuário tenta se logar. `Deeper_Hub.Accounts` delega para `Deeper_Hub.Auth` para verificar as credenciais e, se bem-sucedido, gerencia a criação da sessão.
*   **Atualização de Perfil:** Um usuário logado atualiza suas informações de perfil. `Deeper_Hub.Accounts` usa o `ProfileService` para validar e persistir as alterações.
*   **Confirmação de Email:** Um usuário clica no link de confirmação. `Deeper_Hub.Accounts` usa o `UserService` (ou `EmailVerificationService`) para validar o token e marcar o email como confirmado.
*   **Administrador Lista Usuários:** Um administrador consulta a lista de usuários. `Deeper_Hub.Accounts` usa o `UserService` para buscar e paginar os usuários.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Registro de Novo Usuário (`register_user/1`):**

1.  `Deeper_Hub.Accounts.register_user/1` é chamado com os atributos do usuário e perfil.
2.  A chamada é delegada para `Deeper_Hub.Accounts.Services.RegistrationService.register/1`.
3.  `RegistrationService` primeiro chama `Deeper_Hub.Accounts.Services.UserService.create_user/1` para criar a entidade `User`.
    *   Validações são aplicadas no `User.changeset`.
    *   Senha é hasheada.
    *   Usuário é persistido.
4.  Se a criação do usuário for bem-sucedida, `RegistrationService` chama `Deeper_Hub.Accounts.Services.ProfileService.create_profile/2` para criar o perfil associado.
    *   Validações são aplicadas no `Profile.changeset`.
    *   Perfil é persistido.
5.  `RegistrationService` emite um evento `UserRegisteredEvent` (ou `UserCreatedEvent`) através de `Deeper_Hub.Accounts.Integrations.EventIntegration` para o `Core.EventBus`.
6.  Se a verificação de email estiver habilitada (`FeatureFlags.email_verification_enabled?/1`), uma tarefa para enviar o email de verificação é enfileirada (possivelmente via `EmailVerificationWorker`).
7.  Retorna `{:ok, %{user: user, profile: profile}}` ou `{:error, reason}`.

## 📡 6. API (Se Aplicável)

Este módulo expõe uma API Elixir para ser consumida por outros módulos dentro do Deeper_Hub.

### 6.1. `Deeper_Hub.Accounts.register_user/1`

*   **Descrição:** Registra um novo usuário com informações de usuário e perfil.
*   **`@spec`:** `register_user(attrs :: map()) :: {:ok, %{user: User.t(), profile: Profile.t()}} | {:error, Ecto.Changeset.t() | term()}`
*   **Parâmetros:**
    *   `attrs` (map): Um mapa contendo chaves para os atributos do usuário (ex: `:email`, `:password`) e uma chave `:profile` com os atributos do perfil (ex: `:full_name`).
*   **Retorno:**
    *   `{:ok, %{user: user, profile: profile}}`: Em caso de sucesso, retorna o usuário e perfil criados.
    *   `{:error, changeset}`: Se houver falha na validação dos dados.
    *   `{:error, reason}`: Para outros erros internos.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    attrs = %{
      email: \"novo@exemplo.com\",
      password: \"Senha@123\",
      profile: %{full_name: \"Novo Usuário\"}
    }
    case Deeper_Hub.Accounts.register_user(attrs) do
      {:ok, %{user: user, profile: profile}} -> Logger.info(\"Usuário #{user.email} registrado com perfil #{profile.id}\")
      {:error, reason} -> Logger.error(\"Falha no registro: #{inspect(reason)}\")
    end
    ```

### 6.2. `Deeper_Hub.Accounts.authenticate/5`

*   **Descrição:** Autentica um usuário com email e senha, gerenciando o início da sessão.
*   **`@spec`:** `authenticate(email :: String.t(), password :: String.t(), ip_address :: String.t() | nil, user_agent :: String.t() | nil, geo_data :: map() | nil) :: {:ok, %{user: User.t(), session: Session.t(), token: String.t()}} | {:error, atom()}`
*   **Parâmetros:**
    *   `email` (String): O email do usuário.
    *   `password` (String): A senha do usuário.
    *   `ip_address` (String | nil): O endereço IP do cliente.
    *   `user_agent` (String | nil): O User-Agent do cliente.
    *   `geo_data` (map | nil): Dados geográficos da requisição.
*   **Retorno:**
    *   `{:ok, %{user: user, session: session, token: token}}`: Em caso de sucesso.
    *   `{:error, :invalid_credentials}`: Se as credenciais forem inválidas.
    *   `{:error, :user_locked}`: Se a conta estiver bloqueada.
    *   `{:error, :mfa_required}`: Se MFA for necessário para completar o login.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    case Deeper_Hub.Accounts.authenticate(\"user@example.com\", \"password123\", \"127.0.0.1\", \"MyApp/1.0\", nil) do
      {:ok, auth_data} -> Logger.info(\"Usuário #{auth_data.user.id} autenticado.\")
      {:error, reason} -> Logger.error(\"Falha na autenticação: #{reason}\")
    end
    ```
    *(...documentar outras funções públicas importantes como `get_user/1`, `update_profile/2`, etc.)*

## ⚙️ 7. Configuração

O módulo `Accounts` e seus submódulos podem ser configurados através do `Deeper_Hub.Core.ConfigManager`.

*   **ConfigManager:**
    *   `[:accounts, :registration, :default_role]`: Papel padrão atribuído a novos usuários. (Padrão: `\"user\"`)
    *   `[:accounts, :profile, :max_bio_length]`: Comprimento máximo da biografia do usuário. (Padrão: `500`)
    *   `[:accounts, :profile, :avatar_storage_path]`: Caminho base para armazenamento de avatares (se local). (Padrão: `\"uploads/avatars\"`)
    *   `[:accounts, :email_verification, :token_ttl_hours]`: Tempo de vida (em horas) do token de verificação de email. (Padrão: `24`)
    *   `[:accounts, :session, :cleanup_interval_minutes]`: Intervalo (em minutos) para o worker de limpeza de sessões. (Padrão: `60`)
    *   **Feature Flags (via `Deeper_Hub.Accounts.FeatureFlags` que usa `ConfigManager`):**
        *   `[:accounts, :feature_flags, :registration_enabled]`: (Boolean) Habilita/desabilita o registro de novos usuários. (Padrão: `true`)
        *   `[:accounts, :feature_flags, :email_verification_enabled]`: (Boolean) Requer verificação de email para novos registros. (Padrão: `true`)
        *   `[:accounts, :feature_flags, :social_login_enabled, :google]`: (Boolean) Habilita login com Google. (Padrão: `false`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para acesso a configurações.
*   `Deeper_Hub.Core.EventBus`: Para publicação de eventos de domínio.
*   `Deeper_Hub.Core.Logger`: Para logging estruturado.
*   `Deeper_Hub.Core.Repo`: Para persistência de dados.
*   `Deeper_Hub.Auth`: Para funcionalidades de autenticação e gerenciamento de senhas e sessões.
*   `Deeper_Hub.Notifications` (indireta): Através de eventos, para enviar emails de verificação, etc.
*   `Deeper_Hub.Shared.Utils`: Para utilitários diversos.

### 8.2. Bibliotecas Externas

*   `Ecto`: Para interações com o banco de dados e definições de schema.
*   `Comeonin` ou `Argon2` (ou similar, via `Deeper_Hub.Auth`): Para hashing de senhas.
*   `Jason`: Para serialização/deserialização JSON (se houver APIs REST diretas ou para metadados de eventos).

## 🤝 9. Como Usar / Integração

Outros módulos devem interagir com as funcionalidades de contas exclusivamente através da fachada `Deeper_Hub.Accounts`.

**Exemplo de criação de um novo usuário:**
```elixir
attrs = %{
  email: \"test@example.com\",
  password: \"StrongPassword123!\",
  profile: %{full_name: \"Test User\"}
}
case Deeper_Hub.Accounts.register_user(attrs) do
  {:ok, %{user: user, profile: _profile}} ->
    IO.puts(\"Usuário criado: #{user.id}\")
  {:error, changeset} ->
    IO.puts(\"Erro ao criar usuário: #{inspect(changeset.errors)}\")
  {:error, reason} ->
    IO.puts(\"Erro interno: #{inspect(reason)}\")
end
```

**Exemplo de busca de perfil de usuário:**
```elixir
case Deeper_Hub.Accounts.get_profile(user_id) do
  {:ok, profile} ->
    IO.inspect(profile)
  {:error, :not_found} ->
    IO.puts(\"Perfil não encontrado.\")
  {:error, reason} ->
    IO.puts(\"Erro ao buscar perfil: #{inspect(reason)}\")
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários e de integração para o módulo `Accounts` e seus serviços estão localizados em `test/deeper_hub/accounts/`.
*   Para executar todos os testes do módulo: `mix test test/deeper_hub/accounts/`
*   Para executar um arquivo de teste específico: `mix test test/deeper_hub/accounts/user_service_test.exs`
*   Para executar um teste específico em um arquivo: `mix test test/deeper_hub/accounts/user_service_test.exs:15` (linha 15)
*   Cobertura de testes pode ser gerada com: `mix test --cover`

### 10.2. Métricas

O módulo `Accounts` (e seus componentes) emite métricas para o `Deeper_Hub.Core.Metrics` para monitoramento:

*   `deeper_hub.accounts.user.created.count` (Contador): Número de usuários criados.
*   `deeper_hub.accounts.user.login.success.count` (Contador): Número de logins bem-sucedidos.
*   `deeper_hub.accounts.user.login.failure.count` (Contador): Número de logins falhos.
*   `deeper_hub.accounts.profile.updated.count` (Contador): Número de perfis atualizados.
*   `deeper_hub.accounts.email.verified.count` (Contador): Número de emails verificados.
*   `deeper_hub.accounts.get_user.duration_ms` (Histograma): Duração da busca de usuário.
*   `deeper_hub.accounts.active_users.gauge` (Gauge): Número total de usuários ativos.

### 10.3. Logs

Logs gerados pelo módulo `Accounts` seguem o padrão do `Deeper_Hub.Core.Logger` e incluem automaticamente:
*   `{module: Deeper_Hub.Accounts}` ou o submódulo específico (ex: `{module: Deeper_Hub.Accounts.Services.UserService}`).
*   `{function: \"nome_da_funcao/aridade\"}`.
*   Operações críticas incluem `user_id` e `trace_id` (se aplicável) para rastreamento.
    Ex: `Logger.info(\"Usuário criado\", module: Deeper_Hub.Accounts.Services.UserService, user_id: user.id)`
    Ex: `Logger.error(\"Falha ao atualizar perfil\", module: Deeper_Hub.Accounts.Services.ProfileService, user_id: user.id, error: reason)`

### 10.4. Telemetria

O módulo `Accounts` emite eventos de telemetria através de `Deeper_Hub.Accounts.Integrations.EventIntegration` que são então manipulados pelo `Core.EventBus`. Eventos principais:

*   `[:deeper_hub, :accounts, :user, :created]`: Emitido após um novo usuário ser criado. Payload: `%{user: user_struct}`.
*   `[:deeper_hub, :accounts, :user, :updated]`: Emitido após um usuário ser atualizado. Payload: `%{user: user_struct, changes: changes_map}`.
*   `[:deeper_hub, :accounts, :user, :deleted]`: Emitido após um usuário ser deletado. Payload: `%{user_id: user_id}`.
*   `[:deeper_hub, :accounts, :profile, :updated]`: Emitido após um perfil ser atualizado. Payload: `%{profile: profile_struct, changes: changes_map}`.
*   `[:deeper_hub, :accounts, :email, :verified]`: Emitido quando um email é verificado. Payload: `%{user_id: user_id, email: email_string}`.
*   `[:deeper_hub, :accounts, :password, :changed]`: Emitido após a senha de um usuário ser alterada. Payload: `%{user_id: user_id}`.
*   `[:deeper_hub, :accounts, :session, :created]`: Emitido após uma nova sessão ser criada (login). Payload: `%{user_id: user_id, session_id: session_id}`.
*   `[:deeper_hub, :accounts, :session, :revoked]`: Emitido após uma sessão ser revogada (logout). Payload: `%{user_id: user_id, session_id: session_id}`.

## ❌ 11. Tratamento de Erros

*   Funções que podem falhar devido a dados inválidos geralmente retornam `{:error, changeset}` com os detalhes da validação.
*   Erros de \"não encontrado\" retornam `{:error, :not_found}`.
*   Erros de permissão (embora mais comuns em `Deeper_Hub.Auth`) podem retornar `{:error, :unauthorized}`.
*   Outros erros internos podem retornar `{:error, term()}` com uma descrição do erro.
*   É esperado que os chamadores tratem esses tipos de retorno usando `case` ou `with`.

## 🛡️ 12. Considerações de Segurança

*   **Dados Sensíveis:** Este módulo lida com dados pessoais (nome, email) e credenciais (senhas, via delegação para `Deeper_Hub.Auth`). As senhas nunca são armazenadas em texto plano.
*   **Validação de Entrada:** Todos os dados de entrada fornecidos pelo usuário são rigorosamente validados usando `Ecto.Changeset` para prevenir dados malformados e ataques comuns.
*   **Hashing de Senhas:** O hashing de senhas é delegado para `Deeper_Hub.Auth`, que utiliza algoritmos fortes (ex: Argon2, bcrypt).
*   **Tokens de Verificação:** Tokens de verificação de email são gerados com segurança, têm tempo de vida limitado e são de uso único.
*   **Controle de Acesso:** A modificação de dados de um usuário (perfil, senha) é restrita ao próprio usuário ou a administradores com as devidas permissões (verificado por `Deeper_Hub.Auth` ou `Deeper_Hub.RBAC`).
*   **Prevenção de Enumeração de Usuários:** Respostas a tentativas de login ou recuperação de senha não devem revelar se um email/usuário existe no sistema, para dificultar a enumeração.

## 🧑‍💻 13. Contribuição

Consulte as diretrizes gerais de contribuição do projeto Deeper_Hub.
*   Mantenha a separação entre a fachada `Deeper_Hub.Accounts` e os serviços internos.
*   Adicione testes para todas as novas funcionalidades e correções.
*   Siga os padrões de logging e métricas estabelecidos.
*   Ao adicionar novas operações que alteram estado, considere emitir eventos de domínio através de `EventIntegration`.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar gerenciamento de consentimento do usuário (LGPD/GDPR).
*   [ ] Adicionar opção para usuários solicitarem a exportação de seus dados.
*   [ ] Integrar com um serviço de enriquecimento de perfil (ex: Clearbit) opcional.
*   [ ] Permitir que usuários conectem múltiplas identidades sociais à mesma conta Deeper_Hub.
*   [ ] Refatorar `AccountManager` completamente para dentro dos novos serviços, se ainda houver resquícios.
*   Consultar `TODO:`s no código para tarefas pendentes.

---

*Última atualização: 2025-05-10*