# Documentação Deeper: Módulos de Acesso a Dados para Contas e Perfis

Este documento descreve os módulos Elixir (Repositórios/Contextos) responsáveis por encapsular a lógica de interação com o banco de dados para as funcionalidades de Contas de Usuário e Perfis. Estes módulos fornecerão uma API interna para os controllers da API RESTful \"Deeper\" manipularem os dados.

Eles utilizarão o módulo `Deeper.Core.Data.Repo` (ou similar) para executar queries SQL diretas no banco de dados SQLite.

## Módulos Propostos:

1.  **`Deeper.SystemCore.AccountsRepo`**:
    *   Responsável por todas as operações CRUD e lógicas de busca relacionadas à tabela `sys_accounts`.
    *   Funções para criar contas, buscar por ID/email, verificar senhas, atualizar status, etc.

2.  **`Deeper.SystemCore.ProfilesRepo`**:
    *   Responsável pelas operações na tabela `sys_profiles`.
    *   Funções para criar perfis, buscar perfis por `account_id`, buscar perfil por `type` e `content_id`, etc.
    *   Este módulo frequentemente trabalhará em conjunto com `AccountsRepo` e repositórios específicos de tipo de perfil (como `PersonsRepo`).

3.  **`Deeper.Content.PersonsRepo`** (Exemplo para tipo de perfil \"pessoa\"):
    *   Responsável pelas operações CRUD na tabela `bx_persons_data`.
    *   Funções para criar, buscar, atualizar dados de perfis de pessoa.
    *   Pode incluir lógica para lidar com campos relacionados como `picture`, `cover` (interagindo com um futuro `FilesRepo`).
    *   **Nota:** Embora `bx_persons_data` seja específico do módulo \"Persons\" do UNA, sua interação é tão intrínseca com `sys_profiles` que o repositório é discutido aqui no contexto da funcionalidade de perfis. Outros tipos de perfil (ex: organizações) teriam seus próprios repositórios.

## Estrutura e Responsabilidades de um Módulo de Repositório:

Cada módulo de repositório (ex: `AccountsRepo`) normalmente incluirá:

*   **Funções Públicas:** Uma interface clara para as operações de dados.
    *   Ex: `get_by_id(id)`, `get_by_email(email)`, `create(params)`, `update(id, params)`, `delete(id)`, `list(filters_options)`.
*   **Queries SQL:** As strings SQL exatas usadas para cada operação. Estas serão documentadas para clareza e otimização.
*   **Mapeamento de Resultados:** Funções privadas para mapear as linhas de resultado do banco de dados (geralmente tuplas ou listas de tuplas) para estruturas de dados Elixir mais úteis (mapas ou structs simples).
    *   Ex: `defp map_row_to_account_struct(db_row)`
*   **Tratamento de Erros:** Retorno consistente de `{:ok, result}` ou `{:error, reason}`.
*   **Paginação:** Para funções de listagem, implementação de lógica para `LIMIT` e `OFFSET` e para obter a contagem total de itens.

## Detalhamento dos Módulos:

A seguir, detalharemos as funções e SQLs esperados para cada um dos repositórios propostos.

### 1. `Deeper.SystemCore.AccountsRepo`

Este módulo gerencia a tabela `sys_accounts`.

**Funções Principais e SQLs Esperados:**

*   **`create(params :: map()) :: {:ok, account_map :: map()} | {:error, any()}`**
    *   Insere um novo registro em `sys_accounts`.
    *   `params` deve incluir `name`, `email`, `password_hash`, `role`, `added`, `changed`, `active`. Outros campos podem ter defaults ou serem opcionais.
    *   SQL: `INSERT INTO sys_accounts (name, email, password_hash, ...) VALUES (?, ?, ?, ...) RETURNING *;`
    *   Retorna o mapa da conta criada ou um erro.

*   **`get_by_id(id :: integer()) :: {:ok, account_map :: map()} | {:error, :not_found | any()}`**
    *   Busca uma conta pelo seu `id`.
    *   SQL: `SELECT * FROM sys_accounts WHERE id = ? LIMIT 1;`
    *   Retorna o mapa da conta ou `{:error, :not_found}`.

*   **`get_by_email(email :: String.t()) :: {:ok, account_map :: map()} | {:error, :not_found | any()}`**
    *   Busca uma conta pelo `email`.
    *   SQL: `SELECT * FROM sys_accounts WHERE email = ? LIMIT 1;`

*   **`update(id :: integer(), params :: map()) :: {:ok, account_map :: map()} | {:error, :not_found | any()}`**
    *   Atualiza os campos de uma conta existente.
    *   `params` contém os campos a serem atualizados. A query SQL deve ser construída dinamicamente ou ter todos os campos atualizáveis.
    *   SQL: `UPDATE sys_accounts SET name = ?, email = ?, ... WHERE id = ? RETURNING *;`
    *   Importante: Atualizar `changed` timestamp.

*   **`update_login_info(id :: integer(), ip :: String.t(), logged_timestamp :: integer()) :: :ok | {:error, any()}`**
    *   Atualiza `logged` (timestamp do último login) e `ip`. Reseta `login_attempts`.
    *   SQL: `UPDATE sys_accounts SET logged = ?, ip = ?, login_attempts = 0 WHERE id = ?;`

*   **`increment_login_attempts(id :: integer()) :: {:ok, attempts :: integer()} | {:error, any()}`**
    *   Incrementa `login_attempts`.
    *   SQL: `UPDATE sys_accounts SET login_attempts = login_attempts + 1 WHERE id = ? RETURNING login_attempts;`

*   **`set_locked_status(id :: integer(), locked_status :: boolean()) :: :ok | {:error, any()}`**
    *   Define o status `locked` da conta.
    *   SQL: `UPDATE sys_accounts SET locked = ? WHERE id = ?;` (onde `locked_status` é 0 ou 1)

*   **`set_active_status(id :: integer(), active_status :: boolean()) :: :ok | {:error, any()}`**
    *   Define o status `active` da conta.
    *   SQL: `UPDATE sys_accounts SET active = ? WHERE id = ?;` (onde `active_status` é 0 ou 1)

*   **`delete(id :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   Deleta uma conta. (Considerar se é soft delete ou hard delete. `sys_accounts` no UNA não tem soft delete explícito, mas `sys_profiles` tem `status`).
    *   SQL: `DELETE FROM sys_accounts WHERE id = ?;`
    *   **Cuidado:** Se houver `FOREIGN KEY ... ON DELETE CASCADE` em `sys_profiles` para `account_id`, isso também deletará os perfis associados.

*   **`list_accounts(opts :: Keyword.t()) :: {:ok, {accounts :: list(map()), pagination_meta :: map()}} | {:error, any()}`**
    *   Lista contas com filtros, ordenação e paginação.
    *   `opts` pode incluir: `offset`, `limit`, `sort_by`, `sort_order`, `filter_email`, `filter_name`, `filter_active`, etc.
    *   SQL (Exemplo base):

```sql
        -- Para dados:
        SELECT * FROM sys_accounts
        WHERE (email LIKE ? OR ? IS NULL) AND (active = ? OR ? IS NULL) -- Exemplo de filtro opcional
        ORDER BY ? ?
        LIMIT ? OFFSET ?;

        -- Para contagem total (com os mesmos filtros):
        SELECT COUNT(*) FROM sys_accounts
        WHERE (email LIKE ? OR ? IS NULL) AND (active = ? OR ? IS NULL);
```

```sql
        SELECT p.*, pd.*, sa.email, sa.name as account_name
        FROM sys_profiles p
        JOIN sys_accounts sa ON p.account_id = sa.id
        LEFT JOIN bx_persons_data pd ON p.content_id = pd.id AND p.type = 'bx_persons'
        WHERE p.id = ? LIMIT 1;
```

```sql
        -- Para dados:
        SELECT * FROM bx_persons_data
        WHERE (fullname LIKE ? OR ? IS NULL) -- Exemplo de filtro
        ORDER BY ? ?
        LIMIT ? OFFSET ?;

        -- Para contagem total:
        SELECT COUNT(*) FROM bx_persons_data
        WHERE (fullname LIKE ? OR ? IS NULL);
```

```elixir
defmodule Deeper.SystemCore.AccountsRepo do
  # ... outras funções ...

  defp map_row_to_account_map(columns, row_values) when is_list(columns) and is_list(row_values) do
    Enum.zip(columns, row_values) |> Enum.into(%{})
  end

  # Se Repo.query já retorna uma lista de mapas:
  # defp process_query_result({:ok, %{rows: rows, columns: columns}}) do
  #   mapped_rows = Enum.map(rows, fn row_tuple ->
  #     # Supondo que Repo.query retorna {col_name, value} ou precisamos de col_names
  #     # Aqui você transformaria a tupla em mapa
  #   end)
  #   {:ok, mapped_rows}
  # end

  # Exemplo de struct (opcional)
  # defstruct [:id, :name, :email, :active, ...]
  # defp map_row_to_account_struct(db_row_map) do
  #   %__MODULE__.AccountStruct{ # Ou um struct dedicado como Deeper.SystemCore.Account
  #     id: db_row_map[\"id\"],
  #     name: db_row_map[\"name\"],
  #     # ... outros campos ...
  #   }
  # end
end
```

    *   A construção dinâmica desta query SQL com base nas `opts` será importante.

### 2. `Deeper.SystemCore.ProfilesRepo`

Este módulo gerencia a tabela `sys_profiles`.

**Funções Principais e SQLs Esperados:**

*   **`create(params :: map()) :: {:ok, profile_map :: map()} | {:error, any()}`**
    *   Cria um novo perfil.
    *   `params` deve incluir `account_id`, `type`, `content_id`, `status`.
    *   SQL: `INSERT INTO sys_profiles (account_id, type, content_id, status) VALUES (?, ?, ?, ?) RETURNING *;`

*   **`get_by_id(id :: integer()) :: {:ok, profile_map :: map()} | {:error, :not_found | any()}`**
    *   Busca um perfil pelo seu `id`.
    *   SQL: `SELECT * FROM sys_profiles WHERE id = ? LIMIT 1;`

*   **`get_by_account_id(account_id :: integer(), type :: String.t() | nil) :: {:ok, list(map()) | profile_map :: map()} | {:error, any()}`**
    *   Busca todos os perfis de uma conta, ou um perfil específico se `type` for fornecido.
    *   SQL (todos os tipos): `SELECT * FROM sys_profiles WHERE account_id = ?;`
    *   SQL (tipo específico): `SELECT * FROM sys_profiles WHERE account_id = ? AND type = ? LIMIT 1;`

*   **`get_by_content_id(type :: String.t(), content_id :: integer()) :: {:ok, profile_map :: map()} | {:error, :not_found | any()}`**
    *   Busca um perfil pelo seu `type` e `content_id`.
    *   SQL: `SELECT * FROM sys_profiles WHERE type = ? AND content_id = ? LIMIT 1;`

*   **`update_status(id :: integer(), status :: String.t()) :: {:ok, profile_map :: map()} | {:error, :not_found | any()}`**
    *   Atualiza o `status` de um perfil.
    *   SQL: `UPDATE sys_profiles SET status = ? WHERE id = ? RETURNING *;`

*   **`delete(id :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   Deleta um perfil. (Isso geralmente não deve ser chamado diretamente se `ON DELETE CASCADE` estiver configurado em `account_id`, a menos que seja para desassociar um perfil sem deletar a conta).
    *   SQL: `DELETE FROM sys_profiles WHERE id = ?;`

*   **`get_profile_details(profile_id :: integer()) :: {:ok, detailed_profile_map :: map()} | {:error, :not_found | any()}`**
    *   Busca um perfil e seus dados detalhados da tabela de tipo específico (ex: `bx_persons_data`).
    *   Esta função exigirá um `JOIN` ou múltiplas queries.
    *   SQL (Exemplo para tipo 'bx_persons'):

    *   A lógica precisará lidar com diferentes `p.type` para fazer `JOIN` com a tabela correta.

### 3. `Deeper.Content.PersonsRepo`

Este módulo gerencia a tabela `bx_persons_data`.

**Funções Principais e SQLs Esperados:**

*   **`create(params :: map()) :: {:ok, person_data_map :: map()} | {:error, any()}`**
    *   Cria uma nova entrada em `bx_persons_data`.
    *   `params` deve incluir `author`, `added`, `changed`, `fullname`, e outros campos relevantes.
    *   SQL: `INSERT INTO bx_persons_data (author, added, changed, fullname, ...) VALUES (?, ?, ?, ?, ...) RETURNING *;`
    *   Geralmente chamado como parte de um fluxo maior de criação de perfil.

*   **`get_by_id(id :: integer()) :: {:ok, person_data_map :: map()} | {:error, :not_found | any()}`**
    *   Busca dados de pessoa pelo `id` (que é o `content_id` em `sys_profiles`).
    *   SQL: `SELECT * FROM bx_persons_data WHERE id = ? LIMIT 1;`

*   **`update(id :: integer(), params :: map()) :: {:ok, person_data_map :: map()} | {:error, :not_found | any()}`**
    *   Atualiza dados de pessoa.
    *   SQL: `UPDATE bx_persons_data SET fullname = ?, description = ?, ... WHERE id = ? RETURNING *;`
    *   Importante: Atualizar `changed` timestamp.

*   **`delete(id :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   Deleta dados de pessoa. (Geralmente chamado quando o perfil associado em `sys_profiles` é deletado).
    *   SQL: `DELETE FROM bx_persons_data WHERE id = ?;`

*   **`list_persons_data(opts :: Keyword.t()) :: {:ok, {persons_data :: list(map()), pagination_meta :: map()}} | {:error, any()}`**
    *   Lista dados de pessoas com filtros, ordenação e paginação.
    *   `opts`: `offset`, `limit`, `sort_by`, `sort_order`, `filter_fullname`, `filter_location`, etc.
    *   SQL (Exemplo base):

## Mapeamento de Linhas do Banco de Dados (`map_row_to_struct/map`):

Cada repositório precisará de funções auxiliares (privadas) para converter as linhas retornadas pelo `Deeper.Core.Data.Repo.query/2` (que podem ser tuplas ou listas de valores) em mapas Elixir ou structs simples.

Exemplo (conceitual, depende de como `Repo.query` retorna os dados):