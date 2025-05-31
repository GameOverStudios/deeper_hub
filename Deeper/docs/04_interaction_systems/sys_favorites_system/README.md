# Documentação Deeper: Sistema de Favoritos Genérico

Este documento descreve a API \"Deeper\" para o sistema genérico de \"Favoritos\", permitindo que os usuários marquem diferentes tipos de conteúdo (perfis, posts, fotos, etc.) como seus favoritos.

## Sistema de Favoritos no UNA:

O UNA gerencia favoritos através de:

*   **`sys_objects_favorite`**: Define \"objetos de favorito\" para diferentes módulos ou tipos de conteúdo.
    *   `name`: Nome único do sistema de favoritos (ex: `bx_persons`, `bx_posts`).
    *   `table_track`: Tabela que armazena os registros de quem favoritou o quê (ex: `bx_persons_favorites_track`). Contém colunas como `object_id`, `author_id`, `date`.
    *   `table_lists` (Opcional no UNA, pode não ser usado por todos os objetos): Tabela para listas de favoritos personalizadas. Para \"Deeper\" inicial, podemos focar apenas no `table_track`.
    *   `is_undo`: Se o usuário pode desfavoritar.
    *   `is_public`: Se a lista de quem favoritou um item é pública.
    *   `trigger_table`, `trigger_field_id`, `trigger_field_count`: Para atualizar o contador de favoritos no conteúdo pai (ex: em `bx_persons_data.favorites`).

*   **Tabelas de Rastreamento de Favoritos (ex: `bx_persons_favorites_track`):**
    *   `id` (PK), `object_id` (ID do conteúdo favoritado), `author_id` (ID do perfil que favoritou), `date`.

## Estratégia da API \"Deeper\" para Favoritos:

A API \"Deeper\" fornecerá endpoints genéricos para marcar/desmarcar conteúdo como favorito e para verificar o status de favorito. A rota da API incluirá um identificador para o `favorite_object_name` (que corresponde a `sys_objects_favorite.name`).

### Módulo de Acesso a Dados (`Deeper.Interactions.FavoritesRepo`):

Este repositório genérico operará na `table_track` correta e atualizará a `trigger_table` dinamicamente.

**Funções Principais e SQLs Esperados (Parametrizados por `table_track`, `trigger_table`, etc.):**

*   **`get_favorite_system_config(favorite_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração de `sys_objects_favorite`.
    *   SQL: `SELECT * FROM sys_objects_favorite WHERE name = ? LIMIT 1;`
    *   Retorna `config` incluindo `table_track`, `is_undo`, `trigger_table`, `trigger_field_id`, `trigger_field_count`.

*   **`is_favorited(favorite_object_name, object_id, author_profile_id)`**
    *   Busca `config` para obter `table_track`.
    *   SQL: `SELECT 1 FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
    *   Retorna `true` se encontrado, `false` caso contrário.

*   **`get_favorites_count(favorite_object_name, object_id)`**
    *   Busca `config` para obter `table_track` (ou pode ler diretamente da `trigger_table` se o contador estiver sempre atualizado).
    *   SQL (para contagem direta): `SELECT COUNT(*) FROM #{table_track} WHERE object_id = ?;`
    *   Retorna a contagem.

*   **`add_favorite(favorite_object_name, author_profile_id, object_id)`**
    1.  Busca `config`.
    2.  Verifica se já está favoritado (usando `is_favorited`). Se sim, e `config.is_undo == 0` (ou se o comportamento é não fazer nada se já favoritado), retorna `{:ok, :already_favorited}` ou sucesso.
    3.  **Inicia Transação.**
    4.  Insere em `table_track`:
        *   SQL: `INSERT OR IGNORE INTO #{config.table_track} (object_id, author_id, date) VALUES (?, ?, ?);` (Usa `INSERT OR IGNORE` para evitar erro se já existir, assumindo `UNIQUE(object_id, author_id)` em `table_track`).
        *   Verifica o número de linhas alteradas pela inserção. Se 0, significa que já estava favoritado (se `is_undo` for o comportamento padrão de toggle, essa verificação inicial é mais importante).
    5.  Se a inserção foi bem-sucedida (ou se a lógica é adicionar mesmo que exista para forçar a atualização do contador, o que é menos comum para favoritos):
        *   Se `config.trigger_table` definido:
            *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_count} = #{config.trigger_field_count} + 1 WHERE #{config.trigger_field_id} = ?;`
    6.  **Commita Transação.**
    7.  Retorna `{:ok, :favorited}`.

