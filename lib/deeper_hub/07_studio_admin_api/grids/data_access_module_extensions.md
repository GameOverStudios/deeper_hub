# Documentação Deeper: Extensões ao `Deeper.Grids.GridsRepo` para Administração

Este documento descreve as funções CRUD adicionais necessárias no `Deeper.Grids.GridsRepo` para suportar a API de Administração de Grids. As funções de leitura para o cliente final já foram parcialmente definidas.

## Funções CRUD Adicionais para `sys_objects_grid`:

*   **`create_grid_object(params :: map()) :: {:ok, grid_object :: map()} | {:error, any()}`**
    *   `params`: `object` (único), `source_type` ('Sql'/'Array'), `source` (query SQL ou identificador), `table` (tabela principal), `field_id` (PK), `field_order` (ordenação padrão), `paginate_per_page`, `filter_fields_csv`, `sorting_fields_csv`, `visible_for_levels_mask`, etc.
    *   SQL: `INSERT INTO sys_objects_grid (object, source_type, source, \"table\", ...) VALUES (?, ?, ?, ?, ...) RETURNING *;`

*   **`get_grid_object_admin(grid_object_name :: String.t()) :: {:ok, grid_object_details :: map()} | {:error, :not_found | any()}`**
    *   Busca todos os campos de `sys_objects_grid`.
    *   SQL: `SELECT * FROM sys_objects_grid WHERE object = ? LIMIT 1;`

*   **`list_all_grid_objects(filters :: Keyword.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   `filters`: `filter_object_like`.
    *   SQL: `SELECT id, object, \"table\", source_type FROM sys_objects_grid WHERE (? IS NULL OR object LIKE ?) ORDER BY object;`

*   **`update_grid_object(grid_object_name :: String.t(), params :: map()) :: {:ok, grid_object :: map()} | {:error, :not_found | any()}`**
    *   Atualiza campos de um `sys_objects_grid`. A `source` (query SQL) é um campo crítico.
    *   SQL: `UPDATE sys_objects_grid SET source = ?, \"table\" = ?, ... WHERE object = ? RETURNING *;`

*   **`delete_grid_object(grid_object_name :: String.t()) :: :ok | {:error, :not_found | any()}`**
    *   Deleta `sys_grid_fields` e `sys_grid_actions` associados antes de deletar o `sys_objects_grid`. Deve ser transacional.
    *   SQL: `DELETE FROM sys_grid_fields WHERE object = ?;`
    *   SQL: `DELETE FROM sys_grid_actions WHERE object = ?;`
    *   SQL: `DELETE FROM sys_objects_grid WHERE object = ?;`

## Funções CRUD Adicionais para `sys_grid_fields`:

*   **`create_grid_field(grid_object_name :: String.t(), params :: map()) :: {:ok, grid_field :: map()} | {:error, any()}`**
    *   `params`: `name` (nome da coluna na query, único para o `grid_object_name`), `title_key`, `width`, `is_translatable_cell` (0/1), `chars_limit`, `params_json` (para formatadores), `hidden_on_csv`, `order`.
    *   SQL: `INSERT INTO sys_grid_fields (object, name, title, width, ...) VALUES (?, ?, ?, ?, ...) RETURNING *;`

*   **`get_grid_field(field_id_db :: integer()) :: {:ok, grid_field :: map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_grid_fields WHERE id = ? LIMIT 1;`

*   **`list_grid_fields_admin(grid_object_name :: String.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   SQL: `SELECT * FROM sys_grid_fields WHERE object = ? ORDER BY \"order\";`

*   **`update_grid_field(field_id_db :: integer(), params :: map()) :: {:ok, grid_field :: map()} | {:error, :not_found | any()}`**
    *   SQL: `UPDATE sys_grid_fields SET name = ?, title = ?, \"order\" = ?, ... WHERE id = ? RETURNING *;`

*   **`update_grid_fields_order(grid_object_name :: String.t(), ordered_field_ids :: list(integer())) :: :ok | {:error, any()}`**
    *   Itera sobre `ordered_field_ids` e atualiza o campo `order`. Transacional.
    *   SQL: `UPDATE sys_grid_fields SET \"order\" = ? WHERE id = ? AND object = ?;`

*   **`delete_grid_field(field_id_db :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   SQL: `DELETE FROM sys_grid_fields WHERE id = ?;`

## Funções CRUD Adicionais para `sys_grid_actions`:

*   **`create_grid_action(grid_object_name :: String.t(), params :: map()) :: {:ok, grid_action :: map()} | {:error, any()}`**
    *   `params`: `type` ('bulk', 'single', 'independent'), `name` (único para `grid_object_name`+`type`), `title_key`, `icon`, `is_icon_only` (0/1), `requires_confirmation` (0/1), `is_active` (0/1), `order`.
    *   SQL: `INSERT INTO sys_grid_actions (object, type, name, title, ...) VALUES (?, ?, ?, ?, ...) RETURNING *;`

*   **`get_grid_action(action_id_db :: integer()) :: {:ok, grid_action :: map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_grid_actions WHERE id = ? LIMIT 1;`

*   **`list_grid_actions_admin(grid_object_name :: String.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   SQL: `SELECT * FROM sys_grid_actions WHERE object = ? ORDER BY \"order\";`

*   **`update_grid_action(action_id_db :: integer(), params :: map()) :: {:ok, grid_action :: map()} | {:error, :not_found | any()}`**
    *   SQL: `UPDATE sys_grid_actions SET name = ?, title = ?, icon = ?, ... WHERE id = ? RETURNING *;`

*   **`update_grid_actions_order(grid_object_name :: String.t(), ordered_action_ids :: list(integer())) :: :ok | {:error, any()}`**
    *   Itera sobre `ordered_action_ids` e atualiza o campo `order`. Transacional.
    *   SQL: `UPDATE sys_grid_actions SET \"order\" = ? WHERE id = ? AND object = ?;`

*   **`delete_grid_action(action_id_db :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   SQL: `DELETE FROM sys_grid_actions WHERE id = ?;`