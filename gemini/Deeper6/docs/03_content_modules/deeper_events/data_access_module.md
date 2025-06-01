# Documentação Deeper: Módulo de Acesso a Dados para Eventos (EventsRepo)

Este documento descreve o módulo Elixir `Deeper.Content.EventsRepo` (nome sugerido), responsável por encapsular toda a lógica de acesso ao banco de dados (SQLite) para as funcionalidades do módulo de Eventos.

Ele fornecerá funções para CRUD de eventos, gerenciamento de participantes, listagem de eventos com filtros e ordenação, e atualização de contadores.

## Módulo: `Deeper.Content.EventsRepo`

### Responsabilidades:

*   Criar, ler, atualizar e deletar entradas de eventos (`deeper_events_entries`).
*   Gerenciar categorias de eventos (`deeper_events_categories`).
*   Registrar e gerenciar a participação (RSVP) em eventos (`deeper_events_participants`).
*   Listar eventos com filtros (data, categoria, localização, status, etc.) e ordenação.
*   Atualizar contadores de interação (participantes, visualizações, etc.) na tabela `deeper_events_entries`.

### Estrutura de Dados Retornada (Exemplo para um Evento):

As funções que retornam detalhes de um evento podem retornar um mapa como:

```elixir
%{
  id: 1,
  author_profile_id: 10,
  author_fullname: \"Nome do Autor\", # Obtido com JOIN em sys_profiles e bx_persons_data
  category_id: 2,
  category_name: \"Tecnologia\", # Obtido com JOIN em deeper_events_categories
  title: \"Grande Evento de Elixir\",
  description: \"Uma descrição detalhada do evento...\",
  cover_image_url: \"/path/to/image.jpg\", # Resolvido a partir de cover_image_file_id
  event_url: \"https://example.com/elixir-event\",
  start_datetime: 1678886400, # Timestamp Unix UTC
  end_datetime: 1678893600,   # Timestamp Unix UTC
  timezone: \"America/Sao_Paulo\",
  location_type: \"physical\",
  location_venue_name: \"Centro de Convenções\",
  location_address: \"Rua Exemplo, 123\",
  # ... outros campos de localização ...
  max_participants: 100,
  allow_rsvp: 1,
  participants_count: 25,
  # ... outros contadores e campos ...
  status: \"active\",
  created_at: 1678800000,
  updated_at: 1678800000,
  # Informações de RSVP do usuário logado (se aplicável):
  current_user_rsvp_status: \"attending\" # ou nil se não houver RSVP
}
```

```elixir
defmodule Deeper.Content.EventsRepo do
  alias Deeper.Core.Data.Repo
  # Alias para outros Repos se necessário (ex: FilesRepo para cover_image_file_id)

  @doc \"\"\"
  Cria uma nova entrada de evento.
  `params` é um mapa com os dados do evento.
  Retorna {:ok, event_map} ou {:error, reason}.
  \"\"\"
  @spec create_event(map()) :: {:ok, map()} | {:error, any()}
  def create_event(params) do
    # Timestamps atuais para created_at e updated_at
    now = DateTime.utc_now() |> DateTime.to_unix()

    sql = \"\"\"
    INSERT INTO deeper_events_entries (
      author_profile_id, category_id, title, description, cover_image_file_id, event_url,
      start_datetime, end_datetime, timezone,
      location_type, location_venue_name, location_address, location_city, location_state, location_country, location_zip, location_lat, location_lng, location_online_url,
      max_participants, allow_rsvp, rsvp_deadline,
      status, visibility_group_id, featured,
      created_at, updated_at
    ) VALUES (
      ?, ?, ?, ?, ?, ?,
      ?, ?, ?,
      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
      ?, ?, ?,
      ?, ?, ?,
      ?, ?
    ) RETURNING *;
    \"\"\"
    # Nota: RETURNING * pode não ser suportado da mesma forma por todos os drivers/versões do SQLite via DBConnection.
    # Se não, será necessário um SELECT após o INSERT.
    # Alternativa: pegar o last_insert_rowid() e fazer um get_event(id)

    values = [
      params[:author_profile_id], params[:category_id], params[:title], params[:description], params[:cover_image_file_id], params[:event_url],
      params[:start_datetime], params[:end_datetime], params[:timezone],
      params[:location_type] || \"physical\", params[:location_venue_name], params[:location_address], params[:location_city], params[:location_state], params[:location_country], params[:location_zip], params[:location_lat], params[:location_lng], params[:location_online_url],
      params[:max_participants] || 0, params[:allow_rsvp] || 1, params[:rsvp_deadline],
      params[:status] || \"active\", params[:visibility_group_id] || \"3\", params[:featured] || 0,
      now, now
    ]

    case Repo.query(sql, values) do
      {:ok, %{rows: [event_map]}} -> {:ok, event_map} # Assumindo que Repo.query retorna mapas
      {:ok, %{num_rows: 1, last_insert_id: id}} -> get_event(id) # Se RETURNING * não funcionar como esperado
      {:error, reason} -> {:error, reason}
      _ -> {:error, :insert_failed}
    end
  end
```

