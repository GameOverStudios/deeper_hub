# Documentação Deeper: Módulo de Acesso a Dados para Elementos Padrão (`StdElementsRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.StdElementsRepo` (ou um conjunto de módulos como `StdPagesRepo`, `StdWidgetsRepo`, `StdRolesRepo`), responsável por encapsular a lógica de consulta às tabelas \"padrão\" do sistema UNA (`sys_std_pages`, `sys_std_widgets`, `sys_std_pages_widgets`, `sys_std_roles`, `sys_std_roles_actions`, `sys_std_roles_actions2roles`, `sys_std_roles_members`, `sys_std_widgets_bookmarks`).

O foco inicial é na leitura desses dados, já que a modificação é geralmente uma tarefa administrativa.

**Localização do Código (Exemplo para um Repo unificado, pode ser dividido):** `lib/deeper/system_core/std_elements_repo.ex`

## Funções Principais (Exemplos):

### Seção: Páginas Padrão (`sys_std_pages`, `sys_std_pages_widgets`)

*   **`list_std_pages(opts :: map() | nil) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista todas as páginas padrão.
    *   `opts` pode incluir `sort_by` (ex: `\"index\"`).
    *   **SQL:** `SELECT id, \"index\", name, header, caption, icon FROM sys_std_pages ORDER BY \"index\", name;`
    *   Retorna: `{:ok, [%{id: 1, index: 0, name: \"dashboard\", ...}, ...]}`

*   **`get_std_page_by_name(name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca uma página padrão pelo nome.
    *   **SQL:** `SELECT id, \"index\", name, header, caption, icon FROM sys_std_pages WHERE name = ? LIMIT 1;`

*   **`get_widgets_for_std_page(std_page_id :: integer()) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista todos os widgets associados a uma página padrão, incluindo dados do widget.
    *   **SQL:**

```sql
        SELECT
            w.id as widget_id, w.module, w.type, w.url, w.click, w.icon, w.caption, w.cnt_notices, w.cnt_actions, w.featured,
            spw.\"order\"
        FROM sys_std_widgets w
        JOIN sys_std_pages_widgets spw ON w.id = spw.widget_id
        WHERE spw.page_id = ?
        ORDER BY spw.\"order\";
```

```sql
        SELECT id, page_id, module, type, url, click, icon, caption, cnt_notices, cnt_actions, featured
        FROM sys_std_widgets
        -- WHERE page_id = ? -- Se filtrando por nome da página
        ORDER BY caption;
```

```sql
        SELECT
            wb.widget_id,
            w.caption as widget_caption,
            w.icon as widget_icon,
            wb.bookmark
        FROM sys_std_widgets_bookmarks wb
        JOIN sys_std_widgets w ON wb.widget_id = w.id
        WHERE wb.profile_id = ? AND wb.bookmark = 1;
```

```sql
        INSERT OR REPLACE INTO sys_std_widgets_bookmarks (profile_id, widget_id, bookmark)
        VALUES (?, ?, ?);
```

```sql
        SELECT
            sra.id as action_id, sra.name as action_name, sra.title as action_title, sra.description as action_description
        FROM sys_std_roles_actions sra
        JOIN sys_std_roles_actions2roles sra2r ON sra.id = sra2r.action_id
        WHERE sra2r.role_id = ?;
```

```sql
        SELECT
            sr.id, sr.name, sr.title, sr.description, sr.active
        FROM sys_std_roles sr
        JOIN sys_std_roles_members srm ON sr.id = srm.role
        WHERE srm.account_id = ?
        LIMIT 1;
```

    *   Retorna: `{:ok, [%{widget_id: 10, module: \"bx_accounts\", type: \"service\", caption: \"Login Form\", order: 1, ...}, ...]}`

### Seção: Widgets Padrão (`sys_std_widgets`, `sys_std_widgets_bookmarks`)

*   **`list_std_widgets(opts :: map() | nil) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista todos os widgets padrão.
    *   `opts` pode incluir filtros como `page_id` (nome da página) ou `module`.
    *   **SQL (Exemplo com filtro por `page_id` nome):**

*   **`get_std_widget(widget_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca um widget padrão pelo ID.
    *   **SQL:** `SELECT * FROM sys_std_widgets WHERE id = ? LIMIT 1;`

*   **`get_widget_bookmarks_for_profile(profile_id :: integer()) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista os widgets favoritados por um perfil.
    *   **SQL:**

*   **`set_widget_bookmark(profile_id :: integer(), widget_id :: integer(), bookmarked :: boolean()) :: :ok | {:error, any()}`**
    *   Adiciona ou remove um bookmark de widget para um perfil.
    *   **Lógica:** `INSERT OR REPLACE` ou `DELETE` e `INSERT`.
    *   **SQL (Exemplo com `INSERT OR REPLACE` que atualiza ou insere):**

        (Parâmetros: `profile_id`, `widget_id`, `if bookmarked, do: 1, else: 0`)
        Se `bookmarked` for `false`, pode ser mais limpo deletar a linha:
        `DELETE FROM sys_std_widgets_bookmarks WHERE profile_id = ? AND widget_id = ?;`

### Seção: Papéis Padrão (`sys_std_roles`, `sys_std_roles_actions`, `sys_std_roles_actions2roles`, `sys_std_roles_members`)

*   **`list_std_roles(opts :: map() | nil) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista todos os papéis padrão.
    *   `opts` pode incluir `active: true/false`.
    *   **SQL:** `SELECT id, name, title, description, active, \"order\" FROM sys_std_roles ORDER BY \"order\", title;`

*   **`get_std_role_by_name(name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca um papel padrão pelo nome.
    *   **SQL:** `SELECT * FROM sys_std_roles WHERE name = ? LIMIT 1;`

*   **`get_actions_for_std_role(role_id :: integer()) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista todas as ações associadas a um papel padrão.
    *   **SQL:**

*   **`get_std_role_for_account(account_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca o papel padrão atribuído a uma conta.
    *   **SQL:**

*   **`list_std_roles_actions() :: {:ok, list(map())} | {:error, any()}`**
    *   Lista todas as ações de papéis padrão disponíveis.
    *   **SQL:** `SELECT id, name, title, description FROM sys_std_roles_actions ORDER BY title;`

### Mapeamento de Resultados:

*   As funções devem mapear as linhas do resultado SQL para mapas Elixir.
*   Booleanos (como `active`, `featured`, `bookmark`) devem ser convertidos para `true`/`false`.

### Considerações:

*   **Granularidade do Repo:** Dependendo da complexidade, pode ser benéfico dividir este `StdElementsRepo` em repositórios menores e mais focados (ex: `StdPagesRepo`, `StdWidgetsRepo`, `StdRolesRepo`).
*   **Uso Principal:** Estes dados são primariamente para popular interfaces de administração ou para lógica interna do backend que precise conhecer esses elementos padrão.
*   **Caching:** Informações sobre papéis, páginas e widgets padrão mudam raramente, tornando-as boas candidatas para caching.