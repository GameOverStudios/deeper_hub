# Documentação Deeper: Módulo de Acesso a Dados para Sistema de Favoritos Genérico (`Deeper.Interactions.FavoritesRepo`)

Este documento descreve o módulo Elixir `Deeper.Interactions.FavoritesRepo`. Ele é projetado para ser um repositório genérico que lida com operações de \"favoritar\" para diferentes sistemas definidos em `sys_objects_favorite`.

Ele operará dinamicamente na `table_track` correta e usará as configurações apropriadas (como `trigger_table` para atualizar contadores) com base no `favorite_object_name` fornecido.

## Responsabilidades Principais:

*   Obter configurações de um sistema de favoritos específico de `sys_objects_favorite`.
*   Verificar se um usuário já favoritou um `object_id`.
*   Obter a contagem total de favoritos para um `object_id`.
*   Adicionar um item aos favoritos de um usuário, atualizando a tabela de rastreamento e o contador na tabela \"trigger\".
*   Remover um item dos favoritos de um usuário e atualizar contadores.
*   Listar os itens favoritados por um usuário.
*   Listar os usuários que favoritaram um item específico (se público).

## Funções Auxiliares Chave (Internas):

*   **`get_favorite_system_config(favorite_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração completa de `sys_objects_favorite`.
    *   SQL: `SELECT * FROM sys_objects_favorite WHERE name = ? LIMIT 1;`
    *   Retorna mapa com `name`, `table_track`, `is_undo`, `is_public`, `trigger_table`, `trigger_field_id`, `trigger_field_count`.
    *   Pode ser cacheado.

## Funções Públicas Principais e Lógica SQL:

*(Todas as funções públicas aceitarão `favorite_object_name` como primeiro argumento).*

*   **`get_favorite_status_and_count(favorite_object_name :: String.t(), object_id :: integer(), author_profile_id :: integer() | nil) :: {:ok, status_map :: map()} | {:error, any()}`**
    1.  `{:ok, config} = get_favorite_system_config(favorite_object_name)`
    2.  `table_track = config[\"table_track\"]`
    3.  Busca contagem total (pode ler diretamente do `trigger_table` se confiável, ou contar em `table_track`):
        *   SQL (contar): `SELECT COUNT(*) AS total_count FROM #{table_track} WHERE object_id = ?;`
        *   Alternativa (ler do trigger): `SELECT #{config[\"trigger_field_count\"]} AS total_count FROM #{config[\"trigger_table\"]} WHERE #{config[\"trigger_field_id\"]} = ?;` (Requer que `trigger_table` e campos estejam configurados e atualizados). Vamos assumir contagem direta para mais precisão inicial.
    4.  `is_favorited = false`
    5.  Se `author_profile_id` fornecido:
        *   SQL: `SELECT 1 FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
        *   Se resultado encontrado, `is_favorited = true`.
    6.  Retorna `{:ok, %{object_id: object_id, is_favorited_by_current_user: is_favorited, total_favorites_count: total_count}}`.

*   **`toggle_favorite(favorite_object_name :: String.t(), author_profile_id :: integer(), object_id :: integer()) :: {:ok, result_map :: map()} | {:error, any()}`**
    1.  `{:ok, config} = get_favorite_system_config(favorite_object_name)`
    2.  `table_track = config[\"table_track\"]`
    3.  Verifica se já está favoritado:
        *   SQL: `SELECT id FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
        *   `existing_favorite_id = resultado_ou_nil`
    4.  **Inicia Transação.**
    5.  Se `existing_favorite_id` (está favoritado):
        *   // Tentar Desfavoritar
        *   Se `config.is_undo == 0` (ou `false`), retorna `{:error, :cannot_undo_favorite}` (e rollback).
        *   SQL: `DELETE FROM #{table_track} WHERE id = ?;` (usando `existing_favorite_id`).
        *   Se delete bem-sucedido e `config.trigger_table` definido:
            *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_count} = CASE WHEN #{config.trigger_field_count} > 0 THEN #{config.trigger_field_count} - 1 ELSE 0 END WHERE #{config.trigger_field_id} = ?;`
        *   `action_taken = :unfavorited`, `new_is_favorited = false`
    6.  Else (não está favoritado):
        *   // Tentar Favoritar
        *   `current_time = System.os_time(:second)`
        *   SQL: `INSERT INTO #{table_track} (object_id, author_id, date) VALUES (?, ?, ?);` (A constraint `UNIQUE` em `table_track` previne duplicatas).
        *   Se insert bem-sucedido e `config.trigger_table` definido:
            *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_count} = #{config.trigger_field_count} + 1 WHERE #{config.trigger_field_id} = ?;`
        *   `action_taken = :favorited`, `new_is_favorited = true`
    7.  **Commita Transação.**
    8.  Busca a nova contagem total de favoritos para o `object_id`.
    9.  Retorna `{:ok, %{action: action_taken, is_favorited_by_current_user: new_is_favorited, total_favorites_count: new_total_count}}`.

