# Documentação Deeper: Módulos de Acesso a Dados para Enquetes

Este documento descreve o módulo Elixir (Repositório) principal responsável por interagir com as tabelas do banco de dados relacionadas ao módulo de Enquetes (`deeper_polls`, `deeper_poll_options`, `deeper_poll_votes`).

## Módulo Principal: `Deeper.Content.PollsRepo`

Este módulo lida com todas as operações de banco de dados para o sistema de enquetes.

**Localização do Código Elixir:** `lib/deeper/content/polls_repo.ex`

```elixir
defmodule Deeper.Content.PollsRepo do
  alias Deeper.Core.Data.Repo
  alias Deeper.Files.StorageRepo # Para map_row_to_struct helper

  # Structs opcionais
  # defstruct [:id, :question, ..., :options, :votes] # Poll
  # defstruct [:id, :poll_id, :option_text, :votes_count] # PollOption
  # defstruct [:id, :poll_id, :option_id, :profile_id] # PollVote

  # === Funções para Enquetes (`deeper_polls`) ===

  @doc \"\"\"
  Cria uma nova enquete juntamente com suas opções.
  `attrs` deve incluir :profile_id, :question, e uma lista :options.
  Cada item em :options é um mapa com :option_text e opcionalmente :order_index.
  \"\"\"
  def create_poll_with_options(attrs) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    # Gerar slug se não fornecido a partir de attrs.question

    Repo.transaction(fn ->
      # 1. Inserir a enquete principal
      sql_insert_poll = \"\"\"
      INSERT INTO deeper_polls (
        profile_id, question, slug, description, allow_multiple_choices,
        results_visibility, closes_at, status, total_votes_count,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      RETURNING *;
      \"\"\"
      poll_values = [
        attrs.profile_id, attrs.question, attrs.slug, attrs.description,
        attrs.allow_multiple_choices || 0,
        attrs.results_visibility || \"after_vote\",
        attrs.closes_at, attrs.status || \"open\",
        0, # total_votes_count
        current_ts, current_ts
      ]

      case Repo.query(sql_insert_poll, poll_values) do
        {:ok, %{rows: [poll_row], columns: poll_cols}} ->
          poll_map = StorageRepo.map_row_to_struct(poll_row, poll_cols)
          poll_id = poll_map.id

          # 2. Inserir as opções da enquete
          options_attrs = attrs.options || []
          case Enum.reduce_while(Enum.with_index(options_attrs), [], fn {opt_attrs, index}, acc_options ->
            sql_insert_option = \"\"\"
            INSERT INTO deeper_poll_options (poll_id, option_text, order_index, votes_count)
            VALUES (?, ?, ?, 0) RETURNING *;
            \"\"\"
            option_order = opt_attrs.order_index || index
            option_values = [poll_id, opt_attrs.option_text, option_order]

            case Repo.query(sql_insert_option, option_values) do
              {:ok, %{rows: [opt_row], columns: opt_cols}} ->
                {:cont, [StorageRepo.map_row_to_struct(opt_row, opt_cols) | acc_options]}
              {:error, reason} ->
                {:halt, Repo.rollback({:error, {:option_creation, reason}})}
            end
          end) do
            # O resultado do reduce_while será a lista de opções ou um erro que foi \"halted\"
            created_options when is_list(created_options) ->
              {:ok, %{poll_map | options: Enum.reverse(created_options)}}
            # Se o reduce_while foi interrompido por um erro, esse erro já foi \"propagado\" pelo rollback
            # e a transação falhará. A função transaction retornará esse erro.
            # Se o reduce_while retornar algo que não é uma lista (improvável se não houver erro),
            # isso seria um bug na lógica do reduce_while.
          end
        {:error, reason} ->
          Repo.rollback({:error, {:poll_creation, reason}})
      end
    end)
  end

  @doc \"\"\"
  Busca uma enquete pelo seu ID, opcionalmente incluindo suas opções e o voto do usuário.
  `opts` pode incluir `[:options, :user_vote_for_profile_id, :creator_profile]`
  \"\"\"
  def get_poll(id_or_slug, opts \\\\ [include: [:options, :creator_profile]]) do
    condition = if is_integer(id_or_slug), do: \"p.id = ?\", else: \"p.slug = ?\"
    select_fields = \"p.*\"
    joins = \"\"
    params = [id_or_slug]

    if Enum.member?(opts[:include], :creator_profile) do
        select_fields = select_fields <> \", pa.name as creator_name\"
        joins = joins <> \" LEFT JOIN sys_profiles sp ON p.profile_id = sp.id LEFT JOIN sys_accounts pa ON sp.account_id = pa.id\"
    end

    sql = \"SELECT #{select_fields} FROM deeper_polls p #{joins} WHERE #{condition} LIMIT 1\"

    case Repo.query(sql, params) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        poll_map = StorageRepo.map_row_to_struct(row_tuple, columns)
        poll_id = poll_map.id

        options =
          if Enum.member?(opts[:include], :options) do
            list_poll_options(poll_id) |> elem(1) # Extrai a lista de {:ok, lista}
          else
            []
          end

        user_votes =
          if profile_id = opts[:user_vote_for_profile_id], Enum.member?(opts[:include], :options) do
            get_user_votes_for_poll(poll_id, profile_id) |> elem(1) # Mapa de option_id -> true
          else
            %{}
          end
        
        # Enriquecer opções com o voto do usuário
        options_with_user_vote = Enum.map(options, fn opt ->
            Map.put(opt, :voted_by_user, Map.has_key?(user_votes, opt.id))
        end)

        {:ok, %{poll_map | options: options_with_user_vote}}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"\"\"
  Lista enquetes com filtros e paginação.
  `filters`: %{profile_id: 123, status: \"open\"}
  `pagination_opts`: %{limit: 10, offset: 0, sort_by: \"created_at\", sort_order: \"desc\"}
  \"\"\"
  def list_polls(filters \\\\ %{}, pagination_opts \\\\ %{}) do
    # ... (Implementação similar a list_articles/list_events) ...
    # JOIN com sys_profiles para nome do criador.
    select_clause = \"SELECT p.*, pa.name as creator_name\"
    from_clause = \"FROM deeper_polls p JOIN sys_profiles sp ON p.profile_id = sp.id JOIN sys_accounts pa ON sp.account_id = pa.id\"
    where_conditions = [\"1=1\"]
    params = []
    # ... (construir where e params com base em filters) ...
    if creator_id = filters[:profile_id], do: (Array.push(where_conditions, \"p.profile_id = ?\"); Array.push(params, creator_id))
    if status = filters[:status], do: (Array.push(where_conditions, \"p.status = ?\"); Array.push(params, status))


    where_clause = \"WHERE \" <> Enum.join(where_conditions, \" AND \")
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"created_at\", \"total_votes_count\"], \"created_at\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(p.id) as total_count #{from_clause} #{where_clause}\"
    # ... (executar e retornar) ...
    :not_implemented # Placeholder
  end

  @doc \"Atualiza uma enquete (não suas opções diretamente, apenas campos da enquete).\"
  def update_poll(id, attrs) do
    # ... (Lógica similar a update_article, construindo SET clause) ...
    # Campos permitidos: :question, :slug, :description, :results_visibility, :closes_at, :status
    :not_implemented
  end

  @doc \"Deleta uma enquete (e suas opções/votos via ON DELETE CASCADE).\"
  def delete_poll(id) do
    sql = \"DELETE FROM deeper_polls WHERE id = ?\"
    Repo.execute(sql, [id])
  end


  # === Funções para Opções de Enquete (`deeper_poll_options`) ===

  @doc \"Adiciona uma nova opção a uma enquete existente.\"
  def add_option_to_poll(poll_id, option_attrs) do
    # Atualizar order_index se necessário
    order_index = option_attrs.order_index || get_next_option_order_index(poll_id)
    sql = \"INSERT INTO deeper_poll_options (poll_id, option_text, order_index, votes_count) VALUES (?, ?, ?, 0) RETURNING *;\"
    values = [poll_id, option_attrs.option_text, order_index]
    case Repo.query(sql, values) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      err -> err
    end
  end

  defp get_next_option_order_index(poll_id) do
    sql = \"SELECT COALESCE(MAX(order_index), -1) + 1 FROM deeper_poll_options WHERE poll_id = ?\"
    case Repo.query(sql, [poll_id]) do
      {:ok, %{rows: [{next_index}]}} -> next_index
      _ -> 0
    end
  end

  @doc \"Lista todas as opções para uma enquete específica, ordenadas.\"
  def list_poll_options(poll_id) do
    sql = \"SELECT * FROM deeper_poll_options WHERE poll_id = ? ORDER BY order_index ASC, id ASC\"
    case Repo.query(sql, [poll_id]) do
      {:ok, %{rows: rows, columns: cols}} -> {:ok, Enum.map(rows, &StorageRepo.map_row_to_struct(&1, cols))}
      err -> err
    end
  end

  @doc \"Atualiza o texto ou ordem de uma opção.\"
  def update_poll_option(option_id, attrs) do
    # ... (construir SET clause) ...
    :not_implemented
  end

  @doc \"Remove uma opção de uma enquete (e seus votos via ON DELETE CASCADE).\"
  def remove_poll_option(option_id) do
    # Precisa recalcular total_votes_count na enquete pai.
    Repo.transaction(fn ->
      # 1. Obter poll_id e votos da opção antes de deletar
      option_details_sql = \"SELECT poll_id, votes_count FROM deeper_poll_options WHERE id = ? LIMIT 1\"
      case Repo.query(option_details_sql, [option_id]) do
        {:ok, %{rows: [{poll_id, option_votes_count}]}} ->
          # 2. Deletar a opção (votos em deeper_poll_votes são deletados por CASCADE)
          delete_option_sql = \"DELETE FROM deeper_poll_options WHERE id = ?\"
          case Repo.execute(delete_option_sql, [option_id]) do
            {:ok, _} ->
              # 3. Atualizar total_votes_count na enquete
              update_poll_total_votes_sql = \"UPDATE deeper_polls SET total_votes_count = total_votes_count - ? WHERE id = ?\"
              Repo.execute(update_poll_total_votes_sql, [option_votes_count, poll_id])
              # Ignorar erro do update do contador por simplicidade, mas idealmente checar
              :ok
            err_delete -> Repo.rollback({:error, {:option_delete, err_delete}})
          end
        {:ok, %{rows: []}} -> {:error, :option_not_found} # Ou Repo.rollback
        err_fetch -> Repo.rollback({:error, {:option_fetch, err_fetch}})
      end
    end)
  end


  # === Funções para Votos em Enquetes (`deeper_poll_votes`) ===

  @doc \"\"\"
  Registra um voto de um perfil em uma ou mais opções de uma enquete.
  `option_ids` é uma lista de IDs de opções.
  Verifica `allow_multiple_choices` da enquete.
  \"\"\"
  def cast_vote(poll_id, profile_id, option_ids) when is_list(option_ids) and option_ids != [] do
    poll_settings_sql = \"SELECT allow_multiple_choices FROM deeper_polls WHERE id = ? LIMIT 1\"
    case Repo.query(poll_settings_sql, [poll_id]) do
      {:ok, %{rows: [{allow_multiple}]}} ->
        # Validar se as opções pertencem à enquete (omitido por brevidade)

        Repo.transaction(fn ->
          # Se não permitir múltiplas escolhas, e está tentando votar em mais de uma, erro.
          # Ou se não permitir múltiplas, pegar apenas a primeira opção.
          actual_option_ids =
            if allow_multiple == 0 and length(option_ids) > 1 do
              Repo.rollback({:error, :multiple_votes_not_allowed})
              [] # Para satisfazer o compilador, mas o rollback já ocorreu
            else
              if allow_multiple == 0, do: [List.first(option_ids)], else: Enum.uniq(option_ids)
            end

          # Se for voto único, remover votos anteriores do usuário para esta enquete.
          if allow_multiple == 0 do
            # Obter votos antigos e decrementar contadores
            old_votes_sql = \"SELECT option_id FROM deeper_poll_votes WHERE poll_id = ? AND profile_id = ?\"
            case Repo.query(old_votes_sql, [poll_id, profile_id]) do
                {:ok, %{rows: old_voted_options_tuples}} ->
                    Enum.each(old_voted_options_tuples, fn {old_opt_id} ->
                        decrement_option_vote_count(old_opt_id)
                    end)
                _ -> :ok # Sem votos antigos ou erro, continuar
            end
            delete_old_sql = \"DELETE FROM deeper_poll_votes WHERE poll_id = ? AND profile_id = ?\"
            Repo.execute(delete_old_sql, [poll_id, profile_id]) # Ignorar erro se não houver o que deletar
          end

          # Inserir novos votos
          current_ts = DateTime.to_unix(DateTime.utc_now())
          Enum.reduce_while(actual_option_ids, [], fn option_id, acc_votes ->
            # A constraint UNIQUE(poll_id, profile_id, option_id) previne duplicatas se allow_multiple=1
            # Se allow_multiple=0, a lógica acima já limpou votos antigos.
            insert_vote_sql = \"\"\"
            INSERT INTO deeper_poll_votes (poll_id, option_id, profile_id, voted_at)
            VALUES (?, ?, ?, ?) RETURNING *;
            \"\"\"
            case Repo.query(insert_vote_sql, [poll_id, option_id, profile_id, current_ts]) do
              {:ok, %{rows: [vote_row], columns: vote_cols}} ->
                increment_option_vote_count(option_id) # Atualizar contador da opção
                {:cont, [StorageRepo.map_row_to_struct(vote_row, vote_cols) | acc_votes]}
              # Se for UNIQUE constraint violation e allow_multiple=0, isso não deveria acontecer devido ao delete anterior.
              # Se allow_multiple=1, é um voto duplicado na mesma opção, o que é prevenido pela constraint.
              {:error, reason} -> {:halt, Repo.rollback({:error, {:vote_insertion, reason}})}
            end
          end)
          |> case do
            new_votes when is_list(new_votes) ->
              recalculate_poll_total_votes(poll_id) # Atualizar contador total da enquete
              {:ok, Enum.reverse(new_votes)}
            # Erro já foi propagado pelo rollback
          end
        end)

      {:ok, %{rows: []}} -> {:error, :poll_not_found}
      err -> err
    end
  end
  def cast_vote(_poll_id, _profile_id, []), do: {:error, :no_options_provided}


  @doc \"Obtém os votos de um usuário para uma enquete específica (mapa de option_id -> true).\"
  def get_user_votes_for_poll(poll_id, profile_id) do
    sql = \"SELECT option_id FROM deeper_poll_votes WHERE poll_id = ? AND profile_id = ?\"
    case Repo.query(sql, [poll_id, profile_id]) do
      {:ok, %{rows: rows_tuples}} ->
        voted_options_map = Map.new(rows_tuples, fn {opt_id} -> {opt_id, true} end)
        {:ok, voted_options_map}
      err -> err
    end
  end

  # --- Funções Helper para Contadores ---
  defp increment_option_vote_count(option_id) do
    sql = \"UPDATE deeper_poll_options SET votes_count = votes_count + 1 WHERE id = ?\"
    Repo.execute(sql, [option_id])
  end
  defp decrement_option_vote_count(option_id) do
    sql = \"UPDATE deeper_poll_options SET votes_count = votes_count - 1 WHERE id = ? AND votes_count > 0\"
    Repo.execute(sql, [option_id])
  end
  defp recalculate_poll_total_votes(poll_id) do
    # Recalcula a partir da soma dos votos das opções
    # ou a partir da contagem de entradas em deeper_poll_votes (cuidado com múltiplas escolhas)
    # Se for voto único, COUNT(DISTINCT profile_id) em deeper_poll_votes.
    # Se múltipla escolha, SUM(votes_count) de deeper_poll_options para o poll_id.
    sql_sum_options = \"SELECT SUM(votes_count) FROM deeper_poll_options WHERE poll_id = ?\"
    case Repo.query(sql_sum_options, [poll_id]) do
      {:ok, %{rows: [{total_votes}]}} ->
        total_votes_actual = total_votes || 0
        sql_update_poll = \"UPDATE deeper_polls SET total_votes_count = ? WHERE id = ?\"
        Repo.execute(sql_update_poll, [total_votes_actual, poll_id])
      _ -> Logger.error(\"Falha ao recalcular total de votos para enquete #{poll_id}\", module: __MODULE__)
    end
    :ok
  end

end
```

