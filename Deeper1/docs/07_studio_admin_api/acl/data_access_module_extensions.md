# Documentação Deeper: Extensões ao `Deeper.SystemCore.AclRepo` para Administração

Este documento descreve as funções CRUD adicionais necessárias no `Deeper.SystemCore.AclRepo` para suportar a API de Administração de ACL. As funções de leitura já foram parcialmente definidas em `docs/01_system_core/sys_acl/data_access_module.md`.

## Funções CRUD Adicionais para `sys_acl_levels`:

*   **`create_level(params :: map()) :: {:ok, level :: map()} | {:error, any()}`**
    *   `params`: `Name`, `Icon`, `Description`, `Active` ('yes'/'no'), `Purchasable` ('yes'/'no'), `Removable` ('yes'/'no'), `QuotaSize`, `QuotaNumber`, `QuotaMaxFileSize`, `Order`, `PasswordExpired`, `PasswordExpiredNotify`.
    *   SQL: `INSERT INTO sys_acl_levels (Name, Icon, ...) VALUES (?, ?, ...) RETURNING *;`

*   **`update_level(level_id :: integer(), params :: map()) :: {:ok, level :: map()} | {:error, :not_found | any()}`**
    *   Atualiza campos de um nível existente.
    *   SQL: `UPDATE sys_acl_levels SET Name = ?, Icon = ?, ... WHERE ID = ? RETURNING *;`

*   **`delete_level(level_id :: integer()) :: :ok | {:error, :not_found | :in_use | any()}`**
    *   Antes de deletar, verifica se o `level_id` não está em uso em `sys_acl_levels_members` ou `sys_acl_matrix`. Se estiver, retorna `{:error, :in_use}`.
    *   SQL: `DELETE FROM sys_acl_levels WHERE ID = ?;`

*   **`list_all_levels(opts :: Keyword.t()) :: {:ok, levels :: list(map())} | {:error, any()}`**
    *   Lista todos os níveis, não apenas os ativos.
    *   `opts`: `sort_by`, `sort_order`.
    *   SQL: `SELECT * FROM sys_acl_levels ORDER BY ? ?;` (com interpolação segura para ordenação).

## Funções CRUD Adicionais para `sys_acl_actions`:

*   **`create_action(params :: map()) :: {:ok, action :: map()} | {:error, any()}`**
    *   `params`: `Module`, `Name`, `AdditionalParamName`, `Title` (chave de tradução), `Desc` (chave de tradução), `Countable` (0/1), `DisabledForLevels`.
    *   SQL: `INSERT INTO sys_acl_actions (Module, Name, ...) VALUES (?, ?, ...) RETURNING *;`

*   **`list_all_actions(opts :: Keyword.t()) :: {:ok, actions :: list(map())} | {:error, any()}`**
    *   `opts`: `filter_module`, `filter_name_like`, `sort_by`, `sort_order`.
    *   SQL: `SELECT * FROM sys_acl_actions WHERE (? IS NULL OR Module = ?) AND (? IS NULL OR Name LIKE ?) ORDER BY ? ?;`

*   **`update_action(action_id :: integer(), params :: map()) :: {:ok, action :: map()} | {:error, :not_found | any()}`**
    *   Atualiza campos de uma ação. `Module` e `Name` geralmente não devem ser alterados devido à unicidade e uso.
    *   SQL: `UPDATE sys_acl_actions SET Title = ?, \"Desc\" = ?, ... WHERE ID = ? RETURNING *;`

*   **`delete_action(action_id :: integer()) :: :ok | {:error, :not_found | :in_use | any()}`**
    *   Antes de deletar, verifica se `action_id` não está em uso em `sys_acl_matrix` ou `sys_acl_actions_track`. Se estiver, `{:error, :in_use}`.
    *   SQL: `DELETE FROM sys_acl_actions WHERE ID = ?;`

## Funções CRUD Adicionais para `sys_acl_matrix`:

*   **`set_matrix_permission(params :: map()) :: {:ok, matrix_entry :: map()} | {:error, any()}`**
    *   `params`: `IDLevel`, `IDAction`, `AllowedCount` (pode ser `nil`), `AllowedPeriodLen` (dias, `nil`), `AllowedPeriodStart` (TEXT ISO8601, `nil`), `AllowedPeriodEnd` (TEXT ISO8601, `nil`), `AdditionalParamValue` (`nil`).
    *   SQL (SQLite): `INSERT OR REPLACE INTO sys_acl_matrix (IDLevel, IDAction, AllowedCount, AllowedPeriodLen, AllowedPeriodStart, AllowedPeriodEnd, AdditionalParamValue) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING *;`
        *   (Nota: `RETURNING *` no `INSERT OR REPLACE` pode não ser suportado por todas as versões do SQLite ou drivers da mesma forma. Pode ser necessário um SELECT após o INSERT/UPDATE se `RETURNING *` não funcionar como esperado com `ON CONFLICT` implícito.)
        *   Alternativa se `RETURNING *` não for confiável com `INSERT OR REPLACE`:

```sql
        SELECT
            m.IDLevel, l.Name AS LevelName,
            m.IDAction, a.Module AS ActionModule, a.Name AS ActionName, a.Title AS ActionTitleKey,
            m.AllowedCount, m.AllowedPeriodLen, m.AllowedPeriodStart, m.AllowedPeriodEnd, m.AdditionalParamValue
        FROM sys_acl_matrix m
        JOIN sys_acl_levels l ON m.IDLevel = l.ID
        JOIN sys_acl_actions a ON m.IDAction = a.ID
        WHERE (? IS NULL OR m.IDLevel = ?) AND (? IS NULL OR m.IDAction = ?) AND (? IS NULL OR a.Module = ?)
        ORDER BY l.Name, a.Module, a.Name;
```

```elixir
            # Tenta UPDATE, se falhar (0 linhas afetadas), tenta INSERT
            sql_update = \"UPDATE sys_acl_matrix SET AllowedCount = ?, ... WHERE IDLevel = ? AND IDAction = ?;\"
            # ...
            # Se update afetou 0 linhas:
            sql_insert = \"INSERT INTO sys_acl_matrix (IDLevel, IDAction, ...) VALUES (?, ?, ...);\"
            # ...
            # Depois faz um SELECT para retornar a linha.
```

            A maneira mais simples é `DELETE` e depois `INSERT` se a combinação `IDLevel, IDAction` é a PK. O `INSERT OR REPLACE` é o mais idiomático para SQLite se a PK for essa.

*   **`delete_matrix_permission(level_id :: integer(), action_id :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   SQL: `DELETE FROM sys_acl_matrix WHERE IDLevel = ? AND IDAction = ?;`

*   **`list_matrix_entries(filters :: Keyword.t()) :: {:ok, entries :: list(map())} | {:error, any()}`**
    *   `filters`: `level_id`, `action_id`, `module_name` (requer JOIN com `sys_acl_actions`).
    *   SQL (Exemplo com filtro por `level_id`):

## Outras Funções de Suporte:

*   Pode haver funções para limpar `sys_acl_actions_track` para um usuário/ação se necessário, mas isso é geralmente gerenciado pela lógica de consumo da ação.