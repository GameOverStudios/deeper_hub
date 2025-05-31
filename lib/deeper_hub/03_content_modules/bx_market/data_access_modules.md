# Documentação Deeper: Módulos de Acesso a Dados para Marketplace (`bx_market`)

Este documento descreve os módulos Elixir (Repositórios) que encapsulam a lógica de acesso ao banco de dados e as queries SQL diretas para as funcionalidades do módulo Marketplace (`bx_market`).

O principal módulo de acesso a dados será `Deeper.Content.MarketRepo`.

## Módulo: `Deeper.Content.MarketRepo`

Este módulo fornecerá funções para realizar operações CRUD e consultas customizadas nas tabelas `bx_market_entries`, `bx_market_categories`, e `bx_market_photos`.

**Localização do Código:** `lib/deeper/content/market_repo.ex`

### Estrutura de Dados Retornada (Structs ou Mapas)

Para consistência, as funções podem retornar mapas ou structs Elixir simples representando os dados. Por exemplo:

```sql
    INSERT INTO bx_market_categories (parent_id, name, title, uri, icon, order_index, active, meta_description, meta_keywords)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    RETURNING *;
```

```sql
    SELECT * FROM bx_market_categories WHERE id = ? LIMIT 1;
```

```sql
    SELECT * FROM bx_market_categories WHERE uri = ? LIMIT 1;
```

```sql
    SELECT * FROM bx_market_categories
    -- WHERE parent_id = ? (se fornecido)
    -- AND active = ? (se fornecido)
    ORDER BY order_index ASC, title ASC;
```

```sql
    UPDATE bx_market_categories
    SET parent_id = ?, name = ?, title = ?, uri = ?, icon = ?, order_index = ?, active = ?, meta_description = ?, meta_keywords = ?
    WHERE id = ?
    RETURNING *;
```

```sql
    DELETE FROM bx_market_categories WHERE id = ?;
```

```sql
    INSERT INTO bx_market_entries (author_id, status, status_admin, category_id, title, name, description, tags, price, currency_code, price_negotiable, location_text, location_lat, location_lng, quantity, condition, allow_comments, allow_votes, allow_reports, added, changed, last_bump, expiration_date)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    RETURNING *;
```

```sql
    SELECT * FROM bx_market_entries WHERE id = ? LIMIT 1;
```

```sql
        SELECT m.*, c.name as category_name, c.title as category_title
        FROM bx_market_entries m
        LEFT JOIN bx_market_categories c ON m.category_id = c.id
        WHERE m.id = ? LIMIT 1;
```

```sql
    SELECT * FROM bx_market_entries WHERE name = ? LIMIT 1;
```

```sql
    -- Base para contagem total (para paginação)
    SELECT COUNT(*) FROM bx_market_entries m
    -- LEFT JOIN bx_market_categories c ON m.category_id = c.id (se filtrar por dados da categoria)
    WHERE -- (condições de filtro dinâmicas)
      -- m.author_id = ?
      -- m.category_id = ?
      -- m.status = ?
      -- m.price >= ? AND m.price <= ?
      -- m.location_text LIKE ?
      -- (filtragem por tags é mais complexa, pode exigir LIKE ou uma tabela de junção tags-entries)
      -- m.featured_until IS NOT NULL AND m.featured_until > UNIXEPOCH() (para featured_only)

    -- Base para buscar os dados
    SELECT m.* -- , c.name as category_name (se fizer JOIN)
    FROM bx_market_entries m
    -- LEFT JOIN bx_market_categories c ON m.category_id = c.id
    WHERE -- (mesmas condições de filtro)
    ORDER BY -- (cláusula de ordenação dinâmica, ex: m.price ASC, m.added DESC)
    LIMIT ? OFFSET ?;
```

```sql
    UPDATE bx_market_entries
    SET -- (colunas a serem atualizadas dinamicamente, ex: title = ?, description = ?, price = ?, changed = UNIXEPOCH())
    WHERE id = ?
    RETURNING *;
```

```sql
    DELETE FROM bx_market_entries WHERE id = ?;
```

```sql
    UPDATE bx_market_entries SET views = views + 1 WHERE id = ?;
```

```sql
    INSERT INTO bx_market_photos (entry_id, file_id, title, is_main, order_index)
    VALUES (?, ?, ?, ?, ?)
    RETURNING *;
```

```sql
    SELECT * FROM bx_market_photos WHERE entry_id = ? ORDER BY order_index ASC, id ASC;
```

```sql
    SELECT * FROM bx_market_photos WHERE id = ? LIMIT 1;
```

```sql
    UPDATE bx_market_photos
    SET title = ?, is_main = ?, order_index = ?
    WHERE id = ?
    RETURNING *;
```

```sql
    DELETE FROM bx_market_photos WHERE id = ?;
```

