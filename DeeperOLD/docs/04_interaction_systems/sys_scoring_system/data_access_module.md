# Documentação Deeper: Módulo de Acesso a Dados para Sistema de Pontuações (`Deeper.Interactions.ScoringRepo`)

Este documento descreve o módulo Elixir `Deeper.Interactions.ScoringRepo`. Ele é projetado para ser um repositório genérico que lida com operações de pontuação (up/down votes) para diferentes sistemas definidos em `sys_objects_score`.

Ele operará dinamicamente nas tabelas `table_main` e `table_track` corretas e usará as configurações apropriadas (como `trigger_table` para atualizar contadores) com base no `score_object_name` fornecido.

## Responsabilidades Principais:

*   Obter configurações de um sistema de pontuação específico de `sys_objects_score`.
*   Buscar a pontuação agregada (`count_up`, `count_down`, `score`) para um `object_id`.
*   Buscar o voto individual (up/down) de um usuário para um `object_id`.
*   Registrar um novo voto de score, atualizando a tabela de rastreamento, a tabela de agregação e a tabela \"trigger\" do conteúdo pai.
*   Lidar com a lógica de `post_timeout` e `is_undo` (permitir mudança de voto ou remoção).

## Funções Auxiliares Chave (Internas):

*   **`get_score_system_config(score_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração completa de `sys_objects_score`.
    *   SQL: `SELECT * FROM sys_objects_score WHERE name = ? LIMIT 1;`
    *   Pode ser cacheado.

*   **`map_row_to_score_aggregate(db_row_map :: map() | nil) :: map()`**
    *   Mapeia uma linha da `table_main` para a estrutura de resposta.
    *   Calcula `score = count_up - count_down`.
    *   Exemplo:

```sql
            INSERT INTO #{table_main} (object_id, count_up, count_down)
            VALUES (?, CASE WHEN #{delta_up} > 0 THEN #{delta_up} ELSE 0 END, CASE WHEN #{delta_down} > 0 THEN #{delta_down} ELSE 0 END) -- Apenas para a primeira inserção
            ON CONFLICT(object_id) DO UPDATE SET
              count_up = count_up + #{delta_up},
              count_down = count_down + #{delta_down};
```

```elixir
        defp map_row_to_score_aggregate(agg_data) do
          count_up = Map.get(agg_data, \"count_up\", 0)
          count_down = Map.get(agg_data, \"count_down\", 0)
          score = count_up - count_down
          %{
            count_up: count_up,
            count_down: count_down,
            score: score
          }
        end
```

## Funções Públicas Principais e Lógica SQL:

*(Todas as funções públicas aceitarão `score_object_name` como primeiro argumento).*

*   **`get_score_details(score_object_name :: String.t(), object_id :: integer(), current_user_profile_id :: integer() | nil) :: {:ok, score_details_map :: map()} | {:error, any()}`**
    1.  `{:ok, config} = get_score_system_config(score_object_name)`
    2.  `table_main = config[\"table_main\"]`, `table_track = config[\"table_track\"]`
    3.  Busca dados agregados:
        *   SQL: `SELECT count_up, count_down FROM #{table_main} WHERE object_id = ? LIMIT 1;`
        *   `agg_data = resultado_ou_mapa_default_com_zeros`
    4.  `score_map = map_row_to_score_aggregate(agg_data)`
    5.  `user_vote_type = nil`. Se `current_user_profile_id` fornecido:
        *   SQL: `SELECT type FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
        *   `user_vote_type = resultado[\"type\"] ou nil`
    6.  Retorna `{:ok, Map.put(score_map, :current_user_vote_type, user_vote_type) |> Map.put(:object_id, object_id)}`.

*   **`submit_score_vote(score_object_name :: String.t(), author_profile_id :: integer(), author_nip :: integer() | nil, params :: map()) :: {:ok, new_score_details :: map()} | {:error, any()}`**
    *   `params`: `object_id :: integer()`, `vote_type :: String.t()` (deve ser \"up\" ou \"down\").
    1.  `{:ok, config} = get_score_system_config(score_object_name)`
    2.  Valida `params.vote_type`.
    3.  `table_track = config[\"table_track\"]`, `table_main = config[\"table_main\"]`
    4.  `current_time = System.os_time(:second)`
    5.  Busca o voto anterior do usuário:
        *   SQL: `SELECT id AS track_id, type, date FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
        *   `previous_vote = resultado_ou_nil`
    6.  **Lógica de Permissão/Timeout/Undo:**
        *   Se `previous_vote` existe:
            *   Se `config.post_timeout > 0` e `current_time - previous_vote[\"date\"] < config.post_timeout` E `params.vote_type == previous_vote[\"type\"]`, retorna `{:error, :scoring_timeout}`.
            *   Se `config.is_undo == 0` (não pode refazer/mudar) e `previous_vote` existe (independente do tipo), retorna `{:error, :already_voted_cannot_change}`.
    7.  **Inicia Transação.**
    8.  `delta_up = 0`, `delta_down = 0`. `action_result_type = params.vote_type`.
    9.  Se `previous_vote` existe: // Usuário está mudando ou removendo voto
        *   // Ajustar deltas pelo voto anterior
        *   If `previous_vote[\"type\"] == \"up\"`, `delta_up = delta_up - 1`.
        *   Else, `delta_down = delta_down - 1`.
        *
        *   Se `params.vote_type == previous_vote[\"type\"]`: // Clicou no mesmo botão (desfazendo o voto)
            *   SQL: `DELETE FROM #{table_track} WHERE id = ?;` (usando `previous_vote[\"track_id\"]`).
            *   `action_taken_msg = :vote_removed`, `action_result_type = nil`.
        *   Else (`params.vote_type != previous_vote[\"type\"]`): // Mudou de up para down ou vice-versa
            *   If `params.vote_type == \"up\"`, `delta_up = delta_up + 1`.
            *   Else, `delta_down = delta_down + 1`.
            *   SQL: `UPDATE #{table_track} SET type = ?, date = ? WHERE id = ?;`
            *   `action_taken_msg = :vote_changed`.
    10. Else (`previous_vote` não existe): // Novo voto
        *   If `params.vote_type == \"up\"`, `delta_up = 1`.
        *   Else, `delta_down = 1`.
        *   SQL: `INSERT INTO #{table_track} (object_id, author_id, author_nip, type, date) VALUES (?, ?, ?, ?, ?);`
        *   `action_taken_msg = :vote_added`.
    11. Atualiza `table_main` (se `delta_up != 0` ou `delta_down != 0`):
        *   SQL:

    12. Busca os novos agregados de `table_main`: `SELECT count_up, count_down FROM #{table_main} WHERE object_id = ?;`
    13. `new_agg_data = resultado`. `new_score_map = map_row_to_score_aggregate(new_agg_data)`.
    14. Se `config.trigger_table` definido:
        *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_score} = ?, #{config.trigger_field_cup} = ?, #{config.trigger_field_cdown} = ? WHERE #{config.trigger_field_id} = ?;`
           (Usando `new_score_map.score`, `new_score_map.count_up`, `new_score_map.count_down`, `params.object_id`).
    15. **Commita Transação.**
    16. Retorna `{:ok, Map.put(new_score_map, :current_user_vote_type, action_result_type) |> Map.put(:message, action_taken_msg) |> Map.put(:object_id, params.object_id)}`.

## Considerações:

*   **`UNIQUE (object_id, author_id)` na `table_track`:** Esta constraint é crucial para a lógica de `INSERT OR REPLACE` ou para saber se um `UPDATE` é necessário em vez de um `INSERT`. O schema do UNA para `bx_persons_scores_track` não a possui, o que significa que a lógica de verificar `previous_vote` e depois `DELETE` ou `UPDATE` o registro específico pelo seu `id` (track_id) é mais robusta se a constraint não existir. A migração acima para `bx_persons_scores_track` *adicionou* essa constraint, o que simplificaria o `submit_score_vote` se pudermos usar `INSERT ... ON CONFLICT DO UPDATE`. Se a constraint não puder ser adicionada, a lógica de `submit_score_vote` precisa lidar com `INSERT` para novos votos e `UPDATE` ou `DELETE+INSERT` para votos existentes.
*   **Atomicidade:** A operação completa de submissão de voto deve ser transacional.

Este `ScoringRepo` genérico habilitará a funcionalidade de pontuação up/down em \"Deeper\".