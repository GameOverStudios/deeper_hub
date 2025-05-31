# Documentação Deeper: Módulo de Acesso a Dados para Comentários (`CommentsRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.CommentsRepo` (ou similar), responsável por encapsular a lógica de consulta e manipulação de dados para o sistema de comentários genérico do UNA.

Ele interage principalmente com `sys_objects_cmts` (para configuração), `sys_cmts_ids` (para metadados/status dos comentários), e as tabelas de conteúdo de comentários específicas do objeto (cujo nome é definido em `sys_objects_cmts.\"Table\"`).

**Localização do Código:** `lib/deeper/interaction_systems/comments_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Configuração do Objeto de Comentários

*   **`get_comment_system_config(object_interaction_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a configuração de um sistema de comentários específico de `sys_objects_cmts`.
    *   **Argumentos:**
        *   `object_interaction_name`: O nome do objeto de comentários (de `sys_objects_cmts.Name`).
    *   **Retorno:** `{:ok, config_map}` onde `config_map` contém todas as colunas de `sys_objects_cmts` para o objeto encontrado (ex: `%{name: \"bx_posts_cmts\", table: \"bx_posts_comments_table\", per_view: 10, ...}}`).
    *   **SQL:** `SELECT * FROM sys_objects_cmts WHERE Name = ? AND IsOn = 1 LIMIT 1;`
    *   Esta função é crucial e será usada internamente por muitas outras funções do `CommentsRepo`.

### 2. Listar Comentários para um Item de Conteúdo

*   **`list_comments(object_interaction_name :: String.t(), item_id :: integer(), opts :: map()) :: {:ok, %{data: list(map()), pagination: map(), config: map()}} | {:error, any()}`**
    *   Busca comentários para um item de conteúdo específico, com suporte para paginação, ordenação e respostas aninhadas (de forma limitada ou para o cliente resolver).
    *   **Argumentos:**
        *   `object_interaction_name`: Nome do objeto de comentários (ex: `bx_posts_cmts`).
        *   `item_id`: ID do item de conteúdo que está sendo comentado.
        *   `opts`: Mapa de opções, como:
            *   `parent_id :: integer()` (default `0` para comentários de nível superior).
            *   `page :: integer()`, `per_page :: integer()`.
            *   `sort_by :: String.t()` (ex: `cmt_time_desc`, `cmt_votes_desc`).
            *   `user_level_id :: integer() | nil` (para filtrar por visibilidade do comentário, se `sys_cmts_ids.status_admin` for usado).
    *   **Retorno:** Um mapa contendo a lista de comentários (`data`), informações de paginação (`pagination`), e a configuração do sistema de comentários (`config`) obtida de `get_comment_system_config/1`.
        Cada comentário no mapa `data` deve incluir:
        *   Dados da tabela de conteúdo do comentário (ex: `cmt_id`, `cmt_text`, `cmt_time`, `cmt_parent_id`, `cmt_replies`).
        *   Dados do autor (obtidos por JOIN com `sys_profiles` e `bx_persons_data` ou tabela de perfil equivalente).
        *   Metadados de `sys_cmts_ids` (votos no comentário, reports, score, `status_admin`).
    *   **Lógica Interna Detalhada:**
        1.  Chamar `get_comment_system_config(object_interaction_name)` para obter `config`. Se erro, propagar.
        2.  Obter o nome da tabela de conteúdo dos comentários: `comments_table_name = config.table`.
        3.  Construir a query SQL dinamicamente usando `comments_table_name`.
            *   **SQL (Exemplo para buscar comentários de nível superior, ordenados por tempo):**

```sql
                -- Query para dados
                SELECT
                    ct.cmt_id, ct.cmt_parent_id, ct.cmt_object_id, ct.cmt_author_id, ct.cmt_level, ct.cmt_text, ct.cmt_mood, ct.cmt_time, ct.cmt_replies, ct.cmt_pinned,
                    author_prof.id as author_profile_id, author_pdata.fullname as author_fullname, author_pdata.picture as author_picture_id, -- ou URI da foto
                    meta.rate as cmt_meta_rate, meta.votes as cmt_meta_votes, meta.score as cmt_meta_score, meta.reports as cmt_meta_reports, meta.status_admin as cmt_meta_status_admin
                FROM #{comments_table_name} ct
                JOIN sys_profiles author_prof ON ct.cmt_author_id = author_prof.id
                LEFT JOIN bx_persons_data author_pdata ON author_prof.content_id = author_pdata.id AND author_prof.type = 'bx_persons' -- Adaptar se houver outros tipos de perfil de autor
                LEFT JOIN sys_cmts_ids meta ON meta.system_id = ? AND meta.cmt_id = ct.cmt_id -- system_id é config.id
                WHERE ct.cmt_object_id = ? AND ct.cmt_parent_id = ? -- item_id, opts.parent_id
                  -- AND (meta.status_admin = 'active' OR meta.status_admin IS NULL) -- Filtrar por status_admin se necessário, considerando user_level_id
                ORDER BY ct.cmt_time DESC -- Ou conforme opts.sort_by
                LIMIT ? OFFSET ?;

                -- Query para contagem total (para paginação)
                SELECT COUNT(ct.cmt_id) as total_count
                FROM #{comments_table_name} ct
                LEFT JOIN sys_cmts_ids meta ON meta.system_id = ? AND meta.cmt_id = ct.cmt_id
                WHERE ct.cmt_object_id = ? AND ct.cmt_parent_id = ?;
                  -- AND (meta.status_admin = 'active' OR meta.status_admin IS NULL)
```

            *   Parâmetros: `config.id`, `item_id`, `opts.parent_id || 0`, `opts.per_page`, `offset`.
        4.  Executar as queries.
        5.  Mapear os resultados para a estrutura de dados desejada.
        6.  Construir o mapa de paginação.

### 3. Adicionar um Novo Comentário

*   **`add_comment(object_interaction_name :: String.t(), item_id :: integer(), author_profile_id :: integer(), comment_data :: map()) :: {:ok, map()} | {:error, any()}`**
    *   Adiciona um novo comentário a um item de conteúdo.
    *   **Argumentos:**
        *   `comment_data`: Mapa contendo `cmt_text`, `cmt_parent_id` (opcional, default 0), `cmt_mood` (opcional).
    *   **Retorno:** O comentário criado, incluindo dados do autor e metadados.
    *   **Lógica Interna:**
        1.  Chamar `get_comment_system_config(object_interaction_name)` para obter `config`.
        2.  Validar `comment_data.cmt_text` contra `config.chars_post_min` e `config.chars_post_max`.
        3.  Se `comment_data.cmt_parent_id` > 0, buscar o comentário pai para determinar `cmt_level` e `cmt_vparent_id`.
        4.  **Em uma transação:**
            a.  **Inserir na tabela de conteúdo do comentário (`config.table`):**
                *   SQL: `INSERT INTO #{config.table} (cmt_object_id, cmt_author_id, cmt_text, cmt_parent_id, cmt_level, cmt_vparent_id, cmt_time, cmt_mood) VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING *;`
                *   Parâmetros: `item_id`, `author_profile_id`, `comment_data.cmt_text`, `parent_id`, `level`, `vparent_id`, `current_timestamp`, `mood`.
            b.  Obter o `cmt_id` do comentário inserido.
            c.  **Inserir em `sys_cmts_ids`:**
                *   SQL: `INSERT INTO sys_cmts_ids (system_id, cmt_id, author_id) VALUES (?, ?, ?);`
                *   Parâmetros: `config.id`, `new_cmt_id`, `author_profile_id`.
            d.  **Atualizar contador de respostas no comentário pai (se `cmt_parent_id > 0`):**
                *   SQL: `UPDATE #{config.table} SET cmt_replies = cmt_replies + 1 WHERE cmt_id = ?;`
                *   Parâmetro: `cmt_parent_id`.
            e.  **Atualizar contador de comentários na tabela de conteúdo principal (`config.trigger_table`):**
                *   Se `config.trigger_table` e `config.trigger_field_comments` estiverem definidos:
                *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_comments} = #{config.trigger_field_comments} + 1 WHERE #{config.trigger_field_id} = ?;`
                *   Parâmetro: `item_id`.
        5.  Buscar o comentário recém-criado com detalhes do autor e metadados para retornar.

