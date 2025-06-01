# Documentação Deeper: Módulo de Acesso a Dados para Votos (`VotingRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.VotingRepo`, responsável por interagir com a tabela `deeper_votes_track` e por orquestrar a atualização dos contadores de votos e médias nas tabelas das entidades principais (ex: `deeper_articles_entries.article_votes_count`, `deeper_articles_entries.article_rate`).

**Localização do Código:** `lib/deeper/interaction_systems/voting_repo.ex`

```elixir
defmodule Deeper.InteractionSystems.VotingRepo do
  alias Deeper.Core.Data.Repo
  # Importar Repos dos módulos de conteúdo para atualizar seus contadores de votos.
  # Ex: alias Deeper.Content.ArticlesRepo

  @doc \"\"\"
  Registra ou atualiza um voto para um objeto específico.
  Atualiza os contadores de votos e a média na tabela da entidade principal.
  \"\"\"
  @spec cast_vote(
          system_name :: String.t(),
          object_id :: integer(),
          voter_profile_id :: integer(),
          value :: integer(),
          ip_address :: String.t() | nil
        ) :: {:ok, new_aggregates :: map()} | {:error, any()}
  def cast_vote(system_name, object_id, voter_profile_id, value, ip_address \\\\ nil) do
    # TODO: Validar 'value' contra MinValue/MaxValue configurado para este system_name
    # (essa configuração viria de sys_objects_vote ou uma configuração Deeper).
    # Por agora, assumimos que 'value' é válido (ex: 1-5).

    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    upsert_sql = \"\"\"
    INSERT INTO deeper_votes_track (system_name, object_id, voter_profile_id, value, voted_at, ip_address)
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(system_name, object_id, voter_profile_id) DO UPDATE SET
      value = excluded.value,
      voted_at = excluded.voted_at,
      ip_address = excluded.ip_address;
    \"\"\"
    # A lógica de ON CONFLICT atualiza o voto existente.

    Repo.transaction(fn ->
      case Repo.execute(upsert_sql, [system_name, object_id, voter_profile_id, value, current_timestamp, ip_address]) do
        {:ok, _results} ->
          # Após o voto ser registrado/atualizado, recalcular e atualizar agregados na entidade principal.
          update_entity_vote_aggregates(system_name, object_id)
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc \"\"\"
  Remove um voto de um objeto específico para um usuário.
  Atualiza os contadores de votos e a média na tabela da entidade principal.
  \"\"\"
  @spec remove_vote(
          system_name :: String.t(),
          object_id :: integer(),
          voter_profile_id :: integer()
        ) :: {:ok, new_aggregates :: map()} | {:error, any()}
  def remove_vote(system_name, object_id, voter_profile_id) do
    delete_sql = \"\"\"
    DELETE FROM deeper_votes_track
    WHERE system_name = ? AND object_id = ? AND voter_profile_id = ?;
    \"\"\"
    Repo.transaction(fn ->
      case Repo.execute(delete_sql, [system_name, object_id, voter_profile_id]) do
        {:ok, %{num_rows: 0}} -> # Nenhum voto encontrado para remover
          # Ainda assim, recalcular agregados pode ser uma boa ideia se houve inconsistência.
          # Ou simplesmente retornar :not_found ou :ok com os agregados atuais.
          # Por ora, vamos recalcular.
          update_entity_vote_aggregates(system_name, object_id)
        {:ok, _results} ->
          update_entity_vote_aggregates(system_name, object_id)
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc \"Busca o voto de um usuário específico para um objeto.\"
  @spec get_user_vote(
          system_name :: String.t(),
          object_id :: integer(),
          voter_profile_id :: integer()
        ) :: {:ok, map() | nil} | {:error, any()}
  def get_user_vote(system_name, object_id, voter_profile_id) do
    sql = \"\"\"
    SELECT value, voted_at
    FROM deeper_votes_track
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
  Busca os agregados de votos (contagem, soma, média) para um objeto.
  Esta função lê de `deeper_votes_track`. Os valores nas tabelas de entidade
  devem corresponder a isto se `update_entity_vote_aggregates` funcionar corretamente.
  \"\"\"
  @spec get_vote_aggregates_for_object(
          system_name :: String.t(),
          object_id :: integer()
        ) :: {:ok, map()} | {:error, any()}
  def get_vote_aggregates_for_object(system_name, object_id) do
    sql = \"\"\"
    SELECT
      COUNT(id) as votes_count,
      SUM(value) as votes_sum
    FROM deeper_votes_track
    WHERE system_name = ? AND object_id = ?;
    \"\"\"
    case Repo.query(sql, [system_name, object_id]) do
      {:ok, %{rows: [[count, sum]], columns: _}} ->
        # SQLite COUNT retorna 0 se não houver linhas, SUM retorna NULL.
        actual_count = count || 0
        actual_sum = sum || 0
        rate = if actual_count > 0, do: Float.round(actual_sum / actual_count, 2), else: 0.0

        {:ok, %{votes_count: actual_count, votes_sum: actual_sum, rate: rate}}
      {:error, reason} ->
        {:error, reason}
    end
  end


  # --- Funções Auxiliares Internas ---

  @doc \"\"\"
  Recalcula e atualiza os agregados de votos na tabela da entidade principal.
  Esta função precisa saber qual tabela de entidade e quais colunas atualizar
  baseado no `system_name`.
  Retorna os novos agregados.
  \"\"\"
  defp update_entity_vote_aggregates(system_name, object_id) do
    # 1. Obter os novos agregados de deeper_votes_track
    case get_vote_aggregates_for_object(system_name, object_id) do
      {:ok, %{votes_count: count, votes_sum: sum, rate: rate} = aggregates} ->
        # 2. Determinar a tabela da entidade e as colunas a serem atualizadas
        #    Esta lógica de mapeamento de system_name para tabela/colunas é crucial.
        #    Exemplo:
        target_info =
          case system_name do
            \"deeper_articles_rating\" ->
              %{
                table: \"deeper_articles_entries\",
                count_col: \"article_votes_count\",
                sum_col: \"article_votes_sum\",
                rate_col: \"article_rate\",
                id_col: \"id\"
              }
            \"bx_persons_profile_rating\" -> # Se bx_persons_data for adaptado
              %{
                table: \"bx_persons_data\",
                count_col: \"votes\", # Coluna 'votes' no UNA bx_persons_data
                sum_col: \"votes_sum_placeholder\", # bx_persons_data não tem 'sum' por padrão, precisaria ser adicionada
                rate_col: \"rate\", # Coluna 'rate' no UNA bx_persons_data
                id_col: \"id\"
              }
            # Adicionar outros system_names e seus mapeamentos
            _ ->
              nil # System_name não mapeado
          end

        if target_info do
          update_sql = \"\"\"
          UPDATE #{target_info.table}
          SET #{target_info.count_col} = ?,
              #{target_info.sum_col} = ?,   -- Se a coluna sum_col existir
              #{target_info.rate_col} = ?
          WHERE #{target_info.id_col} = ?;
          \"\"\"
          # Nota: Se a tabela da entidade não tiver uma coluna sum_col,
          # a query de update precisa ser ajustada.
          # Para o exemplo de bx_persons_data que SÓ tem 'votes' e 'rate':
          # O UNA recalcula rate baseado em 'sum' e 'count' de sua própria tabela sys_votes.
          # Se formos atualizar 'rate' diretamente, precisamos de 'sum' e 'count'.
          # A coluna 'votes' em bx_persons_data é a contagem.

          # Ajuste para bx_persons_data (se não adicionarmos votes_sum_placeholder):
          update_sql_final =
            if system_name == \"bx_persons_profile_rating\" do
              # Se bx_persons_data só tem `votes` (count) e `rate` (avg)
              \"UPDATE #{target_info.table} SET #{target_info.count_col} = ?, #{target_info.rate_col} = ? WHERE #{target_info.id_col} = ?\"
            else
              # Para sistemas com count, sum, e rate
              \"UPDATE #{target_info.table} SET #{target_info.count_col} = ?, #{target_info.sum_col} = ?, #{target_info.rate_col} = ? WHERE #{target_info.id_col} = ?\"
            end

          params_final =
            if system_name == \"bx_persons_profile_rating\" do
              [count, rate, object_id]
            else
              [count, sum, rate, object_id]
            end

          case Repo.execute(update_sql_final, params_final) do
            {:ok, _} -> {:ok, aggregates}
            {:error, update_reason} ->
              Logger.error(\"Falha ao atualizar agregados de votos para #{system_name}/#{object_id}: #{inspect(update_reason)}\", module: __MODULE__)
              {:error, update_reason} # Propaga o erro, mas o voto no track foi salvo.
          end
        else
          Logger.warn(\"Mapeamento de system_name não encontrado para atualização de agregados: #{system_name}\", module: __MODULE__)
          {:ok, aggregates} # Voto foi salvo no track, mas agregados não atualizados na entidade.
        end
      error_aggregates ->
        error_aggregates # Erro ao buscar os agregados
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