*   **`list_user_favorite_objects(favorite_object_name :: String.t(), author_profile_id :: integer(), opts :: Keyword.t()) :: {:ok, {object_ids_with_date :: list(map()), pagination_meta :: map()}} | {:error, any()}`**
    *   `opts`: `limit`, `offset`.
    1.  `{:ok, config} = get_favorite_system_config(favorite_object_name)`
    2.  `table_track = config[\"table_track\"]`
    3.  SQL (para dados): `SELECT object_id, date FROM #{table_track} WHERE author_id = ? ORDER BY date DESC LIMIT ? OFFSET ?;`
    4.  SQL (para contagem total): `SELECT COUNT(*) FROM #{table_track} WHERE author_id = ?;`
    5.  Retorna a lista de `%{object_id: ..., date: ...}` e metadados de paginação. O controller da API precisará enriquecer esses `object_id`s.

*   **`list_who_favorited_object(favorite_object_name :: String.t(), object_id :: integer(), opts :: Keyword.t()) :: {:ok, {author_ids_with_date :: list(map()), pagination_meta :: map()}} | {:error, any()}`**
    *   `opts`: `limit`, `offset`.
    1.  `{:ok, config} = get_favorite_system_config(favorite_object_name)`
    2.  Se `config.is_public == 0` (ou `false`), retorna `{:error, :favorites_list_not_public}`.
    3.  `table_track = config[\"table_track\"]`
    4.  SQL (para dados): `SELECT author_id, date FROM #{table_track} WHERE object_id = ? ORDER BY date DESC LIMIT ? OFFSET ?;`
    5.  SQL (para contagem total): `SELECT COUNT(*) FROM #{table_track} WHERE object_id = ?;`
    6.  Retorna a lista de `%{author_id: ..., date: ...}` e metadados de paginação. O controller da API precisará enriquecer esses `author_id`s com detalhes do perfil.

## Considerações:

*   **Constraint `UNIQUE`:** A presença da constraint `UNIQUE (object_id, author_id)` na `table_track` é fundamental para a simplicidade da lógica de `toggle_favorite`, especialmente ao usar `INSERT OR IGNORE` ou ao tentar inserir e deixar o DB sinalizar o erro de duplicidade. O schema do UNA para `bx_persons_favorites_track` *não* tinha essa constraint no dump original, mas foi adicionada na nossa migração SQLite por ser uma prática comum e útil. Se essa constraint não existir, a lógica de `toggle_favorite` precisa primeiro verificar a existência antes de inserir/deletar.
*   **Performance:** A atualização do contador na `trigger_table` deve ser rápida. Para sistemas com muitas interações, essa contagem pode, alternativamente, ser gerenciada por jobs em background, mas isso introduz um atraso na exibição da contagem correta.

Este `FavoritesRepo` genérico fornecerá a base para a funcionalidade de \"favoritar\" em toda a API \"Deeper\".