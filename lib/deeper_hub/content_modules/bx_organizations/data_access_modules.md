# Documentação Deeper: Módulos de Acesso a Dados para Organizações (`bx_organizations`)

Este documento descreve o módulo Elixir (Repositório) `Deeper.Content.OrganizationsRepo`, que encapsula a lógica de acesso ao banco de dados e as queries SQL diretas para as funcionalidades do módulo Organizações (`bx_organizations`).

## Módulo: `Deeper.Content.OrganizationsRepo`

Este módulo fornecerá funções para realizar operações CRUD e consultas customizadas nas tabelas `bx_organizations_data`, e opcionalmente `bx_organizations_categories` e `bx_organizations_members`.

**Localização do Código:** `lib/deeper/content/organizations_repo.ex`

### Estrutura de Dados Retornada (Structs ou Mapas)

Serão definidas structs para representar os dados das organizações, categorias e membros.

```sql
        INSERT INTO bx_organizations_data (author_id, org_name, org_uri, org_cat, org_desc, org_website, org_email, org_phone, added, changed, status, status_admin, ...)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ...);
        RETURNING *;
```

```sql
    SELECT * FROM bx_organizations_data WHERE id = ? LIMIT 1;
```

```sql
        SELECT o.*, c.name as category_name, c.title as category_title
        FROM bx_organizations_data o
        LEFT JOIN bx_organizations_categories c ON o.org_cat = c.id
        WHERE o.id = ? LIMIT 1;
```

```sql
    SELECT * FROM bx_organizations_data WHERE org_uri = ? LIMIT 1;
```

```sql
    -- Para contagem total
    SELECT COUNT(*) FROM bx_organizations_data o
    -- LEFT JOIN bx_organizations_categories c ON o.org_cat = c.id (se filtrar por dados da categoria)
    WHERE -- (condições de filtro dinâmicas)
      -- o.author_id = ?
      -- o.org_cat = ?
      -- o.status = ?
      -- o.org_name LIKE ?
      -- o.featured_until IS NOT NULL AND o.featured_until > UNIXEPOCH() (para featured_only)

    -- Para buscar os dados
    SELECT o.* -- , c.name as category_name (se fizer JOIN)
    FROM bx_organizations_data o
    -- LEFT JOIN bx_organizations_categories c ON o.org_cat = c.id
    WHERE -- (mesmas condições de filtro)
    ORDER BY -- (cláusula de ordenação dinâmica)
    LIMIT ? OFFSET ?;
```

```sql
    UPDATE bx_organizations_data
    SET org_name = ?, org_uri = ?, org_desc = ?, ..., changed = ?
    WHERE id = ?
    RETURNING *;
```

```sql
    INSERT INTO bx_organizations_members (org_id, profile_id, role, added)
    VALUES (?, ?, ?, UNIXEPOCH())
    ON CONFLICT(org_id, profile_id) DO UPDATE SET role = excluded.role -- Atualiza o papel se já for membro
    RETURNING *;
```

```sql
    SELECT om.*, p.type as profile_type, COALESCE(pd.fullname, od.org_name) as member_display_name -- , pd.picture as member_avatar_id
    FROM bx_organizations_members om
    JOIN sys_profiles p ON om.profile_id = p.id
    LEFT JOIN bx_persons_data pd ON p.type = 'bx_persons' AND p.content_id = pd.id
    LEFT JOIN bx_organizations_data od ON p.type = 'bx_organizations' AND p.content_id = od.id -- Se uma organização puder ser membro de outra (improvável como admin)
    WHERE om.org_id = ?
    -- AND om.role = ? (se filtro de papel for aplicado)
    ORDER BY om.added DESC;
```

```sql
    UPDATE bx_organizations_members SET role = ? WHERE org_id = ? AND profile_id = ?
    RETURNING *;
```

