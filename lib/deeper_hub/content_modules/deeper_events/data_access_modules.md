# Documentação Deeper: Módulos de Acesso a Dados para Eventos

Este documento descreve os módulos Elixir (Repositórios) responsáveis por interagir com as tabelas do banco de dados relacionadas ao módulo de Eventos (`deeper_events`, `deeper_event_rsvps`, `deeper_event_categories`, `deeper_events_to_categories`).

## Módulos Principais:

1.  **`Deeper.Content.EventsRepo`**:
    *   Responsável por interagir com as tabelas `deeper_events` e `deeper_event_rsvps`, e a tabela de junção `deeper_events_to_categories`.
    *   Funções para CRUD de eventos, listagem com filtros e paginação, gerenciamento de RSVPs, e associação de categorias.

2.  **`Deeper.Content.EventCategoriesRepo`**:
    *   Responsável por interagir com a tabela `deeper_event_categories`.
    *   Funções para CRUD de categorias de eventos, listagem, etc.

## 1. Módulo: `Deeper.Content.EventsRepo`

Este módulo lida com a tabela `deeper_events` e suas associações diretas.

**Localização do Código Elixir:** `lib/deeper/content/events_repo.ex`

```elixir
defmodule Deeper.Content.EventsRepo do
  alias Deeper.Core.Data.Repo
  alias Deeper.Files.StorageRepo # Para map_row_to_struct helper

  @doc \"\"\"
  Cria um novo evento.
  `attrs` é um mapa contendo os campos do evento.
  `category_ids` (lista de IDs) é opcional para associar categorias.
  \"\"\"
  def create_event(attrs) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    # Garantir que start_datetime e end_datetime sejam timestamps Unix
    # Adicionar lógica para gerar slug se não fornecido

    Repo.transaction(fn ->
      sql_insert_event = \"\"\"
      INSERT INTO deeper_events (
        profile_id, title, slug, description, start_datetime, end_datetime, timezone,
        location_text, location_lat, location_lng, address, city, state, country, zip_code,
        banner_file_id, visibility, allow_rsvps, max_attendees, status,
        rsvps_yes_count, rsvps_maybe_count, rsvps_no_count, views,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      RETURNING *;
      \"\"\"
      event_values = [
        attrs.profile_id, attrs.title, attrs.slug, attrs.description,
        attrs.start_datetime, attrs.end_datetime, attrs.timezone,
        attrs.location_text, attrs.location_lat, attrs.location_lng,
        attrs.address, attrs.city, attrs.state, attrs.country, attrs.zip_code,
        attrs.banner_file_id, attrs.visibility || \"public\", attrs.allow_rsvps || 1,
        attrs.max_attendees || 0, attrs.status || \"draft\",
        0, 0, 0, 0, # rsvp counts and views
        current_ts, current_ts # created_at, updated_at
      ]

      case Repo.query(sql_insert_event, event_values) do
        {:ok, %{rows: [event_row], columns: event_columns}} ->
          event_map = StorageRepo.map_row_to_struct(event_row, event_columns)
          event_id = event_map.id

          case associate_categories_to_event(event_id, attrs.category_ids || []) do
            :ok ->
              {:ok, %{event_map | categories: fetch_event_categories(event_id)}}
            {:error, cat_reason} ->
              Repo.rollback({:error, {:categories_association, cat_reason}})
          end
        {:error, reason} ->
          Repo.rollback({:error, {:event_creation, reason}})
      end
    end)
  end

  @doc \"\"\"
  Busca um evento pelo seu ID.
  `opts` pode incluir `[:categories, :banner_image, :organizer, :rsvps_summary]`
  \"\"\"
  def get_event(id, opts \\\\ [include: [:categories, :banner_image, :organizer]]) do
    select_fields = \"e.*\"
    joins = \"\"
    params = [id]

    if Enum.member?(opts[:include], :organizer) do
      select_fields = select_fields <> \", p.name as organizer_name\"
      joins = joins <> \" LEFT JOIN sys_profiles sp ON e.profile_id = sp.id LEFT JOIN sys_accounts p ON sp.account_id = p.id\"
    end

    if Enum.member?(opts[:include], :banner_image) do
      select_fields = select_fields <> \", bf.file_name as banner_file_name, bf.remote_id as banner_remote_id, bf.storage_object as banner_storage\"
      joins = joins <> \" LEFT JOIN deeper_files bf ON e.banner_file_id = bf.id\"
    end

    sql = \"SELECT #{select_fields} FROM deeper_events e #{joins} WHERE e.id = ? LIMIT 1\"

    case Repo.query(sql, params) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        event_map = StorageRepo.map_row_to_struct(row_tuple, columns)
        categories = if Enum.member?(opts[:include], :categories), do: fetch_event_categories(id), else: []
        # rsvps_summary = if Enum.member?(opts[:include], :rsvps_summary), do: get_rsvps_summary(id), else: %{}
        # A contagem de RSVPs já está na tabela deeper_events, então não precisa de um get_rsvps_summary separado aqui
        # a menos que queiramos mais detalhes do que apenas as contagens.
        {:ok, %{event_map | categories: categories}}
      {:ok, %{rows: []}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc \"Busca um evento pelo seu slug.\"
  def get_event_by_slug(slug, opts \\\\ [include: [:categories, :banner_image, :organizer]]) do
    # Lógica similar a get_event, mas WHERE e.slug = ?
    select_fields = \"e.*\"
    joins = \"\"
    params = [slug]

    if Enum.member?(opts[:include], :organizer) do
      select_fields = select_fields <> \", p.name as organizer_name\"
      joins = joins <> \" LEFT JOIN sys_profiles sp ON e.profile_id = sp.id LEFT JOIN sys_accounts p ON sp.account_id = p.id\"
    end
    if Enum.member?(opts[:include], :banner_image) do
      select_fields = select_fields <> \", bf.file_name as banner_file_name, bf.remote_id as banner_remote_id, bf.storage_object as banner_storage\"
      joins = joins <> \" LEFT JOIN deeper_files bf ON e.banner_file_id = bf.id\"
    end

    sql = \"SELECT #{select_fields} FROM deeper_events e #{joins} WHERE e.slug = ? LIMIT 1\"
    case Repo.query(sql, params) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        event_map = StorageRepo.map_row_to_struct(row_tuple, columns)
        categories = if Enum.member?(opts[:include], :categories), do: fetch_event_categories(event_map.id), else: []
        {:ok, %{event_map | categories: categories}}
      {:ok, %{rows: []}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc \"\"\"
  Lista eventos com filtros e paginação.
  `filters`: %{profile_id: 1, status: \"active\", category_id: 5, upcoming: true, date_range_start: ts, date_range_end: ts}
  `pagination_opts`: %{limit: 10, offset: 0, sort_by: \"start_datetime\", sort_order: \"asc\"}
  \"\"\"
  def list_events(filters \\\\ %{}, pagination_opts \\\\ %{}) do
    select_clause = \"SELECT DISTINCT e.*, p.name as organizer_name\"
    from_clause = \"FROM deeper_events e JOIN sys_profiles sp ON e.profile_id = sp.id JOIN sys_accounts p ON sp.account_id = p.id\"
    join_categories_clause = \"\"
    where_conditions = [\"1=1\"]
    params = []

    # Adicionar filtros (profile_id, status, visibility, etc.)
    if profile_id = filters[:profile_id], do: (Array.push(where_conditions, \"e.profile_id = ?\"); Array.push(params, profile_id))
    if status = filters[:status], do: (Array.push(where_conditions, \"e.status = ?\"); Array.push(params, status))
    if visibility = filters[:visibility], do: (Array.push(where_conditions, \"e.visibility = ?\"); Array.push(params, visibility))

    # Filtro por categoria
    if category_id = filters[:category_id] do
      join_categories_clause = \" JOIN deeper_events_to_categories etc ON e.id = etc.event_id\"
      Array.push(where_conditions, \"etc.category_id = ?\")
      Array.push(params, category_id)
    end

    # Filtro por eventos futuros (\"upcoming\")
    if filters[:upcoming] == true do
      current_ts = DateTime.to_unix(DateTime.utc_now())
      Array.push(where_conditions, \"e.start_datetime >= ?\")
      Array.push(params, current_ts)
    end

    # Filtro por intervalo de datas (start_datetime)
    if start_ts = filters[:date_range_start], do: (Array.push(where_conditions, \"e.start_datetime >= ?\"); Array.push(params, start_ts))
    if end_ts = filters[:date_range_end], do: (Array.push(where_conditions, \"e.start_datetime <= ?\"); Array.push(params, end_ts))


    where_clause = \"WHERE \" <> Enum.join(where_conditions, \" AND \")
    # Adaptar build_order_clause para os campos de 'deeper_events'
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"id\", \"title\", \"start_datetime\", \"created_at\", \"views\"], \"start_datetime\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{join_categories_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(DISTINCT e.id) as total_count #{from_clause} #{join_categories_clause} #{where_clause}\"
    
    # ... (lógica de execução e retorno similar a ArticlesRepo.list_articles) ...
    # Lembre-se de buscar categorias para cada evento se solicitado.
    case Repo.query(sql_data, params) do
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        events = Enum.map(rows_tuples, &StorageRepo.map_row_to_struct(&1, columns))
        events_with_categories = Enum.map(events, fn event ->
          %{event | categories: fetch_event_categories(event.id)}
        end)

        case Repo.query(sql_count, params) do
          {:ok, %{rows: [{total_count}]}} ->
            {:ok, %{data: events_with_categories, total_count: total_count}}
          _err_count -> {:ok, %{data: events_with_categories, total_count: -1}}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Atualiza um evento.\"
  def update_event(id, attrs) do
    # Lógica similar a ArticlesRepo.update_article, construindo SET clause dinamicamente
    # e lidando com a associação de categorias.
    # ...
    # Campos permitidos para update: :title, :slug, :description, ..., :category_ids
    current_ts = DateTime.to_unix(DateTime.utc_now())
    update_fields_map = Map.put(attrs, :updated_at, current_ts)
                       |> Map.drop([:category_ids, :profile_id, :created_at, :id, :rsvps_yes_count, :rsvps_maybe_count, :rsvps_no_count, :views])

    {set_clause, params} = # ... (construir set_clause e params como em ArticlesRepo) ...
        Enum.map_reduce(update_fields_map, [], fn {field, value}, acc_params ->
          allowed_fields = [
            :title, :slug, :description, :start_datetime, :end_datetime, :timezone,
            :location_text, :location_lat, :location_lng, :address, :city, :state, :country, :zip_code,
            :banner_file_id, :visibility, :allow_rsvps, :max_attendees, :status, :updated_at
          ]
          if Enum.member?(allowed_fields, field) do
            {\"#{Atom.to_string(field)} = ?\", [value | acc_params]}
          else {nil, acc_params} end
        end)
        |> then(fn {clauses, acc_params} ->
            valid_clauses = Enum.reject(clauses, &is_nil/1)
            {Enum.join(valid_clauses, \", \"), Enum.reverse(acc_params)}
          end)
    
    if set_clause == \"\" and not Map.has_key?(attrs, :category_ids) do
        return get_event(id) # Nada para atualizar
    end

    Repo.transaction(fn ->
        updated_event_map_intermediate = 
            if set_clause != \"\" do
                sql_update_event = \"UPDATE deeper_events SET #{set_clause} WHERE id = ? RETURNING *\"
                update_params = params ++ [id]
                case Repo.query(sql_update_event, update_params) do
                    {:ok, %{rows: [row], cols: cols}} -> StorageRepo.map_row_to_struct(row, cols)
                    err -> Repo.rollback({:error, {:event_update, err}})
                end
            else # Apenas categorias para atualizar
                case get_event(id) do # Precisamos do mapa do evento se só categorias mudam
                    {:ok, event_map_for_cats} -> event_map_for_cats
                    err -> Repo.rollback({:error, {:event_fetch_for_cat_update, err}})
                end
            end

        if Map.has_key?(attrs, :category_ids) do
            case associate_categories_to_event(id, attrs.category_ids) do
                :ok -> {:ok, %{updated_event_map_intermediate | categories: fetch_event_categories(id)}}
                {:error, cat_reason} -> Repo.rollback({:error, {:categories_association, cat_reason}})
            end
        else
            {:ok, %{updated_event_map_intermediate | categories: fetch_event_categories(id)}}
        end
    end)
  end

  @doc \"Deleta um evento.\"
  def delete_event(id) do
    # ON DELETE CASCADE cuidará de deeper_event_rsvps e deeper_events_to_categories
    sql = \"DELETE FROM deeper_events WHERE id = ?\"
    Repo.execute(sql, [id])
  end


  # --- Funções Helper para Categorias de Evento ---
  def fetch_event_categories(event_id) do
    sql = \"\"\"
    SELECT c.id, c.name, c.slug
    FROM deeper_event_categories c
    JOIN deeper_events_to_categories etc ON c.id = etc.category_id
    WHERE etc.event_id = ?
    ORDER BY c.name
    \"\"\"
    case Repo.query(sql, [event_id]) do
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        Enum.map(rows_tuples, &StorageRepo.map_row_to_struct(&1, columns))
      _ -> []
    end
  end

  def associate_categories_to_event(event_id, category_ids) when is_list(category_ids) do
    # Lógica idêntica a ArticlesRepo.associate_categories_to_article,
    # mas usando a tabela 'deeper_events_to_categories'.
    # Pode ser generalizada em um helper se os nomes das colunas forem os mesmos.
    Repo.transaction(fn ->
      sql_delete_assoc = \"DELETE FROM deeper_events_to_categories WHERE event_id = ?\"
      Repo.execute(sql_delete_assoc, [event_id])

      if Enum.any?(category_ids) do
        Enum.reduce_while(category_ids, :ok, fn cat_id, _acc ->
          sql_insert_single_assoc = \"INSERT INTO deeper_events_to_categories (event_id, category_id) VALUES (?, ?)\"
          case Repo.execute(sql_insert_single_assoc, [event_id, cat_id]) do
            {:ok, _} -> {:cont, :ok}
            {:error, reason} -> {:halt, Repo.rollback({:error, reason})}
          end
        end)
      else
        :ok
      end
    end)
    |> case do
      {:ok, res} -> res
      err -> err
    end
  end


  # --- Funções para RSVP ---
  @doc \"\"\"
  Registra ou atualiza o RSVP de um perfil para um evento.
  Atualiza os contadores na tabela `deeper_events`.
  \"\"\"
  def rsvp_to_event(event_id, profile_id, rsvp_status, comment \\\\ nil, guests_count \\\\ 0) do
    Repo.transaction(fn ->
      # 1. Obter o RSVP antigo, se houver, para saber qual contador decrementar
      old_rsvp_sql = \"SELECT rsvp_status FROM deeper_event_rsvps WHERE event_id = ? AND profile_id = ? LIMIT 1\"
      old_status =
        case Repo.query(old_rsvp_sql, [event_id, profile_id]) do
          {:ok, %{rows: [{old_s}]}} -> old_s
          _ -> nil
        end

      # 2. Inserir ou atualizar o RSVP
      current_ts = DateTime.to_unix(DateTime.utc_now())
      # Usar INSERT OR REPLACE (UPSERT) do SQLite
      upsert_sql = \"\"\"
      INSERT INTO deeper_event_rsvps (event_id, profile_id, rsvp_status, comment, guests_count, rsvped_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(event_id, profile_id) DO UPDATE SET
        rsvp_status = excluded.rsvp_status,
        comment = excluded.comment,
        guests_count = excluded.guests_count,
        updated_at = excluded.updated_at;
      \"\"\"
      values = [event_id, profile_id, rsvp_status, comment, guests_count, current_ts, current_ts]

      case Repo.execute(upsert_sql, values) do
        {:ok, _} ->
          # 3. Atualizar contadores na tabela deeper_events
          update_counters_sql_parts = []
          update_params = []

          # Decrementar contador antigo se mudou e não era nil
          if old_status && old_status != rsvp_status do
            case old_status do
              \"yes\"   -> Array.push(update_counters_sql_parts, \"rsvps_yes_count = rsvps_yes_count - 1\")
              \"maybe\" -> Array.push(update_counters_sql_parts, \"rsvps_maybe_count = rsvps_maybe_count - 1\")
              \"no\"    -> Array.push(update_counters_sql_parts, \"rsvps_no_count = rsvps_no_count - 1\")
              _       -> :ok
            end
          end

          # Incrementar novo contador se não estava lá antes ou mudou
          if is_nil(old_status) || old_status != rsvp_status do
             case rsvp_status do
               \"yes\"   -> Array.push(update_counters_sql_parts, \"rsvps_yes_count = rsvps_yes_count + 1\")
               \"maybe\" -> Array.push(update_counters_sql_parts, \"rsvps_maybe_count = rsvps_maybe_count + 1\")
               \"no\"    -> Array.push(update_counters_sql_parts, \"rsvps_no_count = rsvps_no_count + 1\")
               _       -> :ok
             end
          end
          
          if Enum.any?(update_counters_sql_parts) do
            update_counters_sql = \"UPDATE deeper_events SET #{Enum.join(update_counters_sql_parts, \", \")} WHERE id = ?\"
            Array.push(update_params, event_id)
            Repo.execute(update_counters_sql, update_params) # Checar resultado se necessário
          end
          :ok
        {:error, reason} ->
          Repo.rollback({:error, {:rsvp_upsert, reason}})
      end
    end)
  end

  @doc \"Lista RSVPs para um evento.\"
  def list_rsvps_for_event(event_id, filters \\\\ %{}, pagination_opts \\\\ %{}) do
    # `filters` pode incluir `rsvp_status`.
    # Lógica de construção de query similar a `list_events` ou `list_articles`.
    # Fazer JOIN com sys_profiles/sys_accounts para obter nome do participante.
    select_clause = \"SELECT r.*, p.name as participant_name\"
    from_clause = \"FROM deeper_event_rsvps r JOIN sys_profiles sp ON r.profile_id = sp.id JOIN sys_accounts p ON sp.account_id = p.id\"
    where_conditions = [\"r.event_id = ?\"]
    params = [event_id]

    if rsvp_status = filters[:rsvp_status], do: (Array.push(where_conditions, \"r.rsvp_status = ?\"); Array.push(params, rsvp_status))

    where_clause = \"WHERE \" <> Enum.join(where_conditions, \" AND \")
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"rsvped_at\", \"updated_at\"], \"rsvped_at\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(r.id) as total_count #{from_clause} #{where_clause}\"
    
    # ... (execução das queries e retorno similar a list_articles) ...
    case Repo.query(sql_data, params) do
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        rsvps = Enum.map(rows_tuples, &StorageRepo.map_row_to_struct(&1, columns))
        case Repo.query(sql_count, params) do
          {:ok, %{rows: [{total_count}]}} ->
            {:ok, %{data: rsvps, total_count: total_count}}
          _err_count -> {:ok, %{data: rsvps, total_count: -1}}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Incrementa a contagem de visualizações de um evento.\"
  def increment_event_view_count(event_id) do
    sql = \"UPDATE deeper_events SET views = views + 1 WHERE id = ?\"
    Repo.execute(sql, [event_id])
  end

end
```

