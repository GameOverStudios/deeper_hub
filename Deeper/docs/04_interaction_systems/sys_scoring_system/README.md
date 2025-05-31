# Documentação Deeper: Sistema de Pontuações (Scores) Genérico

Este documento descreve a API \"Deeper\" para o sistema genérico de \"Pontuações\" (Scores), permitindo que os usuários votem positivo (up-vote) ou negativo (down-vote) em diferentes tipos de conteúdo, resultando em uma pontuação líquida.

## Sistema de Pontuações no UNA:

O UNA gerencia pontuações através de:

*   **`sys_objects_score`**: Define \"objetos de score\" para diferentes módulos ou tipos de conteúdo.
    *   `name`: Nome único do sistema de pontuação (ex: `bx_persons_score`, `sys_cmts_default_score` para comentários).
    *   `module`: Módulo associado.
    *   `table_main`: Tabela que armazena os dados agregados das pontuações (ex: `bx_persons_scores`). Contém colunas como `object_id`, `count_up`, `count_down`. A pontuação líquida (`score`) é geralmente `count_up - count_down`.
    *   `table_track`: Tabela que armazena os votos individuais (up/down) dos usuários (ex: `bx_persons_scores_track`). Contém colunas como `object_id`, `author_id`, `author_nip`, `type` ('up' ou 'down'), `date`.
    *   `post_timeout`: Tempo em segundos antes que um usuário possa votar novamente ou mudar seu voto no mesmo item.
    *   `is_undo`: Se o usuário pode remover/alterar seu voto de score.
    *   `trigger_table`, `trigger_field_id`, `trigger_field_score`, `trigger_field_cup` (count up), `trigger_field_cdown` (count down): Para atualizar a pontuação e contagens no conteúdo pai (ex: em `bx_persons_data.score`, `sc_up`, `sc_down`).

*   **Tabelas de Pontuações:**
    *   **Tabela de Agregação (ex: `bx_persons_scores`):** `id` (PK), `object_id` (ID do conteúdo pontuado), `count_up`, `count_down`.
    *   **Tabela de Rastreamento (ex: `bx_persons_scores_track`):** `id` (PK), `object_id`, `author_id`, `author_nip`, `type` (`'up'` ou `'down'`), `date`.

## Estratégia da API \"Deeper\" para Pontuações:

A API \"Deeper\" fornecerá endpoints genéricos para usuários submeterem votos de score (up/down) e para obter a pontuação atual de um item. A rota da API incluirá um identificador para o `score_object_name` (que corresponde a `sys_objects_score.name`).

### Módulo de Acesso a Dados (`Deeper.Interactions.ScoringRepo`):

Este repositório genérico operará nas tabelas `table_main` e `table_track` corretas e atualizará a `trigger_table` dinamicamente.

**Funções Principais e SQLs Esperados (Parametrizados por `table_main`, `table_track`, etc.):**

