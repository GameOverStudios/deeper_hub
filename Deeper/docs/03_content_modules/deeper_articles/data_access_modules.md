# Documentação Deeper: Módulos de Acesso a Dados para Artigos/Posts

Este documento descreve os módulos Elixir (Repositórios) responsáveis por interagir com as tabelas do banco de dados relacionadas ao módulo de Artigos/Posts (`deeper_articles`, `deeper_article_categories`, `deeper_articles_to_categories`).

## Módulos Principais:

1.  **`Deeper.Content.ArticlesRepo`**:
    *   Responsável por interagir com a tabela `deeper_articles` e a tabela de junção `deeper_articles_to_categories`.
    *   Funções para CRUD de artigos, listagem com filtros e paginação, associação de categorias.

2.  **`Deeper.Content.ArticleCategoriesRepo`**:
    *   Responsável por interagir com a tabela `deeper_article_categories`.
    *   Funções para CRUD de categorias, listagem, busca por slug, etc.

## 1. Módulo: `Deeper.Content.ArticlesRepo`

Este módulo lida com a tabela `deeper_articles` e suas associações.

**Localização do Código Elixir:** `lib/deeper/content/articles_repo.ex`

```elixir
defmodule Deeper.Content.ArticlesRepo do
  alias Deeper.Core.Data.Repo
  # alias Deeper.Content.Article # Struct opcional
  # alias Deeper.Content.ArticleCategory # Struct opcional
  alias Deeper.Files.StorageRepo # Para reutilizar map_row_to_struct se aplicável

  @doc \"\"\"
  Cria um novo artigo.
  `attrs` deve ser um mapa contendo: :profile_id, :title, :slug, :body
  e opcionalmente: :excerpt, :featured_image_file_id, :status, :visibility,
                     :allow_comments, :published_at, :category_ids (lista de IDs)
  \"\"\"
  def create_article(attrs) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    published_at_ts = attrs.published_at || (if attrs.status == \"published\", do: current_ts, else: nil)

    # Usar uma transação para garantir atomicidade na criação do artigo e associação de categorias
    Repo.transaction(fn ->
      sql_insert_article = \"\"\"
      INSERT INTO deeper_articles (
        profile_id, title, slug, body, excerpt, featured_image_file_id,
        status, visibility, allow_comments, published_at, views, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      RETURNING *;
      \"\"\"
      article_values = [
        attrs.profile_id,
        attrs.title,
        attrs.slug,
        attrs.body,
        attrs.excerpt,
        attrs.featured_image_file_id,
        attrs.status || \"draft\",
        attrs.visibility || \"public\",
        attrs.allow_comments || 1,
        published_at_ts,
        0, # views
        current_ts, # created_at
        current_ts  # updated_at
      ]

      case Repo.query(sql_insert_article, article_values) do
        {:ok, %{rows: [article_row], columns: article_columns}} ->
          article_map = StorageRepo.map_row_to_struct(article_row, article_columns) # Reutilizando helper
          article_id = article_map.id

          # Associar categorias, se fornecidas
          case associate_categories_to_article(article_id, attrs.category_ids || []) do
            :ok ->
              {:ok, %{article_map | categories: fetch_article_categories(article_id)}} # Retorna o artigo com categorias
            {:error, cat_reason} ->
              Repo.rollback({:error, {:categories_association, cat_reason}}) # Desfaz a transação
          end
        {:error, reason} ->
          Repo.rollback({:error, {:article_creation, reason}}) # Desfaz a transação
      end
    end)
  end

  @doc \"\"\"
  Busca um artigo pelo seu ID.
  Pode opcionalmente fazer JOIN com categorias e imagem de destaque.
  \"\"\"
  def get_article(id, opts \\\\ [include: [:categories, :featured_image, :author]]) do
    # Base SQL
    select_fields = \"a.*\"
    joins = \"\"
    params = [id]

    # Incluir autor (profile)
    if Enum.member?(opts[:include], :author) do
      select_fields = select_fields <> \", p.name as author_name, p.email as author_email\" # Adicionar campos do autor que você quer
      joins = joins <> \" LEFT JOIN sys_profiles sp ON a.profile_id = sp.id LEFT JOIN sys_accounts p ON sp.account_id = p.id\"
    end

    # Incluir imagem de destaque
    if Enum.member?(opts[:include], :featured_image) do
      select_fields = select_fields <> \", fi.file_name as featured_image_name, fi.remote_id as featured_image_remote_id, fi.storage_object as featured_image_storage\"
      joins = joins <> \" LEFT JOIN deeper_files fi ON a.featured_image_file_id = fi.id\"
    end

    sql = \"SELECT #{select_fields} FROM deeper_articles a #{joins} WHERE a.id = ? LIMIT 1\"

    case Repo.query(sql, params) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        article_map = StorageRepo.map_row_to_struct(row_tuple, columns)
        # Incluir categorias se solicitado
        categories = if Enum.member?(opts[:include], :categories), do: fetch_article_categories(id), else: []
        {:ok, %{article_map | categories: categories}}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca um artigo pelo seu slug.\"
  def get_article_by_slug(slug, opts \\\\ [include: [:categories, :featured_image, :author]]) do
    # Similar a get_article, mas WHERE a.slug = ?
    # Reutilizar a lógica de construção de query se possível
    select_fields = \"a.*\"
    joins = \"\"
    params = [slug]

    if Enum.member?(opts[:include], :author) do
      select_fields = select_fields <> \", p.name as author_name, p.email as author_email\"
      joins = joins <> \" LEFT JOIN sys_profiles sp ON a.profile_id = sp.id LEFT JOIN sys_accounts p ON sp.account_id = p.id\"
    end

    if Enum.member?(opts[:include], :featured_image) do
      select_fields = select_fields <> \", fi.file_name as featured_image_name, fi.remote_id as featured_image_remote_id, fi.storage_object as featured_image_storage\"
      joins = joins <> \" LEFT JOIN deeper_files fi ON a.featured_image_file_id = fi.id\"
    end

    sql = \"SELECT #{select_fields} FROM deeper_articles a #{joins} WHERE a.slug = ? LIMIT 1\"

    case Repo.query(sql, params) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        article_map = StorageRepo.map_row_to_struct(row_tuple, columns)
        categories = if Enum.member?(opts[:include], :categories), do: fetch_article_categories(article_map.id), else: []
        {:ok, %{article_map | categories: categories}}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end


  @doc \"\"\"
  Lista artigos com filtros e paginação.
  `filters`: %{profile_id: 1, status: \"published\", category_id: 5, category_slug: \"elixir\"}
  `pagination_opts`: %{limit: 10, offset: 0, sort_by: \"published_at\", sort_order: \"desc\"}
  \"\"\"
  def list_articles(filters \\\\ %{}, pagination_opts \\\\ %{}) do
    # Base da query
    select_clause = \"SELECT DISTINCT a.*, p.name as author_name\" # Adicionar outros campos se necessário (imagem, etc.)
    from_clause = \"FROM deeper_articles a JOIN sys_profiles sp ON a.profile_id = sp.id JOIN sys_accounts p ON sp.account_id = p.id\"
    join_categories_clause = \"\"
    where_conditions = [\"1=1\"] # Começa com uma condição verdadeira para facilitar a adição de ANDs
    params = []

    # Filtro por profile_id
    if profile_id = filters[:profile_id] do
      Array.push(where_conditions, \"a.profile_id = ?\")
      Array.push(params, profile_id)
    end

    # Filtro por status
    if status = filters[:status] do
      Array.push(where_conditions, \"a.status = ?\")
      Array.push(params, status)
    end

    # Filtro por category_id ou category_slug
    cond do
      category_id = filters[:category_id] ->
        join_categories_clause = \" JOIN deeper_articles_to_categories atc ON a.id = atc.article_id\"
        Array.push(where_conditions, \"atc.category_id = ?\")
        Array.push(params, category_id)
      category_slug = filters[:category_slug] ->
        # Precisa de um sub-select ou um join adicional para obter category_id do slug
        join_categories_clause = \" JOIN deeper_articles_to_categories atc ON a.id = atc.article_id JOIN deeper_article_categories ac ON atc.category_id = ac.id\"
        Array.push(where_conditions, \"ac.slug = ?\")
        Array.push(params, category_slug)
      true -> :ok
    end

    where_clause = \"WHERE \" <> Enum.join(where_conditions, \" AND \")
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts) # Reutilizar helper se adaptado
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts) # Reutilizar helper

    sql_data = \"#{select_clause} #{from_clause} #{join_categories_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(DISTINCT a.id) as total_count #{from_clause} #{join_categories_clause} #{where_clause}\"

    case Repo.query(sql_data, params) do
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        articles = Enum.map(rows_tuples, &StorageRepo.map_row_to_struct(&1, columns))
        # Opcional: buscar categorias para cada artigo listado (pode ser N+1, otimizar se necessário)
        articles_with_categories = Enum.map(articles, fn article ->
          %{article | categories: fetch_article_categories(article.id)}
        end)

        case Repo.query(sql_count, params) do
          {:ok, %{rows: [{total_count}]}} ->
            {:ok, %{data: articles_with_categories, total_count: total_count}}
          err_count -> {:ok, %{data: articles_with_categories, total_count: -1}} # Ou erro
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Atualiza um artigo. `attrs` contém os campos a serem atualizados.
  `category_ids` em `attrs` substituirá as categorias existentes.
  \"\"\"
  def update_article(id, attrs) do
    # Construir a cláusula SET dinamicamente
    current_ts = DateTime.to_unix(DateTime.utc_now())
    update_fields_map = Map.put(attrs, :updated_at, current_ts) # Garante que updated_at seja atualizado
                       |> Map.drop([:category_ids, :profile_id, :created_at, :id]) # Campos não atualizáveis diretamente ou especiais

    {set_clause, params} =
      Enum.map_reduce(update_fields_map, [], fn {field, value}, acc_params ->
        # Validar se `field` é uma coluna válida para evitar SQL injection
        allowed_fields = [:title, :slug, :body, :excerpt, :featured_image_file_id, :status, :visibility, :allow_comments, :published_at, :updated_at]
        if Enum.member?(allowed_fields, field) do
          {\"#{Atom.to_string(field)} = ?\", [value | acc_params]}
        else
          {nil, acc_params} # Ignora campos não permitidos
        end
      end)
      |> then(fn {clauses, acc_params} ->
           valid_clauses = Enum.reject(clauses, &is_nil/1)
           {Enum.join(valid_clauses, \", \"), Enum.reverse(acc_params)}
         end)

    if set_clause == \"\" do
      # Nenhum campo válido para atualizar, apenas processar categorias se houver
      return(
        case associate_categories_to_article(id, attrs.category_ids || []) do
            :ok -> get_article(id) # Retorna o artigo (potencialmente com novas categorias)
            {:error, cat_reason} -> {:error, {:categories_association, cat_reason}}
        end
      )
    end

    Repo.transaction(fn ->
      sql_update_article = \"UPDATE deeper_articles SET #{set_clause} WHERE id = ? RETURNING *\"
      update_params = params ++ [id]

      case Repo.query(sql_update_article, update_params) do
        {:ok, %{rows: [updated_row], columns: columns}} ->
          updated_article_map = StorageRepo.map_row_to_struct(updated_row, columns)
          
          # Re-associar categorias (deleta antigas, insere novas)
          # category_ids pode ser nil se não for para mudar, ou lista vazia para remover todas
          if Map.has_key?(attrs, :category_ids) do
             case associate_categories_to_article(id, attrs.category_ids) do
               :ok -> {:ok, %{updated_article_map | categories: fetch_article_categories(id)}}
               {:error, cat_reason} -> Repo.rollback({:error, {:categories_association, cat_reason}})
             end
          else
            {:ok, %{updated_article_map | categories: fetch_article_categories(id)}}
          end
        {:error, reason} ->
          Repo.rollback({:error, {:article_update, reason}})
      end
    end)
  end

  @doc \"Deleta um artigo e suas associações de categoria.\"
  def delete_article(id) do
    Repo.transaction(fn ->
      # As associações em deeper_articles_to_categories serão deletadas por ON DELETE CASCADE
      sql_delete_article = \"DELETE FROM deeper_articles WHERE id = ?\"
      case Repo.execute(sql_delete_article, [id]) do
        {:ok, %{num_rows: 1}} -> :ok
        {:ok, %{num_rows: 0}} -> Repo.rollback({:error, :not_found}) # Ou apenas :ok se não encontrar não for erro
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end


  # --- Funções Helper para Categorias ---
  @doc \"Busca categorias associadas a um artigo.\"
  def fetch_article_categories(article_id) do
    sql = \"\"\"
    SELECT c.id, c.name, c.slug
    FROM deeper_article_categories c
    JOIN deeper_articles_to_categories atc ON c.id = atc.category_id
    WHERE atc.article_id = ?
    ORDER BY c.name
    \"\"\"
    case Repo.query(sql, [article_id]) do
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        Enum.map(rows_tuples, &StorageRepo.map_row_to_struct(&1, columns))
      _ -> [] # Retorna lista vazia em caso de erro ou se não houver categorias
    end
  end

  @doc \"\"\"
  Associa uma lista de category_ids a um article_id.
  Remove associações antigas e cria novas.
  \"\"\"
  def associate_categories_to_article(article_id, category_ids) when is_list(category_ids) do
    Repo.transaction(fn ->
      # 1. Remover associações existentes
      sql_delete_assoc = \"DELETE FROM deeper_articles_to_categories WHERE article_id = ?\"
      Repo.execute(sql_delete_assoc, [article_id]) # Ignorar erro se não houver o que deletar

      # 2. Inserir novas associações (se houver category_ids)
      if Enum.any?(category_ids) do
        # Construir uma query com múltiplos VALUES ou executar múltiplos INSERTs
        # Para SQLite, múltiplos INSERTs em uma transação são eficientes.
        # Ou usar \"INSERT INTO ... VALUES (?), (?), ...\"
        # placeholders = Enum.map_join(category_ids, \",\", fn _ -> \"(?, ?)\" end)
        # sql_insert_assoc = \"INSERT INTO deeper_articles_to_categories (article_id, category_id) VALUES #{placeholders}\"
        # values = Enum.flat_map(category_ids, fn cat_id -> [article_id, cat_id] end)
        # Repo.execute(sql_insert_assoc, values)
        
        # Alternativa mais simples: loop e insert individual
        Enum.reduce_while(category_ids, :ok, fn cat_id, _acc ->
          sql_insert_single_assoc = \"INSERT INTO deeper_articles_to_categories (article_id, category_id) VALUES (?, ?)\"
          case Repo.execute(sql_insert_single_assoc, [article_id, cat_id]) do
            {:ok, _} -> {:cont, :ok}
            {:error, reason} -> {:halt, Repo.rollback({:error, reason})} # Desfaz transação
          end
        end)
      else
        :ok # Nenhuma categoria para associar
      end
    end)
    |> case do # Para capturar o resultado da transação aninhada ou do loop
      {:ok, final_result_from_transaction_or_loop} -> final_result_from_transaction_or_loop
      err -> err # Se a transação foi explicitamente desfeita
    end
  end

end
```