```elixir
defmodule Deeper.Content.EventCategoriesRepo do
  alias Deeper.Core.Data.Repo
  alias Deeper.Files.StorageRepo # Para map_row_to_struct

  # Funções CRUD para categorias de eventos (create_category, get_category,
  # get_category_by_slug, list_categories, update_category, delete_category)
  # seriam muito similares às do Deeper.Content.ArticleCategoriesRepo,
  # apenas operando na tabela `deeper_event_categories`.

  @doc \"Cria uma nova categoria de evento.\"
  def create_category(attrs) do
    # Adicionar lógica para gerar slug
    sql = \"INSERT INTO deeper_event_categories (name, slug, description, parent_id) VALUES (?, ?, ?, ?) RETURNING *;\"
    values = [attrs.name, attrs.slug, attrs.description, attrs.parent_id]
    case Repo.query(sql, values) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      err -> err
    end
  end

  @doc \"Busca uma categoria de evento pelo ID.\"
  def get_category(id) do
    sql = \"SELECT * FROM deeper_event_categories WHERE id = ? LIMIT 1\"
    case Repo.query(sql, [id]) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  # ... (outras funções CRUD como list_categories, update_category, delete_category) ...
  # A implementação seria análoga à de ArticleCategoriesRepo
  @doc \"Lista todas as categorias de eventos.\"
  def list_categories(filters \\\\ %{}) do
    parent_filter = if parent_id = filters[:parent_id], do: \"WHERE parent_id = #{parent_id}\", else: (if Map.has_key?(filters, :parent_id) and is_nil(filters[:parent_id]), do: \"WHERE parent_id IS NULL\", else: \"\")
    sql = \"SELECT * FROM deeper_event_categories #{parent_filter} ORDER BY name\"
    
    case Repo.query(sql, []) do
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        {:ok, Enum.map(rows_tuples, &StorageRepo.map_row_to_struct(&1, columns))}
      err -> err
    end
  end
end
```

