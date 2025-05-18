# Módulo: `Elixir.DeeperHub.Accounts.Services.UserService` 🛠️

## 📜 1. Visão Geral do Módulo `DeeperHub.Accounts.Services.UserService`

O `DeeperHub.Accounts.Services.UserService` é um componente interno do módulo `DeeperHub.Accounts`. Sua responsabilidade primária é encapsular a lógica de negócio relacionada diretamente às operações da entidade Usuário, como criação, busca, atualização, exclusão e gerenciamento de status. Ele interage diretamente com o `DeeperHub.Core.Repo` para persistência e é chamado pela fachada `DeeperHub.Accounts` ou por outros serviços dentro do mesmo contexto de `Accounts` (como o `RegistrationService`). 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **CRUD de Usuários:**
    *   Criação de novos usuários (`create_user/1`), incluindo hashing de senha (delegando para `DeeperHub.Auth.Services.PasswordService`) e validação de atributos.
    *   Busca de usuários por ID (`get_user/1`) ou por outros atributos únicos como email (`get_user_by_email/1`).
    *   Atualização de atributos de usuários existentes (`update_user/2`), como status, email (com fluxo de verificação), ou outros campos não relacionados ao perfil direto.
    *   Exclusão lógica (soft delete) de usuários (`delete_user/1`).
*   **Gerenciamento de Estado do Usuário:**
    *   Alteração de status do usuário (ex: ativo, inativo, bloqueado, pendente de verificação).
    *   Registro de tentativas de login falhas e lógicas de bloqueio de conta (pode integrar com `DeeperHub.Security.BruteForceProtection`).
*   **Verificação de Email:**
    *   Gerar e armazenar tokens de verificação de email.
    *   Processar a confirmação de email baseada em token (`confirm_email/2`).
    *   Disparar o reenvio de emails de verificação (via `DeeperHub.Accounts.Services.EmailVerificationWorker` ou `DeeperHub.Notifications`).
*   **Contagem e Listagem:**
    *   Contagem de usuários ativos, bloqueados, etc. (`count_active_users/0`, `count_locked_accounts/0`).
    *   Listagem paginada de usuários com filtros (`list_users/1`).
*   **Emissão de Eventos de Domínio (via `DeeperHub.Accounts.Integrations.EventIntegration`):**
    *   Publicar eventos como `UserCreated`, `UserUpdated`, `UserEmailVerified`, `UserLocked`.

## 🏗️ 3. Arquitetura e Design

Este módulo é um serviço de lógica de negócio.

*   **Entrada:** Recebe chamadas da fachada `DeeperHub.Accounts` ou de outros serviços dentro do contexto `Accounts`.
*   **Processamento:** Aplica regras de negócio, validações (usando changesets do `DeeperHub.Accounts.Schema.User`), e interage com outros serviços ou o `Core.Repo`.
*   **Saída:** Retorna resultados padronizados `{:ok, data}` ou `{:error, reason}`.
*   **Dependências Principais:**
    *   `DeeperHub.Core.Repo`: Para acesso ao banco de dados.
    *   `DeeperHub.Accounts.Schema.User`: Para changesets e manipulação da struct User.
    *   `DeeperHub.Auth.Services.PasswordService`: Para hashing de senhas.
    *   `DeeperHub.Accounts.Integrations.EventIntegration`: Para publicar eventos.
    *   `DeeperHub.Core.Logger` e `DeeperHub.Core.Metrics`.

### 3.1. Componentes Principais (dentro deste serviço, se houver)

*   Normalmente, um serviço como este não terá subcomponentes complexos, mas sim funções privadas bem definidas para tarefas específicas (ex: `p_hash_password/1`, `p_validate_email_uniqueness/1`).

### 3.3. Decisões de Design Importantes

*   **Foco na Entidade User:** Este serviço lida exclusivamente com a entidade `User`. Operações de perfil são delegadas ao `ProfileService`, e de autenticação ao `AuthService`.
*   **Uso de Changesets:** Todas as operações de escrita (create/update) utilizam Ecto changesets para validação.

## 🛠️ 4. Casos de Uso Principais (como ele é usado internamente)

*   O `DeeperHub.Accounts.Services.RegistrationService` chama `UserService.create_user/1` durante o registro de um novo usuário.
*   A fachada `DeeperHub.Accounts` chama `UserService.get_user/1` quando uma parte do sistema precisa buscar um usuário.
*   A fachada `DeeperHub.Accounts` chama `UserService.update_user/2` para, por exemplo, alterar o status de um usuário.
*   O `DeeperHub.Accounts.Services.EmailVerificationWorker` pode chamar `UserService.confirm_email/2` após um usuário clicar em um link de verificação.

## 📡 6. API (Interna do Módulo `Accounts`)

### 6.1. `DeeperHub.Accounts.Services.UserService.create_user/1`

*   **Descrição:** Cria uma nova entidade de usuário.
*   **`@spec`:** `create_user(attrs :: map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}`
*   **Parâmetros:**
    *   `attrs` (map): Atributos para o novo usuário (ex: `:email`, `:password_hash` já hasheada).
*   **Retorno:** O usuário criado ou um changeset com erros.

*(...outras funções públicas do serviço seriam documentadas aqui de forma similar)*

## ⚙️ 7. Configuração

*   Configurações relevantes são geralmente gerenciadas pelo módulo pai `DeeperHub.Accounts` ou obtidas diretamente do `Core.ConfigManager`.
    *   Ex: `[:accounts, :email_verification, :token_ttl_hours]` (usada para gerar tokens de verificação).

## 🔗 8. Dependências (já listadas em Arquitetura)

## 🤝 9. Como Usar / Integração (Dentro do Módulo `Accounts`)

Este serviço é tipicamente chamado por:
*   `DeeperHub.Accounts` (a fachada)
*   Outros serviços dentro do namespace `DeeperHub.Accounts.Services.*`

```elixir
# Exemplo de uso pelo RegistrationService
defmodule DeeperHub.Accounts.Services.RegistrationService do
  alias DeeperHub.Accounts.Services.UserService

  def register(user_attrs, _profile_attrs) do
    with {:ok, user} <- UserService.create_user(user_attrs) do
      # ... criar perfil, etc.
      {:ok, user}
    # ...
    end
  end
end
```

## ✅ 10. Testes e Observabilidade

*   **Testes:** Foco em testar a lógica de negócio específica do `UserService`, mockando dependências como `Repo` e `PasswordService`. Local: `test/deeper_hub/accounts/services/user_service_test.exs`.
*   **Métricas e Logs:** As métricas e logs são geralmente emitidos pela fachada `DeeperHub.Accounts` ou pelos workers, mas o `UserService` pode logar informações específicas de sua execução.

## ❌ 11. Tratamento de Erros

*   Retorna `{:error, Ecto.Changeset.t()}` para falhas de validação.
*   Retorna `{:error, :not_found}` quando entidades não são encontradas.
*   Outros erros específicos podem ser `{:error, :email_taken}`, `{:error, :invalid_token}`.

---

*Última atualização: YYYY-MM-DD*

---

**Exemplo 2: Submódulo Worker (dentro de `DeeperHub.Security.FraudDetection`)**

