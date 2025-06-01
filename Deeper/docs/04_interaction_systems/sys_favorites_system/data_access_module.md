# Documentação Deeper: Módulo de Acesso a Dados para Favoritos (`FavoritesRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.FavoritesRepo`, responsável por interagir com a tabela `deeper_favorites_track` e por orquestrar a atualização dos contadores de favoritos nas tabelas das entidades principais (ex: `deeper_articles_entries.favorites_count`).

**Localização do Código:** `lib/deeper/interaction_systems/favorites_repo.ex`

```elixir
defmodule Deeper.InteractionSystems.FavoritesRepo do
  alias Deeper.Core.Data.Repo
  # Importar Repos dos módulos de conteúdo para atualizar seus contadores.
  # Ex: alias Deeper.Content.ArticlesRepo

  @doc \"\"\"
  Marca um objeto como favorito para um usuário.
  Incrementa o contador de favoritos na tabela da entidade principal.
  Retorna `:ok` ou `{:error, :already_favorited | any()}`.
  \"\"\"
  @spec add_favorite(
          system_name :: String.t(),
          object_id :: integer(),
          fan_profile_id :: integer()
        ) :: :ok | {:error, :already_favorited | any()}
  def add_favorite(system_name, object_id, fan_profile_id) do
    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    insert_sql = \"\"\"
    INSERT INTO deeper_favorites_track (system_name, object_id, fan_profile_id, favorited_at)
    VALUES (?, ?, ?, ?);
    \"\"\"
    # A constraint UNIQUE (system_name, object_id, fan_profile_id) impedirá duplicatas.

    Repo.transaction(fn ->
      case Repo.execute(insert_sql, [system_name, object_id, fan_profile_id, current_timestamp]) do
        {:ok, %{num_rows: 1}} -> # Inserido com sucesso
          update_entity_favorites_count(system_name, object_id, :increment)
          :ok
        {:ok, %{num_rows: 0}} -> # Não deveria acontecer com INSERT simples, a menos que ON CONFLICT IGNORE
           # Se usando INSERT OR IGNORE, e ignorou, significa que já existia.
           # Para INSERT direto, um erro de constraint é esperado se já existe.
           {:error, :already_favorited_or_failed} # Ajustar este caso
        {:error, reason} ->
          # Verificar se o erro é de constraint UNIQUE
          if is_constraint_error?(reason, \"UNIQUE constraint failed: deeper_favorites_track.system_name, deeper_favorites_track.object_id, deeper_favorites_track.fan_profile_id\") do
            Repo.rollback({:error, :already_favorited})
          else
            Repo.rollback({:error, reason})
          end
      end
    end)
  end

  @doc \"\"\"
  Remove um objeto da lista de favoritos de um usuário.
  Decrementa o contador de favoritos na tabela da entidade principal.
  Retorna `:ok` ou `{:error, :not_favorited | any()}`.
  \"\"\"
  @spec remove_favorite(
          system_name :: String.t(),
          object_id :: integer(),
          fan_profile_id :: integer()
        ) :: :ok | {:error, :not_favorited | any()}
  def remove_favorite(system_name, object_id, fan_profile_id) do
    delete_sql = \"\"\"
    DELETE FROM deeper_favorites_track
    WHERE system_name = ? AND object_id = ? AND fan_profile_id = ?;
    \"\"\"
    Repo.transaction(fn ->
      case Repo.execute(delete_sql, [system_name, object_id, fan_profile_id]) do
        {:ok, %{num_rows: 1}} -> # Removido com sucesso
          update_entity_favorites_count(system_name, object_id, :decrement)
          :ok
        {:ok, %{num_rows: 0}} -> # Nada foi removido, não estava favoritado
          Repo.rollback({:error, :not_favorited}) # Rollback para manter consistência se outras ops na tx
        {:error, reason} ->
          Repo.rollback({:error, reason})
      end
    end)
  end

  @doc \"Verifica se um usuário favoritou um objeto específico.\"
  @spec is_favorited?(
          system_name :: String.t(),
          object_id :: integer(),
          fan_profile_id :: integer()
        ) :: {:ok, boolean()} | {:error, any()}
  def is_favorited?(system_name, object_id, fan_profile_id) do
    sql = \"\"\"
    SELECT 1 FROM deeper_favorites_track
    WHERE system_name = ? AND object_id = ? AND fan_profile_id = ?
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [system_name, object_id, fan_profile_id]) do
      {:ok, %{rows: [_]}} -> {:ok, true}
      {:ok, %{rows: []}} -> {:ok, false}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc \"Conta quantos usuários favoritaram um objeto específico.\"
  @spec get_favorites_count_for_object(
          system_name :: String.t(),
          object_id :: integer()
        ) :: {:ok, integer()} | {:error, any()}
  def get_favorites_count_for_object(system_name, object_id) do
    sql = \"\"\"
    SELECT COUNT(id) as count
    FROM deeper_favorites_track
    WHERE system_name = ? AND object_id = ?;
    \"\"\"
    case Repo.query(sql, [system_name, object_id]) do
      {:ok, %{rows: [[count]], columns: _}} -> {:ok, count || 0}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc \"Lista os IDs dos objetos favoritados por um usuário para um determinado sistema, com paginação.\"
  @spec list_user_favorite_object_ids(
          fan_profile_id :: integer(),
          system_name :: String.t(),
          opts :: map()
        ) :: {:ok, {list(integer()), map()}} | {:error, any()}
  def list_user_favorite_object_ids(fan_profile_id, system_name, opts \\\\ %{}) do
    page = Map.get(opts, :page, 1)
    per_page = Map.get(opts, :per_page, 20)
    offset = (page - 1) * per_page

    data_sql = \"\"\"
    SELECT object_id
    FROM deeper_favorites_track
    WHERE fan_profile_id = ? AND system_name = ?
    ORDER BY favorited_at DESC
    LIMIT ? OFFSET ?;
    \"\"\"
    count_sql = \"\"\"
    SELECT COUNT(id) as total_count
    FROM deeper_favorites_track
    WHERE fan_profile_id = ? AND system_name = ?;
    \"\"\"
    params = [fan_profile_id, system_name]

    case Repo.query(count_sql, params) do
      {:ok, %{rows: [[total_count] | []], columns: _}} ->
        total_count_val = total_count || 0
        case Repo.query(data_sql, params ++ [per_page, offset]) do
          {:ok, %{rows: rows_data, columns: _data_columns}} ->
            object_ids = Enum.map(rows_data, fn [obj_id] -> obj_id end)
            pagination_meta = %{
              total_items: total_count_val,
              current_page: page,
              per_page: per_page,
              total_pages: if(total_count_val > 0, do: ceil(total_count_val / per_page), else: 0)
            }
            {:ok, {object_ids, pagination_meta}}
          err -> err
        end
      err -> err
    end
  end

  # --- Funções Auxiliares Internas ---

  @doc \"Incrementa ou decrementa o contador de favoritos na tabela da entidade principal.\"
  defp update_entity_favorites_count(system_name, object_id, :increment | :decrement = operation) do
    target_info =
      case system_name do
        \"deeper_articles_favorites\" -> %{table: \"deeper_articles_entries\", count_col: \"favorites_count\", id_col: \"id\"}
        \"bx_persons_profile_favorites\" -> %{table: \"bx_persons_data\", count_col: \"favorites\", id_col: \"id\"} # Usa 'favorites' do UNA
        # Adicionar outros system_names
        _ -> nil
      end

    if target_info do
      op_sql = if operation == :increment, do: \"+ 1\", else: \"- 1\"
      # Usar MAX(0, ...) para evitar contagens negativas se houver inconsistência.
      update_sql = \"\"\"
      UPDATE #{target_info.table}
      SET #{target_info.count_col} = MAX(0, #{target_info.count_col} #{op_sql})
      WHERE #{target_info.id_col} = ?;
      \"\"\"
      case Repo.execute(update_sql, [object_id]) do
        {:ok, _} -> :ok
        {:error, reason} ->
          Logger.error(\"Falha ao atualizar contador de favoritos para #{system_name}/#{object_id}: #{inspect(reason)}\", module: __MODULE__)
          {:error, reason} # Propaga o erro, mas a ação no track foi feita.
      end
    else
      Logger.warn(\"Mapeamento de system_name não encontrado para atualização de contador de favoritos: #{system_name}\", module: __MODULE__)
      :ok # Ação no track foi feita.
    end
  end

  # Função auxiliar para verificar erros de constraint (exemplo)
  # A implementação real depende de como o driver DBConnection/SQLite os reporta.
  defp is_constraint_error?(%DBConnection. φωτοError{sqlite_error_code: 19}, constraint_message_part) do
    # SQLite error code 19 é SQLITE_CONSTRAINT.
    # Precisaria inspecionar a mensagem de erro para a parte específica da constraint.
    # Ex: err.message |> String.contains?(constraint_message_part)
    # Isto é apenas um placeholder.
    true # Simular que encontrou
  end
  defp is_constraint_error?(_other_error, _constraint_message_part) do
    false
  end

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