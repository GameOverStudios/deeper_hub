# Documentação Deeper: Extensões ao `Deeper.PageEngine.PagesRepo` para Administração

Este documento descreve as funções CRUD adicionais necessárias no `Deeper.PageEngine.PagesRepo` para suportar a API de Administração do Construtor de Páginas. As funções de leitura para o cliente final já foram parcialmente definidas em `docs/02_page_rendering_engine/sys_objects_page/data_access_module.md` (se criado anteriormente, ou a lógica estava em `api_endpoints.md`).

## Funções CRUD Adicionais para `sys_objects_page`:

*   **`create_page_object(params :: map()) :: {:ok, page_object :: map()} | {:error, any()}`**
    *   `params`: `object` (nome único), `uri` (único), `title_key`, `module`, `layout_id`, `submenu_object_name` (opcional), `visible_for_levels_mask`, `cache_lifetime_seconds`, `deletable` (0/1), `content_info_object` (opcional), `url` (opcional), etc.
    *   SQL: `INSERT INTO sys_objects_page (object, uri, title, module, ...) VALUES (?, ?, ?, ?, ...) RETURNING *;` (onde `title` é a `title_key`).

*   **`get_page_object_admin(page_object_name :: String.t()) :: {:ok, page_object :: map()} | {:error, :not_found | any()}`**
    *   Busca todos os campos de `sys_objects_page` para administração.
    *   SQL: `SELECT * FROM sys_objects_page WHERE object = ? LIMIT 1;`

*   **`list_all_page_objects(filters :: Keyword.t()) :: {:ok, pages :: list(map())} | {:error, any()}`**
    *   `filters`: `filter_module`, `filter_uri_like`, `filter_title_like`, `sort_by`.
    *   SQL: `SELECT id, object, uri, title, module, layout_id, deletable FROM sys_objects_page WHERE (? IS NULL OR module = ?) AND ... ORDER BY ? ?;`

*   **`update_page_object(page_object_name :: String.t(), params :: map()) :: {:ok, page_object :: map()} | {:error, :not_found | any()}`**
    *   Atualiza campos de um `sys_objects_page`. `object` e `uri` geralmente não devem ser alterados se forem chaves lógicas, ou com muito cuidado.
    *   SQL: `UPDATE sys_objects_page SET title = ?, layout_id = ?, ... WHERE object = ? RETURNING *;`

*   **`delete_page_object(page_object_name :: String.t()) :: :ok | {:error, :not_found | :not_deletable | any()}`**
    *   Verifica o campo `deletable`. Se 0, retorna `{:error, :not_deletable}`.
    *   SQL: `DELETE FROM sys_objects_page WHERE object = ?;`
    *   **Lógica Adicional:** Deletar os `sys_pages_blocks` associados (se não houver FK com `ON DELETE CASCADE` na migração, o que é recomendado).
        *   SQL: `DELETE FROM sys_pages_blocks WHERE object = ?;` (executado antes de deletar a página).

## Funções CRUD Adicionais para `sys_pages_blocks`:

*   **`create_page_block(page_object_name :: String.t(), params :: map()) :: {:ok, block :: map()} | {:error, any()}`**
    *   `params`: `cell_id`, `module`, `title_key`, `type`, `content_definition`, `designbox_id`, `cache_lifetime_seconds`, `order`, `active` (0/1), `active_api` (0/1), `visible_for_levels_mask`, `submenu`, `tabs`, `class`, `hidden_on`, `deletable`, `copyable`.
    *   SQL: `INSERT INTO sys_pages_blocks (object, cell_id, module, title, type, content, ...) VALUES (?, ?, ?, ?, ?, ?, ...) RETURNING *;` (onde `title` é `title_key`, `content` é `content_definition`).

*   **`get_page_block_admin(block_id :: integer()) :: {:ok, block :: map()} | {:error, :not_found | any()}`**
    *   Busca todos os campos de `sys_pages_blocks`.
    *   SQL: `SELECT * FROM sys_pages_blocks WHERE id = ? LIMIT 1;`

*   **`list_blocks_for_page_admin(page_object_name :: String.t()) :: {:ok, blocks :: list(map())} | {:error, any()}`**
    *   Busca todos os blocos para uma página, ordenados.
    *   SQL: `SELECT * FROM sys_pages_blocks WHERE object = ? ORDER BY cell_id, \"order\";`

*   **`update_page_block(block_id :: integer(), params :: map()) :: {:ok, block :: map()} | {:error, :not_found | any()}`**
    *   Atualiza campos de um `sys_pages_blocks`.
    *   SQL: `UPDATE sys_pages_blocks SET title = ?, cell_id = ?, \"order\" = ?, content = ?, ... WHERE id = ? RETURNING *;`

*   **`update_page_blocks_order(page_object_name :: String.t(), cell_orders :: map()) :: :ok | {:error, any()}`**
    *   `cell_orders`: Ex: `%{1 => [101, 103, 105], 2 => [102, 104]}` (cell_id => lista de block_ids ordenados).
    *   Itera sobre o mapa, atualizando `cell_id` e `order` para cada `block_id`. Deve ser transacional.
    *   SQL: `UPDATE sys_pages_blocks SET cell_id = ?, \"order\" = ? WHERE id = ?;` (executado para cada bloco).

*   **`delete_page_block(block_id :: integer()) :: :ok | {:error, :not_found | :not_deletable | any()}`**
    *   Verifica o campo `deletable`.
    *   SQL: `DELETE FROM sys_pages_blocks WHERE id = ?;`

## Funções para Layouts, Tipos de Página, Design Boxes (Geralmente Leitura):

*   **`list_page_layouts() :: {:ok, list(map())}`**
    *   SQL: `SELECT id, name, icon, title, template, cells_number FROM sys_pages_layouts ORDER BY id;`
*   **`list_page_types() :: {:ok, list(map())}`** (Se usado pela API de admin)
    *   SQL: `SELECT id, title, template, \"order\" FROM sys_pages_types ORDER BY \"order\";`
*   **`list_design_boxes() :: {:ok, list(map())}`**
    *   SQL: `SELECT id, title, template, \"order\" FROM sys_pages_design_boxes ORDER BY \"order\";`