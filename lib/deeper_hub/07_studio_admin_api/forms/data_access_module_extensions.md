# Documentação Deeper: Extensões ao `Deeper.Forms.FormsRepo` para Administração

Este documento descreve as funções CRUD adicionais necessárias no `Deeper.Forms.FormsRepo` para suportar a API de Administração de Formulários. As funções de leitura para o cliente final já foram parcialmente definidas.

## Funções CRUD Adicionais para `sys_objects_form`:

*   **`create_form_object(params :: map()) :: {:ok, form_object :: map()} | {:error, any()}`**
    *   `params`: `object` (único), `module`, `title_key`, `action_original`, `form_attrs_json`, `submit_name_key`, `target_table`, `target_key`, `uri_redirect`, `uri_title_key`, `params_json_config`, `is_deletable` (0/1), `is_active` (0/1), `parent_form_object`.
    *   SQL: `INSERT INTO sys_objects_form (object, module, title, action, ...) VALUES (?, ?, ?, ?, ...) RETURNING *;`

*   **`get_form_object_admin(form_object_name :: String.t()) :: {:ok, form_object :: map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_objects_form WHERE object = ? LIMIT 1;`

*   **`list_all_form_objects(filters :: Keyword.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   `filters`: `filter_module`, `filter_object_like`.
    *   SQL: `SELECT * FROM sys_objects_form WHERE (? IS NULL OR module = ?) AND (? IS NULL OR object LIKE ?) ORDER BY object;`

*   **`update_form_object(form_object_name :: String.t(), params :: map()) :: {:ok, form_object :: map()} | {:error, :not_found | any()}`**
    *   SQL: `UPDATE sys_objects_form SET title = ?, target_table = ?, ... WHERE object = ? RETURNING *;`

*   **`delete_form_object(form_object_name :: String.t()) :: :ok | {:error, :not_found | :not_deletable | any()}`**
    *   Verifica `deletable`.
    *   Deleta `sys_form_inputs`, `sys_form_displays` (e `sys_form_display_inputs`) associados antes de deletar o `sys_objects_form`. Deve ser transacional.
    *   SQL: `DELETE FROM sys_form_inputs WHERE object = ?;` (e para outras tabelas dependentes)
    *   SQL: `DELETE FROM sys_objects_form WHERE object = ?;`

## Funções CRUD Adicionais para `sys_form_inputs`:

*   **`create_form_input(form_object_name :: String.t(), params :: map()) :: {:ok, form_input :: map()} | {:error, any()}`**
    *   `params`: `module`, `name` (único para o `form_object_name`), `value_default`, `values_options` (para select/radio - pode ser `#prelist_key` ou JSON), `is_checked_default` (0/1), `type`, `caption_system_key`, `caption_key`, `info_key`, `help_key`, `icon`, `is_required` (0/1), `is_unique_input` (0/1), `is_collapsed` (0/1), `html_level`, `privacy_setting`, `rateable_object`, `attrs_json`, `attrs_tr_json`, `attrs_wrapper_json`, `checker_func`, `checker_params_json`, `checker_error_key`, `db_pass_method`, `db_params_json`, `is_editable` (0/1), `is_deletable` (0/1).
    *   SQL: `INSERT INTO sys_form_inputs (object, module, name, value, \"values\", ...) VALUES (?, ?, ?, ?, ?, ...) RETURNING *;`

*   **`get_form_input(input_id :: integer()) :: {:ok, form_input :: map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_form_inputs WHERE id = ? LIMIT 1;`

*   **`list_form_inputs(form_object_name :: String.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   SQL: `SELECT * FROM sys_form_inputs WHERE object = ? ORDER BY id;` (A ordem real na UI vem de `sys_form_display_inputs`).

*   **`update_form_input(input_id :: integer(), params :: map()) :: {:ok, form_input :: map()} | {:error, :not_found | any()}`**
    *   SQL: `UPDATE sys_form_inputs SET name = ?, type = ?, caption = ?, ... WHERE id = ? RETURNING *;`

*   **`delete_form_input(input_id :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   Remove de `sys_form_inputs`. Também remove todas as referências em `sys_form_display_inputs`. Transacional.
    *   SQL: `DELETE FROM sys_form_display_inputs WHERE input_name = (SELECT name FROM sys_form_inputs WHERE id = ?);` (Precisa do `object` também para `input_name` ser único).
    *   Melhor: `DELETE FROM sys_form_display_inputs WHERE input_name = ? AND display_name IN (SELECT display_name FROM sys_form_displays WHERE object = (SELECT object FROM sys_form_inputs WHERE id = ?));`
    *   SQL: `DELETE FROM sys_form_inputs WHERE id = ?;`

## Funções CRUD Adicionais para `sys_form_displays` e `sys_form_display_inputs`:

*   **`create_form_display(form_object_name :: String.t(), params :: map()) :: {:ok, form_display :: map()} | {:error, any()}`**
    *   `params`: `display_name` (único para o `form_object_name`), `module`, `title_key`.
    *   SQL: `INSERT INTO sys_form_displays (display_name, module, object, title) VALUES (?, ?, ?, ?) RETURNING *;`

*   **`get_form_display(display_id :: integer()) :: {:ok, form_display :: map()} | {:error, :not_found | any()}`**
*   **`list_form_displays(form_object_name :: String.t()) :: {:ok, list(map())} | {:error, any()}`**
*   **`update_form_display(display_id :: integer(), params :: map()) :: {:ok, form_display :: map()} | {:error, :not_found | any()}`**
*   **`delete_form_display(display_id :: integer()) :: :ok | {:error, :not_found | any()}`** (Também deleta `sys_form_display_inputs` associados).

*   **`set_display_inputs(form_object_name :: String.t(), display_name :: String.t(), inputs_config :: list(map())) :: :ok | {:error, any()}`**
    *   `inputs_config`: Lista de `%{input_name: \"...\", order: ..., is_active_in_display: ..., visible_for_levels_mask: ...}`.
    *   Deleta todos os `sys_form_display_inputs` existentes para o `display_name` (que pertence ao `form_object_name`).
    *   Insere os novos com base em `inputs_config`. Transacional.

## Funções CRUD Adicionais para `sys_form_pre_lists` e `sys_form_pre_values`:

*   CRUD completo para `sys_form_pre_lists`.
*   CRUD completo para `sys_form_pre_values` (associado a uma `prelist_key`).
*   **`set_prelist_values(prelist_key :: String.t(), values_config :: list(map())) :: :ok | {:error, any()}`**
    *   `values_config`: Lista de `%{value_data: \"...\", lkey_data: \"...\", order_data: ..., extra_data: \"\"}`.
    *   Deleta valores existentes e insere os novos para `prelist_key`. Transacional.