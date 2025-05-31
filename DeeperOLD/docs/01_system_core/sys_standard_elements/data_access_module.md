# Documentação Deeper: Módulo de Acesso a Dados para Elementos Padrão (`Deeper.SystemCore.StdElementsRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.StdElementsRepo`. Sua responsabilidade é interagir com as tabelas de \"Elementos Padrão do Sistema\" do UNA (`sys_std_pages`, `sys_std_widgets`, `sys_std_pages_widgets`, `sys_std_roles`, `sys_std_roles_actions`, `sys_std_roles_actions2roles`, `sys_std_roles_members`).

Este repositório será usado principalmente pela API de Administração para listar, visualizar e potencialmente modificar esses elementos padrão, embora a modificação de alguns deles (especialmente os definidos pelo sistema) deva ser feita com cautela.

## Responsabilidades Principais:

*   Listar e obter detalhes de Páginas Padrão (`sys_std_pages`).
*   Listar e obter detalhes de Widgets Padrão (`sys_std_widgets`).
*   Gerenciar a associação de widgets a páginas padrão (`sys_std_pages_widgets`).
*   Listar e obter detalhes de Papéis Padrão (`sys_std_roles`).
*   Listar e obter detalhes de Ações de Papéis Padrão (`sys_std_roles_actions`).
*   Gerenciar a associação de ações a papéis (`sys_std_roles_actions2roles`).
*   Gerenciar a associação de contas a papéis padrão (`sys_std_roles_members`).

## Funções Públicas Principais e Lógica SQL (Exemplos):

*(Todas as funções de listagem podem aceitar `opts` para ordenação e filtros, e `lang_code` para tradução de títulos/descrições onde aplicável.)*

---
### Páginas Padrão (`sys_std_pages`)

*   **`list_std_pages(lang_code, opts \\\\ []) :: {:ok, list(map())} | {:error, any()}`**
    *   SQL: `SELECT id, \"index\", name, header, caption, icon FROM sys_std_pages ORDER BY \"index\", name;`
    *   Traduz `header` e `caption` usando `LocalizationRepo`.

*   **`get_std_page(page_id_or_name, lang_code) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca por `id` ou `name`.
    *   SQL: `SELECT id, \"index\", name, header, caption, icon FROM sys_std_pages WHERE id = ? OR name = ? LIMIT 1;`
    *   Traduz.

*   **`create_std_page(params, lang_code) :: {:ok, map()} | {:error, any()}`** (Admin)
    *   `params`: `name`, `index`, `header_key`, `caption_key`, `icon`.
    *   SQL: `INSERT INTO sys_std_pages (name, \"index\", header, caption, icon) VALUES (?, ?, ?, ?, ?) RETURNING *;`

*   **`update_std_page(page_id, params, lang_code) :: {:ok, map()} | {:error, any()}`** (Admin)
    *   SQL: `UPDATE sys_std_pages SET name = ?, \"index\" = ?, ... WHERE id = ? RETURNING *;`

*   **`delete_std_page(page_id) :: :ok | {:error, any()}`** (Admin)
    *   Deleta de `sys_std_pages`. Também deleta associações em `sys_std_pages_widgets`.
    *   SQL: `DELETE FROM sys_std_pages_widgets WHERE page_id = ?;`
    *   SQL: `DELETE FROM sys_std_pages WHERE id = ?;`

---
### Widgets Padrão (`sys_std_widgets` e `sys_std_pages_widgets`)

*   **`list_std_widgets(lang_code, opts \\\\ []) :: {:ok, list(map())} | {:error, any()}`**
    *   `opts`: `filter_page_id_std` (o `name` da `sys_std_pages`), `filter_module`.
    *   SQL: `SELECT id, page_id, module, type, url, click, icon, caption, cnt_notices, cnt_actions, featured FROM sys_std_widgets WHERE (? IS NULL OR page_id = ?) AND (? IS NULL OR module = ?) ORDER BY page_id, id;`
    *   Traduz `caption`.

*   **`get_std_widget(widget_id, lang_code) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_std_widgets WHERE id = ? LIMIT 1;`
    *   Traduz `caption`.

*   **`create_std_widget(params, lang_code) :: {:ok, map()} | {:error, any()}`** (Admin)
    *   `params`: `page_id_std_name`, `module`, `type`, `url`, `click`, `icon`, `caption_key`, `cnt_notices_config`, `cnt_actions_config`, `is_featured`.
    *   SQL: `INSERT INTO sys_std_widgets (page_id, module, type, ...) VALUES (?, ?, ?, ...) RETURNING *;`

*   **`update_std_widget(widget_id, params, lang_code) :: {:ok, map()} | {:error, any()}`** (Admin)
*   **`delete_std_widget(widget_id) :: :ok | {:error, any()}`** (Admin)
    *   Deleta de `sys_std_widgets` e `sys_std_pages_widgets`.

*   **`get_widgets_for_std_page(std_page_id, lang_code) :: {:ok, list(map())} | {:error, any()}`**
    *   SQL:

