# Documentação Deeper: Módulo de Acesso a Dados para Pessoas (`PersonsRepo`)

Este documento descreve o módulo Elixir `Deeper.Content.PersonsRepo`. Ele expande as funcionalidades já esboçadas em `01_system_core` para `bx_persons_data` e agora inclui interações com tabelas relacionadas a perfis de pessoas, como galeria de fotos, rastreamento de interações (visualizações, favoritos, etc.), metadados e habilidades.

**Localização do Código:** `lib/deeper/content/persons_repo.ex`

## Funções Relacionadas a `bx_persons_data` (Revisão/Expansão)

*As funções `get_person_data/1`, `create_person_data/1`, `update_person_data/2`, e `list_persons_data/1` foram esboçadas anteriormente. Aqui, reforçamos a necessidade de JOINs com `sys_profiles` para obter `profile_id` ou buscar por `sys_profiles.id`.*

*   **`get_person_details_by_profile_id(profile_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca dados de `bx_persons_data` juntamente com informações de `sys_profiles` e `sys_accounts`.
    *   **SQL (Exemplo):**

```sql
        SELECT
            pd.*, -- todos os campos de bx_persons_data
            p.id as profile_id, p.type as profile_type, p.status as profile_status,
            sa.id as account_id, sa.name as account_name, sa.email as account_email, sa.active as account_active
        FROM bx_persons_data pd
        JOIN sys_profiles p ON pd.id = p.content_id
        JOIN sys_accounts sa ON p.account_id = sa.id
        WHERE p.id = ? AND p.type = 'bx_persons';
```

```sql
        SELECT
            pd.*, p.id as profile_id, p.type as profile_type, p.status as profile_status,
            sa.id as account_id, sa.name as account_name, sa.email as account_email, sa.active as account_active
        FROM bx_persons_data pd
        JOIN sys_profiles p ON pd.id = p.content_id
        JOIN sys_accounts sa ON p.account_id = sa.id
        WHERE pd.uri = ? AND p.type = 'bx_persons'; -- Assumindo pd.uri
```

```sql
        INSERT INTO bx_persons_pictures (profile_id, remote_id, path, file_name, mime_type, ext, size, dimensions, added, modified, private)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        RETURNING *;
```

```sql
        INSERT INTO bx_persons_pictures_resized (profile_id, remote_id, path, file_name, mime_type, ext, size, added, modified, private)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        RETURNING *;
```

```sql
        INSERT INTO bx_persons_views_track (object_id, viewer_id, viewer_nip, date)
        VALUES (?, ?, ?, ?); -- date é o timestamp atual
```

```sql
        SELECT
            t.date,
            v_prof.id as viewer_profile_id,
            v_pd.fullname as viewer_fullname,
            v_pd.picture as viewer_picture_id -- ou o remote_id da foto principal
        FROM bx_persons_views_track t
        JOIN sys_profiles v_prof ON t.viewer_id = v_prof.id AND t.viewer_id != 0
        JOIN bx_persons_data v_pd ON v_prof.content_id = v_pd.id AND v_prof.type = 'bx_persons'
        WHERE t.object_id = ?
        ORDER BY t.date DESC
        LIMIT ? OFFSET ?;
```

```sql
        INSERT INTO bx_persons_cmts (cmt_object_id, cmt_author_id, cmt_text, cmt_parent_id, cmt_time, ...)
        VALUES (?, ?, ?, ?, ?, ...)
        RETURNING *;
```

```sql
        SELECT
            c.*,
            a_prof.id as author_profile_id,
            a_pd.fullname as author_fullname,
            a_pd.picture as author_picture_id
        FROM bx_persons_cmts c
        JOIN sys_profiles a_prof ON c.cmt_author_id = a_prof.id
        JOIN bx_persons_data a_pd ON a_prof.content_id = a_pd.id AND a_prof.type = 'bx_persons'
        WHERE c.cmt_object_id = ? AND c.cmt_parent_id = 0 -- Nível superior
        ORDER BY c.cmt_time DESC
        LIMIT ? OFFSET ?;
        -- Query para contagem total para paginação também necessária.
        -- Buscar respostas (cmt_parent_id != 0) exigiria uma query separada ou lógica recursiva.
