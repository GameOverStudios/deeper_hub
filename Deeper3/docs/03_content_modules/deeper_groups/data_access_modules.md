# Documentação Deeper: Módulos de Acesso a Dados para Grupos

Este documento descreve os módulos Elixir (Repositórios) responsáveis por interagir com as tabelas do banco de dados relacionadas ao módulo de Grupos (`deeper_groups`, `deeper_group_members`, `deeper_group_content_posts`, e tabelas opcionais como `deeper_group_invites` e `deeper_group_join_requests`).

## Módulo Principal: `Deeper.Content.GroupsRepo`

Este módulo lida com a tabela `deeper_groups`, a tabela de membros `deeper_group_members`, e potencialmente tabelas relacionadas como posts de grupo, convites e solicitações de adesão.

**Localização do Código Elixir:** `lib/deeper/content/groups_repo.ex`

```elixir
defmodule Deeper.Content.GroupsRepo do
  alias Deeper.Core.Data.Repo
  alias Deeper.Files.StorageRepo # Para map_row_to_struct helper

  @doc \"\"\"
  Cria um novo grupo e automaticamente adiciona o criador como 'owner'.
  `attrs` é um mapa contendo os campos do grupo.
  O `profile_id` em `attrs` é o criador do grupo.
  \"\"\"
  def create_group(attrs) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    # Adicionar lógica para gerar slug se não fornecido
    # attrs = Map.put_if_absent(attrs, :slug, Slugger.generate(attrs.title))

    Repo.transaction(fn ->
      sql_insert_group = \"\"\"
      INSERT INTO deeper_groups (
        profile_id, title, slug, description, rules, avatar_file_id, cover_file_id,
        privacy_level, allow_member_invites, join_approval_mode, status,
        members_count, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      RETURNING *;
      \"\"\"
      group_values = [
        attrs.profile_id, attrs.title, attrs.slug, attrs.description, attrs.rules,
        attrs.avatar_file_id, attrs.cover_file_id,
        attrs.privacy_level || \"public\", attrs.allow_member_invites || 1,
        attrs.join_approval_mode || \"open\", attrs.status || \"active\",
        1, # members_count (o criador é o primeiro membro)
        current_ts, current_ts # created_at, updated_at
      ]

      case Repo.query(sql_insert_group, group_values) do
        {:ok, %{rows: [group_row], columns: group_columns}} ->
          group_map = StorageRepo.map_row_to_struct(group_row, group_columns)
          group_id = group_map.id

          # Adicionar o criador como membro 'owner'
          member_attrs = %{
            group_id: group_id,
            profile_id: attrs.profile_id,
            role: \"owner\",
            status: \"active\",
            joined_at: current_ts
          }
          case add_member_to_group_direct(member_attrs) do # Função interna para adicionar sem checagens de permissão
            {:ok, _member_map} ->
              {:ok, group_map} # Retorna o grupo criado
            {:error, member_reason} ->
              Repo.rollback({:error, {:owner_membership_creation, member_reason}})
          end
        {:error, reason} ->
          Repo.rollback({:error, {:group_creation, reason}})
      end
    end)
  end

  @doc \"\"\"
  Busca um grupo pelo seu ID.
  `opts` pode incluir `[:creator_profile, :avatar, :cover, :members_summary]`
  \"\"\"
  def get_group(id, opts \\\\ [include: [:creator_profile, :avatar, :cover]]) do
    select_fields = \"g.*\"
    joins = \"\"
    params = [id]

    if Enum.member?(opts[:include], :creator_profile) do
      select_fields = select_fields <> \", p_creator.name as creator_name\"
      joins = joins <> \" LEFT JOIN sys_profiles sp_creator ON g.profile_id = sp_creator.id LEFT JOIN sys_accounts p_creator ON sp_creator.account_id = p_creator.id\"
    end
    if Enum.member?(opts[:include], :avatar) do
      select_fields = select_fields <> \", f_avatar.remote_id as avatar_remote_id, f_avatar.storage_object as avatar_storage\"
      joins = joins <> \" LEFT JOIN deeper_files f_avatar ON g.avatar_file_id = f_avatar.id\"
    end
    if Enum.member?(opts[:include], :cover) do
      select_fields = select_fields <> \", f_cover.remote_id as cover_remote_id, f_cover.storage_object as cover_storage\"
      joins = joins <> \" LEFT JOIN deeper_files f_cover ON g.cover_file_id = f_cover.id\"
    end

    sql = \"SELECT #{select_fields} FROM deeper_groups g #{joins} WHERE g.id = ? LIMIT 1\"

    case Repo.query(sql, params) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        group_map = StorageRepo.map_row_to_struct(row_tuple, columns)
        # Adicionar contagem de membros (já está em group_map.members_count) ou outros sumários se necessário
        {:ok, group_map}
      {:ok, %{rows: []}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc \"Busca um grupo pelo seu slug.\"
  def get_group_by_slug(slug, opts \\\\ [include: [:creator_profile, :avatar, :cover]]) do
    # Lógica similar a get_group, mas WHERE g.slug = ?
    # ... (implementação omitida por brevidade, mas análoga a get_group)
    select_fields = \"g.*\"
    joins = \"\"
    params = [slug]
    # ... (adicionar joins e selects conforme opts) ...
    sql = \"SELECT #{select_fields} FROM deeper_groups g #{joins} WHERE g.slug = ? LIMIT 1\"
    case Repo.query(sql, params) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        {:ok, StorageRepo.map_row_to_struct(row_tuple, columns)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc \"\"\"
  Lista grupos com filtros e paginação.
  `filters`: %{profile_id_creator: 1, privacy_level: \"public\", status: \"active\", member_profile_id: 5 (grupos que este perfil é membro)}
  `pagination_opts`: %{limit: 10, offset: 0, sort_by: \"created_at\", sort_order: \"desc\"}
  \"\"\"
  def list_groups(filters \\\\ %{}, pagination_opts \\\\ %{}) do
    select_clause = \"SELECT DISTINCT g.*, p_creator.name as creator_name\"
    from_clause = \"FROM deeper_groups g JOIN sys_profiles sp_creator ON g.profile_id = sp_creator.id JOIN sys_accounts p_creator ON sp_creator.account_id = p_creator.id\"
    join_members_clause = \"\"
    where_conditions = [\"1=1\"]
    params = []

    # Adicionar filtros (profile_id_creator, privacy_level, status, etc.)
    if creator_id = filters[:profile_id_creator], do: (Array.push(where_conditions, \"g.profile_id = ?\"); Array.push(params, creator_id))
    if privacy = filters[:privacy_level], do: (Array.push(where_conditions, \"g.privacy_level = ?\"); Array.push(params, privacy))
    if status = filters[:status], do: (Array.push(where_conditions, \"g.status = ?\"); Array.push(params, status))

    # Filtro por membro (grupos que um certo profile_id é membro)
    if member_id = filters[:member_profile_id] do
      join_members_clause = \" JOIN deeper_group_members gm ON g.id = gm.group_id\"
      Array.push(where_conditions, \"gm.profile_id = ? AND gm.status = 'active'\") # Apenas membro ativo
      Array.push(params, member_id)
    end

    where_clause = \"WHERE \" <> Enum.join(where_conditions, \" AND \")
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"id\", \"title\", \"created_at\", \"members_count\"], \"created_at\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{join_members_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(DISTINCT g.id) as total_count #{from_clause} #{join_members_clause} #{where_clause}\"

    # ... (lógica de execução e retorno similar a ArticlesRepo.list_articles) ...
    case Repo.query(sql_data, params) do
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        groups = Enum.map(rows_tuples, &StorageRepo.map_row_to_struct(&1, columns))
        case Repo.query(sql_count, params) do
          {:ok, %{rows: [{total_count}]}} ->
            {:ok, %{data: groups, total_count: total_count}}
          _err_count -> {:ok, %{data: groups, total_count: -1}}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Atualiza um grupo.\"
  def update_group(id, attrs) do
    # Lógica similar a ArticlesRepo.update_article, construindo SET clause dinamicamente.
    # ... (campos permitidos: :title, :slug, :description, :rules, :avatar_file_id, :cover_file_id, :privacy_level, etc.)
    current_ts = DateTime.to_unix(DateTime.utc_now())
    update_fields_map = Map.put(attrs, :updated_at, current_ts)
                       |> Map.drop([:profile_id, :created_at, :id, :members_count])

    {set_clause, params} = # ... (construir set_clause e params) ...
    # ... (implementação omitida por brevidade) ...
    sql = \"UPDATE deeper_groups SET #{set_clause} WHERE id = ? RETURNING *\"
    # ... (executar query) ...
    :not_implemented # Placeholder
  end

  @doc \"Deleta um grupo.\"
  def delete_group(id) do
    # ON DELETE CASCADE cuidará de deeper_group_members, posts de grupo, etc.
    sql = \"DELETE FROM deeper_groups WHERE id = ?\"
    Repo.execute(sql, [id])
  end


  # --- Funções para Membros do Grupo ---
  @doc \"\"\"
  Adiciona um membro a um grupo diretamente (usado internamente ou por admins).
  Attrs: %{group_id: _, profile_id: _, role: _, status: _, joined_at: _}
  \"\"\"
  defp add_member_to_group_direct(attrs) do
    sql = \"\"\"
    INSERT INTO deeper_group_members (group_id, profile_id, role, status, joined_at, notifications_level)
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(group_id, profile_id) DO UPDATE SET
      role = excluded.role,
      status = excluded.status,
      joined_at = excluded.joined_at, -- ou não atualizar joined_at no update
      notifications_level = excluded.notifications_level
    RETURNING *;
    \"\"\"
    values = [
      attrs.group_id, attrs.profile_id, attrs.role || \"member\",
      attrs.status || \"active\", attrs.joined_at || DateTime.to_unix(DateTime.utc_now()),
      attrs.notifications_level || \"all\"
    ]

    Repo.transaction(fn ->
        case Repo.query(sql, values) do
            {:ok, %{rows: [row], columns: cols}} ->
                # Atualizar members_count na tabela deeper_groups
                # Apenas se o status for 'active' e era um novo membro ou não era 'active' antes
                # (Lógica mais complexa para contagem precisa em UPSERT)
                # Por simplicidade, vamos recalcular ou usar uma trigger se o DB suportar.
                # Ou, se for uma nova adição ativa:
                # if attrs.status == \"active\" (e não era antes, ou é novo) do
                #   update_member_count(attrs.group_id, 1)
                # end
                recalculate_member_count(attrs.group_id) # Mais simples, mas pode ser menos performático
                {:ok, StorageRepo.map_row_to_struct(row, cols)}
            err -> Repo.rollback({:error, {:member_upsert, err}})
        end
    end)
  end

  @doc \"\"\"
  Processa uma solicitação de um `requester_profile_id` para se juntar ao `group_id`.
  Depende do `join_approval_mode` do grupo.
  Retorna :ok, :pending_approval, ou {:error, reason}.
  \"\"\"
  def request_to_join_group(group_id, requester_profile_id, group_join_mode) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    member_attrs = %{
        group_id: group_id,
        profile_id: requester_profile_id,
        role: \"member\",
        joined_at: current_ts
    }

    case group_join_mode do
        \"open\" ->
            add_member_to_group_direct(Map.put(member_attrs, :status, \"active\"))
            |> case do
                {:ok, member_map} -> {:ok, member_map} # Adicionado diretamente
                err -> err
            end
        \"approval\" ->
            # Adicionar à tabela deeper_group_join_requests (se implementada) ou
            # adicionar como membro com status 'pending_approval'
            add_member_to_group_direct(Map.put(member_attrs, :status, \"pending_approval\"))
             |> case do
                {:ok, _member_map} -> {:ok, :pending_approval} # Solicitação registrada
                err -> err
            end
        \"invite_only\" ->
            {:error, :invite_only}
        _ ->
            {:error, :invalid_join_mode}
    end
  end

  @doc \"Aprova um membro pendente ou um convite.\"
  def approve_group_membership(group_id, profile_id_to_approve, approver_profile_id) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    sql = \"\"\"
    UPDATE deeper_group_members
    SET status = 'active', approved_by_profile_id = ?, joined_at = ?
    WHERE group_id = ? AND profile_id = ? AND status IN ('pending_approval', 'invited')
    RETURNING *;
    \"\"\"
    values = [approver_profile_id, current_ts, group_id, profile_id_to_approve]

    Repo.transaction(fn ->
        case Repo.query(sql, values) do
            {:ok, %{rows: [row], columns: cols}} ->
                recalculate_member_count(group_id)
                {:ok, StorageRepo.map_row_to_struct(row, cols)}
            {:ok, %{rows: []}} -> # Ninguém para aprovar ou já aprovado
                {:error, :no_pending_member_to_approve}
            err -> Repo.rollback({:error, {:approve_member, err}})
        end
    end)
  end
  
  @doc \"Muda o papel de um membro no grupo.\"
  def change_member_role(group_id, profile_id, new_role, changer_profile_id) do
    # Adicionar verificação de permissão (changer_profile_id deve ser admin/owner)
    sql = \"UPDATE deeper_group_members SET role = ? WHERE group_id = ? AND profile_id = ? RETURNING *;\"
    case Repo.query(sql, [new_role, group_id, profile_id]) do
        {:ok, %{rows: [row], cols: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
        {:ok, %{rows: []}} -> {:error, :member_not_found}
        err -> err
    end
  end

  @doc \"Remove/Bane/Deixa um membro do grupo.\"
  def remove_member_from_group(group_id, profile_id_to_remove, remover_profile_id \\\\ nil, new_status \\\\ \"left\", ban_reason \\\\ nil) do
    # Adicionar verificação de permissão
    # Se new_status == \"banned\", setar banned_by_profile_id e ban_reason
    # Se new_status == \"left\", não precisa de remover_profile_id
    # Para remover completamente (DELETE):
    # sql = \"DELETE FROM deeper_group_members WHERE group_id = ? AND profile_id = ?\"
    # Para mudar status para 'left' ou 'banned':
    set_clauses = [\"status = ?\"]
    params = [new_status]
    if new_status == \"banned\" and remover_profile_id do
        Array.push(set_clauses, \"banned_by_profile_id = ?\")
        Array.push(params, remover_profile_id)
        if ban_reason, do: (Array.push(set_clauses, \"ban_reason = ?\"); Array.push(params, ban_reason))
    end
    Array.push(params, group_id)
    Array.push(params, profile_id_to_remove)
    
    sql = \"UPDATE deeper_group_members SET #{Enum.join(set_clauses, \", \")} WHERE group_id = ? AND profile_id = ? RETURNING *;\"

    Repo.transaction(fn ->
        case Repo.query(sql, params) do
            {:ok, %{rows: [row], columns: cols}} ->
                # Apenas recalcular se o status anterior era 'active' e o novo não é, ou vice-versa
                recalculate_member_count(group_id)
                {:ok, StorageRepo.map_row_to_struct(row, cols)}
            {:ok, %{rows: []}} -> {:error, :member_not_found}
            err -> Repo.rollback({:error, {:remove_member, err}})
        end
    end)
  end

  @doc \"Lista membros de um grupo.\"
  def list_group_members(group_id, filters \\\\ %{}, pagination_opts \\\\ %{}) do
    # `filters` pode incluir `role`, `status`.
    # JOIN com sys_profiles/sys_accounts para detalhes do perfil.
    select_clause = \"SELECT gm.*, p.name as member_name, sa.email as member_email\" # Adicionar mais campos do perfil se necessário
    from_clause = \"FROM deeper_group_members gm JOIN sys_profiles p ON gm.profile_id = p.id JOIN sys_accounts sa ON p.account_id = sa.id\"
    where_conditions = [\"gm.group_id = ?\"]
    params = [group_id]

    if role = filters[:role], do: (Array.push(where_conditions, \"gm.role = ?\"); Array.push(params, role))
    if status = filters[:status], do: (Array.push(where_conditions, \"gm.status = ?\"); Array.push(params, status))
    
    where_clause = \"WHERE \" <> Enum.join(where_conditions, \" AND \")
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"joined_at\", \"member_name\"], \"joined_at\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(gm.id) as total_count #{from_clause} #{where_clause}\"
    
    # ... (lógica de execução e retorno similar a list_articles) ...
    :not_implemented # Placeholder
  end

  @doc \"Verifica se um perfil é membro (ativo) de um grupo.\"
  def is_member?(group_id, profile_id) do
    sql = \"SELECT 1 FROM deeper_group_members WHERE group_id = ? AND profile_id = ? AND status = 'active' LIMIT 1\"
    case Repo.query(sql, [group_id, profile_id]) do
      {:ok, %{rows: [_]}} -> true
      _ -> false
    end
  end

  @doc \"Obtém o papel de um membro no grupo.\"
  def get_member_role(group_id, profile_id) do
    sql = \"SELECT role FROM deeper_group_members WHERE group_id = ? AND profile_id = ? AND status = 'active' LIMIT 1\"
     case Repo.query(sql, [group_id, profile_id]) do
      {:ok, %{rows: [{role}]}} -> {:ok, role}
      _ -> {:error, :not_member_or_inactive}
    end
  end

  @doc \"Recalcula e atualiza a contagem de membros ativos para um grupo.\"
  def recalculate_member_count(group_id) do
    count_sql = \"SELECT COUNT(id) FROM deeper_group_members WHERE group_id = ? AND status = 'active'\"
    update_sql = \"UPDATE deeper_groups SET members_count = ? WHERE id = ?\"
    
    case Repo.query(count_sql, [group_id]) do
      {:ok, %{rows: [{count}]}} ->
        Repo.execute(update_sql, [count, group_id])
      _ ->
        # Logar erro, mas não necessariamente falhar a operação principal
        Logger.error(\"Falha ao recalcular contagem de membros para grupo #{group_id}\", module: __MODULE__)
    end
    :ok
  end

  # --- Funções para Posts de Conteúdo do Grupo ---
  # (CRUD para deeper_group_content_posts)
  # def create_group_post(attrs) do ... end
  # def get_group_post(post_id) do ... end
  # def list_group_posts(group_id, pagination_opts) do ... end
  # def update_group_post(post_id, attrs) do ... end
  # def delete_group_post(post_id) do ... end

end
```

