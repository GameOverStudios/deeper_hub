# Documentação Deeper: Módulos de Acesso a Dados para Contas e Perfis

Este documento descreve os módulos Elixir (Repositórios/Contextos) responsáveis por encapsular a lógica de interação com o banco de dados (queries SQL diretas) para as tabelas `sys_accounts`, `sys_profiles`, e `bx_persons_data`.

Esses módulos fornecerão uma API interna para os controllers da API RESTful e outros serviços da aplicação \"Deeper\".

## Módulos Propostos:

1.  **`Deeper.SystemCore.AccountsRepo`**: Gerencia a tabela `sys_accounts`.
2.  **`Deeper.SystemCore.ProfilesRepo`**: Gerencia a tabela `sys_profiles` e a lógica de associação entre contas e diferentes tipos de perfis.
3.  **`Deeper.Content.PersonsRepo`**: Gerencia a tabela `bx_persons_data` e outras tabelas específicas de perfis do tipo \"pessoa\" (ex: `bx_persons_pictures` futuramente).

## 1. Módulo: `Deeper.SystemCore.AccountsRepo`

Responsável pelas interações com a tabela `sys_accounts`.

**Localização do Código:** `lib/deeper/system_core/accounts_repo.ex`

### Funções Principais (Exemplos):

*   **`get_account(id :: integer() | String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca uma conta pelo seu `id`.
    *   **SQL:** `SELECT * FROM sys_accounts WHERE id = ? LIMIT 1;`
    *   Retorna um mapa representando a conta ou `:not_found`.

*   **`get_account_by_email(email :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca uma conta pelo seu `email`.
    *   **SQL:** `SELECT * FROM sys_accounts WHERE email = ? LIMIT 1;`

*   **`create_account(params :: map()) :: {:ok, map()} | {:error, any()}`**
    *   Cria uma nova conta.
    *   `params` deve incluir: `name`, `email`, `password_hash`, `role` (opcional, default 1), `lang_id` (opcional, default 0), `active` (opcional, default 0).
    *   `added` e `changed` timestamps devem ser gerados (Unix epoch).
    *   **SQL:**

```sql
        INSERT INTO sys_accounts (name, email, password_hash, role, lang_id, added, changed, active, email_confirmed, phone_confirmed, receive_updates, receive_news, login_attempts, locked)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 1, 1, 0, 0)
        RETURNING *; -- Para SQLite, ou fazer um SELECT após INSERT se RETURNING não for usado/disponível consistentemente
```

```sql
        UPDATE sys_accounts
        SET name = ?, email = ?, changed = ?, -- outros campos...
        WHERE id = ?
        RETURNING *;
```

```sql
        INSERT INTO sys_profiles (account_id, type, content_id, status)
        VALUES (?, ?, ?, ?)
        RETURNING *;
```

```sql
        SELECT p_data.*
        FROM bx_persons_data p_data
        JOIN sys_profiles prof ON p_data.id = prof.content_id
        WHERE prof.id = ? AND prof.type = 'bx_persons'
        LIMIT 1;
```

```sql
        INSERT INTO bx_persons_data (author, fullname, added, changed, allow_view_to, allow_post_to, allow_contact_to)
        VALUES (?, ?, ?, ?, '3', '5', '3')
        RETURNING *;
```

```sql
        UPDATE bx_persons_data
        SET fullname = ?, description = ?, changed = ?, -- outros campos...
        WHERE id = ?
        RETURNING *;
```

```sql
        -- Para os dados:
        SELECT * FROM bx_persons_data
        -- WHERE ... (filtros dinâmicos)
        -- ORDER BY ... (ordenação dinâmica)
        LIMIT ? OFFSET ?;

        -- Para a contagem total (para paginação):
        SELECT COUNT(*) as total_count FROM bx_persons_data
        -- WHERE ... (mesmos filtros);
```

```elixir
        Repo.transaction(fn ->
          with {:ok, account} <- AccountsRepo.create_account(account_params),
               {:ok, _profile_content} <- PersonsRepo.create_person_data(person_data_params |> Map.put(:author, account.profile_id)), # Supondo que profile_id é gerado ou passado
               {:ok, profile} <- ProfilesRepo.create_profile(%{account_id: account.id, type: \"bx_persons\", content_id: _profile_content.id}) do
            # Atualizar account.profile_id se ele não foi setado antes
            AccountsRepo.update_account(account.id, %{profile_id: profile.id})
            # Retornar o resultado desejado da transação
          else
            error -> Repo.rollback(error)
          end
        end)
```

    *   **Considerações:**
        *   `password_hash` deve ser gerado usando uma biblioteca como `Comeonin.Argon2` ou `Comeonin.Bcrypt` antes de chamar esta função.
        *   A função deve garantir que `email` seja único (a constraint `UNIQUE` na tabela ajudará, mas a função pode retornar um erro mais amigável).

*   **`update_account(id :: integer() | String.t(), params :: map()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Atualiza dados de uma conta existente.
    *   `params` pode incluir campos como `name`, `email`, `phone`, `password_hash` (se a senha for alterada), `role`, `lang_id`, `active`, `locked`, etc.
    *   O timestamp `changed` deve ser atualizado.
    *   **SQL (Exemplo para alguns campos):**

    *   **Nota:** Construir a query de `UPDATE` dinamicamente com base nos `params` fornecidos é comum para evitar atualizar campos desnecessariamente ou com `NULL` se não forem passados.

*   **`verify_password(hashed_password :: String.t(), supplied_password :: String.t()) :: boolean()`**
    *   Função utilitária (pode estar em um módulo de autenticação separado, mas o `AccountsRepo` pode usá-la) para verificar uma senha fornecida contra um hash armazenado. Usa `Comeonin.Argon2.check_pass/2` ou similar.

*   **`increment_login_attempts(id :: integer()) :: :ok | {:error, any()}`**
    *   Incrementa `login_attempts`.
    *   **SQL:** `UPDATE sys_accounts SET login_attempts = login_attempts + 1, changed = ? WHERE id = ?;`

*   **`reset_login_attempts(id :: integer()) :: :ok | {:error, any()}`**
    *   Reseta `login_attempts` para 0.
    *   **SQL:** `UPDATE sys_accounts SET login_attempts = 0, changed = ? WHERE id = ?;`

*   **`lock_account(id :: integer()) :: :ok | {:error, any()}`**
    *   Define `locked = 1`.
    *   **SQL:** `UPDATE sys_accounts SET locked = 1, changed = ? WHERE id = ?;`

*   **`unlock_account(id :: integer()) :: :ok | {:error, any()}`**
    *   Define `locked = 0`.
    *   **SQL:** `UPDATE sys_accounts SET locked = 0, changed = ? WHERE id = ?;`

*   **`set_account_active_status(id :: integer(), active_status :: boolean()) :: :ok | {:error, any()}`**
    *   Define `active` (0 ou 1).
    *   **SQL:** `UPDATE sys_accounts SET active = ?, changed = ? WHERE id = ?;`

*   **`update_last_logged(id :: integer(), ip_address :: String.t()) :: :ok | {:error, any()}`**
    *   Atualiza `logged` (timestamp atual) e `ip`.
    *   **SQL:** `UPDATE sys_accounts SET logged = ?, ip = ?, changed = ? WHERE id = ?;`

### Mapeamento de Resultados:

*   Cada função que retorna dados da tabela deve mapear as linhas do resultado SQL (geralmente tuplas ou listas de tuplas via `DBConnection`) para mapas Elixir ou structs simples. Ex: `%{id: 1, name: \"John Doe\", email: \"...\"}`.

## 2. Módulo: `Deeper.SystemCore.ProfilesRepo`

Responsável pelas interações com a tabela `sys_profiles`.

**Localização do Código:** `lib/deeper/system_core/profiles_repo.ex`

### Funções Principais (Exemplos):

*   **`get_profile(id :: integer() | String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca um perfil pelo seu `id` em `sys_profiles`.
    *   **SQL:** `SELECT * FROM sys_profiles WHERE id = ? LIMIT 1;`

*   **`get_profiles_by_account_id(account_id :: integer()) :: {:ok, list(map())} | {:error, any()}`**
    *   Busca todos os perfis associados a um `account_id`.
    *   **SQL:** `SELECT * FROM sys_profiles WHERE account_id = ?;`

*   **`get_profile_by_type_and_content_id(type :: String.t(), content_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca um perfil específico pelo `type` e `content_id`.
    *   **SQL:** `SELECT * FROM sys_profiles WHERE type = ? AND content_id = ? LIMIT 1;`

*   **`create_profile(params :: map()) :: {:ok, map()} | {:error, any()}`**
    *   Cria uma nova entrada em `sys_profiles`.
    *   `params` deve incluir: `account_id`, `type`, `content_id`, `status` (opcional, default 'active').
    *   **SQL:**

*   **`update_profile_status(id :: integer(), status :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Atualiza o status de um perfil.
    *   **SQL:** `UPDATE sys_profiles SET status = ? WHERE id = ? RETURNING *;`

*   **`delete_profile(id :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   Remove um perfil. (Cuidado: `ON DELETE CASCADE` em `sys_profiles` para `account_id` é para quando a conta é deletada, não o perfil individualmente em relação à sua tabela de conteúdo).
    *   A lógica para deletar o `content_id` correspondente (ex: a entrada em `bx_persons_data`) deve ser tratada separadamente ou em uma transação.
    *   **SQL:** `DELETE FROM sys_profiles WHERE id = ?;`

## 3. Módulo: `Deeper.Content.PersonsRepo`

Responsável pelas interações com a tabela `bx_persons_data` (e futuramente outras tabelas relacionadas a pessoas como fotos, etc.).

**Localização do Código:** `lib/deeper/content/persons_repo.ex`

### Funções Principais (Exemplos):

*   **`get_person_data(id :: integer() | String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca dados de uma pessoa pelo `id` de `bx_persons_data`.
    *   **SQL:** `SELECT * FROM bx_persons_data WHERE id = ? LIMIT 1;`

*   **`get_person_data_by_profile_id(profile_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Função de conveniência que busca os dados da pessoa associada a um `sys_profiles.id`.
    *   Requer um `JOIN` ou duas queries:
        1.  `ProfilesRepo.get_profile(profile_id)` para obter `content_id` e `type`.
        2.  Se `type == \"bx_persons\"`, então `get_person_data(content_id)`.
    *   **SQL com JOIN (Exemplo):**

*   **`create_person_data(params :: map()) :: {:ok, map()} | {:error, any()}`**
    *   Cria uma nova entrada em `bx_persons_data`.
    *   `params` deve incluir: `author` (profile_id do criador), `fullname`, e outros campos opcionais.
    *   `added` e `changed` timestamps devem ser gerados.
    *   **SQL (Exemplo com campos mínimos):**

*   **`update_person_data(id :: integer(), params :: map()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Atualiza dados em `bx_persons_data`.
    *   `params` pode incluir `fullname`, `description`, `gender`, `birthday`, `location`, `settings`, etc.
    *   O timestamp `changed` deve ser atualizado.
    *   **SQL (Exemplo):**

*   **`list_persons_data(options :: map()) :: {:ok, %{data: list(map()), pagination: map()}} | {:error, any()}`**
    *   Lista perfis de pessoas com filtros, ordenação e paginação.
    *   `options` pode incluir: `limit`, `offset` (ou `page`, `per_page`), `sort_by`, `filters` (ex: `%{fullname_like: \"John%\"}`).
    *   **SQL (Base, sem filtros/ordenação complexos):**

    *   A construção dinâmica do SQL para filtros e ordenação precisa ser feita com cuidado para evitar SQL injection se não usar placeholders corretamente para os valores.
    *   **Paginação:** Calcular `total_pages`, `current_page`, etc., com base no `total_count`, `limit`, e `offset`.

### Considerações Gerais para Repositórios:

*   **Tratamento de Erros:** As funções devem retornar tuplas `{:ok, result}` ou `{:error, reason}` de forma consistente.
*   **Sanitização de Entradas:** Ao construir SQL dinamicamente (especialmente para cláusulas `WHERE` com filtros ou `ORDER BY`), garantir que os valores dos usuários sejam passados como parâmetros para as funções de execução do `Repo` (`Repo.query(sql_com_placeholders, [valores])`) para prevenir SQL injection. Nomes de colunas para `ORDER BY` devem ser validados contra uma lista permitida.
*   **Transações:** Para operações que envolvem múltiplas tabelas (ex: criar conta, perfil e dados da pessoa), usar transações para garantir atomicidade. O módulo `Deeper.Core.Data.Repo` precisaria expor funcionalidades para `begin`, `commit`, `rollback`.
    *   Exemplo:

*   **Mapeamento de Colunas para Chaves de Mapa/Struct:** Definir uma convenção clara (ex: `snake_case` no DB para `atom_keys_in_snake_case` ou `camelCaseKeys` nos mapas Elixir).