# Documentação Deeper: Módulo de Acesso a Dados para Sistema de Comentários Genérico (`Deeper.Interactions.CommentsRepo`)

Este documento descreve o módulo Elixir `Deeper.Interactions.CommentsRepo`. Ele é projetado para ser um repositório genérico que lida com operações CRUD e de listagem para diferentes sistemas de comentários definidos em `sys_objects_cmts`.

A principal característica deste repositório é sua capacidade de operar dinamicamente na tabela de comentários correta e usar as configurações apropriadas (como tabelas de gatilho para contadores) com base no `comments_object_name` fornecido.

## Responsabilidades Principais:

*   Obter configurações de um sistema de comentários específico de `sys_objects_cmts`.
*   Listar comentários (e suas respostas) para um `object_id` específico, consultando a tabela de comentários correta.
*   Criar novos comentários na tabela correta e atualizar os contadores na tabela \"trigger\" pai.
*   Atualizar e deletar comentários, respeitando permissões.
*   Buscar dados do autor do comentário para exibição.

## Funções Auxiliares Chave (Internas):

*   **`get_comment_system_config(comments_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração completa de `sys_objects_cmts` para o `comments_object_name` fornecido.
    *   SQL: `SELECT * FROM sys_objects_cmts WHERE Name = ? LIMIT 1;`
    *   O `config` retornado incluirá `Table` (nome da tabela de comentários), `TriggerTable`, `TriggerFieldId`, `TriggerFieldComments`, etc.
    *   Este resultado pode ser cacheado para performance.

*   **`map_row_to_comment_struct(db_row_map :: map(), author_details :: map() | nil) :: map()`**
    *   Mapeia uma linha da tabela de comentários e os detalhes do autor para a estrutura de resposta da API.
    *   Exemplo:

```sql
            SELECT c.*,
                   author_sa.name as author_account_name, -- de sys_accounts
                   author_pd.fullname as author_fullname, -- de bx_persons_data
                   author_pd.picture as author_avatar_file_id -- de bx_persons_data
            FROM #{target_comment_table} c
            LEFT JOIN sys_profiles author_sp ON c.cmt_author_id = author_sp.id
            LEFT JOIN sys_accounts author_sa ON author_sp.account_id = author_sa.id
            LEFT JOIN bx_persons_data author_pd ON author_sp.content_id = author_pd.id AND author_sp.type = 'bx_persons' -- Assumindo autores são 'bx_persons'
            WHERE c.cmt_object_id = ? AND c.cmt_parent_id = ?
            ORDER BY c.cmt_time #{sort_order_sql}
            LIMIT ? OFFSET ?;
