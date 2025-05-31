# Documentação Deeper: Módulo de Acesso a Dados para Artigos (`ArticlesRepo`)

Este documento descreve o módulo Elixir `Deeper.Content.ArticlesRepo`, responsável por interagir com as tabelas do módulo de Artigos (`deeper_articles_entries`, `deeper_articles_categories`, `deeper_articles_tags`, `deeper_articles_tags_to_entries`) no banco de dados SQLite. Ele encapsula as queries SQL e fornece uma interface funcional para a lógica de negócios e os controllers da API.

**Localização do Código:** `lib/deeper/content/articles_repo.ex`

```elixir
defmodule Deeper.Content.ArticlesRepo do
  alias Deeper.Core.Data.Repo
  # Poderia importar outros Repos se necessário, ex: ProfilesRepo para detalhes do autor.

  # --- Funções CRUD para Artigos (deeper_articles_entries) ---

  @doc \"Cria um novo artigo.\"
  @spec create_article(params :: map()) :: {:ok, map()} | {:error, any()}
  def create_article(params) do
    # params deve conter: :author_profile_id, :title, :slug, :body, :body_type (opc), etc.
    # :created_at, :updated_at são gerados aqui.
    # :status pode ser 'draft' por padrão.
    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    sql = \"\"\"
    INSERT INTO deeper_articles_entries (
      author_profile_id, title, slug, summary, body, body_type,
      featured_image_id, category_id, status, published_at,
      views, allow_view_to, meta_title, meta_description,
      created_at, updated_at
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?)
    RETURNING *;
    \"\"\"
    values = [
      params[:author_profile_id],
      params[:title],
      params[:slug], # Deve ser validado para unicidade antes de chamar esta função, ou tratar o erro UNIQUE
      params[:summary],
      params[:body],
      params[:body_type] || \"markdown\",
      params[:featured_image_id], # pode ser nil
      params[:category_id],       # pode ser nil
      params[:status] || \"draft\",
      params[:published_at],      # pode ser nil (se draft) ou futuro (agendado)
      params[:allow_view_to] || \"3\", # Default privacy
      params[:meta_title],
      params[:meta_description],
      params[:created_at] || current_timestamp,
      params[:updated_at] || current_timestamp
    ]

    case Repo.query(sql, values) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        article = map_row_to_generic_struct(row_data, columns)
        # Lidar com tags após criar o artigo
        handle_article_tags(article[\"id\"], params[:tags]) # params[:tags] pode ser uma lista de nomes de tags
        {:ok, article}
      {:error, reason} ->
        # Tratar erro de SLUG UNIQUE: se reason for um erro de constraint, retornar algo específico
        # ex: if String.contains?(inspect(reason), \"UNIQUE constraint failed: deeper_articles_entries.slug\") ...
        {:error, reason}
    end
  end

  @doc \"Busca um artigo pelo seu ID.\"
  @spec get_article_by_id(id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_article_by_id(id) do
    sql = \"\"\"
    SELECT dae.*, dac.name AS category_name, dac.slug AS category_slug,
           p.type AS author_profile_type, p.content_id AS author_content_id, -- Para buscar nome do autor
           (SELECT GROUP_CONCAT(dat.name) FROM deeper_articles_tags_to_entries datte JOIN deeper_articles_tags dat ON datte.tag_id = dat.id WHERE datte.entry_id = dae.id) as tags_names
    FROM deeper_articles_entries dae
    LEFT JOIN deeper_articles_categories dac ON dae.category_id = dac.id
    LEFT JOIN sys_profiles p ON dae.author_profile_id = p.id
    WHERE dae.id = ?
    LIMIT 1;
    \"\"\"
    # GROUP_CONCAT para tags é específico do SQLite. Outros DBs têm funções diferentes (STRING_AGG, LISTAGG).
    # A coluna `tags_names` retornará uma string de tags separadas por vírgula.
    case Repo.query(sql, [id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        article_map = map_row_to_generic_struct(row_data, columns)
        # Processar a string de tags_names para uma lista se necessário
        tags_list =
          case Map.get(article_map, \"tags_names\") || Map.get(article_map, :tags_names) do
            nil -> []
            tags_str -> String.split(tags_str, \",\", trim: true)
          end
        {:ok, Map.put(article_map, \"tags\", tags_list)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca um artigo pelo seu SLUG.\"
  @spec get_article_by_slug(slug :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_article_by_slug(slug) do
    # Query similar a get_article_by_id, mas com `WHERE dae.slug = ?`
    sql = \"\"\"
    SELECT dae.*, dac.name AS category_name, dac.slug AS category_slug,
           p.type AS author_profile_type, p.content_id AS author_content_id,
           (SELECT GROUP_CONCAT(dat.name) FROM deeper_articles_tags_to_entries datte JOIN deeper_articles_tags dat ON datte.tag_id = dat.id WHERE datte.entry_id = dae.id) as tags_names
    FROM deeper_articles_entries dae
    LEFT JOIN deeper_articles_categories dac ON dae.category_id = dac.id
    LEFT JOIN sys_profiles p ON dae.author_profile_id = p.id
    WHERE dae.slug = ?
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [slug]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        article_map = map_row_to_generic_struct(row_data, columns)
        tags_list =
          case Map.get(article_map, \"tags_names\") || Map.get(article_map, :tags_names) do
            nil -> []
            tags_str -> String.split(tags_str, \",\", trim: true)
          end
        {:ok, Map.put(article_map, \"tags\", tags_list)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Atualiza um artigo existente. Retorna o artigo atualizado.\"
  @spec update_article(id :: integer(), params :: map()) :: {:ok, map()} | {:error, :not_found | any()}
  def update_article(id, params) do
    # Similar a AccountsRepo.update_account, requer uma construção segura da cláusula SET.
    # Campos atualizáveis: title, slug (cuidado com unicidade), summary, body, body_type,
    # featured_image_id, category_id, status, published_at, allow_view_to, meta_*, etc.
    # author_profile_id e created_at geralmente não são atualizados.
    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    # Função auxiliar para construir a cláusula SET e os valores de forma segura
    # {set_clause, values_for_set} = build_article_update_clause(params)
    # if set_clause == \"\", do: get_article_by_id(id) # Nada para atualizar

    # Exemplo simplificado (precisa ser robusto e seguro):
    updatable_fields = [
      \"title\", \"slug\", \"summary\", \"body\", \"body_type\", \"featured_image_id\",
      \"category_id\", \"status\", \"published_at\", \"allow_view_to\",
      \"meta_title\", \"meta_description\"
    ]
    {set_parts, set_values} =
      Enum.reduce(updatable_fields, {[], []}, fn field, {acc_parts, acc_values} ->
        case Map.get(params, String.to_atom(field)) do
          nil -> {acc_parts, acc_values} # Campo não presente nos params
          value -> {[\"#{field} = ?\"] ++ acc_parts, [value] ++ acc_values}
        end
      end)

    if Enum.empty?(set_parts) and is_nil(params[:tags]) do # Se não há campos nem tags para atualizar
      get_article_by_id(id)
    else
      # Lidar com atualização de tags
      handle_article_tags(id, params[:tags]) # params[:tags] pode ser uma nova lista de nomes de tags ou nil para não alterar

      if Enum.empty?(set_parts) do # Se só atualizou tags
        get_article_by_id(id)
      else
        sql_set_clause = Enum.join(set_parts, \", \")
        sql = \"UPDATE deeper_articles_entries SET #{sql_set_clause}, updated_at = ? WHERE id = ? RETURNING *\"
        final_values = Enum.reverse(set_values) ++ [current_timestamp, id]

        case Repo.query(sql, final_values) do
          {:ok, %{rows: [row_data], columns: columns}} ->
            # Retornar o artigo com tags atualizadas pode exigir nova busca ou merge inteligente
            get_article_by_id(id) # Mais simples é rebuscar após update
          {:ok, %{rows: []}} -> {:error, :not_found} # Não deveria acontecer
          {:error, reason} -> {:error, reason}
        end
      end
    end
  end

  @doc \"Deleta um artigo.\"
  @spec delete_article(id :: integer()) :: :ok | {:error, :not_found | any()}
  def delete_article(id) do
    # Antes de deletar, pode ser necessário limpar associações (ex: tags_to_entries)
    # se não houver ON DELETE CASCADE nas FKs da tabela de junção (mas há).
    # Repo.execute(\"DELETE FROM deeper_articles_tags_to_entries WHERE entry_id = ?\", [id])
    sql = \"DELETE FROM deeper_articles_entries WHERE id = ?\"
    case Repo.execute(sql, [id]) do
      {:ok, %{num_rows: 1}} -> :ok
      {:ok, %{num_rows: 0}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc \"Lista artigos com paginação, filtros e ordenação.\"
  @spec list_articles(opts :: map()) :: {:ok, {list(map()), map()}} | {:error, any()}
  def list_articles(opts \\\\ %{}) do
    page = Map.get(opts, :page, 1)
    per_page = Map.get(opts, :per_page, 20)
    offset = (page - 1) * per_page

    # Base da query
    select_sql = \"\"\"
    SELECT dae.*, dac.name AS category_name, dac.slug AS category_slug,
           p.type AS author_profile_type, p.content_id AS author_content_id, -- Para obter nome do autor depois
           (SELECT GROUP_CONCAT(dat.name) FROM deeper_articles_tags_to_entries datte JOIN deeper_articles_tags dat ON datte.tag_id = dat.id WHERE datte.entry_id = dae.id) as tags_names
    FROM deeper_articles_entries dae
    LEFT JOIN deeper_articles_categories dac ON dae.category_id = dac.id
    LEFT JOIN sys_profiles p ON dae.author_profile_id = p.id
    \"\"\"
    count_select_sql = \"SELECT COUNT(dae.id) as total_count FROM deeper_articles_entries dae LEFT JOIN sys_profiles p ON dae.author_profile_id = p.id\" # JOINs para filtros

    # Construção de WHERE e JOINs baseada em opts[:filters]
    # Exemplo: filters = %{status: \"published\", category_slug: \"tech\", tag_slug: \"elixir\", author_id: 123}
    where_clauses = []
    join_clauses = [] # Para tags, por exemplo
    query_params = []

    # Filtro por status
    if status_filter = Map.get(opts, [:filters, :status]) do
      where_clauses = where_clauses ++ [\"dae.status = ?\"]
      query_params = query_params ++ [status_filter]
    end

    # Filtro por autor_profile_id
    if author_id_filter = Map.get(opts, [:filters, :author_profile_id]) do
      where_clauses = where_clauses ++ [\"dae.author_profile_id = ?\"]
      query_params = query_params ++ [author_id_filter]
    end

    # Filtro por category_slug (requer JOIN com categories se não já presente)
    if category_slug_filter = Map.get(opts, [:filters, :category_slug]) do
      # Assegurar que o JOIN com dac (deeper_articles_categories) está no select_sql
      where_clauses = where_clauses ++ [\"dac.slug = ?\"]
      query_params = query_params ++ [category_slug_filter]
    end

    # Filtro por tag_slug (requer JOIN com tags e tags_to_entries)
    if tag_slug_filter = Map.get(opts, [:filters, :tag_slug]) do
      join_clauses = join_clauses ++ [
        \"JOIN deeper_articles_tags_to_entries _datte ON dae.id = _datte.entry_id\",
        \"JOIN deeper_articles_tags _dat ON _datte.tag_id = _dat.id\"
      ]
      where_clauses = where_clauses ++ [\"_dat.slug = ?\"]
      query_params = query_params ++ [tag_slug_filter]
    end

    # Filtro por allow_view_to (simulado, ACL real seria mais complexo)
    # if viewing_level_id = Map.get(opts, :viewing_level_id) do
    #   where_clauses = where_clauses ++ [\"(dae.allow_view_to = '3' OR dae.allow_view_to = ? OR dae.author_profile_id = (SELECT id FROM sys_profiles WHERE account_id = ? LIMIT 1))\"]
    #   query_params = query_params ++ [viewing_level_id, current_account_id_if_any]
    # end

    where_sql = if Enum.empty?(where_clauses), do: \"\", else: \"WHERE \" <> Enum.join(where_clauses, \" AND \")
    join_sql = Enum.join(join_clauses, \" \")

    # Ordenação
    sort_field = Map.get(opts, :sort_by, \"published_at\") # Ex: 'published_at', 'views', 'title'
    sort_direction = Map.get(opts, :sort_dir, \"DESC\") |> String.upcase()
    # Validar sort_field e sort_direction contra uma lista permitida
    allowed_sort_fields = [\"published_at\", \"created_at\", \"updated_at\", \"title\", \"views\"]
    sort_field_safe = if Enum.member?(allowed_sort_fields, sort_field), do: \"dae.#{sort_field}\", else: \"dae.published_at\"
    sort_dir_safe = if Enum.member?([\"ASC\", \"DESC\"], sort_direction), do: sort_direction, else: \"DESC\"
    order_sql = \"ORDER BY #{sort_field_safe} #{sort_dir_safe}, dae.id #{sort_dir_safe}\" # Adiciona id para desempate

    # Query para os dados
    data_sql_final = \"#{select_sql} #{join_sql} #{where_sql} #{order_sql} LIMIT ? OFFSET ?;\"
    final_data_query_params = query_params ++ [per_page, offset]

    # Query para contagem total
    count_sql_final = \"#{count_select_sql} #{join_sql} #{where_sql};\" # JOINs são necessários no count se estiverem no filtro

    case Repo.query(count_sql_final, query_params) do
      {:ok, %{rows: [[total_count] | []], columns: _}} -> # Permite 0 resultados no COUNT
        total_count_val = total_count || 0
        case Repo.query(data_sql_final, final_data_query_params) do
          {:ok, %{rows: rows_data, columns: data_columns}} ->
            articles = Enum.map(rows_data, fn row ->
              map_row_to_generic_struct(row, data_columns)
              |> Map.update(\"tags\", [], fn _ -> # Simula processamento de tags_names
                  case Map.get(map_row_to_generic_struct(row, data_columns), \"tags_names\") do
                    nil -> []
                    tags_str -> String.split(tags_str, \",\", trim: true)
                  end
                end)
            end)
            pagination_meta = %{
              total_items: total_count_val,
              current_page: page,
              per_page: per_page,
              total_pages: if(total_count_val > 0, do: ceil(total_count_val / per_page), else: 0)
            }
            {:ok, {articles, pagination_meta}}
          err -> err
        end
      err -> err # Erro ao buscar contagem
    end
  end

  @doc \"Incrementa o contador de visualizações de um artigo.\"
  @spec increment_article_views(id :: integer()) :: :ok | {:error, any()}
  def increment_article_views(id) do
    sql = \"UPDATE deeper_articles_entries SET views = views + 1 WHERE id = ?\"
    Repo.execute(sql, [id])
    # Não retorna o artigo, apenas status. A leitura é separada.
  end


  # --- Funções para Categorias (deeper_articles_categories) ---

  @doc \"Cria uma nova categoria de artigo.\"
  @spec create_category(params :: map()) :: {:ok, map()} | {:error, any()}
  def create_category(params) do
    # params: :name, :slug, :description (opc), :parent_id (opc), :order (opc)
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    sql = \"\"\"
    INSERT INTO deeper_articles_categories (name, slug, description, parent_id, \"order\", created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING *;
    \"\"\"
    values = [
      params[:name], params[:slug], params[:description],
      params[:parent_id] || 0, params[:order] || 0,
      current_timestamp, current_timestamp
    ]
    case Repo.query(sql, values) do
      {:ok, %{rows: [row_data], columns: cols}} -> {:ok, map_row_to_generic_struct(row_data, cols)}
      err -> err
    end
  end

  @doc \"Busca uma categoria pelo slug.\"
  @spec get_category_by_slug(slug :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_category_by_slug(slug) do
    sql = \"SELECT * FROM deeper_articles_categories WHERE slug = ? LIMIT 1\"
    case Repo.query(sql, [slug]) do
      {:ok, %{rows: [r], cols: c}} -> {:ok, map_row_to_generic_struct(r,c)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"Lista todas as categorias, opcionalmente hierarquicamente.\"
  @spec list_categories(opts :: map()) :: {:ok, list(map())} | {:error, any()}
  def list_categories(opts \\\\ %{}) do
    # opts: :hierarchical (boolean, default false)
    sql = \"SELECT * FROM deeper_articles_categories ORDER BY parent_id ASC, \\\"order\\\" ASC, name ASC\"
    case Repo.query(sql, []) do
      {:ok, %{rows: rows, columns: cols}} ->
        categories_flat = Enum.map(rows, &map_row_to_generic_struct(&1, cols))
        if opts[:hierarchical] do
          {:ok, build_category_hierarchy(categories_flat)}
        else
          {:ok, categories_flat}
        end
      err -> err
    end
  end

  defp build_category_hierarchy(flat_list, parent_id \\\\ 0) do
    flat_list
    |> Enum.filter(fn cat -> (Map.get(cat, \"parent_id\") || Map.get(cat, :parent_id)) == parent_id end)
    |> Enum.map(fn cat ->
      children = build_category_hierarchy(flat_list, Map.get(cat, \"id\") || Map.get(cat, :id))
      if Enum.empty?(children), do: cat, else: Map.put(cat, :sub_categories, children)
    end)
  end

  # ... Funções para update_category, delete_category ...


  # --- Funções para Tags (deeper_articles_tags e junção) ---

  @doc \"Busca ou cria uma tag. Retorna o ID da tag.\"
  @spec find_or_create_tag(tag_name :: String.t()) :: {:ok, integer()} | {:error, any()}
  def find_or_create_tag(tag_name) do
    # Slugify tag_name
    slug = tag_name |> String.downcase() |> String.replace(~r/\\s+/, \"-\") # Simplificado
    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    find_sql = \"SELECT id FROM deeper_articles_tags WHERE name = ? OR slug = ? LIMIT 1\"
    case Repo.query(find_sql, [tag_name, slug]) do
      {:ok, %{rows: [[tag_id]], columns: _}} -> {:ok, tag_id}
      {:ok, %{rows: []}} -> # Não encontrada, criar
        create_sql = \"\"\"
        INSERT INTO deeper_articles_tags (name, slug, created_at, updated_at)
        VALUES (?, ?, ?, ?) RETURNING id;
        \"\"\"
        case Repo.query(create_sql, [tag_name, slug, current_timestamp, current_timestamp]) do
          {:ok, %{rows: [[new_tag_id]], columns: _}} -> {:ok, new_tag_id}
          err_create -> err_create
        end
      err_find -> err_find
    end
  end

  @doc \"Lida com a atribuição/desatribuição de tags para um artigo.\"
  # tag_names_list pode ser nil (não fazer nada), lista vazia (remover todas), ou lista de nomes de tags.
  defp handle_article_tags(_article_id, nil), do: :ok # Não fazer nada se :tags não for fornecido
  defp handle_article_tags(article_id, tag_names_list) when is_list(tag_names_list) do
    # 1. Remover todas as tags existentes para este artigo
    Repo.execute(\"DELETE FROM deeper_articles_tags_to_entries WHERE entry_id = ?\", [article_id])

    # 2. Encontrar ou criar cada tag e associá-la
    Enum.each(tag_names_list, fn tag_name ->
      case find_or_create_tag(tag_name) do
        {:ok, tag_id} ->
          # Usar INSERT OR IGNORE para evitar erro se a combinação já existir (embora tenhamos deletado antes)
          Repo.execute(\"INSERT OR IGNORE INTO deeper_articles_tags_to_entries (entry_id, tag_id) VALUES (?, ?)\", [article_id, tag_id])
        {:error, _reason} -> # Logar erro ao criar/encontrar tag
          Deeper.Core.Logger.error(\"Falha ao processar tag '#{tag_name}' para artigo #{article_id}\", module: __MODULE__)
      end
    end)
    :ok
  end

  @doc \"Lista todas as tags populares (ex: com mais artigos).\"
  @spec list_popular_tags(limit :: integer()) :: {:ok, list(map())} | {:error, any()}
  def list_popular_tags(limit \\\\ 10) do
    sql = \"SELECT id, name, slug, item_count FROM deeper_articles_tags ORDER BY item_count DESC, name ASC LIMIT ?\"
    case Repo.query(sql, [limit]) do
      {:ok, %{rows: rows, cols: c}} -> {:ok, Enum.map(rows, &map_row_to_generic_struct(&1, c))}
      err -> err
    end
  end

  # TODO: Funções para atualizar item_count em tags e categories (pode ser com triggers no DB ou na lógica da app).


  # --- Função Auxiliar de Mapeamento ---
  defp map_row_to_generic_struct(row_data_list, columns_list) when is_list(row_data_list) and is_list(columns_list) do
    Enum.zip(columns_list, row_data_list)
    |> Enum.map(fn {col, val} ->
        key = try do String.to_atom(Atom.to_string(col)) rescue _ -> Atom.to_string(col) end
        {key, val}
      end)
    |> Enum.into(%{})
  end
end
```