*   **`remove_favorite(favorite_object_name, author_profile_id, object_id)`**
    1.  Busca `config`.
    2.  Se `config.is_undo == 0`, retorna `{:error, :cannot_undo_favorite}`.
    3.  **Inicia Transação.**
    4.  Deleta de `table_track`:
        *   SQL: `DELETE FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;`
    5.  Verifica o número de linhas afetadas. Se > 0 (significa que foi desfavoritado com sucesso):
        *   Se `config.trigger_table` definido:
            *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_count} = CASE WHEN #{config.trigger_field_count} > 0 THEN #{config.trigger_field_count} - 1 ELSE 0 END WHERE #{config.trigger_field_id} = ?;`
    6.  **Commita Transação.**
    7.  Retorna `{:ok, :unfavorited}`.

*   **`list_user_favorites(favorite_object_name, author_profile_id, opts)`** (Para \"Meus Favoritos\")
    *   Busca `config` para `table_track`.
    *   `opts`: `limit`, `offset`.
    *   SQL: `SELECT object_id, date FROM #{table_track} WHERE author_id = ? ORDER BY date DESC LIMIT ? OFFSET ?;`
    *   O resultado (lista de `object_id`s) precisará ser enriquecido com detalhes dos objetos (ex: nome, thumbnail) fazendo chamadas aos repositórios dos módulos de conteúdo correspondentes.

*   **`list_who_favorited(favorite_object_name, object_id, opts)`** (Se `config.is_public`)
    *   Busca `config` para `table_track`.
    *   SQL: `SELECT author_id, date FROM #{table_track} WHERE object_id = ? ORDER BY date DESC LIMIT ? OFFSET ?;`
    *   O resultado (lista de `author_id`s) precisará ser enriquecido com detalhes dos perfis dos autores.

### Endpoints da API (`/api/v1/favorites/{favorite_object_name}`):

O `{favorite_object_name}` na rota corresponde a `sys_objects_favorite.name` (ex: `bx_persons`, `bx_posts`).

*   **Verificar Status de Favorito e Contagem:**
    *   **Endpoint:** `GET /api/v1/favorites/{favorite_object_name}/object/{object_id}/status`
    *   **Path Parameters:** `favorite_object_name`, `object_id`.
    *   **Autenticação:** Requer JWT.
    *   **Resposta de Sucesso (200 OK):**

```json
        {
          \"data\": {
            \"object_id\": 123,
            \"is_favorited_by_current_user\": true,
            \"total_favorites_count\": 75
          }
        }
```

```json
        {
          \"data\": {
            \"object_id\": 123,
            \"is_favorited_by_current_user\": false, // Novo status
            \"total_favorites_count\": 74, // Nova contagem
            \"message\": \"Removed from favorites.\" // ou \"Added to favorites.\"
          }
        }
```

```json
        {
          \"data\": [ // Lista de objetos favoritados, enriquecidos com alguns detalhes
            { \"object_id\": 123, \"title\": \"Título do Post 1\", \"favorited_date\": 1678886400, \"thumbnail_url\": \"...\" },
            { \"object_id\": 456, \"fullname\": \"Nome da Pessoa\", \"favorited_date\": 1678880000, \"avatar_url\": \"...\" }
          ],
          \"pagination\": { /* ... */ }
        }
```

```json
        {
          \"data\": [ // Lista de perfis que favoritaram
            { \"profile_id\": 789, \"fullname\": \"Jane Doe\", \"favorited_date\": 1678886400, \"avatar_url\": \"...\" }
          ],
          \"pagination\": { /* ... */ }
        }
```

```sql
    CREATE TABLE IF NOT EXISTS sys_objects_favorite (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE, -- Nome do objeto de favorito, ex: bx_persons
      table_track TEXT NOT NULL, -- Tabela de rastreamento, ex: bx_persons_favorites_track
      table_lists TEXT, -- Opcional, para listas de favoritos
      pruning INTEGER DEFAULT 0, -- Dias para manter (0 = para sempre)
      is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      is_undo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      is_public INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      base_url TEXT, -- URL base no UNA PHP
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_author TEXT, -- Não usualmente necessário para favoritos, mas presente no schema UNA
      trigger_field_count TEXT, -- Coluna para contagem de favoritos
      class_name TEXT, -- Específico do UNA PHP
      class_file TEXT -- Específico do UNA PHP
    );
```

```sql
    CREATE TABLE IF NOT EXISTS bx_persons_favorites_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para bx_persons_data.id
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) que favoritou
      date INTEGER NOT NULL, -- Unix Timestamp
      UNIQUE (object_id, author_id) -- Um usuário só pode favoritar um item uma vez
    );
    CREATE INDEX IF NOT EXISTS idx_bx_persons_fav_track_author_object ON bx_persons_favorites_track(author_id, object_id);
```

*   **Marcar como Favorito / Desmarcar (Toggle):**
    *   **Endpoint:** `POST /api/v1/favorites/{favorite_object_name}/object/{object_id}/toggle`
    *   **Autenticação:** Requer JWT.
    *   **Lógica do Backend:** Verifica se já está favoritado. Se sim, chama `remove_favorite`. Se não, chama `add_favorite`. A resposta reflete o novo status.
    *   **Resposta de Sucesso (200 OK):**

    *   **Alternativa (endpoints separados):**
        *   `POST /api/v1/favorites/{favorite_object_name}/object/{object_id}` (para adicionar)
        *   `DELETE /api/v1/favorites/{favorite_object_name}/object/{object_id}` (para remover)

*   **Listar Meus Itens Favoritos (para um tipo de objeto):**
    *   **Endpoint:** `GET /api/v1/favorites/{favorite_object_name}/my-list`
    *   **Autenticação:** Requer JWT.
    *   **Query Parameters:** `page`, `per_page`.
    *   **Resposta de Sucesso (200 OK):**

    *   **Lógica do Backend:** Usa `FavoritesRepo.list_user_favorites` e depois busca detalhes de cada `object_id` no repositório do módulo correspondente.

*   **Listar Usuários que Favoritaram um Item (se público):**
    *   **Endpoint:** `GET /api/v1/favorites/{favorite_object_name}/object/{object_id}/who-favorited`
    *   **Autenticação:** Opcional (depende de `is_public`).
    *   **Query Parameters:** `page`, `per_page`.
    *   **Resposta de Sucesso (200 OK):**

## Tabelas de Favoritos (Esquema SQLite):

*   **`sys_objects_favorite` (Configuração):**

*   **Exemplo de Tabela de Rastreamento (`bx_persons_favorites_track`):**

## Considerações:

*   **Atomicidade:** Adicionar/remover favoritos e atualizar o contador na `trigger_table` deve ser uma operação atômica (transação).
*   **Chave Única:** A restrição `UNIQUE (object_id, author_id)` na `table_track` simplifica a lógica de adicionar/remover, pois `INSERT OR IGNORE` pode ser usado para adicionar, e `DELETE` para remover.
*   **Enriquecimento de Dados:** Os endpoints de listagem (`my-list`, `who-favorited`) exigirão que o `FavoritesRepo` colabore com outros repositórios para buscar os detalhes dos objetos favoritados ou dos perfis que favoritaram. Isso pode levar a problemas de N+1 se não for feito com cuidado (ex: buscar todos os IDs e depois fazer uma única query `WHERE id IN (...)` para cada tipo de objeto/perfil).

Este sistema de favoritos genérico oferece uma maneira consistente de gerenciar a funcionalidade de \"favoritar\" em toda a API \"Deeper\".