### Notas para `EventsRepo`:
*   **Datas e Timezones:** O armazenamento de `start_datetime` e `end_datetime` como timestamps Unix UTC é uma boa prática. A coluna `timezone` é crucial para que o cliente possa interpretar essas datas corretamente.
*   **RSVP Counters:** A função `rsvp_to_event/5` inclui lógica para atualizar os contadores desnormalizados (`rsvps_yes_count`, etc.) na tabela `deeper_events`. Isso é feito dentro de uma transação para garantir consistência. O uso de `INSERT ... ON CONFLICT ... DO UPDATE` (UPSERT) do SQLite simplifica a lógica de inserir ou atualizar um RSVP.
*   **Reutilização de Helpers:** Funções helper para construir `ORDER BY` e `LIMIT/OFFSET` (como as do `FilesRepo`) devem ser generalizadas e movidas para um módulo utilitário comum se possível. Adaptei a chamada para `Deeper.Files.FilesRepo.build_order_clause` com uma lista de campos permitidos e um padrão para `deeper_events`.
*   **N+1 em Listagem:** Similar ao `ArticlesRepo`, a listagem de eventos e, em seguida, a busca de categorias para cada um pode levar a N+1. Para `list_events`, otimizações (como um segundo `IN` query para todas as categorias de todos os eventos listados) seriam necessárias para produção em larga escala.
*   **Filtros de Data:** O `list_events` inclui exemplos de como filtrar por eventos futuros (`upcoming`) e por intervalo de datas.

## 2. Módulo: `Deeper.Content.EventCategoriesRepo`

Este módulo lida com a tabela `deeper_event_categories`.

**Localização do Código Elixir:** `lib/deeper/content/event_categories_repo.ex`

### Notas para `EventCategoriesRepo`:
*   A funcionalidade é muito parecida com `ArticleCategoriesRepo`. Em um projeto real, você poderia considerar um módulo de Categoria genérico parametrizado pela tabela e colunas, ou simplesmente duplicar a lógica adaptada, que é mais simples para começar.

Com estes Repos, a camada de acesso a dados para o módulo de eventos está bem definida. O próximo passo lógico seria o `api_endpoints.md` para `deeper_events`.