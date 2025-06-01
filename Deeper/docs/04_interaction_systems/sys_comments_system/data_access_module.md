# Documentação Deeper: Módulo de Acesso a Dados para Comentários (`CommentsRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.CommentsRepo`, responsável por interagir com as tabelas do sistema de comentários (`deeper_comments`, `deeper_comment_votes_track`) no banco de dados SQLite. Ele fornecerá funções para criar, ler, atualizar, deletar comentários e gerenciar votos/reações neles.

**Localização do Código:** `lib/deeper/interaction_systems/comments_repo.ex`

```elixir
defmodule Deeper.InteractionSystems.CommentsRepo do
  alias Deeper.Core.Data.Repo
  # Pode precisar do ProfilesRepo para buscar detalhes do autor para enriquecer os comentários
  # alias Deeper.SystemCore.ProfilesRepo

  @default_per_page 20

  # --- Funções CRUD para Comentários (deeper_comments) ---

  @doc \"\"\"
  Cria um novo comentário.
  Atualiza `replies_count` no comentário pai, se aplicável.
  \"\"\"
  @spec create_comment(params :: map()) :: {:ok, map()} | {:error, any()}
  def create_comment(params) do
    # params: :system_name, :object_id, :author_profile_id, :text
    #         :parent_id (opcional), :status (opcional, default 'active')
    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    parent_id = Map.get(params, :parent_id, 0)
    level = if parent_id == 0, do: 0, else: (get_comment_level(parent_id) + 1)

    sql = \"\"\"
    INSERT INTO deeper_comments (
      system_name, object_id, author_profile_id, parent_id, level, text, status,
      created_at, updated_at,
      votes, score, reactions_up, reactions_down, reports, replies_count
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, 0)
    RETURNING *;
    \"\"\"
    values = [
      params[:system_name],
      params[:object_id],
      params[:author_profile_id],
      parent_id,
      level,
      params[:text],
      params[:status] || \"active\",
      current_timestamp,
      current_timestamp
    ]

    # Usar transação para criar comentário e atualizar contagem de respostas no pai
    Repo.transaction(fn ->
      case Repo.query(sql, values) do
        {:ok, %{rows: [row_data], columns: columns}} ->
          comment = map_row_to_generic_struct(row_data, columns)
          # Se for uma resposta, incrementar replies_count do pai
          if parent_id != 0 do
            increment_replies_count(parent_id) # Ignora o resultado aqui, melhor tratar erro se houver
          end
          # TODO: Atualizar contagem de comentários na entidade principal (ex: articles.comments_count)
          # Isso pode ser feito aqui, por um trigger, ou por um \"serviço\" que é chamado.
          {:ok, comment}
        {:error, reason} ->
          Repo.rollback(reason) # Desfaz a transação
      end
    end)
  end

  @doc \"Busca um comentário pelo ID, opcionalmente com detalhes do autor.\"
  @spec get_comment_by_id(id :: integer(), opts :: keyword()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_comment_by_id(id, opts \\\\ []) do
    # opts: [include_author_details: true]
    base_sql = \"SELECT dc.*\"
    joins_sql = \"\"
    params_sql = [id]

    if Keyword.get(opts, :include_author_details, false) do
      # Exemplo de como buscar nome do autor. Na prática, pode ser mais complexo
      # para buscar o 'fullname' de bx_persons_data ou nome de organização.
      base_sql = base_sql <> \", p.type as author_profile_type, pa.name as author_account_name\"
      joins_sql = joins_sql <> \" JOIN sys_profiles p ON dc.author_profile_id = p.id JOIN sys_accounts pa ON p.account_id = pa.id\"
    end

    final_sql = \"#{base_sql} FROM deeper_comments dc #{joins_sql} WHERE dc.id = ? LIMIT 1;\"

    case Repo.query(final_sql, params_sql) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        comment = map_row_to_generic_struct(row_data, columns)
        # TODO: Adicionar informações de voto/reação do usuário atual, se logado.
        {:ok, comment}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Atualiza o texto ou status de um comentário.\"
  @spec update_comment(id :: integer(), params :: map()) :: {:ok, map()} | {:error, :not_found | any()}
  def update_comment(id, params) do
    # params pode conter :text e/ou :status
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    set_parts = []
    values = []

    if text = params[:text], do: (
      set_parts = [\"text = ?\"] ++ set_parts
      values = [text] ++ values
    )
    if status = params[:status], do: ( # Validar status contra a lista permitida
      set_parts = [\"status = ?\"] ++ set_parts
      values = [status] ++ values
    )

    if Enum.empty?(set_parts) do
      get_comment_by_id(id) # Nada para atualizar
    else
      set_clause = Enum.join(set_parts, \", \")
      sql = \"UPDATE deeper_comments SET #{set_clause}, updated_at = ? WHERE id = ? RETURNING *\"
      final_values = Enum.reverse(values) ++ [current_timestamp, id]

      case Repo.query(sql, final_values) do
        {:ok, %{rows: [row_data], columns: columns}} ->
          {:ok, map_row_to_generic_struct(row_data, columns)}
        {:ok, %{rows: []}} -> {:error, :not_found}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc \"\"\"
  Deleta um comentário (soft delete mudando status ou hard delete).
  Se hard delete e o comentário tiver respostas, elas também são deletadas (devido ao ON DELETE CASCADE na FK parent_id).
  Precisa decrementar `replies_count` no pai se este comentário for uma resposta.
  \"\"\"
  @spec delete_comment(id :: integer(), type :: :soft | :hard) :: :ok | {:error, :not_found | any()}
  def delete_comment(id, type \\\\ :soft) do
    # Primeiro, buscar o comentário para obter parent_id
    case get_comment_by_id(id) do
      {:ok, comment} ->
        Repo.transaction(fn ->
          op_result =
            case type do
              :soft ->
                # Determinar o status apropriado, ex: 'deleted_by_user' ou 'deleted_by_admin'
                update_comment(id, %{status: \"deleted_by_user\"})
              :hard ->
                sql = \"DELETE FROM deeper_comments WHERE id = ?\"
                Repo.execute(sql, [id])
            end

          case op_result do
            {:ok, _} ->
              parent_id = Map.get(comment, \"parent_id\") || Map.get(comment, :parent_id)
              if parent_id != 0 && parent_id != nil do
                decrement_replies_count(parent_id)
              end
              # TODO: Atualizar contagem de comentários na entidade principal
              :ok
            err -> Repo.rollback(err)
          end
        end)
      err -> err # Comentário não encontrado
    end
  end

  @doc \"Lista comentários para um objeto específico, com paginação e aninhamento (opcional).\"
  @spec list_comments(system_name :: String.t(), object_id :: integer(), opts :: map()) :: {:ok, {list(map()), map()}} | {:error, any()}
  def list_comments(system_name, object_id, opts \\\\ %{}) do
    # opts: :page, :per_page, :sort_by ('created_at_asc', 'created_at_desc', 'score_desc')
    #       :parent_id (para buscar respostas de um comentário específico, default 0 para raízes)
    #       :include_author_details (boolean)
    #       :current_user_profile_id (para marcar se o usuário votou/reagiu)
    page = Map.get(opts, :page, 1)
    per_page = Map.get(opts, :per_page, @default_per_page)
    offset = (page - 1) * per_page
    parent_id_filter = Map.get(opts, :parent_id, 0)

    # Ordenação
    # Validar sort_by e sort_dir
    sort_map = %{
      \"created_at_asc\" => \"dc.created_at ASC\",
      \"created_at_desc\" => \"dc.created_at DESC\",
      \"score_desc\" => \"dc.score DESC, dc.created_at DESC\"
    }
    sort_by_str = Map.get(opts, :sort_by, \"created_at_asc\")
    order_sql = Map.get(sort_map, sort_by_str, \"dc.created_at ASC\")


    # Construção da Query
    base_select = \"SELECT dc.*\"
    base_from = \"FROM deeper_comments dc\"
    joins = \"\"
    where_clauses = [\"dc.system_name = ?\", \"dc.object_id = ?\", \"dc.parent_id = ?\", \"dc.status = 'active'\"] # Apenas ativos por padrão
    query_params = [system_name, object_id, parent_id_filter]

    # Incluir detalhes do autor
    if Keyword.get(opts, :include_author_details, true) do # Default true para detalhes do autor
      # Exemplo simples, pode ser mais complexo para nome completo de bx_persons_data
      base_select = base_select <> \", p.type as author_profile_type, pa.name as author_account_name, pd.fullname as author_fullname, pd.picture as author_picture_id\"
      joins = joins <> \"\"\"
       JOIN sys_profiles p ON dc.author_profile_id = p.id
       JOIN sys_accounts pa ON p.account_id = pa.id
       LEFT JOIN bx_persons_data pd ON p.type = 'bx_persons' AND p.content_id = pd.id
      \"\"\"
      # Adicionar LEFT JOIN para outros tipos de perfil se necessário (ex: bx_organizations_data)
    end

    # TODO: Incluir se o usuário atual votou/reagiu (requer current_user_profile_id e JOIN com deeper_comment_votes_track)
    # Exemplo:
    # if current_user_id = opts[:current_user_profile_id] do
    #   base_select = base_select <> \", (SELECT dvt.value FROM deeper_comment_votes_track dvt WHERE dvt.comment_id = dc.id AND dvt.voter_profile_id = ? AND dvt.vote_type = 'score' LIMIT 1) as current_user_score_vote\"
    #   query_params = query_params ++ [current_user_id] # Adicionar no lugar certo
    # end

    where_sql = \"WHERE \" <> Enum.join(where_clauses, \" AND \")
    data_sql = \"#{base_select} #{base_from} #{joins} #{where_sql} ORDER BY #{order_sql} LIMIT ? OFFSET ?;\"
    count_sql = \"SELECT COUNT(dc.id) as total_count #{base_from} #{joins} #{where_sql};\" # JOINs necessários para filtros

    final_data_query_params = query_params ++ [per_page, offset]

    case Repo.query(count_sql, query_params) do
      {:ok, %{rows: [[total_count] | []], columns: _}} ->
        total_count_val = total_count || 0
        case Repo.query(data_sql, final_data_query_params) do
          {:ok, %{rows: rows_data, columns: data_columns}} ->
            comments = Enum.map(rows_data, &map_row_to_generic_struct(&1, data_columns))
            # Se for uma listagem hierárquica, precisaria de uma função para buscar todas as respostas recursivamente.
            # Esta função `list_comments` é mais para uma página de comentários (raiz ou respostas de um pai).
            # Para uma árvore completa, a lógica seria diferente (buscar todos e montar no Elixir).
            pagination_meta = %{
              total_items: total_count_val,
              current_page: page,
              per_page: per_page,
              total_pages: if(total_count_val > 0, do: ceil(total_count_val / per_page), else: 0)
            }
            {:ok, {comments, pagination_meta}}
          err -> err
        end
      err -> err
    end
  end


  # --- Funções para Votos/Reações em Comentários (deeper_comment_votes_track) ---

  @doc \"Registra um voto/reação em um comentário e atualiza os contadores do comentário.\"
  @spec vote_on_comment(comment_id :: integer(), voter_profile_id :: integer(), vote_type :: String.t(), value :: integer()) :: :ok | {:error, any()}
  def vote_on_comment(comment_id, voter_profile_id, vote_type, value) do
    # Validar vote_type e value
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    upsert_sql = \"\"\"
    INSERT INTO deeper_comment_votes_track (comment_id, voter_profile_id, vote_type, value, voted_at)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(comment_id, voter_profile_id, vote_type) DO UPDATE SET
      value = excluded.value,
      voted_at = excluded.voted_at;
    \"\"\"
    Repo.transaction(fn ->
      case Repo.execute(upsert_sql, [comment_id, voter_profile_id, vote_type, value, current_timestamp]) do
        {:ok, _} ->
          # Atualizar contadores em deeper_comments
          # Esta lógica pode ser complexa e depende se o voto é novo, uma mudança, ou remoção.
          # E se o sistema permite apenas um tipo de voto ou múltiplos.
          # Exemplo simplificado:
          update_comment_counters(comment_id)
          :ok
        err -> Repo.rollback(err)
      end
    end)
  end

  @doc \"Remove um voto/reação de um comentário.\"
  @spec unvote_comment(comment_id :: integer(), voter_profile_id :: integer(), vote_type :: String.t()) :: :ok | {:error, any()}
  def unvote_comment(comment_id, voter_profile_id, vote_type) do
    delete_sql = \"DELETE FROM deeper_comment_votes_track WHERE comment_id = ? AND voter_profile_id = ? AND vote_type = ?\"
    Repo.transaction(fn ->
      case Repo.execute(delete_sql, [comment_id, voter_profile_id, vote_type]) do
        {:ok, _} ->
          update_comment_counters(comment_id)
          :ok
        err -> Repo.rollback(err)
      end
    end)
  end

  @doc \"Busca os votos/reações de um usuário em um conjunto de IDs de comentários.\"
  @spec get_user_votes_for_comments(comment_ids :: list(integer()), voter_profile_id :: integer()) :: {:ok, map()} | {:error, any()}
  def get_user_votes_for_comments(comment_ids, voter_profile_id) when is_list(comment_ids) and length(comment_ids) > 0 do
    placeholders = Enum.map_join(comment_ids, \",\", fn _ -> \"?\" end)
    sql = \"\"\"
    SELECT comment_id, vote_type, value
    FROM deeper_comment_votes_track
    WHERE voter_profile_id = ? AND comment_id IN (#{placeholders});
    \"\"\"
    params = [voter_profile_id | comment_ids]
    case Repo.query(sql, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        # Agrupar por comment_id: %{comment_id => %{vote_type => value}}
        user_votes_map =
          Enum.reduce(rows, %{}, fn row_data, acc ->
            vote_map = map_row_to_generic_struct(row_data, cols)
            cid = Map.get(vote_map, \"comment_id\") || Map.get(vote_map, :comment_id)
            vtype = Map.get(vote_map, \"vote_type\") || Map.get(vote_map, :vote_type)
            val = Map.get(vote_map, \"value\") || Map.get(vote_map, :value)
            Map.update(acc, cid, %{vtype => val}, fn existing_votes -> Map.put(existing_votes, vtype, val) end)
          end)
        {:ok, user_votes_map}
      err -> err
    end
  end
  def get_user_votes_for_comments([], _voter_profile_id), do: {:ok, %{}}


  # --- Funções Auxiliares Internas ---
  defp get_comment_level(parent_id) do
    sql = \"SELECT level FROM deeper_comments WHERE id = ? LIMIT 1\"
    case Repo.query(sql, [parent_id]) do
      {:ok, %{rows: [[level]], columns: _}} -> level
      _ -> 0 # Default para 0 se pai não encontrado ou erro, resultando em nível 1 para a resposta
    end
  end

  defp increment_replies_count(comment_id) do
    sql = \"UPDATE deeper_comments SET replies_count = replies_count + 1, updated_at = ? WHERE id = ?\"
    Repo.execute(sql, [DateTime.to_unix(DateTime.utc_now()), comment_id])
  end

  defp decrement_replies_count(comment_id) do
    sql = \"UPDATE deeper_comments SET replies_count = MAX(0, replies_count - 1), updated_at = ? WHERE id = ?\"
    Repo.execute(sql, [DateTime.to_unix(DateTime.utc_now()), comment_id])
  end

  @doc \"Recalcula e atualiza os contadores de votos/score/reações para um comentário.\"
  # Esta função pode ser complexa dependendo da lógica exata de contagem.
  defp update_comment_counters(comment_id) do
    # Exemplo para recalcular 'votes' e 'score' baseado em 'deeper_comment_votes_track'
    # onde vote_type = 'score' e value = 1 (up) ou -1 (down)
    score_sql = \"\"\"
    SELECT
      SUM(CASE WHEN value = 1 THEN 1 ELSE 0 END) as up_votes,
      SUM(CASE WHEN value = -1 THEN 1 ELSE 0 END) as down_votes
    FROM deeper_comment_votes_track
    WHERE comment_id = ? AND vote_type = 'score';
    \"\"\"
    case Repo.query(score_sql, [comment_id]) do
      {:ok, %{rows: [[up_votes, down_votes]], columns: _}} ->
        up = up_votes || 0
        down = down_votes || 0
        total_votes = up + down
        net_score = up - down

        # Atualizar outros contadores de reações de forma similar se necessário
        # Ex: COUNT(*) WHERE vote_type = 'reaction' AND value = (ID da reação 'like')

        update_sql = \"UPDATE deeper_comments SET votes = ?, score = ?, reactions_up = ?, reactions_down = ?, updated_at = ? WHERE id = ?\"
        Repo.execute(update_sql, [total_votes, net_score, up, down, DateTime.to_unix(DateTime.utc_now()), comment_id])
      _ ->
        # Erro ao buscar contagens, logar ou tratar
        :ok # Não falhar a operação principal por causa da atualização do contador, mas logar
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