### 4. Obter um Comentário Específico

*   **`get_comment(object_interaction_name :: String.t(), cmt_id_in_content_table :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca um comentário específico pelo seu ID na tabela de conteúdo.
    *   **Lógica:** Similar a `list_comments`, mas buscando por `ct.cmt_id`.

### 5. Atualizar um Comentário

*   **`update_comment(object_interaction_name :: String.t(), cmt_id_in_content_table :: integer(), author_profile_id :: integer(), new_text :: String.t()) :: {:ok, map()} | {:error, :not_found | :unauthorized | any()}`**
    *   Permite que o autor atualize seu comentário.
    *   **Lógica:**
        1.  Verificar se `author_profile_id` é o autor do comentário.
        2.  SQL: `UPDATE #{config.table} SET cmt_text = ?, cmt_time = ? WHERE cmt_id = ? AND cmt_author_id = ? RETURNING *;` (atualiza `cmt_time` para refletir a edição).

### 6. Deletar um Comentário

*   **`delete_comment(object_interaction_name :: String.t(), cmt_id_in_content_table :: integer(), Deleter_profile_id :: integer(), is_moderator :: boolean()) :: :ok | {:error, :not_found | :unauthorized | any()}`**
    *   Deleta um comentário. Requer verificação se o `deleter_profile_id` é o autor ou um moderador.
    *   **Lógica:**
        1.  Verificar permissões.
        2.  **Em uma transação:**
            a.  Deletar de `sys_cmts_ids`.
            b.  Deletar da tabela de conteúdo do comentário (`config.table`).
            c.  Atualizar `cmt_replies` no pai (se houver).
            d.  Decrementar o contador em `config.trigger_table`.
            e.  (Opcional) Deletar recursivamente as respostas, ou marcá-las como órfãs/deletadas.