```elixir
defmodule Deeper.Content.Organizations.Organization do
  @enforce_keys [:id, :author_id, :org_name, :org_uri, :added, :changed]
  defstruct [
    :id, :author_id, :org_name, :org_uri, :org_cat, :org_desc,
    :org_logo, :org_cover, :org_website, :org_email, :org_phone,
    :org_address_street, :org_address_city, :org_address_state, :org_address_zip, :org_address_country,
    :org_location_lat, :org_location_lng,
    :status, :status_admin, :allow_view_to, :allow_post_to, :allow_contact_to,
    :views, :fans_count, :comments_count, :reports_count, :featured_until,
    :added, :changed, :settings,
    :category, # Deeper.Content.Organizations.Category
    :author,   # Deeper.SystemCore.ProfileSummary
    :members,  # Lista de Deeper.Content.Organizations.Member
    :logo_url, :cover_url # URLs de arquivos, preenchidas pelo FileRepo
  ]
end

defmodule Deeper.Content.Organizations.Category do
  @enforce_keys [:id, :name, :title, :uri]
  defstruct [:id, :parent_id, :name, :title, :uri, :order_index]
end

defmodule Deeper.Content.Organizations.Member do
  @enforce_keys [:org_id, :profile_id, :role, :added]
  defstruct [:id, :org_id, :profile_id, :role, :added, :profile_summary] # profile_summary com nome e avatar
end
```

```elixir
        # Dentro de SystemCore.ProfilesRepo
        # create_profile(%{account_id: org_author_account_id, type: \"bx_organizations\", content_id: org_data.id, status: \"active\"})
        # org_author_account_id precisa ser buscado a partir do profile_id do autor
```

---

### Funções para Dados de Organizações (`bx_organizations_data`)

#### `create_organization(profile_id :: integer(), params :: map()) :: {:ok, %{organization: Organization.t(), profile: Deeper.SystemCore.Profile.t()}} | {:error, any()}`
*   **Descrição:** Cria uma nova organização e o perfil associado em `sys_profiles`.
*   **`profile_id`:** O `id` do perfil do usuário (em `sys_profiles`) que está criando a organização (será o `author_id`).
*   **`params`:** Mapa contendo `:org_name`, `:org_uri`, e opcionalmente outros campos de `bx_organizations_data`. Deve incluir `added` e `changed` (timestamps Unix).
*   **Lógica (em transação):**
    1.  Insere na `bx_organizations_data` usando `author_id = profile_id`.

    2.  Com o `id` da organização recém-criada (`org_data.id`), insere em `sys_profiles`:

*   **Retorno:** A organização criada e o perfil do sistema associado.

#### `get_organization(id :: integer(), opts :: Keyword.t()) :: {:ok, Organization.t() | nil} | {:error, any()}`
*   **Descrição:** Busca uma organização pelo seu ID (`bx_organizations_data.id`). Pode incluir categoria, autor, membros.
*   **`opts`:** `preload: [:category, :author_summary, :members, :logo, :cover]`
*   **SQL (Base):**

    *   **Para preloads:** Queries separadas para buscar categoria, perfil do autor (resumido), lista de membros, e URLs de logo/capa do `FileRepo`.
    *   **Otimização com JOINs (Exemplo para categoria):**

#### `get_organization_by_uri(uri :: String.t(), opts :: Keyword.t()) :: {:ok, Organization.t() | nil} | {:error, any()}`
*   **Descrição:** Busca uma organização pela sua `org_uri`.
*   **`opts`:** Similar a `get_organization/2`.
*   **SQL (Base):**

#### `list_organizations(filters :: map(), pagination_opts :: map()) :: {:ok, %{data: [Organization.t()], pagination: map()}} | {:error, any()}`
*   **Descrição:** Lista organizações com filtros e paginação.
*   **`filters`:** Mapa com chaves como `:author_id`, `:org_cat` (ID da categoria), `:status`, `:org_name_like`, `:featured_only`.
*   **`pagination_opts`:** Mapa com `:page`, `:per_page`, `:sort_by` (ex: `\"org_name_asc\"`, `\"added_desc\"`, `\"fans_count_desc\"`).
*   **SQL (Construído Dinamicamente):**

    *   **Pré-carregamento:** Similar a `get_organization/2`, para cada item na lista.

#### `update_organization(id :: integer(), params :: map()) :: {:ok, Organization.t()} | {:error, any()}`
*   **Descrição:** Atualiza uma organização existente. `params` contém apenas os campos a serem atualizados. O `changed` timestamp deve ser atualizado.
*   **SQL:**

    *(Construir a cláusula SET dinamicamente)*

