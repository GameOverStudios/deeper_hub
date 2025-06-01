# Documentação Deeper: Módulos de Acesso a Dados para Fóruns

Este documento descreve o módulo Elixir (Repositório) principal responsável por interagir com as tabelas do banco de dados relacionadas ao módulo de Fóruns (`deeper_forum_categories`, `deeper_forums`, `deeper_forum_topics`, `deeper_forum_posts`, `deeper_forum_read_topics`, `deeper_forum_subscriptions`).

## Módulo Principal: `Deeper.Content.ForumsRepo`

Este módulo lida com todas as operações de banco de dados para o sistema de fóruns.

**Localização do Código Elixir:** `lib/deeper/content/forums_repo.ex`

```elixir
defmodule Deeper.Content.ForumsRepo do
  alias Deeper.Core.Data.Repo
  alias Deeper.Files.StorageRepo # Para map_row_to_struct helper

  # Structs opcionais para melhor tipagem (podem ser definidos em outro lugar)
  # defstruct [:id, :title, :slug, :description, :order_index, ...] # ForumCategory, Forum, ForumTopic, ForumPost

  # === Funções para Categorias de Fóruns (`deeper_forum_categories`) ===

  def create_forum_category(attrs) do
    # Adicionar lógica para gerar slug a partir de attrs.title
    sql = \"INSERT INTO deeper_forum_categories (title, slug, description, order_index) VALUES (?, ?, ?, ?) RETURNING *;\"
    values = [attrs.title, attrs.slug, attrs.description, attrs.order_index || 0]
    case Repo.query(sql, values) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      err -> err
    end
  end

  def get_forum_category(id_or_slug) do
    condition = if is_integer(id_or_slug), do: \"id = ?\", else: \"slug = ?\"
    sql = \"SELECT * FROM deeper_forum_categories WHERE #{condition} LIMIT 1\"
    case Repo.query(sql, [id_or_slug]) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  def list_forum_categories(opts \\\\ %{sort_by: \"order_index\", sort_order: \"asc\"}) do
    # Adaptar build_order_clause
    order_clause = Deeper.Files.FilesRepo.build_order_clause(opts, [\"id\", \"title\", \"slug\", \"order_index\"], \"order_index\")
    sql = \"SELECT * FROM deeper_forum_categories #{order_clause}\"
    case Repo.query(sql, []) do
      {:ok, %{rows: rows, columns: cols}} -> {:ok, Enum.map(rows, &StorageRepo.map_row_to_struct(&1, cols))}
      err -> err
    end
  end

  # ... update_forum_category, delete_forum_category ...


  # === Funções para Fóruns (`deeper_forums`) ===

  def create_forum(attrs) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    # Gerar slug, etc.
    sql = \"\"\"
    INSERT INTO deeper_forums (category_id, title, slug, description, order_index, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING *;
    \"\"\"
    values = [attrs.category_id, attrs.title, attrs.slug, attrs.description, attrs.order_index || 0, current_ts, current_ts]
    case Repo.query(sql, values) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      err -> err
    end
  end

  def get_forum(id_or_slug, opts \\\\ [include: []]) do
    condition = if is_integer(id_or_slug), do: \"f.id = ?\", else: \"f.slug = ?\"
    select_fields = \"f.*\"
    joins = \"\"
    # Adicionar joins para last_post_profile, last_topic se em opts[:include]
    if Enum.member?(opts[:include], :last_post_details) do
        select_fields = select_fields <> \", lpp.name as last_post_profile_name, lpt.title as last_topic_title\"
        joins = joins <> \" LEFT JOIN sys_profiles lpp_sp ON f.last_post_profile_id = lpp_sp.id LEFT JOIN sys_accounts lpp ON lpp_sp.account_id = lpp.id\"
        joins = joins <> \" LEFT JOIN deeper_forum_topics lpt ON f.last_topic_id = lpt.id\"
    end

    sql = \"SELECT #{select_fields} FROM deeper_forums f #{joins} WHERE #{condition} LIMIT 1\"
    case Repo.query(sql, [id_or_slug]) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  def list_forums(filters \\\\ %{}, pagination_opts \\\\ %{}) do
    # `filters` pode incluir `category_id`
    # `pagination_opts` para sort_by (order_index, title, last_post_at), limit, offset
    # ... (implementação omitida por brevidade, mas similar a list_articles/list_events) ...
    select_clause = \"SELECT f.*\" # Adicionar JOINs para last_post_profile_name, etc.
    from_clause = \"FROM deeper_forums f\"
    where_conditions = [\"1=1\"]
    params = []
    # ... (construir where e params) ...
    if category_id = filters[:category_id], do: (Array.push(where_conditions, \"f.category_id = ?\"); Array.push(params, category_id))

    where_clause = \"WHERE \" <> Enum.join(where_conditions, \" AND \")
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"order_index\", \"title\", \"last_post_at\"], \"order_index\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(f.id) as total_count #{from_clause} #{where_clause}\"
    # ... (executar e retornar) ...
    :not_implemented
  end

  # ... update_forum, delete_forum ...

  @doc \"Atualiza os contadores e o último post de um fórum. Chamado após novo tópico/post.\"
  def update_forum_stats(forum_id) do
    Repo.transaction(fn ->
      # Contar tópicos
      count_topics_sql = \"SELECT COUNT(id) FROM deeper_forum_topics WHERE forum_id = ?\"
      {:ok, %{rows: [{topics_count}]}} = Repo.query(count_topics_sql, [forum_id])

      # Contar posts
      count_posts_sql = \"\"\"
      SELECT COUNT(p.id) FROM deeper_forum_posts p
      JOIN deeper_forum_topics t ON p.topic_id = t.id
      WHERE t.forum_id = ?
      \"\"\"
      {:ok, %{rows: [{posts_count}]}} = Repo.query(count_posts_sql, [forum_id])

      # Encontrar último post no fórum
      last_post_sql = \"\"\"
      SELECT p.id as last_post_id, p.profile_id as last_post_profile_id, p.created_at as last_post_at, p.topic_id as last_topic_id
      FROM deeper_forum_posts p
      JOIN deeper_forum_topics t ON p.topic_id = t.id
      WHERE t.forum_id = ?
      ORDER BY p.created_at DESC LIMIT 1
      \"\"\"
      last_post_info =
        case Repo.query(last_post_sql, [forum_id]) do
          {:ok, %{rows: [row], columns: cols}} -> StorageRepo.map_row_to_struct(row, cols)
          _ -> %{last_post_id: nil, last_post_profile_id: nil, last_post_at: nil, last_topic_id: nil}
        end

      update_sql = \"\"\"
      UPDATE deeper_forums
      SET topics_count = ?, posts_count = ?, last_topic_id = ?, last_post_id = ?, last_post_profile_id = ?, last_post_at = ?
      WHERE id = ?
      \"\"\"
      Repo.execute(update_sql, [
        topics_count, posts_count,
        last_post_info.last_topic_id, last_post_info.last_post_id,
        last_post_info.last_post_profile_id, last_post_info.last_post_at,
        forum_id
      ])
    end)
  end


  # === Funções para Tópicos de Fórum (`deeper_forum_topics`) ===

  def create_topic(attrs) do
    # `attrs` inclui :forum_id, :profile_id, :title, :body_do_primeiro_post
    # Deve criar o tópico e o primeiro post em uma transação.
    # Atualizar estatísticas do fórum.
    current_ts = DateTime.to_unix(DateTime.utc_now())
    # Gerar slug para o tópico

    Repo.transaction(fn ->
      # 1. Criar o post inicial
      sql_insert_post = \"\"\"
      INSERT INTO deeper_forum_posts (topic_id, profile_id, body, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?) RETURNING *;
      \"\"\"
      # topic_id é temporariamente 0 ou nil, será atualizado depois
      # Esta é uma dependência circular complicada.
      # Estratégia: Criar tópico primeiro, pegar ID, depois criar post com esse ID, depois atualizar first_post_id no tópico.

      # 1. Criar o registro do tópico (sem first_post_id e last_post_id inicialmente)
      sql_insert_topic = \"\"\"
      INSERT INTO deeper_forum_topics (forum_id, profile_id, title, slug, created_at, updated_at, last_post_at)
      VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id;
      \"\"\"
      topic_values = [attrs.forum_id, attrs.profile_id, attrs.title, attrs.slug, current_ts, current_ts, current_ts]
      {:ok, %{rows: [{topic_id}]}} = Repo.query(sql_insert_topic, topic_values)
        |> case do err = {:error, _} -> Repo.rollback(err); res -> res end # Rollback se falhar

      # 2. Criar o primeiro post, agora com o topic_id correto
      post_values = [topic_id, attrs.profile_id, attrs.body_of_first_post, current_ts, current_ts]
      {:ok, %{rows: [post_row], columns: post_cols}} = Repo.query(sql_insert_post, post_values)
         |> case do err = {:error, _} -> Repo.rollback(err); res -> res end
      first_post_map = StorageRepo.map_row_to_struct(post_row, post_cols)
      first_post_id = first_post_map.id

      # 3. Atualizar o tópico com first_post_id, last_post_id, e outros contadores iniciais
      sql_update_topic = \"\"\"
      UPDATE deeper_forum_topics
      SET first_post_id = ?, last_post_id = ?, last_post_profile_id = ?, replies_count = 0
      WHERE id = ? RETURNING *;
      \"\"\"
      update_topic_values = [first_post_id, first_post_id, attrs.profile_id, topic_id]
      {:ok, %{rows: [topic_final_row], columns: topic_final_cols}} = Repo.query(sql_update_topic, update_topic_values)
        |> case do err = {:error, _} -> Repo.rollback(err); res -> res end
      
      # 4. Atualizar estatísticas do fórum
      update_forum_stats(attrs.forum_id)

      {:ok, StorageRepo.map_row_to_struct(topic_final_row, topic_final_cols)}
    end)
  end

  def get_topic(id_or_slug_pair, opts \\\\ [include: []]) do
    # `id_or_slug_pair` pode ser `id` (inteiro) ou `{forum_id_or_slug, topic_slug}`
    # `opts` pode incluir `:forum_details, :author_profile, :first_post, :last_post_details`
    # ... (implementação complexa de JOINs e condições) ...
    :not_implemented
  end

  def list_topics_in_forum(forum_id_or_slug, pagination_opts \\\\ %{}) do
    # `pagination_opts` para sort_by (is_sticky DESC, last_post_at DESC), limit, offset
    # JOIN com profile para autor, last_reply_profile para último autor de resposta.
    # ... (implementação similar a list_events/list_articles) ...
    # Obter forum_id numérico se slug for fornecido
    forum_id = case get_forum(forum_id_or_slug) do # Reutiliza get_forum
        {:ok, %{id: fid}} -> fid
        _ -> nil # Ou retorna erro
    end
    unless forum_id, do: (return {:error, :forum_not_found})

    select_clause = \"SELECT t.*, p_author.name as author_name, p_last_reply.name as last_reply_profile_name\"
    from_clause = \"\"\"
    FROM deeper_forum_topics t
    LEFT JOIN sys_profiles sp_author ON t.profile_id = sp_author.id LEFT JOIN sys_accounts p_author ON sp_author.account_id = p_author.id
    LEFT JOIN sys_profiles sp_last_reply ON t.last_post_profile_id = sp_last_reply.id LEFT JOIN sys_accounts p_last_reply ON sp_last_reply.account_id = p_last_reply.id
    \"\"\"
    where_clause = \"WHERE t.forum_id = ?\"
    params = [forum_id]
    
    # build_order_clause precisa ser adaptado para campos de tópicos e default
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"is_sticky\", \"last_post_at\", \"created_at\", \"title\", \"replies_count\", \"views_count\"], \"is_sticky DESC, last_post_at DESC\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(t.id) as total_count #{from_clause} #{where_clause}\"
    # ... (executar e retornar) ...
    :not_implemented
  end

  # ... update_topic (título, status - sticky, locked), delete_topic ...

  @doc \"Incrementa a contagem de visualizações de um tópico.\"
  def increment_topic_view_count(topic_id) do
    sql = \"UPDATE deeper_forum_topics SET views_count = views_count + 1 WHERE id = ?\"
    Repo.execute(sql, [topic_id])
  end

  @doc \"Atualiza os contadores e o último post de um tópico. Chamado após novo post/resposta.\"
  def update_topic_stats(topic_id) do
    Repo.transaction(fn ->
      # Contar respostas (posts - 1)
      count_replies_sql = \"SELECT COUNT(id) - 1 FROM deeper_forum_posts WHERE topic_id = ?\"
      {:ok, %{rows: [{replies_count}]}} = Repo.query(count_replies_sql, [topic_id])
      # Garantir que replies_count não seja negativo se houver apenas o primeiro post
      replies_count = max(0, replies_count)


      # Encontrar último post no tópico
      last_post_sql = \"SELECT id as last_post_id, profile_id as last_post_profile_id, created_at as last_post_at FROM deeper_forum_posts WHERE topic_id = ? ORDER BY created_at DESC LIMIT 1\"
      last_post_info =
        case Repo.query(last_post_sql, [topic_id]) do
          {:ok, %{rows: [row], columns: cols}} -> StorageRepo.map_row_to_struct(row, cols)
          _ -> %{last_post_id: nil, last_post_profile_id: nil, last_post_at: nil}
        end

      update_sql = \"\"\"
      UPDATE deeper_forum_topics
      SET replies_count = ?, last_post_id = ?, last_post_profile_id = ?, last_post_at = ?, updated_at = ?
      WHERE id = ?
      \"\"\"
      current_ts = DateTime.to_unix(DateTime.utc_now())
      Repo.execute(update_sql, [
        replies_count, last_post_info.last_post_id,
        last_post_info.last_post_profile_id, last_post_info.last_post_at,
        current_ts, # updated_at para o tópico
        topic_id
      ])
      |> case do # Atualizar também o fórum pai
          {:ok, _} -> update_forum_stats(get_topic_forum_id(topic_id)) # Precisa de uma fn para get forum_id
          err -> err
      end
    end)
  end

  # Helper para obter forum_id de um topic_id
  defp get_topic_forum_id(topic_id) do
    sql = \"SELECT forum_id FROM deeper_forum_topics WHERE id = ? LIMIT 1\"
    case Repo.query(sql, [topic_id]) do
      {:ok, %{rows: [{forum_id}]}} -> forum_id
      _ -> nil
    end
  end

  # === Funções para Posts de Fórum (`deeper_forum_posts`) ===

  def create_post(attrs) do
    # `attrs` inclui :topic_id, :profile_id, :body, :parent_post_id (opcional)
    # Deve atualizar estatísticas do tópico e do fórum.
    current_ts = DateTime.to_unix(DateTime.utc_now())
    Repo.transaction(fn ->
      sql = \"\"\"
      INSERT INTO deeper_forum_posts (topic_id, profile_id, parent_post_id, body, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?) RETURNING *;
      \"\"\"
      values = [attrs.topic_id, attrs.profile_id, attrs.parent_post_id, attrs.body, current_ts, current_ts]
      
      with {:ok, %{rows: [row], columns: cols}} <- Repo.query(sql, values),
           :ok <- update_topic_stats(attrs.topic_id) do # update_topic_stats já atualiza o fórum
        {:ok, StorageRepo.map_row_to_struct(row, cols)}
      else
        err -> Repo.rollback(err)
      end
    end)
  end

  def get_post(id, opts \\\\ [include: []]) do
    # `opts` pode incluir `:author_profile`
    # ...
    :not_implemented
  end

  def list_posts_in_topic(topic_id, pagination_opts \\\\ %{}) do
    # `pagination_opts` para sort_by (created_at ASC), limit, offset
    # JOIN com profile para autor.
    # Lidar com posts aninhados/hierarquia se `parent_post_id` for usado extensivamente.
    # ... (implementação similar a list_events/list_articles) ...
    select_clause = \"SELECT p.*, pa.name as author_name\"
    from_clause = \"FROM deeper_forum_posts p JOIN sys_profiles sp ON p.profile_id = sp.id JOIN sys_accounts pa ON sp.account_id = pa.id\"
    where_clause = \"WHERE p.topic_id = ?\"
    params = [topic_id]

    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"created_at\"], \"created_at ASC\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(p.id) as total_count #{from_clause} #{where_clause}\"
    # ... (executar e retornar) ...
    :not_implemented
  end

  # ... update_post (body, status), delete_post (soft ou hard) ...
  # Ao deletar/atualizar status de um post, recalcular estatísticas do tópico e fórum.


  # === Funções para Tópicos Lidos (`deeper_forum_read_topics`) ===

  def mark_topic_as_read(profile_id, topic_id, last_read_post_id) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    sql = \"\"\"
    INSERT INTO deeper_forum_read_topics (profile_id, topic_id, last_read_post_id, last_read_at)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(profile_id, topic_id) DO UPDATE SET
      last_read_post_id = excluded.last_read_post_id,
      last_read_at = excluded.last_read_at;
    \"\"\"
    Repo.execute(sql, [profile_id, topic_id, last_read_post_id, current_ts])
  end

  def get_topic_read_status(profile_id, topic_ids_list) when is_list(topic_ids_list) and topic_ids_list != [] do
    placeholders = Enum.map_join(topic_ids_list, \",\", fn _ -> \"?\" end)
    sql = \"SELECT topic_id, last_read_post_id FROM deeper_forum_read_topics WHERE profile_id = ? AND topic_id IN (#{placeholders})\"
    params = [profile_id | topic_ids_list]
    case Repo.query(sql, params) do
      {:ok, %{rows: rows, columns: _cols}} ->
        # Retorna um mapa de topic_id -> last_read_post_id
        read_status_map = Map.new(rows, fn {tid, lpid} -> {tid, lpid} end)
        {:ok, read_status_map}
      err -> err
    end
  end
  def get_topic_read_status(_profile_id, []), do: {:ok, %{}} # Lista vazia de tópicos


  # === Funções para Subscrições de Fórum/Tópico (`deeper_forum_subscriptions`) ===

  def subscribe(profile_id, target_type, target_id, subscription_type \\\\ \"instant\") do
    # `target_type` é :forum ou :topic
    # `target_id` é forum_id ou topic_id
    # Garantir unicidade e constraint CHECK via lógica da aplicação se os índices parciais não forem suficientes.
    # ...
    :not_implemented
  end

  # ... list_subscriptions_for_profile, get_subscription_status, unsubscribe ...

end
```