```

    *   Parâmetro: `profile_id`.

*   **`get_person_details_by_uri(uri_slug :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Similar ao anterior, mas busca pelo `uri_slug` (assumindo que `bx_persons_data` tem um campo `uri`).
    *   **SQL (Exemplo):**

## Funções para Galeria de Fotos (`bx_persons_pictures`, `bx_persons_pictures_resized`)

*   **`add_picture_to_profile(profile_id :: integer(), picture_attrs :: map()) :: {:ok, map()} | {:error, any()}`**
    *   Adiciona uma nova foto à galeria do perfil.
    *   `picture_attrs` deve conter: `remote_id`, `path`, `file_name`, `mime_type`, `ext`, `size`, `dimensions`, `added`, `modified`, `private` (opcional).
    *   **SQL:**

    *   **Nota:** `remote_id` e outros atributos relacionados ao arquivo físico vêm do sistema de upload/storage.

*   **`list_pictures_for_profile(profile_id :: integer(), opts :: map() | nil) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista as fotos da galeria de um perfil, com paginação.
    *   `opts` pode incluir `limit`, `offset`.
    *   **SQL:** `SELECT * FROM bx_persons_pictures WHERE profile_id = ? ORDER BY added DESC LIMIT ? OFFSET ?;`

*   **`get_picture(picture_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca uma foto específica pelo seu `id`.
    *   **SQL:** `SELECT * FROM bx_persons_pictures WHERE id = ?;`

*   **`delete_picture(picture_id :: integer(), profile_id_owner :: integer()) :: :ok | {:error, :not_found | :unauthorized | any()}`**
    *   Deleta uma foto. Verifica se `profile_id_owner` é o dono da foto.
    *   **SQL:** `DELETE FROM bx_persons_pictures WHERE id = ? AND profile_id = ?;`
    *   **Nota:** Precisa lidar com a exclusão dos arquivos físicos no storage e das versões redimensionadas.

*   **`add_resized_picture_info(original_picture_id :: integer() | nil, profile_id :: integer(), resized_attrs :: map()) :: {:ok, map()} | {:error, any()}`**
    *   Adiciona informações de uma imagem redimensionada.
    *   `resized_attrs` similar a `picture_attrs`. O `original_picture_id` pode não ser diretamente armazenado em `bx_persons_pictures_resized` no UNA, mas o `remote_id` da imagem original é frequentemente usado para agrupar/identificar as versões redimensionadas. A lógica aqui dependerá de como o sistema de transcodificação e armazenamento lida com isso.
    *   **SQL:**

*   **`get_resized_versions(original_remote_id :: String.t(), profile_id :: integer()) :: {:ok, list(map())} | {:error, any()}`**
    *   Busca todas as versões redimensionadas associadas a um `remote_id` de uma imagem original. (A tabela `bx_persons_pictures_resized` do UNA original não tem uma FK direta para a imagem original, usa `remote_id` que seria o da imagem *redimensionada*).
    *   **Nota:** A lógica de associação entre original e redimensionada pode precisar ser mais bem definida ou adaptada. Se a `bx_persons_pictures_resized` tivesse uma `original_picture_id` ou se o `remote_id` dela fosse construído a partir do `remote_id` da original, a query seria mais direta.
    *   Assumindo que o `remote_id` na `bx_persons_pictures_resized` é único por si só e não diretamente ligado via FK ao `remote_id` da `bx_persons_pictures`:
        *   Este caso de uso exigiria uma convenção de nomenclatura ou uma tabela de mapeamento se você quisesse listar \"versões de X\". A API pode expor as imagens redimensionadas individualmente.

## Funções para Rastreamento de Visualizações (`bx_persons_views_track`)

*   **`track_profile_view(object_profile_id :: integer(), viewer_profile_id :: integer() | nil, viewer_ip_integer :: integer() | nil) :: :ok | {:error, any()}`**
    *   Registra uma visualização de perfil.
    *   `viewer_profile_id` é 0 ou nulo para anônimos.
    *   `viewer_ip_integer` é o IP convertido para inteiro.
    *   **Lógica:**
        1.  Verificar se já existe uma view recente deste `viewer_id` (ou `viewer_nip`) para este `object_id` para evitar contagem excessiva (ex: dentro das últimas X horas). Esta lógica não está no SQL puro, mas na aplicação.
        2.  Se for para registrar:
    *   **SQL:**

    *   **Após o INSERT, atualizar o contador `views` em `bx_persons_data`:**
        *   **SQL:** `UPDATE bx_persons_data SET views = views + 1 WHERE id = (SELECT content_id FROM sys_profiles WHERE id = ? AND type = 'bx_persons');` (Parâmetro: `object_profile_id`)

*   **`get_profile_view_count(object_profile_id :: integer()) :: {:ok, integer()} | {:error, any()}`**
    *   Retorna a contagem de visualizações de `bx_persons_data.views`.
    *   **SQL:** `SELECT views FROM bx_persons_data WHERE id = (SELECT content_id FROM sys_profiles WHERE id = ? AND type = 'bx_persons');`

*   **`list_recent_viewers(object_profile_id :: integer(), opts :: map()) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista os últimos perfis que visualizaram `object_profile_id`.
    *   Requer `JOIN` com `sys_profiles` e `bx_persons_data` para obter detalhes dos visualizadores.
    *   **SQL (Exemplo):**

## Funções para Comentários (`bx_persons_cmts` - Condicional)

*Se `bx_persons_cmts` for usado (em vez do sistema genérico):*

*   **`add_comment_to_profile(object_profile_id :: integer(), author_profile_id :: integer(), comment_data :: map()) :: {:ok, map()} | {:error, any()}`**
    *   `comment_data` inclui `cmt_text`, `cmt_parent_id`, etc.
    *   **SQL:**

    *   **Após o INSERT, atualizar o contador `comments` em `bx_persons_data`.**

*   **`list_comments_for_profile(object_profile_id :: integer(), opts :: map()) :: {:ok, %{data: list(map()), pagination: map()}} | {:error, any()}`**
    *   Lista comentários para um perfil, com paginação e ordenação.
    *   Precisa lidar com a estrutura aninhada (`cmt_parent_id`) ou retornar uma lista plana para o cliente reconstruir.
    *   Requer `JOIN` com `sys_profiles` e `bx_persons_data` para detalhes do autor do comentário.
    *   **SQL (Exemplo para nível superior, ordenado por tempo):**

*   **(CRUD para comentários: `get_comment`, `update_comment`, `delete_comment`)**

## Funções para Sistemas de Interação Genéricos (Favoritos, Reports, Scores, Votos)

*Estas funções irão interagir com as tabelas `bx_persons_favorites_track`, `bx_persons_reports_track`, etc. A lógica será muito similar entre elas: adicionar uma entrada de track, remover uma entrada (para toggle), listar.*
*Elas também precisam atualizar os contadores correspondentes em `bx_persons_data` (ex: `favorites`, `reports`, `sc_up`/`sc_down`, `votes`).*

*   **`add_favorite(object_profile_id :: integer(), author_profile_id :: integer()) :: :ok | {:error, :already_favorited | any()}`**
*   **`remove_favorite(object_profile_id :: integer(), author_profile_id :: integer()) :: :ok | {:error, :not_favorited | any()}`**
*   **`is_favorited(object_profile_id :: integer(), author_profile_id :: integer()) :: {:ok, boolean()} | {:error, any()}`**
*   **`list_favorited_by(object_profile_id :: integer(), opts :: map()) :: {:ok, list(map())} | {:error, any()}`** (Lista quem favoritou)
*   **`list_favorites_of(author_profile_id :: integer(), opts :: map()) :: {:ok, list(map())} | {:error, any()}`** (Lista quem o autor favoritou)

*Funções análogas para `reports`, `scores` (com `type = 'up'/'down'`), e `votes` (com `value`).*

**Exemplo para `add_favorite`:**
1.  **SQL INSERT:** `INSERT INTO bx_persons_favorites_track (object_id, author_id, date) VALUES (?, ?, ?);` (Lidar com `UNIQUE` constraint violation).
2.  **SQL UPDATE COUNT:** `UPDATE bx_persons_data SET favorites = favorites + 1 WHERE id = (SELECT content_id FROM sys_profiles WHERE id = ? AND type = 'bx_persons');`

## Funções para Metadados e Habilidades

*   **`set_profile_keywords(profile_id :: integer(), keywords :: list(String.t())) :: :ok | {:error, any()}`**
    *   Deleta keywords existentes para o `profile_id` e insere as novas.
    *   **SQL (DELETE):** `DELETE FROM bx_persons_meta_keywords WHERE object_id = ?;`
    *   **SQL (INSERT, em loop):** `INSERT INTO bx_persons_meta_keywords (object_id, keyword) VALUES (?, ?);` (Tudo em uma transação).

*   **`get_profile_keywords(profile_id :: integer()) :: {:ok, list(String.t())} | {:error, any()}`**
    *   **SQL:** `SELECT keyword FROM bx_persons_meta_keywords WHERE object_id = ?;`

*   **`set_profile_location_meta(profile_id :: integer(), location_attrs :: map()) :: {:ok, map()} | {:error, any()}`**
    *   `location_attrs` contém `lat`, `lng`, `country`, etc.
    *   **SQL:** `INSERT OR REPLACE INTO bx_persons_meta_locations (object_id, lat, lng, ...) VALUES (?, ?, ?, ...);`

*   **`get_profile_location_meta(profile_id :: integer()) :: {:ok, map() | nil} | {:error, any()}`**
    *   **SQL:** `SELECT * FROM bx_persons_meta_locations WHERE object_id = ?;`

*   **`add_mention(object_profile_id_context :: integer(), mentioned_profile_id :: integer()) :: :ok | {:error, any()}`**
*   **`get_mentions_in_object(object_profile_id_context :: integer()) :: {:ok, list(map())} | {:error, any()}`**
*   **`get_mentions_of_profile(mentioned_profile_id :: integer()) :: {:ok, list(map())} | {:error, any()}`**

*   **`set_profile_skills(profile_id :: integer(), skills :: list(String.t())) :: :ok | {:error, any()}`**
*   **`get_profile_skills(profile_id :: integer()) :: {:ok, list(String.t())} | {:error, any()}`**

### Considerações Gerais para `PersonsRepo`:

*   **Transações:** Muitas operações (como adicionar um favorito e atualizar o contador) devem ocorrer dentro de uma transação.
*   **Atualização de Contadores:** Após cada interação que tem um contador em `bx_persons_data` (views, comments, favorites, reports, scores, votes), o respectivo contador deve ser atualizado. Isso pode ser feito com uma query `UPDATE ... SET count_column = count_column + 1` ou buscando o valor atual e incrementando na aplicação antes de um `UPDATE`.
*   **Permissões:** A lógica de quem pode realizar certas ações (ex: deletar foto de outro, votar) será gerenciada pelos controllers da API usando o `AclRepo` antes de chamar as funções do `PersonsRepo`.
*   **Mapeamento de IDs:** Consistência no uso de `sys_profiles.id` (que chamaremos de `profile_id`) versus `bx_persons_data.id` (que é o `content_id` para perfis do tipo pessoa). Muitas queries farão `JOIN` entre `sys_profiles` e `bx_persons_data`.
*   **Paginação:** Para todas as funções de listagem (`list_pictures_for_profile`, `list_comments_for_profile`, etc.), implementar paginação com `LIMIT`/`OFFSET` e retornar metadados de paginação.