```elixir
defmodule Deeper.Content.Market.Entry do
  @enforce_keys [:id, :author_id, :category_id, :title, :name, :added, :changed]
  defstruct [
    :id, :author_id, :status, :status_admin, :category_id, :title, :name,
    :description, :tags, :price, :currency_code, :price_negotiable,
    :location_text, :location_lat, :location_lng, :quantity, :condition,
    :allow_comments, :allow_votes, :allow_reports,
    :views, :favorites, :comments_count, :votes_count, :score, :reports_count,
    :featured_until, :added, :changed, :last_bump, :expiration_date,
    :photos, # Lista de Deeper.Content.Market.Photo
    :category, # Deeper.Content.Market.Category
    :author # Informações do autor (ex: Deeper.SystemCore.ProfileSummary)
  ]
end

defmodule Deeper.Content.Market.Category do
  @enforce_keys [:id, :name, :title, :uri]
  defstruct [:id, :parent_id, :name, :title, :uri, :icon, :order_index, :active, :meta_description, :meta_keywords, :subcategories]
end

defmodule Deeper.Content.Market.Photo do
  @enforce_keys [:id, :entry_id, :file_id]
  defstruct [:id, :entry_id, :file_id, :title, :is_main, :order_index, :file_url] # file_url viria do FileRepo
end
```

*(Nota: A definição exata das structs pode evoluir. O importante é que as funções do Repo retornem dados estruturados.)*

---

### Funções para Categorias (`bx_market_categories`)

#### `create_category(params :: map()) :: {:ok, Category.t()} | {:error, any()}`
*   **Descrição:** Cria uma nova categoria.
*   **`params`:** Mapa contendo `:name`, `:title`, `:uri`, e opcionalmente `:parent_id`, `:icon`, `:order_index`, `:active`, `:meta_description`, `:meta_keywords`.
*   **SQL:**

*   **Retorno:** A categoria criada.

#### `get_category(id :: integer()) :: {:ok, Category.t() | nil} | {:error, any()}`
*   **Descrição:** Busca uma categoria pelo ID.
*   **SQL:**

#### `get_category_by_uri(uri :: String.t()) :: {:ok, Category.t() | nil} | {:error, any()}`
*   **Descrição:** Busca uma categoria pela URI.
*   **SQL:**

#### `list_categories(opts :: Keyword.t()) :: {:ok, [Category.t()]} | {:error, any()}`
*   **Descrição:** Lista categorias, opcionalmente filtrando por `parent_id` e `active`.
*   **`opts`:** `parent_id: integer()`, `active: boolean()`
*   **SQL (Base):**

    *(A query será construída dinamicamente com base nas `opts`)*

#### `update_category(id :: integer(), params :: map()) :: {:ok, Category.t()} | {:error, any()}`
*   **Descrição:** Atualiza uma categoria existente.
*   **SQL:**

    *(Construir a cláusula SET dinamicamente com base nos `params` fornecidos)*

#### `delete_category(id :: integer()) :: :ok | {:error, any()}`
*   **Descrição:** Deleta uma categoria. (Cuidado: `ON DELETE RESTRICT` nos produtos pode impedir isso se a categoria tiver produtos).
*   **SQL:**

---

### Funções para Listagens de Produtos (`bx_market_entries`)

#### `create_entry(params :: map()) :: {:ok, Entry.t()} | {:error, any()}`
*   **Descrição:** Cria uma nova listagem de produto/serviço.
*   **`params`:** Mapa com todos os campos necessários para `bx_market_entries` (ex: `:author_id`, `:category_id`, `:title`, `:name`, `:description`, `:price`, `:currency_code`, `:added`, `:changed`, etc.).
*   **SQL:**

#### `get_entry(id :: integer(), opts :: Keyword.t()) :: {:ok, Entry.t() | nil} | {:error, any()}`
*   **Descrição:** Busca uma listagem pelo ID. Pode incluir fotos, categoria e informações do autor.
*   **`opts`:** `preload: [:photos, :category, :author]`
*   **SQL (Base, sem preloads complexos no mesmo SQL, pode exigir queries separadas):**

    *   **Para preloads:**
        *   Buscar fotos: `SELECT * FROM bx_market_photos WHERE entry_id = ? ORDER BY order_index ASC;`
        *   Buscar categoria: Usa `get_category/1`.
        *   Buscar autor: Usa um `ProfilesRepo.get_profile_summary/1`.
    *   **Otimização com JOINs (Exemplo para categoria):**

#### `get_entry_by_name(name :: String.t(), opts :: Keyword.t()) :: {:ok, Entry.t() | nil} | {:error, any()}`
*   **Descrição:** Busca uma listagem pelo seu `name` (slug).
*   **`opts`:** Similar a `get_entry/2`.
*   **SQL (Base):**