### Notas para `ForumsRepo`:
*   **Complexidade:** Este é um Repo significativamente mais complexo devido ao número de entidades interconectadas (Categorias, Fóruns, Tópicos, Posts) e à necessidade de manter estatísticas denormalizadas (`topics_count`, `posts_count`, `last_post_*`).
*   **Transações:** Operações como `create_topic` (que cria um tópico e seu primeiro post) e `create_post` (que cria um post e depois atualiza estatísticas do tópico e do fórum) devem ocorrer dentro de transações para garantir atomicidade.
*   **Dependências Circulares/Posteriores para FKs:** As colunas `last_topic_id`, `last_post_id` em `deeper_forums`, e `first_post_id`, `last_post_id` em `deeper_forum_topics` referenciam IDs de tabelas que podem ser criadas *depois* ou que são preenchidas como parte da mesma transação. A integridade dessas referências é crucial e precisa ser gerenciada com cuidado, seja pela ordem de operações dentro de uma transação, atualizações subsequentes, ou (idealmente, mas difícil com SQLite e `ALTER TABLE`) constraints FK deferíveis ou adicionadas posteriormente. A estratégia atual é criar as colunas e preenchê-las/atualizá-las programaticamente.
*   **Atualização de Estatísticas:** As funções `update_forum_stats` e `update_topic_stats` são vitais. Elas seriam chamadas após a criação/exclusão de tópicos e posts. Em um sistema com alta taxa de escrita, essas atualizações podem se tornar um gargalo ou levar a condições de corrida se não forem bem gerenciadas (ex: usando `SELECT ... FOR UPDATE` se o DB suportar, ou filas para atualizações de contadores). SQLite tem limitações de concorrência aqui.
*   **Listagem com JOINs:** As funções de listagem (`list_forums`, `list_topics_in_forum`, `list_posts_in_topic`) envolvem `JOIN`s para buscar informações relacionadas (autor, último postador, etc.). É importante selecionar apenas os campos necessários e garantir que os `JOIN`s sejam eficientes.
*   **Paginação de Posts:** A listagem de posts dentro de um tópico (`list_posts_in_topic`) é fundamental e geralmente é paginada.
*   **Tópicos Lidos e Subscrições:** As funcionalidades para `deeper_forum_read_topics` e `deeper_forum_subscriptions` são importantes para a experiência do usuário e adicionam mais complexidade ao Repo.
*   **Reutilização de Helpers:** Continuar a refatorar helpers comuns (como `build_order_clause`, `map_row_to_struct`) para um módulo utilitário.

Este `ForumsRepo` é um bom exemplo de como um módulo de conteúdo mais tradicional e hierárquico seria implementado. O próximo passo seriam os `api_endpoints.md` para ele.