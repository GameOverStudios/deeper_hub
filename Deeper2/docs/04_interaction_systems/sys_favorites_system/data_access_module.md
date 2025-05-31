# Documentação Deeper: Módulo de Acesso a Dados para Favoritos (`FavoritesRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.FavoritesRepo` (ou similar), responsável por encapsular a lógica de consulta e manipulação de dados para o sistema de favoritos genérico do UNA.

Ele interage com `sys_objects_favorite` (para configuração) e dinamicamente com a tabela de rastreamento (`table_track`) especificada na configuração do objeto de favorito.

**Localização do Código:** `lib/deeper/interaction_systems/favorites_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Configuração do Objeto de Favorito

*   **`get_favorite_system_config(object_fav_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a configuração de um sistema de favoritos específico de `sys_objects_favorite`.
    *   **Argumentos:**
        *   `object_fav_name`: O nome do objeto de favorito (de `sys_objects_favorite.name`).
    *   **Retorno:** `{:ok, config_map}` contendo todas as colunas de `sys_objects_favorite` (ex: `%{name: \"bx_persons_favorites\", table_track: \"bx_persons_favorites_track\", ...}}`).
    *   **SQL:** `SELECT * FROM sys_objects_favorite WHERE name = ? AND is_on = 1 LIMIT 1;`
    *   Usada internamente por outras funções do `FavoritesRepo`.

### 2. Adicionar um Item aos Favoritos de um Usuário

*   **`add_favorite(object_fav_name :: String.t(), item_id :: integer(), author_profile_id :: integer()) :: {:ok, map()} | {:error, :already_favorited | :cannot_favorite | any()}`**
    *   Registra que um usuário favoritou um item.
    *   **Retorno:** Mapa com o status, ex: `%{favorited: true, item_id: item_id, favorites_count: new_count}`.
    *   **Lógica Interna:**
        1.  Chamar `get_favorite_system_config(object_fav_name)` para obter `config`.
        2.  **Em uma transação:**
            a.  Verificar se já existe na `config.table_track`.
                *   SQL: `SELECT id FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;`
                *   Se sim, retorna `{:error, :already_favorited}` ou simplesmente `{:ok, current_status}`.
            b.  **Inserir em `config.table_track`:**
                *   SQL: `INSERT INTO #{config.table_track} (object_id, author_id, date) VALUES (?, ?, ?);` (date é timestamp atual).
            c.  **Atualizar `TriggerTable` (contador de favoritos):**
                *   Se `config.trigger_table` e `config.trigger_field_count` estiverem definidos:
                *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_count} = #{config.trigger_field_count} + 1 WHERE #{config.trigger_field_id} = ?;`
                *   Parâmetro: `item_id`.
        3.  Buscar o novo contador de favoritos para o item e retornar.

### 3. Remover um Item dos Favoritos de um Usuário

