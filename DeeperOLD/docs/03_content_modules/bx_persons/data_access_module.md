# Documentação Deeper: Módulo de Acesso a Dados para Pessoas (`Deeper.Content.PersonsRepo`)

Este documento descreve o módulo Elixir `Deeper.Content.PersonsRepo`, responsável por encapsular toda a lógica de interação com o banco de dados para as tabelas relacionadas ao módulo \"Pessoas\" (`bx_persons`), principalmente `bx_persons_data` e suas tabelas associadas como `bx_persons_pictures`, `bx_persons_views_track`, `bx_persons_cmts`, etc.

Este repositório fornecerá uma API interna para os controllers da API RESTful \"Deeper\" e outros serviços que precisam manipular ou buscar dados de perfis de pessoas.

## Responsabilidades Principais:

*   Operações CRUD para `bx_persons_data`.
*   Gerenciamento de fotos de perfil (`bx_persons_pictures`, `bx_persons_pictures_resized`), incluindo associação com `bx_persons_data.picture` e `bx_persons_data.cover`.
*   Registro e contagem de visualizações de perfil (`bx_persons_views_track` e atualização de `bx_persons_data.views`).
*   Operações CRUD para comentários de perfil (`bx_persons_cmts`).
*   Listagem de perfis com filtros complexos, ordenação e paginação.
*   Fornecer dados para os \"serviços de bloco\" do UNA relacionados a pessoas (ex: listar amigos, últimos membros).
*   Interagir com outros repositórios para funcionalidades relacionadas (ex: `ProfilesRepo` para obter `account_id`, `ConnectionsRepo` para dados de amizade).

## Funções Principais e SQLs Esperados (Exemplos):

*(Nota: Algumas funções CRUD básicas para `bx_persons_data` podem já ter sido insinuadas ou parcialmente cobertas em `Deeper.SystemCore.ProfilesRepo` ao lidar com a criação/atualização de perfis. Aqui, focaremos em operações mais específicas do módulo `bx_persons` ou expandiremos essas operações.)*

---
### Gerenciamento de `bx_persons_data`

*   **`create_person_data(params :: map()) :: {:ok, person_data :: map()} | {:error, any()}`**
    *   Cria uma entrada em `bx_persons_data`. Usado durante o registro de um novo perfil de pessoa.
    *   `params` inclui: `author` (profile_id do criador), `fullname`, e outros campos de `bx_persons_data`. `added` e `changed` timestamps devem ser gerados.
    *   SQL: `INSERT INTO bx_persons_data (author, added, changed, fullname, description, ...) VALUES (?, ?, ?, ?, ?, ...) RETURNING *;`
    *   *Referência: Esta função é similar à mencionada em `Deeper.SystemCore.ProfilesRepo` ou `AccountsRepo` durante o fluxo de criação de perfil completo.*

*   **`get_person_data_by_id(id :: integer()) :: {:ok, person_data :: map()} | {:error, :not_found | any()}`**
    *   Busca um registro de `bx_persons_data` pelo seu `id`.
    *   SQL: `SELECT * FROM bx_persons_data WHERE id = ? LIMIT 1;`

*   **`update_person_data(id :: integer(), params :: map()) :: {:ok, person_data :: map()} | {:error, :not_found | any()}`**
    *   Atualiza campos em `bx_persons_data`.
    *   `params` contém os campos a serem atualizados. O timestamp `changed` deve ser atualizado.
    *   SQL: `UPDATE bx_persons_data SET fullname = ?, description = ?, ..., changed = ? WHERE id = ? RETURNING *;`

*   **`list_persons_with_details(opts :: Keyword.t()) :: {:ok, {persons :: list(map()), pagination_meta :: map()}} | {:error, any()}`**
    *   Lista perfis de pessoas com detalhes combinados de `sys_accounts`, `sys_profiles`, e `bx_persons_data`.
    *   Esta é uma query chave para listagens de membros.
    *   `opts`: `offset`, `limit`, `sort_by` (ex: `fullname_asc`, `added_desc`), `sort_order`, e filtros (`filter_fullname_like`, `filter_location_like`, `filter_gender`, `filter_active_account` (requer JOIN com `sys_accounts`)).
    *   Também precisa considerar as permissões de visualização (`bx_persons_data.allow_view_to`) em relação ao `acl_level_id` do usuário solicitante.
    *   SQL (Exemplo conceitual complexo):