#### `list_entries(filters :: map(), pagination_opts :: map()) :: {:ok, %{data: [Entry.t()], pagination: map()}} | {:error, any()}`
*   **Descrição:** Lista produtos com filtros e paginação.
*   **`filters`:** Mapa com chaves como `:author_id`, `:category_id`, `:status`, `:min_price`, `:max_price`, `:location_text_like`, `:tags_include_any`, `:tags_include_all`, `:featured_only`, `:condition`.
*   **`pagination_opts`:** Mapa com `:page`, `:per_page` (ou `:offset`, `:limit`), `:sort_by` (ex: `\"price_asc\"`, `\"added_desc\"`).
*   **SQL (Construído Dinamicamente):**

    *   **Nota:** A filtragem por tags (ex: `tags TEXT`) pode ser feita com `LIKE '%tag%'`. Para uma filtragem mais robusta, uma tabela de junção `bx_market_entry_tags` seria melhor.
    *   **Pré-carregamento de fotos/categoria/autor:** Deve ser feito para cada item na lista, possivelmente com uma query N+1 otimizada (buscar todos os autores/categorias/fotos necessários de uma vez após buscar as entradas).

#### `update_entry(id :: integer(), params :: map()) :: {:ok, Entry.t()} | {:error, any()}`
*   **Descrição:** Atualiza uma listagem existente. `params` contém apenas os campos a serem atualizados.
*   **SQL:**

#### `delete_entry(id :: integer()) :: :ok | {:error, any()}`
*   **Descrição:** Deleta uma listagem (e suas fotos associadas devido ao `ON DELETE CASCADE`).
*   **SQL:**

#### `increment_view_count(id :: integer()) :: :ok | {:error, any()}`
*   **Descrição:** Incrementa o contador de visualizações.
*   **SQL:**

    *(Pode ser combinado com a lógica de rastreamento de visualizações em `sys_views_track` se essa tabela for usada)*

---

### Funções para Fotos de Produtos (`bx_market_photos`)

#### `add_photo_to_entry(entry_id :: integer(), file_id :: integer(), params :: map()) :: {:ok, Photo.t()} | {:error, any()}`
*   **Descrição:** Associa uma foto (referenciada por `file_id`) a uma listagem.
*   **`params`:** Mapa opcional com `:title`, `:is_main`, `:order_index`.
*   **SQL:**

    *   **Lógica Adicional:** Se `:is_main` for true, garantir que outras fotos da mesma `entry_id` tenham `is_main = 0`.

#### `list_photos_for_entry(entry_id :: integer()) :: {:ok, [Photo.t()]} | {:error, any()}`
*   **Descrição:** Lista todas as fotos de uma listagem, ordenadas.
*   **SQL:**

#### `get_photo(photo_id :: integer()) :: {:ok, Photo.t() | nil} | {:error, any()}`
*   **Descrição:** Busca uma associação de foto pelo seu ID.
*   **SQL:**

#### `update_photo_details(photo_id :: integer(), params :: map()) :: {:ok, Photo.t()} | {:error, any()}`
*   **Descrição:** Atualiza detalhes de uma foto (título, ordem, is_main).
*   **`params`:** Mapa com `:title`, `:is_main`, `:order_index`.
*   **SQL:**

    *   **Lógica Adicional:** Se `:is_main` for alterado, ajustar outras fotos.

#### `remove_photo_from_entry(photo_id :: integer()) :: :ok | {:error, any()}`
*   **Descrição:** Remove a associação de uma foto de uma listagem. (Não deleta o arquivo em si, apenas a entrada em `bx_market_photos`).
*   **SQL:**

#### `set_main_photo(entry_id :: integer(), photo_id :: integer()) :: :ok | {:error, any()}`
*   **Descrição:** Define uma foto específica como a principal para uma listagem.
*   **SQL (em transação):**
    1.  `UPDATE bx_market_photos SET is_main = 0 WHERE entry_id = ?;`
    2.  `UPDATE bx_market_photos SET is_main = 1 WHERE id = ? AND entry_id = ?;`

---

## Considerações Adicionais:

*   **Mapeamento de Resultados:** Cada função que retorna dados precisará de uma sub-função auxiliar (ex: `map_row_to_entry_struct/1`) para converter a tupla/mapa bruto do banco de dados na struct Elixir apropriada.
*   **Tratamento de Erros:** As funções devem lidar com possíveis erros do `Repo.execute/1` ou `Repo.query/X` e retornar `{:error, reason}` de forma consistente.
*   **Transações:** Operações que envolvem múltiplas escritas (como `set_main_photo/2`) devem ser envolvidas em transações para garantir atomicidade. O `Deeper.Core.Data.Repo` precisaria suportar transações.
*   **Otimização de Queries `list_entries`:** A função `list_entries` é a mais complexa e exigirá uma construção cuidadosa da query SQL para incluir filtros e ordenação dinamicamente, além de otimizar a contagem total para paginação.
*   **Segurança:** Todas as entradas de usuário usadas para construir queries SQL devem ser passadas como parâmetros vinculados (placeholders `?`) para prevenir injeção de SQL. A biblioteca `DBConnection` (e camadas sobre ela) geralmente lida com isso.

Este módulo `MarketRepo` será fundamental para a funcionalidade do marketplace na API \"Deeper\".