*   **`remove_favorite(object_fav_name :: String.t(), item_id :: integer(), author_profile_id :: integer()) :: {:ok, map()} | {:error, :not_favorited | :cannot_undo | any()}`**
    *   Remove um item da lista de favoritos de um usuário.
    *   **Retorno:** Mapa com o status, ex: `%{favorited: false, item_id: item_id, favorites_count: new_count}`.
    *   **Lógica Interna:**
        1.  Chamar `get_favorite_system_config(object_fav_name)` para obter `config`.
        2.  Se `config.is_undo == 0`, retorna `{:error, :cannot_undo}`.
        3.  **Em uma transação:**
            a.  **Deletar de `config.table_track`:**
                *   SQL: `DELETE FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;`
                *   Verificar se alguma linha foi afetada. Se não, retorna `{:error, :not_favorited}`.
            b.  **Atualizar `TriggerTable` (contador de favoritos):**
                *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_count} = MAX(0, #{config.trigger_field_count} - 1) WHERE #{config.trigger_field_id} = ?;`
        4.  Buscar o novo contador de favoritos para o item e retornar.

### 4. Verificar Status de Favorito

*   **`is_item_favorited_by_user(object_fav_name :: String.t(), item_id :: integer(), author_profile_id :: integer()) :: {:ok, boolean()} | {:error, any()}`**
    *   Verifica se um usuário específico favoritou um item.
    *   **Lógica Interna:**
        1.  Chamar `get_favorite_system_config(object_fav_name)`.
        2.  SQL: `SELECT COUNT(id) as count FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;`
        3.  Retorna `{:ok, count > 0}`.

### 5. Listar Usuários que Favoritaram um Item

*   **`list_users_who_favorited_item(object_fav_name :: String.t(), item_id :: integer(), opts :: map()) :: {:ok, %{data: list(map()), pagination: map()}} | {:error, :not_public | any()}`**
    *   Lista os perfis dos usuários que favoritaram um item específico.
    *   **Argumentos:**
        *   `opts`: Mapa para paginação (`page`, `per_page`).
    *   **Retorno:** Lista de perfis (com dados resumidos como ID, nome, avatar).
    *   **Lógica Interna:**
        1.  Chamar `get_favorite_system_config(object_fav_name)`.
        2.  Se `config.is_public == 0`, retorna `{:error, :not_public}` (a menos que o solicitante seja admin/dono).
        3.  SQL (para `config.table_track`):

```sql
            SELECT
                fav.author_id,
                fav.date as favorited_date,
                author_prof.id as profile_id, -- sys_profiles.id
                author_pdata.fullname as author_fullname,
                author_pdata.picture as author_picture_id -- ou URI da foto principal
            FROM #{config.table_track} fav
            JOIN sys_profiles author_prof ON fav.author_id = author_prof.id
            LEFT JOIN bx_persons_data author_pdata ON author_prof.content_id = author_pdata.id AND author_prof.type = 'bx_persons' -- Adaptar para outros tipos de perfil
            WHERE fav.object_id = ?
            ORDER BY fav.date DESC
            LIMIT ? OFFSET ?;
```

```sql
            SELECT
                fav.object_id,
                fav.date as favorited_date
                -- ,content_main.title as item_title -- Exemplo se TriggerTable for bx_posts e TriggerFieldTitle for 'title'
                -- ,content_main.uri as item_uri
            FROM #{config.table_track} fav
            -- LEFT JOIN #{config.trigger_table} content_main ON fav.object_id = content_main.#{config.trigger_field_id} -- JOIN para obter detalhes do item
            WHERE fav.author_id = ?
            ORDER BY fav.date DESC
            LIMIT ? OFFSET ?;
```

        4.  Query para contagem total para paginação.
        5.  Mapear e retornar.

### 6. Listar Itens Favoritados por um Usuário

*   **`list_items_favorited_by_user(object_fav_name :: String.t(), author_profile_id :: integer(), opts :: map()) :: {:ok, %{data: list(map()), pagination: map()}} | {:error, any()}`**
    *   Lista todos os itens (de um determinado `object_fav_name`) que um usuário favoritou.
    *   **Retorno:** Lista de itens favoritados. Os detalhes do item (título, link, imagem) precisarão ser buscados com `JOIN`s ou chamadas subsequentes dependendo do tipo de `item_id`.
    *   **Lógica Interna:**
        1.  Chamar `get_favorite_system_config(object_fav_name)`.
        2.  SQL (para `config.table_track`):

            *   **Nota:** O JOIN com `config.trigger_table` para obter detalhes do item é complexo porque o nome da tabela e dos campos são dinâmicos. Pode ser mais prático retornar apenas `object_id` e `favorited_date`, e o cliente/serviço de nível superior busca os detalhes do item se necessário, sabendo o tipo de `object_fav_name`.
        3.  Query para contagem total.
        4.  Mapear e retornar.

### 7. Obter Contagem de Favoritos para um Item

*   **`get_favorites_count_for_item(object_fav_name :: String.t(), item_id :: integer()) :: {:ok, integer()} | {:error, any()}`**
    *   Retorna o número de vezes que um item foi favoritado.
    *   **Lógica Interna:**
        1.  Chamar `get_favorite_system_config(object_fav_name)`.
        2.  Se `config.trigger_table` e `config.trigger_field_count` estiverem definidos:
            *   SQL: `SELECT #{config.trigger_field_count} FROM #{config.trigger_table} WHERE #{config.trigger_field_id} = ?;`
        3.  Alternativamente, ou como fallback, contar diretamente da `config.table_track`:
            *   SQL: `SELECT COUNT(id) FROM #{config.table_track} WHERE object_id = ?;`

### Considerações:

*   **Nomes de Tabela Dinâmicos:** Validação ou mapeamento seguro dos nomes de tabela de `config.table_track` e `config.trigger_table` é essencial.
*   **Transações:** `add_favorite` e `remove_favorite` devem usar transações se atualizarem múltiplas tabelas (track e trigger).
*   **Atualização de Contadores:** A lógica para incrementar/decrementar `config.trigger_field_count` na `config.trigger_table` é uma parte chave.