```elixir
  @doc \"\"\"
  Busca um evento pelo seu ID, opcionalmente incluindo informações do autor e categoria.
  \"\"\"
  @spec get_event(integer(), keyword()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_event(id, opts \\\\ []) do
    # Opts pode incluir :current_profile_id para buscar o status de RSVP do usuário
    current_profile_id = Keyword.get(opts, :current_profile_id)

    # Base SQL
    select_fields = \"\"\"
    SELECT
      e.*,
      p.fullname AS author_fullname,  -- de bx_persons_data
      sa.name AS author_account_name, -- de sys_accounts
      c.name AS category_name,
      c.title_lang_key AS category_title_lang_key
      #{if current_profile_id, do: \", ep.rsvp_status AS current_user_rsvp_status\"}
    \"\"\"

    from_clause = \"\"\"
    FROM deeper_events_entries AS e
    JOIN sys_profiles AS sp ON e.author_profile_id = sp.id
    JOIN sys_accounts AS sa ON sp.account_id = sa.id
    -- Assumindo que bx_persons_data é a tabela de dados para perfis de autor
    JOIN bx_persons_data AS p ON sp.content_id = p.id AND sp.type = 'bx_persons'
    LEFT JOIN deeper_events_categories AS c ON e.category_id = c.id
    #{if current_profile_id, do: \"LEFT JOIN deeper_events_participants AS ep ON e.id = ep.event_id AND ep.profile_id = ?\"}
    \"\"\"

    where_clause = \"WHERE e.id = ?\"
    
    params = if current_profile_id, do: [current_profile_id, id], else: [id]

    sql = \"#{select_fields} #{from_clause} #{where_clause} LIMIT 1;\"

    case Repo.query(sql, params) do
      {:ok, %{rows: [event_map]}} -> {:ok, event_map}
      {:ok, %{rows: []}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end
```

```elixir
  @doc \"\"\"
  Lista eventos com base em filtros, ordenação e paginação.
  `filters` é um mapa como %{category_id: 1, status: \"active\", date_from: timestamp, date_to: timestamp, search_term: \"elixir\"}
  `pagination_opts` é um mapa como %{offset: 0, limit: 20}
  `order_opts` é um mapa como %{sort_by: \"start_datetime\", direction: \"asc\"}
  \"\"\"
  @spec list_events(map(), map(), map()) :: {:ok, %{data: [map()], total_items: integer()}} | {:error, any()}
  def list_events(filters \\\\ %{}, pagination_opts \\\\ %{}, order_opts \\\\ %{}) do
    select_base = \"\"\"
    SELECT
      e.id, e.title, e.start_datetime, e.end_datetime, e.location_city, e.location_venue_name,
      e.cover_image_file_id, e.status, e.participants_count,
      p.fullname AS author_fullname,
      c.name AS category_name
    \"\"\"
    # Adicionar mais campos conforme necessário para a visualização de lista

    from_base = \"\"\"
    FROM deeper_events_entries AS e
    JOIN sys_profiles AS sp ON e.author_profile_id = sp.id
    JOIN sys_accounts AS sa ON sp.account_id = sa.id
    JOIN bx_persons_data AS p ON sp.content_id = p.id AND sp.type = 'bx_persons'
    LEFT JOIN deeper_events_categories AS c ON e.category_id = c.id
    \"\"\"

    # --- Construir Cláusula WHERE ---
    {where_clause_sql, where_params} = build_event_list_where_clause(filters)

    # --- Construir Cláusula ORDER BY ---
    order_by_sql = build_event_list_order_by_clause(order_opts)

    # --- SQL para Contagem Total ---
    count_sql = \"SELECT COUNT(e.id) AS total #{from_base} #{where_clause_sql}\"

    # --- SQL para Dados Paginados ---
    limit = Map.get(pagination_opts, :limit, 20)
    offset = Map.get(pagination_opts, :offset, 0)
    data_sql = \"#{select_base} #{from_base} #{where_clause_sql} #{order_by_sql} LIMIT #{limit} OFFSET #{offset};\"

    # --- Executar Queries ---
    with {:ok, %{rows: [%{\"total\" => total_items}]}} <- Repo.query(count_sql, where_params),
         {:ok, %{rows: data_rows}} <- Repo.query(data_sql, where_params) do
      {:ok, %{data: data_rows, total_items: total_items}}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :query_failed}
    end
  end

  defp build_event_list_where_clause(filters) do
    clauses = [\"e.status != 'draft'\"] # Exemplo: não listar rascunhos por padrão
    values = []

    if category_id = Map.get(filters, :category_id) do
      clauses = clauses ++ [\"e.category_id = ?\"]
      values = values ++ [category_id]
    end

    if status = Map.get(filters, :status), status != \"\" do
      clauses = clauses ++ [\"e.status = ?\"]
      values = values ++ [status]
    end

    if date_from = Map.get(filters, :date_from) do # Timestamp
      clauses = clauses ++ [\"e.start_datetime >= ?\"]
      values = values ++ [date_from]
    end
    
    if date_to = Map.get(filters, :date_to) do # Timestamp
      clauses = clauses ++ [\"e.start_datetime <= ?\"] # Ou e.end_datetime, dependendo da lógica
      values = values ++ [date_to]
    end

    if search_term = Map.get(filters, :search_term), String.trim(search_term) != \"\" do
      clauses = clauses ++ [\"(e.title LIKE ? OR e.description LIKE ?)\"]
      values = values ++ [\"%#{search_term}%\", \"%#{search_term}%\"]
    end
    
    # Adicionar filtro por author_profile_id, localização, etc.

    if Enum.empty?(clauses) do
      {\"\", []}
    else
      where_sql = \"WHERE \" <> Enum.join(clauses, \" AND \")
      {where_sql, values}
    end
  end

  defp build_event_list_order_by_clause(order_opts) do
    sort_by = Map.get(order_opts, :sort_by, \"start_datetime\") # Campo padrão
    direction = Map.get(order_opts, :direction, \"asc\") |> String.upcase()

    # Validar campos e direção para segurança
    allowed_sort_fields = [\"start_datetime\", \"title\", \"created_at\", \"participants_count\"]
    allowed_directions = [\"ASC\", \"DESC\"]

    if Enum.member?(allowed_sort_fields, sort_by) && Enum.member?(allowed_directions, direction) do
      \"ORDER BY e.#{sort_by} #{direction}\"
    else
      \"ORDER BY e.start_datetime ASC\" # Fallback seguro
    end
  end
```

