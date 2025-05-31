# Documentação Deeper: Extensões ao `MenusRepo` para Administração

Este documento descreve as funções CRUD adicionais necessárias no `Deeper.PageEngine.MenusRepo` (ou `Deeper.SystemCore.MenusRepo`) para suportar a API de Administração de Menus. As funções de leitura para o cliente final já foram parcialmente definidas.

## Funções CRUD Adicionais para `sys_menu_sets`:

*   **`create_menu_set(params :: map()) :: {:ok, menu_set :: map()} | {:error, any()}`**
    *   `params`: `set_name` (único), `module`, `title_key`, `is_deletable` (0/1).
    *   SQL: `INSERT INTO sys_menu_sets (set_name, module, title, deletable) VALUES (?, ?, ?, ?) RETURNING *;` (onde `title` é `title_key`).

*   **`get_menu_set(set_name :: String.t()) :: {:ok, menu_set :: map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT set_name, module, title, deletable FROM sys_menu_sets WHERE set_name = ? LIMIT 1;`

*   **`list_all_menu_sets(filters :: Keyword.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   `filters`: `filter_module`.
    *   SQL: `SELECT set_name, module, title, deletable FROM sys_menu_sets WHERE (? IS NULL OR module = ?) ORDER BY set_name;`

*   **`update_menu_set(set_name :: String.t(), params :: map()) :: {:ok, menu_set :: map()} | {:error, :not_found | any()}`**
    *   `params`: `title_key`, `is_deletable`. `set_name` e `module` geralmente não são alterados.
    *   SQL: `UPDATE sys_menu_sets SET title = ?, deletable = ? WHERE set_name = ? RETURNING *;`

*   **`delete_menu_set(set_name :: String.t()) :: :ok | {:error, :not_found | :not_deletable | :in_use | any()}`**
    *   Verifica `deletable`.
    *   Verifica se o `set_name` não está em uso em `sys_objects_menu` ou `sys_menu_items`. Se estiver, `{:error, :in_use}`.
    *   SQL: `DELETE FROM sys_menu_sets WHERE set_name = ?;`

## Funções CRUD Adicionais para `sys_objects_menu`:

*   **`create_menu_object(params :: map()) :: {:ok, menu_object :: map()} | {:error, any()}`**
    *   `params`: `object` (nome único), `title_key`, `set_name`, `module`, `template_id`, `is_active` (0/1), `is_deletable` (0/1), `override_class_name`, `override_class_file`, `persistent`.
    *   SQL: `INSERT INTO sys_objects_menu (object, title, set_name, module, ...) VALUES (?, ?, ?, ?, ...) RETURNING *;`

*   **`get_menu_object_admin(menu_object_name :: String.t()) :: {:ok, menu_object :: map()} | {:error, :not_found | any()}`**
    *   Busca todos os campos de `sys_objects_menu`.
    *   SQL: `SELECT * FROM sys_objects_menu WHERE object = ? LIMIT 1;`

*   **`list_all_menu_objects(filters :: Keyword.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   `filters`: `filter_set_name`, `filter_module`.
    *   SQL: `SELECT * FROM sys_objects_menu WHERE (? IS NULL OR set_name = ?) AND (? IS NULL OR module = ?) ORDER BY object;`

*   **`update_menu_object(menu_object_name :: String.t(), params :: map()) :: {:ok, menu_object :: map()} | {:error, :not_found | any()}`**
    *   SQL: `UPDATE sys_objects_menu SET title = ?, set_name = ?, ... WHERE object = ? RETURNING *;`

*   **`delete_menu_object(menu_object_name :: String.t()) :: :ok | {:error, :not_found | :not_deletable | any()}`**
    *   Verifica `deletable`.
    *   SQL: `DELETE FROM sys_objects_menu WHERE object = ?;` (Não deleta os itens, pois pertencem ao `set_name`).

## Funções CRUD Adicionais para `sys_menu_items`:

*   **`create_menu_item(params :: map()) :: {:ok, menu_item :: map()} | {:error, any()}`**
    *   `params`: `set_name`, `module`, `name` (único dentro do set/module), `title_key`, `link`, `icon`, `parent_id` (0 para item raiz), `order`, `visible_for_levels_mask`, `is_active` (0/1), `target`, `onclick`, `addon`, `submenu_object_name`, `copyable`, `editable`, `hidden_on`, etc.
    *   SQL: `INSERT INTO sys_menu_items (set_name, module, name, title, link, ...) VALUES (?, ?, ?, ?, ?, ...) RETURNING *;`

*   **`get_menu_item(item_id :: integer()) :: {:ok, menu_item :: map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_menu_items WHERE id = ? LIMIT 1;`

*   **`list_menu_items_for_set_admin(set_name :: String.t(), filters :: Keyword.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   Busca todos os itens (ativos e inativos) para um `set_name`, para administração.
    *   SQL: `SELECT * FROM sys_menu_items WHERE set_name = ? ORDER BY parent_id, \"order\";`
    *   A hierarquização é feita em Elixir.

*   **`update_menu_item(item_id :: integer(), params :: map()) :: {:ok, menu_item :: map()} | {:error, :not_found | any()}`**
    *   SQL: `UPDATE sys_menu_items SET title = ?, link = ?, \"order\" = ?, ... WHERE id = ? RETURNING *;`

*   **`update_menu_items_order(set_name :: String.t(), parent_item_id :: integer(), ordered_item_ids :: list(integer())) :: :ok | {:error, any()}`**
    *   Itera sobre `ordered_item_ids` e atualiza o campo `order` e `parent_id` (se a reordenação envolver mudança de pai, o que é mais complexo).
    *   SQL: `UPDATE sys_menu_items SET \"order\" = ?, parent_id = ? WHERE id = ? AND set_name = ?;` (executado para cada item). Deve ser transacional.

*   **`delete_menu_item(item_id :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   SQL: `DELETE FROM sys_menu_items WHERE id = ?;`
    *   **Lógica Adicional:** Se o item deletado era um pai, seus filhos (`parent_id = item_id`) devem ser deletados recursivamente ou re-parentados (ex: para o avô ou para 0). O UNA pode simplesmente deletá-los.

## Funções para Menu Templates (Leitura):

*   **`list_menu_templates() :: {:ok, list(map())}`**
    *   SQL: `SELECT id, template, title, visible FROM sys_menu_templates ORDER BY title;`