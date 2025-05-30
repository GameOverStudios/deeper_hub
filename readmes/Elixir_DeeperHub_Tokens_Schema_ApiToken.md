# Módulo: `Elixir.DeeperHub.Tokens.Schema.ApiToken` 🔑

## 📜 1. Visão Geral do Módulo `Elixir.DeeperHub.Tokens.Schema.ApiToken`

O `DeeperHub.Tokens.Schema.ApiToken` é um schema Ecto que define a estrutura de dados para tokens de API persistentes dentro do módulo `DeeperHub.Tokens`. Estes tokens são gerados para usuários ou aplicações externas para permitir acesso programático à API do DeeperHub, com escopos de permissão definidos, limites de uso e datas de expiração. 😊

Este schema é utilizado pelo `DeeperHub.Tokens.Services.DefaultTokenService` (ou um serviço mais específico como `ApiTokenService`) para criar, gerenciar e validar tokens de API armazenados no banco de dados.

## 🎯 2. Responsabilidades e Campos Chave do Schema

*   **Representação da Entidade Token de API:**
    *   `id` (UUID): Identificador único do token (registro no DB, não o valor do token em si).
    *   `user_id` (UUID, opcional): ID do usuário proprietário do token (se for um token de usuário).
    *   `client_id` (String, opcional): ID da aplicação cliente proprietária do token.
    *   `name` (String): Nome descritivo para o token (ex: \"Token para Integração XPTO\").
    *   `token_hash` (String): Hash do valor real do token (o valor do token nunca é armazenado em texto plano).
    *   `token_prefix` (String): Primeiros caracteres do token para fácil identificação pelo usuário.
    *   `scopes` (list(String)): Lista de escopos de permissão concedidos ao token (ex: `[\"read:servers\", \"write:reviews\"]`).
    *   `expires_at` (NaiveDateTime, opcional): Data e hora de expiração do token. Se nulo, o token não expira.
    *   `last_used_at` (NaiveDateTime, opcional): Data e hora do último uso do token.
    *   `revoked_at` (NaiveDateTime, opcional): Data e hora em que o token foi revogado.
    *   `usage_count` (Integer): Número de vezes que o token foi utilizado.
    *   `max_uses` (Integer, opcional): Número máximo de utilizações permitidas.
    *   `rate_limit_per_minute` (Integer, opcional): Limite de requisições por minuto para este token específico.
    *   `metadata` (map): Campo para metadados adicionais.
    *   `inserted_at` (NaiveDateTime): Timestamp de criação.
    *   `updated_at` (NaiveDateTime): Timestamp da última atualização.

*   **Validações (definidas no `changeset/2`):**
    *   Presença de `name`, `token_hash`, `token_prefix`.
    *   Pelo menos um entre `user_id` ou `client_id` deve estar presente.
    *   Formato dos escopos.
    *   Validade de `expires_at` (deve ser no futuro, se presente).

## 🏗️ 3. Arquitetura e Design

*   **Tipo:** Módulo Elixir contendo um schema Ecto (`use Ecto.Schema`).
*   **Funções de Changeset:**
    *   `changeset/2`: Para criação e atualização geral.
    *   `create_changeset/2`: Validações específicas para criação (ex: garantir geração de hash).
    *   `revoke_changeset/1`: Para marcar um token como revogado.
    *   `usage_changeset/1`: Para incrementar `usage_count` e `last_used_at`.
*   **Interações:**
    *   Utilizado por serviços dentro de `DeeperHub.Tokens.Services.*` para operações de banco de dados via `DeeperHub.Core.Repo`.
    *   Pode ter funções auxiliares para, por exemplo, verificar se um token está expirado ou revogado.

### 3.1. Componentes Principais (dentro deste schema)

*   Definição dos campos com `field/3`.
*   Definição de associações (`belongs_to`, `has_many`, etc.) se aplicável (ex: `belongs_to :user, DeeperHub.Accounts.Schema.User`).
*   Funções de changeset para validação.

### 3.3. Decisões de Design Importantes

*   **Armazenamento de Token:** Apenas o hash do valor do token é armazenado por razões de segurança. O valor real do token é mostrado ao usuário apenas uma vez, no momento da criação.
*   **Prefixos de Token:** Armazenar um prefixo ajuda os usuários a identificar qual token está sendo usado ou precisa ser revogado, sem expor o token inteiro.
*   **Escopos Flexíveis:** O campo `scopes` como uma lista de strings permite uma definição granular e flexível de permissões.

## 🛠️ 4. Casos de Uso Principais (como este schema é utilizado)

*   **Criação de Token de API:** Um usuário gera um novo token de API em suas configurações. Um novo registro `ApiToken` é criado.
*   **Validação de Requisição de API:** Uma requisição chega com um token de API. O sistema busca o `ApiToken` pelo hash do token fornecido, verifica se não está revogado ou expirado, e se os escopos são suficientes para a operação.
*   **Revogação de Token:** Um usuário revoga um token de API que não usa mais. O campo `revoked_at` do registro `ApiToken` é preenchido.
*   **Listagem de Tokens:** Um usuário visualiza todos os seus tokens de API ativos.

## 📡 6. API (Funções de Changeset e Queries Comuns)

### 6.1. `DeeperHub.Tokens.Schema.ApiToken.changeset/2`

*   **Descrição:** Cria um changeset para validar os atributos de um token de API.
*   **`@spec`:** `changeset(token_struct :: struct() | Ecto.Changeset.t(), attrs :: map()) :: Ecto.Changeset.t()`

*(Outras funções como `create_token/3`, `get_token_by_value/1` seriam parte de um módulo de serviço, não diretamente no schema, mas o schema seria usado por elas).*

## ⚙️ 7. Configuração

*   Nenhuma configuração direta neste módulo de schema. Configurações relacionadas (ex: comprimento do prefixo do token) seriam gerenciadas pelo `Core.ConfigManager` e usadas pelos serviços que coordenam este schema.

## ✅ 10. Testes e Observabilidade

*   **Testes:** Foco em testar as validações dos changesets. Garantir que todos os campos obrigatórios são validados, formatos corretos, etc. Local: `test/deeper_hub/tokens/schema/api_token_test.exs`.

---

*Última atualização: YYYY-MM-DD*

---

**Módulos de Domínio \"Services\"**

Agora, para os módulos que antes estavam sob `Elixir.DeeperHub.Services.*`. A ideia é que cada um se torne um contexto de domínio de nível superior. Vou fazer o `DeeperHub.Achievements` como exemplo.

---