*   **`get_score_system_config(score_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração de `sys_objects_score`.
    *   SQL: `SELECT * FROM sys_objects_score WHERE name = ? LIMIT 1;`
    *   Retorna `config` incluindo `table_main`, `table_track`, `is_undo`, `post_timeout`, `trigger_table`, `trigger_field_id`, `trigger_field_score`, `trigger_field_cup`, `trigger_field_cdown`.

*   **`get_score_details(score_object_name, object_id, current_user_profile_id :: integer() | nil)`**
    1.  Busca `config`. `table_main = config[\"table_main\"]`.
    2.  SQL (agregação): `SELECT count_up, count_down FROM #{table_main} WHERE object_id = ? LIMIT 1;`
    3.  `score_data = resultado_ou_mapa_default_com_zeros`. `net_score = score_data[\"count_up\"] - score_data[\"count_down\"]`.
    4.  `user_vote_type = nil`. Se `current_user_profile_id` fornecido:
        *   SQL (voto do usuário): `SELECT type FROM #{config[\"table_track\"]} WHERE object_id = ? AND author_id = ? ORDER BY date DESC LIMIT 1;`
        *   `user_vote_type = resultado_ou_nil`.
    5.  Retorna `%{object_id: object_id, score: net_score, count_up: score_data[\"count_up\"], count_down: score_data[\"count_down\"], current_user_vote_type: user_vote_type}`.

*   **`submit_score_vote(score_object_name, author_profile_id, author_nip, params :: map())`**
    *   `params`: `object_id :: integer()`, `vote_type :: String.t()` (deve ser \"up\" ou \"down\").
    1.  Busca `config`. Valida `vote_type`.
    2.  `table_track = config[\"table_track\"]`, `table_main = config[\"table_main\"]`.
    3.  `current_time = System.os_time(:second)`.
    4.  Busca o voto anterior do usuário:
        *   SQL: `SELECT id AS track_id, type, date FROM #{table_track} WHERE object_id = ? AND author_id = ? ORDER BY date DESC LIMIT 1;`
        *   `previous_vote = resultado_ou_nil`.
    5.  **Lógica de Permissão/Timeout/Undo:**
        *   Se `previous_vote` existe:
            *   Se `config.post_timeout > 0` e `current_time - previous_vote[\"date\"] < config.post_timeout` E `params.vote_type == previous_vote[\"type\"]` (tentando votar o mesmo novamente dentro do timeout), retorna `{:error, :scoring_timeout}`.
            *   Se `config.is_undo == 0` E `params.vote_type == previous_vote[\"type\"]`, retorna `{:error, :already_voted_same}`.
            *   Se `config.is_undo == 0` E `params.vote_type != previous_vote[\"type\"]`, retorna `{:error, :cannot_change_vote}`.
    6.  **Inicia Transação.**
    7.  `delta_up = 0`, `delta_down = 0`.
    8.  Se `previous_vote` existe e `config.is_undo == 1`: // Usuário está mudando o voto ou removendo-o
        *   Se `previous_vote[\"type\"] == \"up\"`, `delta_up = delta_up - 1`.
        *   Else (`previous_vote[\"type\"] == \"down\"`), `delta_down = delta_down - 1`.
        *   Se `params.vote_type == previous_vote[\"type\"]`: // Usuário clicou no mesmo botão (desfazendo o voto)
            *   SQL: `DELETE FROM #{table_track} WHERE id = ?;` (usando `previous_vote[\"track_id\"]`).
            *   `action_result = :vote_removed`.
        *   Else (`params.vote_type != previous_vote[\"type\"]`): // Usuário mudou de up para down ou vice-versa
            *   Se `params.vote_type == \"up\"`, `delta_up = delta_up + 1`.
            *   Else, `delta_down = delta_down + 1`.
            *   SQL: `UPDATE #{table_track} SET type = ?, date = ? WHERE id = ?;` (usando `params.vote_type`, `current_time`, `previous_vote[\"track_id\"]`).
            *   `action_result = :vote_changed`.
    9.  Else (`previous_vote` não existe): // Novo voto
        *   Se `params.vote_type == \"up\"`, `delta_up = 1`.
        *   Else, `delta_down = 1`.
        *   SQL: `INSERT INTO #{table_track} (object_id, author_id, author_nip, type, date) VALUES (?, ?, ?, ?, ?);`
        *   `action_result = :vote_added`.
    10. Atualiza `table_main`:
        *   SQL:

```json
        {
          \"data\": {
            \"object_id\": 123,
            \"score\": 75, // count_up - count_down
            \"count_up\": 100,
            \"count_down\": 25,
            \"current_user_vote_type\": \"up\" // \"up\", \"down\", ou null
          }
        }
```

```json
        {
          \"vote_type\": \"up\" // ou \"down\"
        }
```

```json
        {
          \"data\": {
            \"object_id\": 123,
            \"score\": 76,
            \"count_up\": 101,
            \"count_down\": 25,
            \"current_user_vote_type\": \"up\",
            \"message\": \"Vote registered.\" // ou \"Vote changed.\", \"Vote removed.\"
          }
        }
```

```sql
            INSERT INTO #{table_main} (object_id, count_up, count_down)
            VALUES (?, CASE WHEN #{delta_up} > 0 THEN #{delta_up} ELSE 0 END, CASE WHEN #{delta_down} > 0 THEN #{delta_down} ELSE 0 END)
            ON CONFLICT(object_id) DO UPDATE SET
              count_up = count_up + #{delta_up},
              count_down = count_down + #{delta_down};
```

```sql
    CREATE TABLE IF NOT EXISTS sys_objects_score (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      table_main TEXT NOT NULL, -- Tabela de agregação, ex: bx_persons_scores
      table_track TEXT NOT NULL, -- Tabela de rastreamento, ex: bx_persons_scores_track
      post_timeout INTEGER NOT NULL DEFAULT 0, -- Em segundos
      pruning INTEGER NOT NULL DEFAULT 0, -- Dias para manter votos em track
      is_undo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      is_on INTEGER NOT NULL DEFAULT 1,
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_author TEXT, -- Não usado tipicamente
      trigger_field_score TEXT, -- Coluna para score (up-down)
      trigger_field_cup TEXT, -- Coluna para count_up
      trigger_field_cdown TEXT, -- Coluna para count_down
      class_name TEXT,
      class_file TEXT
    );
```

```sql
    CREATE TABLE IF NOT EXISTS bx_persons_scores (
      id INTEGER PRIMARY KEY AUTOINCREMENT, -- O schema UNA usa 'id' como PK, não 'object_id'
      object_id INTEGER NOT NULL UNIQUE, -- FK para bx_persons_data.id
      count_up INTEGER NOT NULL DEFAULT 0,
      count_down INTEGER NOT NULL DEFAULT 0
      -- FOREIGN KEY (object_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE -- Opcional
    );
    CREATE INDEX IF NOT EXISTS idx_bx_persons_scores_object_id ON bx_persons_scores(object_id);
```

```sql
    CREATE TABLE IF NOT EXISTS bx_persons_scores_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL,
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do votante
      author_nip INTEGER, -- IP como inteiro
      type TEXT NOT NULL CHECK(type IN ('up', 'down')),
      date INTEGER NOT NULL -- Unix Timestamp
      -- UNIQUE (object_id, author_id) -- Para garantir que um usuário só tenha um tipo de voto (up/down) por objeto
    );
    CREATE INDEX IF NOT EXISTS idx_bx_persons_scores_track_obj_author ON bx_persons_scores_track(object_id, author_id);
```

            (Usando `params.object_id`).
    11. Busca os novos agregados de `table_main`: `SELECT count_up, count_down FROM #{table_main} WHERE object_id = ?;`
    12. `new_score_data = resultado`. `new_net_score = new_score_data[\"count_up\"] - new_score_data[\"count_down\"]`.
    13. Se `config.trigger_table` definido:
        *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_score} = ?, #{config.trigger_field_cup} = ?, #{config.trigger_field_cdown} = ? WHERE #{config.trigger_field_id} = ?;`
           (Usando `new_net_score`, `new_score_data.count_up`, `new_score_data.count_down`, `params.object_id`).
    14. **Commita Transação.**
    15. Retorna `{:ok, %{action: action_result, score: new_net_score, count_up: new_score_data.count_up, count_down: new_score_data.count_down, current_user_vote_type: if(action_result == :vote_removed, nil, params.vote_type)}}`.

### Endpoints da API (`/api/v1/scores/{score_object_name}`):

O `{score_object_name}` na rota corresponde a `sys_objects_score.name`.

*   **Obter Pontuação de um Objeto:**
    *   **Endpoint:** `GET /api/v1/scores/{score_object_name}/object/{object_id}`
    *   **Autenticação:** Opcional para ler, mas se autenticado, a resposta inclui o voto do usuário.
    *   **Resposta de Sucesso (200 OK):**

*   **Submeter um Voto de Score (Up-vote ou Down-vote):**
    *   **Endpoint:** `POST /api/v1/scores/{score_object_name}/object/{object_id}/vote`
    *   **Autenticação:** Requer JWT.
    *   **Corpo da Requisição (JSON):**

    *   **Resposta de Sucesso (200 OK ou 201 Created):**

    *   **Respostas de Erro:** `400 Bad Request` (vote_type inválido), `401 Unauthorized`, `403 Forbidden` (timeout, não pode refazer/mudar voto).

## Tabelas de Pontuações (Esquema SQLite):

*   **`sys_objects_score` (Configuração):**

*   **Exemplo de Tabela de Agregação (`bx_persons_scores`):**

*   **Exemplo de Tabela de Rastreamento (`bx_persons_scores_track`):**

    *   A restrição `UNIQUE (object_id, author_id)` é importante aqui para que a lógica de \"mudar voto\" ou \"remover voto\" funcione corretamente ao atualizar ou deletar o registro existente do usuário.

## Considerações:

*   **Atomicidade:** A submissão de um voto de score e todas as atualizações de contadores devem ser uma operação atômica.
*   **Lógica de `is_undo` e `post_timeout`:** A implementação no `ScoringRepo.submit_score_vote` precisa lidar corretamente com essas configurações para permitir ou proibir a alteração ou remoção de votos.

Este sistema de pontuações fornece uma maneira flexível de implementar votação up/down em diferentes partes da aplicação \"Deeper\".