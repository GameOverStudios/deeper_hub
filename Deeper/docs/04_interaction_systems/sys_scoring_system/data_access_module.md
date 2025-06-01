# Documentação Deeper: Módulo de Acesso a Dados para Pontuações (`ScoringRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.ScoringRepo`, responsável por interagir com a tabela `deeper_scores_track` e por orquestrar a atualização dos contadores de pontuação (`score_up_count`, `score_down_count`, `score_net`) nas tabelas das entidades principais.

**Localização do Código:** `lib/deeper/interaction_systems/scoring_repo.ex`

```elixir
defmodule Deeper.InteractionSystems.ScoringRepo do
  alias Deeper.Core.Data.Repo
  # Importar Repos dos módulos de conteúdo/comentários para atualizar seus contadores.
  # Ex: alias Deeper.Content.ArticlesRepo
  # Ex: alias Deeper.InteractionSystems.CommentsRepo (se scores forem em comentários)

  @doc \"\"\"
  Registra um voto de pontuação (upvote/downvote) para um objeto.
  Se o usuário já votou, o voto anterior é removido/ignorado e o novo é registrado.
  Se o usuário clica no mesmo tipo de voto novamente, o voto é removido (undo).
  Atualiza os contadores de score na tabela da entidade principal.
  \"\"\"
  @spec cast_score_vote(
          system_name :: String.t(),
          object_id :: integer(),
          voter_profile_id :: integer(),
          vote_type :: :up | :down, # ou String.t() \"up\" | \"down\"
          ip_address :: String.t() | nil
        ) :: {:ok, new_aggregates :: map()} | {:error, any()}
  def cast_score_vote(system_name, object_id, voter_profile_id, vote_type, ip_address \\\\ nil) do
    vote_type_str = to_string(vote_type) # Garante que é \"up\" ou \"down\"
    unless Enum.member?([\"up\", \"down\"], vote_type_str) do
      return {:error, :invalid_vote_type}
    end

    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    Repo.transaction(fn ->
      # 1. Verificar voto existente do usuário para este objeto
      existing_vote_sql = \"SELECT type FROM deeper_scores_track WHERE system_name = ? AND object_id = ? AND voter_profile_id = ? LIMIT 1\"
      existing_vote_type =
        case Repo.query(existing_vote_sql, [system_name, object_id, voter_profile_id]) do
          {:ok, %{rows: [[type]], columns: _}} -> type
          _ -> nil
        end

      cond do
        # Caso 1: Usuário clica no mesmo tipo de voto que já deu (remove o voto - undo)
        existing_vote_type == vote_type_str ->
          delete_sql = \"DELETE FROM deeper_scores_track WHERE system_name = ? AND object_id = ? AND voter_profile_id = ?\"
          case Repo.execute(delete_sql, [system_name, object_id, voter_profile_id]) do
            {:ok, _} -> update_entity_score_aggregates(system_name, object_id) # Recalcular após remoção
            err -> Repo.rollback(err)
          end

        # Caso 2: Usuário vota (novo voto ou muda voto existente)
        true -> # Inclui o caso de existing_vote_type ser nil ou diferente
          upsert_sql = \"\"\"
          INSERT INTO deeper_scores_track (system_name, object_id, voter_profile_id, type, voted_at, ip_address)
          VALUES (?, ?, ?, ?, ?, ?)
          ON CONFLICT(system_name, object_id, voter_profile_id) DO UPDATE SET
            type = excluded.type,
            voted_at = excluded.voted_at,
            ip_address = excluded.ip_address;
          \"\"\"
          case Repo.execute(upsert_sql, [system_name, object_id, voter_profile_id, vote_type_str, current_timestamp, ip_address]) do
            {:ok, _} -> update_entity_score_aggregates(system_name, object_id)
            err -> Repo.rollback(err)
          end
      end
    end)
  end

  @doc \"Busca o voto de score de um usuário específico para um objeto.\"
  @spec get_user_score_vote(
          system_name :: String.t(),
          object_id :: integer(),
          voter_profile_id :: integer()
        ) :: {:ok, %{type: String.t(), voted_at: integer()} | nil} | {:error, any()}
  def get_user_score_vote(system_name, object_id, voter_profile_id) do
    sql = \"\"\"
    SELECT type, voted_at
    FROM deeper_scores_track
    WHERE system_name = ? AND object_id = ? AND voter_profile_id = ?
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [system_name, object_id, voter_profile_id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:ok, nil} # Usuário não votou
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Busca os agregados de score (up_count, down_count, net_score) para um objeto.
  Esta função lê e calcula a partir de `deeper_scores_track`.
  \"\"\"
  @spec get_score_aggregates_for_object(
          system_name :: String.t(),
          object_id :: integer()
        ) :: {:ok, map()} | {:error, any()}
  def get_score_aggregates_for_object(system_name, object_id) do
    sql = \"\"\"
    SELECT
      SUM(CASE WHEN type = 'up' THEN 1 ELSE 0 END) as up_count,
      SUM(CASE WHEN type = 'down' THEN 1 ELSE 0 END) as down_count
    FROM deeper_scores_track
    WHERE system_name = ? AND object_id = ?;
    \"\"\"
    case Repo.query(sql, [system_name, object_id]) do
      {:ok, %{rows: [[up_raw, down_raw]], columns: _}} ->
        up_count = up_raw || 0
        down_count = down_raw || 0
        net_score = up_count - down_count
        {:ok, %{score_up_count: up_count, score_down_count: down_count, score_net: net_score}}
      {:error, reason} ->
        {:error, reason}
    end
  end


  # --- Funções Auxiliares Internas ---

  @doc \"\"\"
  Recalcula e atualiza os agregados de score na tabela da entidade principal.
  Retorna os novos agregados.
  \"\"\"
  defp update_entity_score_aggregates(system_name, object_id) do
    # 1. Obter os novos agregados de deeper_scores_track
    case get_score_aggregates_for_object(system_name, object_id) do
      {:ok, %{score_up_count: up, score_down_count: down, score_net: net_score} = aggregates} ->
        # 2. Determinar a tabela da entidade e as colunas a serem atualizadas
        target_info =
          case system_name do
            \"deeper_articles_score\" ->
              %{table: \"deeper_articles_entries\", up_col: \"score_up_count\", down_col: \"score_down_count\", net_col: \"score_net\", id_col: \"id\"}
            \"deeper_comments_score\" -> # Se comentários tiverem scores
              %{table: \"deeper_comments\", up_col: \"reactions_up\", down_col: \"reactions_down\", net_col: \"score\", id_col: \"id\"}
            \"bx_persons_profile_score\" -> # Se perfis tiverem scores (usando colunas do UNA)
              %{table: \"bx_persons_data\", up_col: \"sc_up\", down_col: \"sc_down\", net_col: \"score\", id_col: \"id\"}
            _ -> nil
          end

        if target_info do
          update_sql = \"\"\"
          UPDATE #{target_info.table}
          SET #{target_info.up_col} = ?,
              #{target_info.down_col} = ?,
              #{target_info.net_col} = ?
              #{if target_info.table == \"deeper_comments\" or target_info.table == \"deeper_articles_entries\", do: \", updated_at = #{DateTime.to_unix(DateTime.utc_now())}\" , else: \"\"}
          WHERE #{target_info.id_col} = ?;
          \"\"\"
          # Adicionar updated_at se a tabela da entidade tiver essa coluna e fizer sentido atualizá-la.
          params = [up, down, net_score, object_id]

          case Repo.execute(update_sql, params) do
            {:ok, _} -> {:ok, aggregates}
            {:error, update_reason} ->
              Logger.error(\"Falha ao atualizar agregados de score para #{system_name}/#{object_id}: #{inspect(update_reason)}\", module: __MODULE__)
              {:error, update_reason}
          end
        else
          Logger.warn(\"Mapeamento de system_name não encontrado para atualização de agregados de score: #{system_name}\", module: __MODULE__)
          {:ok, aggregates}
        end
      error_aggregates ->
        error_aggregates
    end
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