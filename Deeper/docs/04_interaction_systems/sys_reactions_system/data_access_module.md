# Documentação Deeper: Módulo de Acesso a Dados para Reações (`ReactionsRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.ReactionsRepo`, responsável por interagir com as tabelas do sistema de reações (`deeper_reactions_track`, opcionalmente `deeper_reaction_types` e `deeper_object_reactions_summary`) no banco de dados SQLite. Ele fornecerá funções para adicionar, alterar, remover reações e para buscar agregados de reações.

**Localização do Código:** `lib/deeper/interaction_systems/reactions_repo.ex`

```elixir
defmodule Deeper.InteractionSystems.ReactionsRepo do
  alias Deeper.Core.Data.Repo
  # Importar Repos dos módulos de conteúdo/comentários para atualizar seus contadores, se aplicável.

  @doc \"\"\"
  Adiciona ou altera a reação de um usuário a um objeto.
  Se o usuário já reagiu, a reação anterior é substituída.
  Se o usuário clica na mesma reação novamente, a reação é removida (undo).
  Atualiza os contadores de reações (seja na entidade principal ou em `deeper_object_reactions_summary`).
  \"\"\"
  @spec cast_reaction(
          system_name :: String.t(),
          object_id :: integer(),
          reactor_profile_id :: integer(),
          reaction_type_key :: String.t(), # Ex: \"like\", \"love\"
          ip_address :: String.t() | nil
        ) :: {:ok, new_aggregates :: map()} | {:error, any()}
  def cast_reaction(system_name, object_id, reactor_profile_id, reaction_type_key, ip_address \\\\ nil) do
    # TODO: Validar reaction_type_key contra uma lista de tipos permitidos
    # (seja de `deeper_reaction_types` ou uma lista fixa na aplicação).

    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    Repo.transaction(fn ->
      # 1. Verificar reação existente do usuário para este objeto
      existing_reaction_sql = \"SELECT reaction_type_key FROM deeper_reactions_track WHERE system_name = ? AND object_id = ? AND reactor_profile_id = ? LIMIT 1\"
      existing_reaction_key =
        case Repo.query(existing_reaction_sql, [system_name, object_id, reactor_profile_id]) do
          {:ok, %{rows: [[type_key]], columns: _}} -> type_key
          _ -> nil
        end

      cond do
        # Caso 1: Usuário clica na mesma reação que já deu (remove a reação - undo)
        existing_reaction_key == reaction_type_key ->
          delete_sql = \"DELETE FROM deeper_reactions_track WHERE system_name = ? AND object_id = ? AND reactor_profile_id = ?\"
          case Repo.execute(delete_sql, [system_name, object_id, reactor_profile_id]) do
            {:ok, _} -> update_entity_reaction_aggregates(system_name, object_id) # Recalcular após remoção
            err -> Repo.rollback(err)
          end

        # Caso 2: Usuário reage (nova reação ou muda reação existente)
        true -> # Inclui o caso de existing_reaction_key ser nil ou diferente
          upsert_sql = \"\"\"
          INSERT INTO deeper_reactions_track (system_name, object_id, reactor_profile_id, reaction_type_key, reacted_at, ip_address)
          VALUES (?, ?, ?, ?, ?, ?)
          ON CONFLICT(system_name, object_id, reactor_profile_id) DO UPDATE SET
            reaction_type_key = excluded.reaction_type_key,
            reacted_at = excluded.reacted_at,
            ip_address = excluded.ip_address;
          \"\"\"
          case Repo.execute(upsert_sql, [system_name, object_id, reactor_profile_id, reaction_type_key, current_timestamp, ip_address]) do
            {:ok, _} -> update_entity_reaction_aggregates(system_name, object_id)
            err -> Repo.rollback(err)
          end
      end
    end)
  end

  @doc \"Remove a reação de um usuário a um objeto específico.\"
  # Este é redundante se cast_reaction com o mesmo tipo já remove.
  # Mas pode ser útil se a UI tiver um botão explícito de \"Remover Reação\".
  @spec remove_reaction(
          system_name :: String.t(),
          object_id :: integer(),
          reactor_profile_id :: integer()
        ) :: {:ok, new_aggregates :: map()} | {:error, any()}
  def remove_reaction(system_name, object_id, reactor_profile_id) do
    delete_sql = \"\"\"
    DELETE FROM deeper_reactions_track
    WHERE system_name = ? AND object_id = ? AND reactor_profile_id = ?;
    \"\"\"
    Repo.transaction(fn ->
      case Repo.execute(delete_sql, [system_name, object_id, reactor_profile_id]) do
        {:ok, %{num_rows: 0}} -> # Nada foi removido, não havia reagido
          # Pode retornar {:error, :not_reacted} ou simplesmente os agregados atuais
          update_entity_reaction_aggregates(system_name, object_id) # Garante que agregados estão corretos
        {:ok, _results} ->
          update_entity_reaction_aggregates(system_name, object_id)
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc \"Busca a reação de um usuário específico para um objeto.\"
  @spec get_user_reaction(
          system_name :: String.t(),
          object_id :: integer(),
          reactor_profile_id :: integer()
        ) :: {:ok, %{reaction_type_key: String.t(), reacted_at: integer()} | nil} | {:error, any()}
  def get_user_reaction(system_name, object_id, reactor_profile_id) do
    sql = \"\"\"
    SELECT reaction_type_key, reacted_at
    FROM deeper_reactions_track
    WHERE system_name = ? AND object_id = ? AND reactor_profile_id = ?
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [system_name, object_id, reactor_profile_id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:ok, nil} # Usuário não reagiu
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Busca os agregados de reações (contagem por tipo) para um objeto.
  Retorna um mapa como %{\"like\" => 10, \"love\" => 5, \"total_reactions\" => 15}.
  \"\"\"
  @spec get_reaction_aggregates_for_object(
          system_name :: String.t(),
          object_id :: integer()
        ) :: {:ok, map()} | {:error, any()}
  def get_reaction_aggregates_for_object(system_name, object_id) do
    # Abordagem 1: Se usando a tabela deeper_object_reactions_summary
    # sql_summary = \"SELECT reaction_type_key, reaction_count FROM deeper_object_reactions_summary WHERE system_name = ? AND object_id = ?\"
    # ... e então processar ...

    # Abordagem 2: Calcular diretamente de deeper_reactions_track
    sql_track = \"\"\"
    SELECT reaction_type_key, COUNT(id) as count
    FROM deeper_reactions_track
    WHERE system_name = ? AND object_id = ?
    GROUP BY reaction_type_key;
    \"\"\"
    case Repo.query(sql_track, [system_name, object_id]) do
      {:ok, %{rows: rows_data, columns: _columns}} ->
        # rows_data será lista de [reaction_key, count]
        aggregates =
          Enum.reduce(rows_data, %{}, fn [key, count], acc ->
            Map.put(acc, key, count)
          end)

        total_reactions = Enum.sum(Map.values(aggregates))
        {:ok, Map.put(aggregates, \"total_reactions\", total_reactions)}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"(Opcional) Lista os tipos de reação disponíveis.\"
  @spec list_reaction_types() :: {:ok, list(map())} | {:error, any()}
  def list_reaction_types() do
    # Se usar a tabela deeper_reaction_types:
    # sql = \"SELECT reaction_key, title_lkey, icon_class, color_hex, \\\"order\\\" FROM deeper_reaction_types WHERE active = 1 ORDER BY \\\"order\\\" ASC\"
    # Repo.query(sql, []) ...
    # Se os tipos forem fixos na aplicação:
    fixed_types = [
      %{reaction_key: \"like\", title_lkey: \"_reaction_like\", icon_class: \"bxi-thumb-up\", is_positive: 1},
      %{reaction_key: \"love\", title_lkey: \"_reaction_love\", icon_class: \"bxi-heart\", is_positive: 1},
      %{reaction_key: \"haha\", title_lkey: \"_reaction_haha\", icon_class: \"bxi-happy\", is_positive: 1},
      %{reaction_key: \"wow\", title_lkey: \"_reaction_wow\", icon_class: \"bxi-surprised\", is_positive: 1},
      %{reaction_key: \"sad\", title_lkey: \"_reaction_sad\", icon_class: \"bxi-sad\", is_positive: 0},
      %{reaction_key: \"angry\", title_lkey: \"_reaction_angry\", icon_class: \"bxi-angry\", is_positive: -1}
    ]
    # O cliente usaria LocalizationRepo para traduzir title_lkey.
    {:ok, fixed_types}
  end


  # --- Funções Auxiliares Internas ---

  @doc \"\"\"
  Recalcula e atualiza os agregados de reações na tabela da entidade principal
  ou na tabela `deeper_object_reactions_summary`.
  Retorna os novos agregados.
  \"\"\"
  defp update_entity_reaction_aggregates(system_name, object_id) do
    # 1. Obter os novos agregados de deeper_reactions_track
    case get_reaction_aggregates_for_object(system_name, object_id) do
      {:ok, aggregates_map} -> # aggregates_map é %{\"like\" => N, \"love\" => M, \"total_reactions\" => T}
        # 2. Determinar como atualizar a entidade principal.
        #    Isto é complexo e depende da estratégia de armazenamento de agregados.

        # Estratégia A: Atualizar tabela `deeper_object_reactions_summary`
        # Para cada {reaction_key, count} em aggregates_map (exceto \"total_reactions\"):
        #   UPSERT INTO deeper_object_reactions_summary (system_name, object_id, reaction_type_key, reaction_count)
        #   VALUES (?, ?, ?, ?) ON CONFLICT DO UPDATE SET reaction_count = excluded.reaction_count;
        # Remover entradas de summary para reaction_type_keys que não estão mais em aggregates_map (count 0).
        # Exemplo:
        # existing_summary_keys_sql = \"SELECT reaction_type_key FROM deeper_object_reactions_summary WHERE system_name = ? AND object_id = ?\"
        # ... (lógica para encontrar chaves a remover e chaves a upsertar) ...

        # Estratégia B: Atualizar colunas separadas na tabela da entidade (ex: articles.reactions_like_count)
        target_info =
          case system_name do
            \"deeper_articles_reactions\" ->
              %{
                table: \"deeper_articles_entries\",
                # Mapeamento de reaction_key para nome da coluna de contagem
                count_cols_map: %{
                  \"like\" => \"reactions_like_count\",
                  \"love\" => \"reactions_love_count\"
                  # ... etc.
                },
                total_col: \"total_reactions_count\", # Coluna para contagem total de reações
                id_col: \"id\"
              }
            # Adicionar outros system_names
            _ -> nil
          end

        if target_info do
          set_parts = []
          set_values = []
          Enum.each(target_info.count_cols_map, fn {react_key, col_name} ->
            count = Map.get(aggregates_map, react_key, 0) # Default para 0 se a reação não existir
            set_parts = [\"#{col_name} = ?\"] ++ set_parts
            set_values = [count] ++ set_values
          end)
          # Adicionar total_reactions_count
          total_reactions = Map.get(aggregates_map, \"total_reactions\", 0)
          set_parts = [\"#{target_info.total_col} = ?\"] ++ set_parts
          set_values = [total_reactions] ++ set_values

          if Enum.any?(set_parts) do
            # Adicionar updated_at se a tabela da entidade tiver
            updated_at_timestamp = DateTime.to_unix(DateTime.utc_now())
            if has_updated_at_column?(target_info.table) do # Função hipotética
                set_parts = [\"updated_at = ?\"] ++ set_parts
                set_values = [updated_at_timestamp] ++ set_values
            end

            update_sql = \"UPDATE #{target_info.table} SET #{Enum.join(set_parts, \", \")} WHERE #{target_info.id_col} = ?;\"
            final_params = Enum.reverse(set_values) ++ [object_id]

            case Repo.execute(update_sql, final_params) do
              {:ok, _} -> {:ok, aggregates_map}
              {:error, update_reason} ->
                Logger.error(\"Falha ao atualizar agregados de reações para #{system_name}/#{object_id}: #{inspect(update_reason)}\", module: __MODULE__)
                {:error, update_reason}
            end
          else
            {:ok, aggregates_map} # Nada para atualizar nas colunas específicas
          end
        else
          Logger.warn(\"Mapeamento de system_name não encontrado para atualização de agregados de reações: #{system_name}\", module: __MODULE__)
          {:ok, aggregates_map}
        end
      error_aggregates ->
        error_aggregates
    end
  end

  # Função hipotética para verificar se uma tabela tem a coluna 'updated_at'
  # Na prática, isso seria conhecido pela estrutura da tabela.
  defp has_updated_at_column?(table_name) do
    Enum.member?([\"deeper_articles_entries\", \"deeper_comments\"], table_name)
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