```elixir
defmodule Deeper.Content.ArticleCategoriesRepo do
  alias Deeper.Core.Data.Repo
  alias Deeper.Files.StorageRepo # Para map_row_to_struct

  @doc \"Cria uma nova categoria de artigo.\"
  def create_category(attrs) do
    # Adicionar lógica para gerar slug a partir de attrs.name
    # attrs = Map.put(attrs, :slug, generate_slug(attrs.name))
    sql = \"\"\"
    INSERT INTO deeper_article_categories (name, slug, description, parent_id)
    VALUES (?, ?, ?, ?)
    RETURNING *;
    \"\"\"
    values = [attrs.name, attrs.slug, attrs.description, attrs.parent_id]
    case Repo.query(sql, values) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      err -> err
    end
  end

  @doc \"Busca uma categoria pelo ID.\"
  def get_category(id) do
    sql = \"SELECT * FROM deeper_article_categories WHERE id = ? LIMIT 1\"
    case Repo.query(sql, [id]) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"Busca uma categoria pelo slug.\"
  def get_category_by_slug(slug) do
    sql = \"SELECT * FROM deeper_article_categories WHERE slug = ? LIMIT 1\"
    case Repo.query(sql, [slug]) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"Lista todas as categorias, opcionalmente filtrando por parent_id.\"
  def list_categories(filters \\\\ %{}) do
    # Adicionar WHERE clause se filters[:parent_id] estiver presente
    parent_filter = if parent_id = filters[:parent_id], do: \"WHERE parent_id = #{parent_id}\", else: (if Map.has_key?(filters, :parent_id) and is_nil(filters[:parent_id]), do: \"WHERE parent_id IS NULL\", else: \"\")
    sql = \"SELECT * FROM deeper_article_categories #{parent_filter} ORDER BY name\"
    
    case Repo.query(sql, []) do # Adicionar [parent_id] se o filtro for usado com placeholder
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        {:ok, Enum.map(rows_tuples, &StorageRepo.map_row_to_struct(&1, columns))}
      err -> err
    end
  end

  @doc \"Atualiza uma categoria.\"
  def update_category(id, attrs) do
    # Similar a update_article, construir SET clause dinamicamente
    # Garantir que slug seja atualizado se o nome mudar
    # attrs = Map.put_new_if_absent(attrs, :slug, generate_slug_from_name_if_name_changed(...))
    {set_clause, params} = # ... construir set_clause e params ...
      Enum.map_reduce(attrs, [], fn {field, value}, acc_params ->
          allowed_fields = [:name, :slug, :description, :parent_id]
          if Enum.member?(allowed_fields, field) do
            {\"#{Atom.to_string(field)} = ?\", [value | acc_params]}
          else
            {nil, acc_params}
          end
        end)
        |> then(fn {clauses, acc_params} ->
            valid_clauses = Enum.reject(clauses, &is_nil/1)
            {Enum.join(valid_clauses, \", \"), Enum.reverse(acc_params)}
            end)

    if set_clause == \"\", do: return(get_category(id)) # Nada para atualizar

    sql = \"UPDATE deeper_article_categories SET #{set_clause} WHERE id = ? RETURNING *\"
    update_params = params ++ [id]

    case Repo.query(sql, update_params) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      err -> err
    end
  end

  @doc \"Deleta uma categoria.\"
  def delete_category(id) do
    # Considerar o que acontece com artigos associados (ON DELETE CASCADE na tabela de junção)
    # e subcategorias (ON DELETE SET NULL / CASCADE na própria tabela de categorias)
    sql = \"DELETE FROM deeper_article_categories WHERE id = ?\"
    Repo.execute(sql, [id])
  end
end
```