### Notas para `GroupsRepo`:
*   **Criação de Grupo e Proprietário:** `create_group/1` lida com a criação do grupo e a adição automática do criador como membro \"owner\" dentro de uma transação.
*   **Contagem de Membros:** A coluna `members_count` em `deeper_groups` é desnormalizada. A função `add_member_to_group_direct` (e outras que alteram o status/presença de membros) precisa de lógica para atualizar essa contagem. `recalculate_member_count/1` é uma forma simples de fazer isso, mas para alta concorrência, abordagens mais incrementais ou triggers (se o DB suportar bem) seriam melhores.
*   **Manejo de Solicitações/Convites:** A função `request_to_join_group` exemplifica como o `join_approval_mode` do grupo influenciaria a adição de um membro (direto, pendente de aprovação, ou erro se for apenas por convite). A implementação completa exigiria as tabelas `deeper_group_invites` e `deeper_group_join_requests` e mais funções no repo.
*   **Permissões:** Funções como `change_member_role` e `remove_member_from_group` mencionam a necessidade de verificações de permissão (ex: apenas um admin/owner do grupo pode mudar o papel de outro membro). Essa lógica de verificação de permissão residiria na Camada de Contexto/Serviço, que chamaria `get_member_role` para verificar o papel do `changer_profile_id` antes de prosseguir.
*   **Posts de Grupo:** As funções para `deeper_group_content_posts` foram apenas esboçadas, mas seguiriam padrões CRUD similares.

## 2. Módulo: `Deeper.Content.GroupCategoriesRepo` (se categorias de grupo forem necessárias)

Se os grupos puderem ser categorizados (diferente de categorias de artigos ou eventos):

*   **Tabelas:** `deeper_group_categories`, `deeper_groups_to_group_categories`.
*   **Funcionalidade:** Similar a `ArticleCategoriesRepo` ou `EventCategoriesRepo`.
*   **Localização do Código Elixir:** `lib/deeper/content/group_categories_repo.ex`
*   *(Implementação omitida por brevidade, mas seria análoga aos outros repos de categoria).*

Este `GroupsRepo` é bastante abrangente, cobrindo tanto os grupos em si quanto o gerenciamento básico de seus membros. A complexidade pode aumentar significativamente com fluxos detalhados de convite, aprovação, e moderação.