#### `delete_organization(id :: integer()) :: :ok | {:error, any()}`
*   **Descrição:** Deleta uma organização. Isso também deve deletar o perfil associado em `sys_profiles` (devido ao `ON DELETE CASCADE` na FK de `sys_profiles` para `account_id`, se a conta for deletada, ou a lógica aqui deve deletar a entrada em `sys_profiles` cujo `content_id = id` e `type = 'bx_organizations'`).
*   **Lógica (em transação):**
    1.  Deletar de `bx_organizations_data`: `DELETE FROM bx_organizations_data WHERE id = ?;`
    2.  Deletar de `sys_profiles`: `DELETE FROM sys_profiles WHERE type = 'bx_organizations' AND content_id = ?;`

#### `increment_organization_view_count(id :: integer()) :: :ok | {:error, any()}`
*   **SQL:** `UPDATE bx_organizations_data SET views = views + 1 WHERE id = ?;`

#### `update_organization_fans_count(id :: integer(), delta :: integer()) :: :ok | {:error, any()}`
*   **Descrição:** Atualiza o contador de fãs/seguidores.
*   **SQL:** `UPDATE bx_organizations_data SET fans_count = fans_count + ? WHERE id = ?;`
    *   `delta` pode ser `1` ou `-1`.

---

### Funções para Categorias de Organizações (`bx_organizations_categories`)
*(Se a tabela `bx_organizations_categories` for implementada. A interface seria muito similar às funções de categoria do `MarketRepo`: `create_org_category`, `get_org_category`, `list_org_categories`, `update_org_category`, `delete_org_category`.)*

---

### Funções para Membros/Administradores de Organizações (`bx_organizations_members`)
*(Se a tabela `bx_organizations_members` for implementada)*

#### `add_member_to_organization(org_id :: integer(), profile_id :: integer(), role :: String.t()) :: {:ok, Member.t()} | {:error, any()}`
*   **Descrição:** Adiciona um perfil como membro/admin de uma organização.
*   **`role`:** ex: \"admin\", \"editor\", \"member\".
*   **SQL:**

#### `get_organization_member(org_id :: integer(), profile_id :: integer()) :: {:ok, Member.t() | nil} | {:error, any()}`
*   **SQL:** `SELECT * FROM bx_organizations_members WHERE org_id = ? AND profile_id = ? LIMIT 1;`

#### `list_organization_members(org_id :: integer(), filters :: map()) :: {:ok, [Member.t()]} | {:error, any()}`
*   **Descrição:** Lista membros de uma organização, opcionalmente filtrando por papel.
*   **`filters`:** `role: String.t()`
*   **SQL (pode incluir JOIN com `sys_profiles` e `bx_persons_data` para obter nome/avatar do membro):**

#### `update_organization_member_role(org_id :: integer(), profile_id :: integer(), new_role :: String.t()) :: {:ok, Member.t()} | {:error, any()}`
*   **SQL:**

#### `remove_member_from_organization(org_id :: integer(), profile_id :: integer()) :: :ok | {:error, any()}`
*   **SQL:** `DELETE FROM bx_organizations_members WHERE org_id = ? AND profile_id = ?;`

---

## Considerações Gerais:

*   **Criação de Perfil (`sys_profiles`):** A criação de uma organização (`create_organization/2`) deve ser atômica com a criação da sua entrada correspondente em `sys_profiles`. Isso é crucial para a integridade do sistema. O `account_id` para a entrada em `sys_profiles` será o `account_id` associado ao `author_id` (perfil) que criou a organização.
*   **Upload de Logo/Capa:** As funções `create_organization` e `update_organization` podem aceitar `org_logo_file_id` e `org_cover_file_id`. Esses IDs seriam obtidos de uploads prévios feitos através da API de Gerenciamento de Arquivos (`06_file_management`). O `OrganizationsRepo` apenas armazenaria esses IDs.
*   **Permissões:** A lógica de permissão para determinar quem pode criar, editar ou gerenciar membros de uma organização residirá nos controllers da API, que consultarão o `OrganizationsRepo` (para verificar `author_id` ou papéis em `bx_organizations_members`) e o sistema ACL.

Este `OrganizationsRepo` fornecerá a camada de dados necessária para as funcionalidades de perfis de organização na API \"Deeper\".