```

```elixir
        defp map_row_to_comment_struct(cmt, author_details \\\\ %{}) do
          %{
            comment_id: cmt[\"cmt_id\"],
            parent_id: cmt[\"cmt_parent_id\"],
            object_id: cmt[\"cmt_object_id\"],
            text: cmt[\"cmt_text\"],
            timestamp: cmt[\"cmt_time\"],
            replies_count: cmt[\"cmt_replies\"],
            pinned: cmt[\"cmt_pinned\"] == 1,
            author: %{
              profile_id: cmt[\"cmt_author_id\"],
              fullname: author_details[\"fullname\"],
              avatar_url: author_details[\"avatar_url\"] # Construída a partir do ID do avatar
            }
            # Adicionar outros campos relevantes: rate, rate_count, mood
          }
        end
```

## Funções Públicas Principais e Lógica SQL:

*(Todas as funções públicas aceitarão `comments_object_name` como primeiro argumento para buscar a configuração correta e determinar a `target_comment_table`.)*

*   **`list_comments(comments_object_name, object_id, current_user_profile_id, opts \\\\ [])`**
    *   `opts`: `parent_id` (default 0), `limit`, `offset`, `sort_order` ('asc'/'desc', default 'asc' para `cmt_time`).
    1.  Chama `get_comment_system_config(comments_object_name)` para obter `config`. Se erro, retorna erro.
    2.  `target_comment_table = config[\"Table\"]`.
    3.  Constrói a query SQL dinamicamente (com segurança) para `target_comment_table`.
        *   SQL (conceitual):

        *   O JOIN para dados do autor precisa ser robusto para diferentes tipos de perfil de autor, se aplicável.
    4.  Executa a query e a query de contagem total (com os mesmos filtros `WHERE`).
    5.  Mapeia os resultados usando `map_row_to_comment_struct/2`, adicionando lógica para `can_edit`/`can_delete` baseada no `current_user_profile_id` vs `cmt_author_id` e permissões de admin/moderador.
    6.  Retorna `{:ok, {comments_list, pagination_meta}}`.

*   **`create_comment(comments_object_name, current_user_profile_id, params :: map())`**
    *   `params`: `object_id`, `text`, `parent_id` (opcional).
    1.  Verificar ACL: O `current_user_profile_id` tem permissão para comentar neste `comments_object_name` / `object_id`? (Requer consulta ao sistema ACL do módulo pai).
    2.  Chama `get_comment_system_config(comments_object_name)` para `config`.
    3.  `target_comment_table = config[\"Table\"]`.
    4.  Prepara dados para inserção: `cmt_author_id = current_user_profile_id`, `cmt_time = current_timestamp()`, etc.
    5.  SQL: `INSERT INTO #{target_comment_table} (cmt_object_id, cmt_author_id, cmt_text, cmt_parent_id, cmt_time, ...) VALUES (?, ?, ?, ?, ?, ...) RETURNING *;`
    6.  Se sucesso e `config[\"TriggerTable\"]` estiver definido:
        *   SQL: `UPDATE #{config[\"TriggerTable\"]} SET #{config[\"TriggerFieldComments\"]} = #{config[\"TriggerFieldComments\"]} + 1 WHERE #{config[\"TriggerFieldId\"]} = ?;` (usando `params.object_id`).
    7.  Se `params.parent_id` for > 0:
        *   SQL: `UPDATE #{target_comment_table} SET cmt_replies = cmt_replies + 1 WHERE cmt_id = ?;` (usando `params.parent_id`).
    8.  (Opcional) Atualizar `cmt_vparent_id`: Se `params.parent_id` é 0, `cmt_vparent_id` é o novo `cmt_id`. Se `params.parent_id` > 0, herda `cmt_vparent_id` do pai (ou o `cmt_id` do pai se o pai for nível 0).
    9.  Mapeia o comentário inserido e retorna `{:ok, comment_map}`.

*   **`get_comment_details(comments_object_name, comment_id, current_user_profile_id)`**
    1.  Busca config, `target_comment_table`.
    2.  SQL: `SELECT c.*, ... (JOINs com autor) ... FROM #{target_comment_table} c WHERE c.cmt_id = ? LIMIT 1;`
    3.  Mapeia e adiciona `can_edit`/`can_delete`.

*   **`update_comment(comments_object_name, comment_id, current_user_profile_id, new_text :: String.t())`**
    1.  Busca config, `target_comment_table`.
    2.  Busca o comentário para verificar se `current_user_profile_id` é o `cmt_author_id` (ou se é admin/moderador com permissão). Se não, `{:error, :forbidden}`.
    3.  SQL: `UPDATE #{target_comment_table} SET cmt_text = ?, cmt_time = ? /* (opcional: atualizar tempo de edição) */ WHERE cmt_id = ? RETURNING *;`
    4.  Mapeia e retorna.

*   **`delete_comment(comments_object_name, comment_id, current_user_profile_id)`**
    1.  Busca config, `target_comment_table`.
    2.  Busca o comentário (incluindo `cmt_object_id`, `cmt_parent_id`) para verificar permissão e para atualizar contadores.
    3.  Se permissão OK:
        *   SQL: `DELETE FROM #{target_comment_table} WHERE cmt_id = ?;` (Também deletar respostas recursivamente ou marcá-las como órfãs/deletadas).
        *   Se `config[\"TriggerTable\"]` definido:
            *   SQL: `UPDATE #{config[\"TriggerTable\"]} SET #{config[\"TriggerFieldComments\"]} = CASE WHEN #{config[\"TriggerFieldComments\"]} > 0 THEN #{config[\"TriggerFieldComments\"]} - 1 ELSE 0 END WHERE #{config[\"TriggerFieldId\"]} = ?;` (usando `cmt_object_id` do comentário deletado).
        *   Se `cmt_parent_id` > 0, decrementar `cmt_replies` do pai.
        *   Retorna `{:ok, :deleted}`.

## Considerações Adicionais:

*   **Segurança SQL Dinâmico:** Ao construir SQL com nomes de tabelas/colunas dinâmicos (de `sys_objects_cmts`), é **crucial** garantir que esses nomes sejam validados contra uma lista de permissões ou sanitizados para prevenir SQL injection. Como eles vêm do banco de dados (que é administrado), o risco é menor do que com input do usuário, mas ainda é uma boa prática validar.
*   **Transações:** Operações como `create_comment` (que inserem e depois atualizam contadores) devem ser envolvidas em transações para garantir atomicidade.
*   **Performance:** JOINs para buscar dados do autor podem impactar a performance de `list_comments`. Considere estratégias de N+1 ou batch loading se necessário, embora com `DBConnection` e SQL direto, o `JOIN` seja geralmente a abordagem. Bons índices nas colunas de FK (`cmt_author_id`, `cmt_object_id`) e `cmt_time` são essenciais.
*   **Full-Text Search:** Se a busca em comentários for necessária, o SQLite FTS5 pode ser integrado posteriormente.

Este `CommentsRepo` genérico formará a espinha dorsal para todas as interações de comentários na API \"Deeper\".