```elixir
  @spec update_event(integer(), map()) :: {:ok, map()} | {:error, any()}
  def update_event(event_id, params) do
    # Construir a cláusula SET dinamicamente com base nos `params` fornecidos.
    # Ex: \"SET title = ?, description = ?, updated_at = ?\"
    # Cuidado com SQL Injection nos nomes das colunas. Validar chaves de `params`.
    # Pegar `current_event_data <- get_event(event_id)` para verificar permissões (ex: autor).

    # Exemplo simplificado:
    now = DateTime.utc_now() |> DateTime.to_unix()
    sql = \"\"\"
    UPDATE deeper_events_entries
    SET title = ?, description = ?, start_datetime = ?, end_datetime = ?, updated_at = ?
    WHERE id = ?;
    \"\"\"
    # Adicionar todos os campos atualizáveis
    values = [
      Map.get(params, :title), Map.get(params, :description), 
      Map.get(params, :start_datetime), Map.get(params, :end_datetime), 
      now, event_id
    ]

    case Repo.execute(sql, values) do
      {:ok, %{num_rows: 1}} -> get_event(event_id) # Retorna o evento atualizado
      {:ok, %{num_rows: 0}} -> {:error, :not_found_or_not_changed}
      {:error, reason} -> {:error, reason}
    end
  end
```

```elixir
  @spec delete_event(integer()) :: :ok | {:error, any()}
  def delete_event(event_id) do
    # Verificar permissões antes de deletar.
    sql = \"DELETE FROM deeper_events_entries WHERE id = ?;\"
    case Repo.execute(sql, [event_id]) do
      {:ok, %{num_rows: 1}} -> :ok
      {:ok, %{num_rows: 0}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end
```

```elixir
  @spec rsvp_event(integer(), integer(), String.t()) :: :ok | {:error, any()}
  def rsvp_event(event_id, profile_id, rsvp_status) do
    # Validar rsvp_status contra ('attending', 'interested', 'not_attending')
    # Verificar se o evento permite RSVP e se o prazo não passou.
    # Obter o evento para verificar max_participants se rsvp_status == 'attending'.

    now = DateTime.utc_now() |> DateTime.to_unix()
    sql = \"\"\"
    INSERT INTO deeper_events_participants (event_id, profile_id, rsvp_status, added_at)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(event_id, profile_id) DO UPDATE SET
      rsvp_status = excluded.rsvp_status,
      added_at = excluded.added_at;
    \"\"\"
    # `excluded` é uma feature do SQLite para UPSERT.

    case Repo.execute(sql, [event_id, profile_id, rsvp_status, now]) do
      {:ok, _} ->
        # Atualizar contadores em deeper_events_entries
        update_event_rsvp_counts(event_id)
        :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc \"Lista participantes de um evento.\"
  @spec list_event_participants(integer(), map()) :: {:ok, %{data: [map()], total_items: integer()}} | {:error, any()}
  def list_event_participants(event_id, pagination_opts \\\\ %{}) do
    # Similar a list_events, mas buscando em deeper_events_participants
    # JOIN com sys_profiles e bx_persons_data para obter detalhes dos participantes
    # Ex: \"SELECT p.fullname, ep.rsvp_status, ep.added_at FROM deeper_events_participants ep JOIN ...\"
    # Implementar paginação.
    # ...
    {:ok, %{data: [], total_items: 0}} # Placeholder
  end
```