### Notas para `ArticlesRepo`:
*   **Transações:** `create_article/1`, `update_article/2`, e `associate_categories_to_article/2` usam `Repo.transaction/1` para garantir atomicidade, especialmente ao lidar com a tabela de junção de categorias.
*   **Construção Dinâmica de SQL:** `list_articles/2` e `update_article/2` demonstram como construir SQL dinamicamente. É **crucial** validar e sanitizar todas as entradas do usuário (como nomes de campos para `ORDER BY` ou chaves de filtro) para prevenir SQL injection. O exemplo `build_order_clause` no `FilesRepo` é uma boa referência.
*   **N+1 Queries:** Em `list_articles/2`, buscar categorias para cada artigo listado (`Enum.map(articles, fn article -> %{article | categories: fetch_article_categories(article.id)} end)`) pode levar a um problema de N+1 queries. Para um grande número de artigos, isso deve ser otimizado, possivelmente buscando todas as categorias para os IDs de artigos listados em uma única query adicional e depois mapeando-as de volta.
*   **Reutilização de Helpers:** Funções como `build_order_clause` e `map_row_to_struct` do `FilesRepo` ou `StorageRepo` podem ser movidas para um módulo helper comum se forem genéricas o suficiente.
*   **Tratamento de Erro:** O tratamento de erro é simplificado. Em uma aplicação real, você pode querer logar mais detalhes ou retornar tipos de erro mais específicos.
*   **Slugs:** A geração de slugs únicos a partir do título não está implementada aqui, mas seria uma lógica importante (geralmente no controller ou em um \"serviço\" antes de chamar o repo).

## 2. Módulo: `Deeper.Content.ArticleCategoriesRepo`

Este módulo lida com a tabela `deeper_article_categories`.

**Localização do Código Elixir:** `lib/deeper/content/article_categories_repo.ex`

### Notas para `ArticleCategoriesRepo`:
*   A geração de `slug` a partir do `name` é uma lógica importante que deve ser consistente.
*   A listagem pode ser estendida para suportar paginação se o número de categorias se tornar muito grande.
*   A exclusão de uma categoria precisa considerar o impacto nas subcategorias e nos artigos associados, conforme definido pelas constraints `ON DELETE`.

Estes módulos fornecem uma interface de acesso a dados robusta para o módulo de artigos. O próximo passo seria definir os `api_endpoints.md` para este módulo.