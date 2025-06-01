# Documentação Deeper: Módulo de Acesso a Dados para Denúncias (`ReportingRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.ReportingRepo`, responsável por interagir com as tabelas do sistema de denúncias (`deeper_reports_track` e opcionalmente `deeper_report_types`) no banco de dados SQLite. Ele fornecerá funções para criar denúncias, e (principalmente para uso de admin) listar e atualizar o status das denúncias.

**Localização do Código:** `lib/deeper/interaction_systems/reporting_repo.ex`

```elixir
defmodule Deeper.InteractionSystems.ReportingRepo do
  alias Deeper.Core.Data.Repo
  # alias Deeper.SystemCore.LocalizationRepo # Para buscar títulos de report_type_key
  # alias Deeper.SystemCore.ProfilesRepo # Para buscar detalhes do reporter/admin

  @doc \"Cria uma nova denúncia.\"
  @spec create_report(params :: map()) :: {:ok, map()} | {:error, :already_reported | any()}
  def create_report(params) do
    # params: :system_name, :object_id, :reporter_profile_id, :report_type_key, :comment (opc)
    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    sql = \"\"\"
    INSERT INTO deeper_reports_track (
      system_name, object_id, reporter_profile_id, report_type_key, comment,
      status, reported_at
    )
    VALUES (?, ?, ?, ?, ?, 'new', ?)
    RETURNING *;
    \"\"\"
    values = [
      params[:system_name],
      params[:object_id],
      params[:reporter_profile_id],
      params[:report_type_key], # Validar contra lista de tipos permitidos
      params[:comment],
      current_timestamp
    ]

    Repo.transaction(fn ->
      case Repo.query(sql, values) do
        {:ok, %{rows: [row_data], columns: columns}} ->
          report = map_row_to_generic_struct(row_data, columns)
          # Opcional: Incrementar contador de denúncias na entidade principal
          update_entity_reports_count(params[:system_name], params[:object_id], :increment)
          {:ok, report}
        {:error, reason} ->
          # Verificar se o erro é de constraint UNIQUE
          if is_constraint_error?(reason, \"UNIQUE constraint failed: deeper_reports_track.system_name, deeper_reports_track.object_id, deeper_reports_track.reporter_profile_id, deeper_reports_track.report_type_key\") do
            Repo.rollback({:error, :already_reported_this_type})
          else
            Repo.rollback({:error, reason})
          end
      end
    end)
  end

  @doc \"Verifica se um usuário já denunciou um objeto por um tipo específico.\"
  @spec has_user_reported_object_for_type?(
          system_name :: String.t(),
          object_id :: integer(),
          reporter_profile_id :: integer(),
          report_type_key :: String.t()
        ) :: {:ok, boolean()} | {:error, any()}
  def has_user_reported_object_for_type?(system_name, object_id, reporter_profile_id, report_type_key) do
    sql = \"\"\"
    SELECT 1 FROM deeper_reports_track
    WHERE system_name = ? AND object_id = ? AND reporter_profile_id = ? AND report_type_key = ?
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [system_name, object_id, reporter_profile_id, report_type_key]) do
      {:ok, %{rows: [_]}} -> {:ok, true}
      {:ok, %{rows: []}} -> {:ok, false}
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Funções principalmente para Administração ---

  @doc \"Busca uma denúncia pelo seu ID.\"
  @spec get_report_by_id(id :: integer(), opts :: keyword()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_report_by_id(id, opts \\\\ []) do
    # opts: [include_details: true] para JOIN com reporter, admin, tipo de denúncia
    base_sql = \"SELECT drt.*\"
    joins_sql = \"\"
    params_sql = [id]

    if Keyword.get(opts, :include_details, false) do
      base_sql = base_sql <> \"\"\"
      , rep_p.type as reporter_profile_type, rep_a.name as reporter_account_name, rep_pd.fullname as reporter_fullname
      , adm_p.type as admin_profile_type, adm_a.name as admin_account_name, adm_pd.fullname as admin_fullname
      \"\"\"
      # , drtype.title_lkey as report_type_title_lkey -- Se usar deeper_report_types
      joins_sql = joins_sql <> \"\"\"
       JOIN sys_profiles rep_p ON drt.reporter_profile_id = rep_p.id
       JOIN sys_accounts rep_a ON rep_p.account_id = rep_a.id
       LEFT JOIN bx_persons_data rep_pd ON rep_p.type = 'bx_persons' AND rep_p.content_id = rep_pd.id
       LEFT JOIN sys_profiles adm_p ON drt.checked_by_admin_profile_id = adm_p.id
       LEFT JOIN sys_accounts adm_a ON adm_p.account_id = adm_a.id
       LEFT JOIN bx_persons_data adm_pd ON adm_p.type = 'bx_persons' AND adm_p.content_id = adm_pd.id
      \"\"\"
      # LEFT JOIN deeper_report_types drtype ON drt.report_type_id = drtype.id -- Se usar
    end

    final_sql = \"#{base_sql} FROM deeper_reports_track drt #{joins_sql} WHERE drt.id = ? LIMIT 1;\"

    case Repo.query(final_sql, params_sql) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Atualiza o status e notas de uma denúncia (para uso de admin/moderador).\"
  @spec update_report_status(id :: integer(), admin_profile_id :: integer(), new_status :: String.t(), admin_notes :: String.t() | nil) :: {:ok, map()} | {:error, :not_found | any()}
  def update_report_status(id, admin_profile_id, new_status, admin_notes \\\\ nil) do
    # Validar new_status contra a lista permitida
    allowed_statuses = ['pending_review', 'acknowledged', 'resolved_action_taken', 'resolved_no_action', 'rejected']
    unless Enum.member?(allowed_statuses, new_status) do
      return {:error, :invalid_status}
    end

    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    sql = \"\"\"
    UPDATE deeper_reports_track
    SET status = ?, checked_by_admin_profile_id = ?, checked_at = ?, admin_notes = ?
    WHERE id = ?
    RETURNING *;
    \"\"\"
    params = [new_status, admin_profile_id, current_timestamp, admin_notes, id]

    Repo.transaction(fn ->
      # Buscar o status antigo para lógica de contagem
      {:ok, old_report} = get_report_by_id(id) # Assume que existe, ou tratar erro
      old_status = Map.get(old_report, \"status\") || Map.get(old_report, :status)

      case Repo.query(sql, params) do
        {:ok, %{rows: [row_data], columns: columns}} ->
          updated_report = map_row_to_generic_struct(row_data, columns)
          # Atualizar contador de denúncias ativas na entidade principal se o status mudou de/para 'new' ou 'pending_review'
          if new_status != old_status && (Enum.member?([\"new\", \"pending_review\"], old_status) || Enum.member?([\"new\", \"pending_review\"], new_status)) do
            system_name = Map.get(updated_report, \"system_name\") || Map.get(updated_report, :system_name)
            object_id = Map.get(updated_report, \"object_id\") || Map.get(updated_report, :object_id)
            # Esta chamada precisa recalcular denúncias ativas para o objeto
            recalculate_entity_active_reports_count(system_name, object_id)
          end
          {:ok, updated_report}
        {:ok, %{rows: []}} -> Repo.rollback({:error, :not_found}) # Não deveria acontecer com RETURNING
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end

  @doc \"Lista denúncias com paginação e filtros (para uso de admin/moderador).\"
  @spec list_reports(opts :: map()) :: {:ok, {list(map()), map()}} | {:error, any()}
  def list_reports(opts \\\\ %{}) do
    page = Map.get(opts, :page, 1)
    per_page = Map.get(opts, :per_page, 20)
    offset = (page - 1) * per_page

    # Filtros: :system_name, :object_id, :status, :reporter_profile_id, :report_type_key
    # Ordenação: :reported_at_desc (default), :reported_at_asc, :status_asc
    select_sql = \"SELECT drt.*\" # Adicionar JOINs para detalhes do reporter, admin, etc. se necessário para a lista
    from_sql = \"FROM deeper_reports_track drt\"
    # joins_sql = \"...\" (similar a get_report_by_id se include_details for uma opção)
    where_clauses = []
    query_params = []

    if status_filter = opts[:status], do: (
      where_clauses = [\"drt.status = ?\"] ++ where_clauses
      query_params = [status_filter] ++ query_params # Prepend para manter ordem com Enum.reverse depois
    )
    if system_filter = opts[:system_name], do: (
      where_clauses = [\"drt.system_name = ?\"] ++ where_clauses
      query_params = [system_filter] ++ query_params
    )
    # ... outros filtros ...

    where_sql = if Enum.empty?(where_clauses), do: \"\", else: \"WHERE \" <> Enum.join(Enum.reverse(where_clauses), \" AND \")

    order_map = %{
      \"reported_at_desc\" => \"drt.reported_at DESC\",
      \"reported_at_asc\" => \"drt.reported_at ASC\",
      \"status_asc\" => \"drt.status ASC, drt.reported_at DESC\" # Status e depois mais recente
    }
    sort_by_str = Map.get(opts, :sort_by, \"reported_at_desc\")
    order_sql = Map.get(order_map, sort_by_str, \"drt.reported_at DESC\")

    data_sql = \"#{select_sql} #{from_sql} #{where_sql} ORDER BY #{order_sql} LIMIT ? OFFSET ?;\"
    count_sql = \"SELECT COUNT(drt.id) as total_count #{from_sql} #{where_sql};\"

    final_data_query_params = Enum.reverse(query_params) ++ [per_page, offset]
    final_count_query_params = Enum.reverse(query_params)

    case Repo.query(count_sql, final_count_query_params) do
      {:ok, %{rows: [[total_count] | []], columns: _}} ->
        total_count_val = total_count || 0
        case Repo.query(data_sql, final_data_query_params) do
          {:ok, %{rows: rows_data, columns: data_columns}} ->
            reports = Enum.map(rows_data, &map_row_to_generic_struct(&1, data_columns))
            pagination_meta = %{
              total_items: total_count_val,
              current_page: page,
              per_page: per_page,
              total_pages: if(total_count_val > 0, do: ceil(total_count_val / per_page), else: 0)
            }
            {:ok, {reports, pagination_meta}}
          err -> err
        end
      err -> err
    end
  end

  @doc \"(Opcional) Lista os tipos de denúncia disponíveis.\"
  @spec list_report_types() :: {:ok, list(map())} | {:error, any()}
  def list_report_types() do
    # Se usar a tabela deeper_report_types:
    # sql = \"SELECT type_key, title_lkey FROM deeper_report_types WHERE active = 1 ORDER BY \\\"order\\\" ASC\"
    # Repo.query(sql, []) ...
    # Se os tipos forem fixos na aplicação:
    fixed_types = [
      %{type_key: \"spam\", title_lkey: \"_report_type_spam_title\"},
      %{type_key: \"harassment\", title_lkey: \"_report_type_harassment_title\"},
      %{type_key: \"inappropriate_content\", title_lkey: \"_report_type_inappropriate_content_title\"},
      %{type_key: \"copyright\", title_lkey: \"_report_type_copyright_title\"},
      %{type_key: \"other\", title_lkey: \"_report_type_other_title\"}
    ]
    # O cliente usaria LocalizationRepo para traduzir title_lkey.
    {:ok, fixed_types}
  end


  # --- Funções Auxiliares Internas ---
  defp update_entity_reports_count(system_name, object_id, :increment | :decrement = operation) do
    target_info =
      case system_name do
        \"deeper_articles_reports\" -> %{table: \"deeper_articles_entries\", count_col: \"reports_active_count\", id_col: \"id\"}
        \"bx_persons_profile_reports\" -> %{table: \"bx_persons_data\", count_col: \"reports\", id_col: \"id\"}
        _ -> nil
      end

    if target_info do
      op_sql = if operation == :increment, do: \"+ 1\", else: \"- 1\"
      update_sql = \"\"\"
      UPDATE #{target_info.table}
      SET #{target_info.count_col} = MAX(0, #{target_info.count_col} #{op_sql})
      WHERE #{target_info.id_col} = ?;
      \"\"\"
      Repo.execute(update_sql, [object_id]) # Ignorar resultado por simplicidade, mas logar erro.
    else
      :ok
    end
  end

  # Recalcula a contagem de denúncias ATIVAS (new, pending_review) para um objeto
  defp recalculate_entity_active_reports_count(system_name, object_id) do
    count_sql = \"\"\"
    SELECT COUNT(id) FROM deeper_reports_track
    WHERE system_name = ? AND object_id = ? AND status IN ('new', 'pending_review', 'acknowledged');
    \"\"\" # 'acknowledged' pode ou não contar como ativa dependendo da política.
    case Repo.query(count_sql, [system_name, object_id]) do
      {:ok, %{rows: [[active_count]], columns: _}} ->
        actual_active_count = active_count || 0
        target_info =
          case system_name do
            \"deeper_articles_reports\" -> %{table: \"deeper_articles_entries\", count_col: \"reports_active_count\", id_col: \"id\"}
            \"bx_persons_profile_reports\" -> %{table: \"bx_persons_data\", count_col: \"reports\", id_col: \"id\"}
            _ -> nil
          end
        if target_info do
          update_sql = \"UPDATE #{target_info.table} SET #{target_info.count_col} = ? WHERE #{target_info.id_col} = ?\"
          Repo.execute(update_sql, [actual_active_count, object_id])
        end
        :ok
      _ -> :ok # Falha ao recalcular, não quebrar a operação principal
    end
  end


  defp is_constraint_error?(%DBConnection. φωτοError{sqlite_error_code: 19}, constraint_message_part) do
    # Implementação placeholder
    true
  end
  defp is_constraint_error?(_other_error, _constraint_message_part), do: false

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