```sql
        -- Para dados:
        SELECT
            pd.id AS person_id, pd.fullname, pd.description, pd.picture AS picture_file_id, pd.cover AS cover_file_id, pd.location, pd.added,
            sa.id AS account_id, sa.email, sa.active AS account_active,
            sp.id AS profile_id, sp.status AS profile_status
        FROM bx_persons_data pd
        JOIN sys_profiles sp ON pd.id = sp.content_id AND sp.type = 'bx_persons'
        JOIN sys_accounts sa ON sp.account_id = sa.id
        WHERE
            (pd.fullname LIKE ? OR ? IS NULL) AND
            (sa.active = ? OR ? IS NULL) AND
            -- Lógica de permissão de visualização (allow_view_to) aqui, pode ser complexa:
            -- Ex: (pd.allow_view_to = 'public_group_id' OR (pd.allow_view_to = 'members_group_id' AND current_user_level > visitor_level) OR ...)
            EXISTS (SELECT 1 FROM fn_check_privacy(pd.allow_view_to, ?_current_user_level_or_groups)) -- Função hipotética
        ORDER BY ? ?
        LIMIT ? OFFSET ?;

        -- Para contagem total (com os mesmos filtros e JOINs):
        SELECT COUNT(pd.id)
        FROM bx_persons_data pd
        JOIN sys_profiles sp ON pd.id = sp.content_id AND sp.type = 'bx_persons'
        JOIN sys_accounts sa ON sp.account_id = sa.id
        WHERE ... (mesmas condições WHERE acima);
```

```sql
        SELECT c.*, author_profile.fullname AS author_fullname -- (Exemplo de JOIN para nome do autor)
        FROM bx_persons_cmts c
        LEFT JOIN bx_persons_data author_profile ON c.cmt_author_id = author_profile.id -- Assumindo que cmt_author_id é bx_persons_data.id
                                                 -- ou JOIN com sys_profiles e depois bx_persons_data
        WHERE c.cmt_object_id = ? AND c.cmt_parent_id = 0
        ORDER BY c.cmt_time DESC
        LIMIT ? OFFSET ?;
```

```sql
        SELECT friend_pd.* -- Dados do perfil do amigo
        FROM sys_profiles_conn_friends cf
        JOIN sys_profiles friend_sp ON (cf.initiator = ?_person_profile_id AND cf.content = friend_sp.id) OR (cf.content = ?_person_profile_id AND cf.initiator = friend_sp.id)
        JOIN bx_persons_data friend_pd ON friend_sp.content_id = friend_pd.id AND friend_sp.type = 'bx_persons'
        WHERE cf.mutual = 1 -- Apenas amigos mútuos
        AND friend_sp.id != ?_person_profile_id -- Exclui o próprio perfil
        -- Aplicar filtros de privacidade para os perfis dos amigos
        ORDER BY RANDOM() -- Ou alguma outra ordenação
        LIMIT ?; -- count
```

    *   A parte de `fn_check_privacy` é uma representação da lógica complexa de verificação de `allow_view_to`. No UNA, isso pode envolver a checagem de grupos de privacidade (`sys_privacy_groups`). A implementação direta em SQL pode ser difícil, podendo exigir que parte da filtragem de privacidade seja feita em Elixir após uma busca mais ampla, ou com subqueries/CTEs mais elaboradas.
    *   **Otimização:** Esta query será crítica e precisará de bons índices em todas as colunas de JOIN e filtro.

---
### Gerenciamento de Fotos (`bx_persons_pictures`, `bx_persons_pictures_resized`)

*   **`add_profile_picture(person_id :: integer(), file_info :: map()) :: {:ok, picture_meta :: map()} | {:error, any()}`**
    *   Adiciona uma nova imagem à tabela `bx_persons_pictures`.
    *   `file_info` contém: `remote_id`, `path`, `file_name`, `mime_type`, `ext`, `size`, `dimensions`. `added` e `modified` timestamps são gerados.
    *   SQL: `INSERT INTO bx_persons_pictures (profile_id, remote_id, path, ...) VALUES (?, ?, ?, ...) RETURNING *;`
    *   Pode envolver a exclusão de fotos antigas se houver um limite.

*   **`set_as_main_picture(person_id :: integer(), picture_id :: integer()) :: {:ok, person_data :: map()} | {:error, any()}`**
    *   Atualiza `bx_persons_data.picture` com o `id` (ou `remote_id`) da imagem de `bx_persons_pictures`.
    *   SQL: `UPDATE bx_persons_data SET picture = ? WHERE id = ? RETURNING *;`

*   **`get_profile_pictures(person_id :: integer(), opts :: Keyword.t()) :: {:ok, {pictures :: list(map()), pagination_meta :: map()}} | {:error, any()}`**
    *   Lista todas as fotos (originais) de um perfil.
    *   SQL: `SELECT id, remote_id, path, file_name, added FROM bx_persons_pictures WHERE profile_id = ? ORDER BY added DESC LIMIT ? OFFSET ?;`
    *   Contagem total: `SELECT COUNT(*) FROM bx_persons_pictures WHERE profile_id = ?;`