### Funções para Interações *nos* Comentários (Votos, Reports, etc.)

*Se os comentários em si puderem ser votados, denunciados, etc. (configurado em `sys_objects_cmts.ObjectVote`, etc.), o `CommentsRepo` pode ter funções que delegam para os Repos de interação correspondentes (ex: `VotingRepo`, `ReportingRepo`).*

*   **`vote_on_comment(object_interaction_name :: String.t(), cmt_id_in_content_table :: integer(), voter_profile_id :: integer(), vote_value :: integer()) :: :ok | {:error, any()}`**
    *   **Lógica:**
        1.  Obter `config` de `sys_objects_cmts`.
        2.  Obter `sys_cmts_ids.id` para o `config.id` e `cmt_id_in_content_table`. Este `sys_cmts_ids.id` se torna o `item_id` para o `VotingRepo`.
        3.  Chamar `VotingRepo.add_vote(config.object_vote, sys_cmts_ids_id, voter_profile_id, vote_value)`.
        4.  O `VotingRepo` (ou uma camada de serviço) seria responsável por atualizar `sys_cmts_ids.rate` e `sys_cmts_ids.votes`.

### Considerações:

*   **Nomes de Tabela Dinâmicos:** O uso de `#{config.table}` para construir SQL é uma forma de lidar com nomes de tabela dinâmicos. É crucial que `config.table` seja validado ou venha de uma fonte confiável para evitar injeção de SQL no nome da tabela. Uma abordagem mais segura seria ter um case/condicional que mapeia `object_interaction_name` para um nome de tabela fixo conhecido pela aplicação, se o número de tabelas de comentários for limitado.
*   **Desserialização/Serialização:** Se campos como `cmt_mood` ou outros metadados forem armazenados de forma serializada (embora menos comum para comentários), a lógica de tratamento seria necessária.
*   **Performance:** JOINs com tabelas de perfil de autor são comuns. Índices em `cmt_author_id`, `cmt_object_id`, `cmt_parent_id` são essenciais. Para paginação eficiente, especialmente com ordenação complexa, podem ser necessárias estratégias de \"deferred join\" ou \"keyset pagination\".
*   **Traduções (se `cmt_text` for uma chave de linguagem):** Improvável para conteúdo de usuário, mas se fosse o caso, integração com `LocalizationRepo`.