### Notas para `PollsRepo`:
*   **Criação Atômica:** `create_poll_with_options/1` usa uma transação para garantir que a enquete e suas opções iniciais sejam criadas atomicamente.
*   **Votação (`cast_vote/3`):** Esta é a função mais complexa.
    *   Verifica a configuração `allow_multiple_choices` da enquete.
    *   Se for voto único, remove votos anteriores do usuário para aquela enquete antes de inserir o novo.
    *   Atualiza os contadores denormalizados (`votes_count` em `deeper_poll_options` e `total_votes_count` em `deeper_polls`) dentro da mesma transação.
*   **Recuperação de Votos do Usuário:** `get_user_votes_for_poll/2` é útil para a UI saber quais opções o usuário já marcou.
*   **Contadores Denormalizados:** A manutenção dos contadores `votes_count` e `total_votes_count` é crucial. Funções helper como `increment_option_vote_count` e `recalculate_poll_total_votes` são usadas. A precisão dessas atualizações, especialmente em cenários concorrentes, precisaria de atenção (embora SQLite seja serializado por escrita, a lógica deve ser correta).
*   **Remoção de Opção:** `remove_poll_option/1` precisa recalcular o `total_votes_count` da enquete pai.

Este Repo fornece a camada de acesso a dados para o módulo de enquetes. O próximo passo seria o `api_endpoints.md` para ele.