```sql
        SELECT w.*
        FROM sys_std_widgets w
        JOIN sys_std_pages_widgets pw ON w.id = pw.widget_id
        WHERE pw.page_id = ?
        ORDER BY pw.\"order\";
```

    *   Traduz legendas dos widgets.

*   **`set_widgets_for_std_page(std_page_id, ordered_widget_ids :: list(integer())) :: :ok | {:error, any()}`** (Admin)
    *   Deleta associações existentes em `sys_std_pages_widgets` para `std_page_id`.
    *   Insere novas associações com a ordem fornecida. Transacional.

---
### Papéis Padrão (`sys_std_roles`, `sys_std_roles_actions`, `sys_std_roles_actions2roles`, `sys_std_roles_members`)

*   **`list_std_roles(lang_code, opts \\\\ []) :: {:ok, list(map())} | {:error, any()}`**
    *   SQL: `SELECT id, name, title, description, active, \"order\" FROM sys_std_roles ORDER BY \"order\", name;`
    *   Traduz `title`, `description`.

*   **`get_std_role(role_id_or_name, lang_code) :: {:ok, map()} | {:error, any()}`**
*   **`create_std_role(params, lang_code) :: {:ok, map()} | {:error, any()}`** (Admin)
*   **`update_std_role(role_id, params, lang_code) :: {:ok, map()} | {:error, any()}`** (Admin)
*   **`delete_std_role(role_id) :: :ok | {:error, any()}`** (Admin)
    *   Deleta de `sys_std_roles`, `sys_std_roles_actions2roles`, `sys_std_roles_members`.

*   **`list_std_role_actions(lang_code, opts \\\\ []) :: {:ok, list(map())} | {:error, any()}`**
    *   SQL: `SELECT id, name, title, description FROM sys_std_roles_actions ORDER BY name;`
    *   Traduz `title`, `description`.
*   **`create_std_role_action(params, lang_code) :: {:ok, map()} | {:error, any()}`** (Admin)
*   **`update_std_role_action(action_id, params, lang_code) :: {:ok, map()} | {:error, any()}`** (Admin)
*   **`delete_std_role_action(action_id) :: :ok | {:error, any()}`** (Admin)
    *   Deleta de `sys_std_roles_actions` e `sys_std_roles_actions2roles`.

*   **`get_actions_for_std_role(role_id, lang_code) :: {:ok, list(map())} | {:error, any()}`**
    *   SQL: `SELECT ra.* FROM sys_std_roles_actions ra JOIN sys_std_roles_actions2roles r2a ON ra.id = r2a.action_id WHERE r2a.role_id = ?;`
    *   Traduz.

*   **`set_actions_for_std_role(role_id, action_ids :: list(integer())) :: :ok | {:error, any()}`** (Admin)
    *   Deleta e recria entradas em `sys_std_roles_actions2roles`. Transacional.

*   **`get_std_role_for_account(account_id) :: {:ok, map() | nil} | {:error, any()}`**
    *   SQL: `SELECT r.* FROM sys_std_roles r JOIN sys_std_roles_members rm ON r.id = rm.role WHERE rm.account_id = ? LIMIT 1;`
    *   Pode precisar de tradução se for para exibição.

*   **`set_std_role_for_account(account_id, role_id) :: {:ok, map()} | {:error, any()}`** (Admin)
    *   SQL (SQLite): `INSERT OR REPLACE INTO sys_std_roles_members (account_id, role) VALUES (?, ?);`
    *   Retorna o papel atribuído.

*   **`remove_std_role_from_account(account_id) :: :ok | {:error, any()}`** (Admin)
    *   SQL: `DELETE FROM sys_std_roles_members WHERE account_id = ?;`

## Considerações:

*   **Traduções:** Muitos campos (`caption`, `header`, `title`, `description`) são chaves de tradução e exigirão chamadas ao `LocalizationRepo`.
*   **Lógica `cnt_notices` e `cnt_actions` em `sys_std_widgets`:** No UNA PHP, estes campos contêm lógica ou chamadas de serviço para buscar contagens dinâmicas. A API \"Deeper\" não executará PHP.
    *   **Abordagem \"Deeper\":** A API pode retornar a definição original desses campos para informação. Se a funcionalidade de contagem for necessária, a API \"Deeper\" precisará de endpoints ou lógica Elixir equivalentes para calcular essas contagens, e o cliente chamaria esses endpoints separadamente ou a API de widgets os pré-buscaria.
*   **Uso no Cliente:**
    *   `sys_std_pages` e `sys_std_widgets` podem ser usados pela API de Admin para construir interfaces de gerenciamento para dashboards ou seções padrão do Studio.
    *   `sys_std_roles` pode ser usado para uma camada de permissão mais simples ou complementar ao ACL, ou para exibir um \"papel principal\" para o usuário. A API \"Deeper\" precisa definir claramente como `sys_std_roles` interage (ou não) com `sys_acl_levels`. No UNA, `sys_accounts.role` geralmente armazena o ID de `sys_std_roles`, enquanto `sys_acl_levels_members` gerencia os níveis de permissão mais granulares.

Este `StdElementsRepo` permite à API \"Deeper\" acessar e gerenciar os componentes padrão que formam a estrutura base de muitas visualizações no UNA, especialmente no painel de administração.