*   **`add_resized_picture_info(person_id :: integer(), resized_file_info :: map()) :: {:ok, resized_meta :: map()} | {:error, any()}`**
    *   Adiciona informações de uma imagem redimensionada a `bx_persons_pictures_resized`.
    *   Normalmente chamado após um processo de transcodificação/redimensionamento de imagem.
    *   SQL: `INSERT INTO bx_persons_pictures_resized (profile_id, remote_id, path, ...) VALUES (?, ?, ?, ...) RETURNING *;`

---
### Rastreamento de Visualizações (`bx_persons_views_track`)

*   **`record_profile_view(person_id :: integer(), viewer_profile_id :: integer() | nil, viewer_ip_integer :: integer() | nil) :: :ok | {:error, any()}`**
    *   Insere um registro em `bx_persons_views_track`.
    *   Gera o timestamp `date`.
    *   SQL: `INSERT INTO bx_persons_views_track (object_id, viewer_id, viewer_nip, date) VALUES (?, ?, ?, ?);`
    *   **Lógica Adicional:** Após inserir, pode ser necessário atualizar o contador `bx_persons_data.views`. Isso pode ser feito aqui, ou por um job separado para agregar visualizações. Se feito aqui:
        *   SQL: `UPDATE bx_persons_data SET views = views + 1 WHERE id = ?;` (Com cuidado para não causar race conditions se muitas visualizações simultâneas).
        *   Para evitar contagem excessiva do mesmo visualizador em curto período, pode haver lógica para verificar a última visualização desse `viewer_id` ou `viewer_nip`.

---
### Comentários em Perfis (`bx_persons_cmts`)

*   **`create_profile_comment(params :: map()) :: {:ok, comment :: map()} | {:error, any()}`**
    *   Cria um novo comentário em um perfil.
    *   `params`: `cmt_object_id` (person_id), `cmt_author_id` (profile_id do autor), `cmt_text`, `cmt_parent_id` (se for resposta). `cmt_time` é gerado.
    *   SQL: `INSERT INTO bx_persons_cmts (cmt_object_id, cmt_author_id, cmt_text, ...) VALUES (?, ?, ?, ...) RETURNING *;`
    *   **Lógica Adicional:** Atualizar `bx_persons_data.comments` e `bx_persons_cmts.cmt_replies` no comentário pai.

*   **`get_profile_comments(person_id :: integer(), opts :: Keyword.t()) :: {:ok, {comments :: list(map()), pagination_meta :: map()}} | {:error, any()}`**
    *   Lista comentários de um perfil, com suporte para aninhamento e paginação.
    *   `opts`: `offset`, `limit`, `sort_by` (ex: `cmt_time_desc`), `parent_id` (para buscar respostas).
    *   SQL (para comentários de nível superior):

    *   A busca por respostas (`cmt_parent_id != 0`) e a construção da árvore de comentários podem ser complexas e podem exigir múltiplas queries ou CTEs recursivas (SQLite suporta CTEs recursivas).
    *   Contagem total: `SELECT COUNT(*) FROM bx_persons_cmts WHERE cmt_object_id = ? AND cmt_parent_id = 0;`

*   **`update_profile_comment(comment_id :: integer(), text :: String.t()) :: {:ok, comment :: map()} | {:error, any()}`**
*   **`delete_profile_comment(comment_id :: integer()) :: :ok | {:error, any()}`**

---
### Funções para \"Serviços de Bloco\" (Exemplos)

*   **`get_latest_persons(count :: integer()) :: {:ok, list(map())} | {:error, any()}`**
    *   Para um bloco \"Últimos Membros\".
    *   SQL: (similar a `list_persons_with_details` mas ordenado por `pd.added DESC` e limitado por `count`, com filtros de privacidade aplicados).

*   **`get_person_friends_preview(person_id :: integer(), count :: integer()) :: {:ok, list(map())} | {:error, any()}`**
    *   Para um bloco \"Amigos de {Nome}\".
    *   Requereria `JOIN` com a tabela de conexões/amizades (ex: `sys_profiles_conn_friends`).
    *   SQL (Conceitual):

    *   `?_person_profile_id` aqui seria o `sys_profiles.id` do `person_id` original.

## Mapeamento de Linhas e Estruturas de Dados

*   O `PersonsRepo` (e outros repositórios) precisará de funções auxiliares para mapear as linhas de resultado do banco de dados para mapas ou structs Elixir.
*   Definir structs simples para `PersonData`, `PersonPicture`, `PersonComment` pode ser útil para clareza, embora mapas também funcionem.

## Otimização de SQL (`sql_queries.md`)

*   Um arquivo separado `docs/03_content_modules/bx_persons/data_access_module/sql_queries.md` pode ser criado para detalhar e analisar as queries mais complexas, especialmente `list_persons_with_details` e as queries para blocos de serviço, mostrando os `EXPLAIN QUERY PLAN` e as estratégias de indexação.

Este `PersonsRepo` será um dos módulos de acesso a dados mais movimentados e complexos, dada a centralidade dos perfis de pessoa em uma plataforma social.