```elixir
  defp update_event_rsvp_counts(event_id) do
    # Esta função deve ser chamada atomicamente após um RSVP.
    # Idealmente, dentro de uma transação com a inserção/atualização do RSVP.

    # SQL para contar 'attending'
    count_attending_sql = \"SELECT COUNT(*) AS total FROM deeper_events_participants WHERE event_id = ? AND rsvp_status = 'attending';\"
    # SQL para contar 'interested'
    count_interested_sql = \"SELECT COUNT(*) AS total FROM deeper_events_participants WHERE event_id = ? AND rsvp_status = 'interested';\"

    with {:ok, %{rows: [%{\"total\" => attending_total}]}} <- Repo.query(count_attending_sql, [event_id]),
         {:ok, %{rows: [%{\"total\" => interested_total}]}} <- Repo.query(count_interested_sql, [event_id]) do
      
      update_counts_sql = \"\"\"
      UPDATE deeper_events_entries
      SET participants_count = ?, interested_count = ?, updated_at = ?
      WHERE id = ?;
      \"\"\"
      now = DateTime.utc_now() |> DateTime.to_unix()
      Repo.execute(update_counts_sql, [attending_total, interested_total, now, event_id])
      # Lidar com o resultado da atualização, se necessário
    else
      _err -> Logger.error(\"Falha ao atualizar contadores de RSVP para evento #{event_id}\")
    end
  end
```

```elixir
  @spec create_category(map()) :: {:ok, map()} | {:error, any()}
  def create_category(params) do
    sql = \"INSERT INTO deeper_events_categories (parent_id, name, title_lang_key, \\\"order\\\") VALUES (?, ?, ?, ?) RETURNING *;\"
    values = [params[:parent_id] || 0, params[:name], params[:title_lang_key], params[:order] || 0]
    # ... implementação similar a create_event ...
    {:ok, %{}} # Placeholder
  end

  @spec list_categories() :: {:ok, [map()]} | {:error, any()}
  def list_categories() do
    sql = \"SELECT * FROM deeper_events_categories ORDER BY \\\"order\\\" ASC, name ASC;\"
    # ... implementação ...
    {:ok, []} # Placeholder
  end
  # ... get_category(id), update_category(id, params), delete_category(id) ...
```

### Funções Principais (Exemplos):

**1. Criar Evento**

**2. Buscar Evento por ID**

**3. Listar Eventos (com Filtros e Paginação)**

**4. Atualizar Evento**

**5. Deletar Evento**

**6. Registrar Participação (RSVP)**

**7. Atualizar Contadores de RSVP (Interno)**

**8. Funções para Categorias (CRUD Simples)**

### Considerações Importantes:

*   **Transações:** Operações que modificam múltiplos registros ou que precisam ser atômicas (como registrar RSVP e atualizar contadores) devem ser envolvidas em transações (`Repo.transaction(...)` se o seu `Repo` suportar, ou gerenciamento manual com `BEGIN`/`COMMIT`/`ROLLBACK`).
*   **Mapeamento de Resultados:** As queries SQL retornam listas de tuplas ou mapas crus. É responsabilidade deste módulo (ou de funções auxiliares) mapear esses dados para structs Elixir bem definidas ou mapas consistentes, se desejado, antes de retorná-los.
*   **Segurança SQL:** Validar e sanitizar todos os inputs, especialmente aqueles usados para construir nomes de colunas dinamicamente (ex: em `ORDER BY`). Usar placeholders (`?`) para todos os valores.
*   **Performance:** Otimizar as queries SQL, especialmente para `list_events`, usando índices apropriados. A função `build_event_list_where_clause` e `build_event_list_order_by_clause` são cruciais.
*   **Abstração do `Repo`:** O exemplo assume um módulo `Deeper.Core.Data.Repo` com funções como `query/2` (para SELECTs) e `execute/2` (para INSERT/UPDATE/DELETE DDL). A assinatura exata e o formato de retorno dessas funções influenciarão a implementação.

Este módulo `EventsRepo` formará a espinha dorsal da lógica de negócios para o módulo de eventos, fornecendo uma interface clara para os controllers da API.