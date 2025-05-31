# Documentação Deeper: Módulo de Acesso a Dados para Sistema de Votos/Avaliações Genérico (`Deeper.Interactions.VotingRepo`)

Este documento descreve o módulo Elixir `Deeper.Interactions.VotingRepo`. Ele é projetado para ser um repositório genérico que lida com operações de votação para diferentes sistemas definidos em `sys_objects_vote`.

Ele operará dinamicamente nas tabelas `TableMain` e `TableTrack` corretas e usará as configurações apropriadas (como `TriggerTable` para atualizar contadores/médias) com base no `voting_object_name` fornecido.

## Responsabilidades Principais:

*   Obter configurações de um sistema de votação específico de `sys_objects_vote`.
*   Buscar a avaliação agregada (média, contagem) para um `object_id`.
*   Buscar o voto individual de um usuário para um `object_id`.
*   Registrar um novo voto, atualizando a tabela de rastreamento, a tabela de agregação e a tabela \"trigger\" do conteúdo pai.
*   Lidar com a lógica de `PostTimeout` e `IsUndo`.

## Funções Auxiliares Chave (Internas):

*   **`get_voting_system_config(voting_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração completa de `sys_objects_vote`.
    *   SQL: `SELECT * FROM sys_objects_vote WHERE Name = ? LIMIT 1;`
    *   Retorna mapa com `Name`, `Module`, `TableMain`, `TableTrack`, `PostTimeout`, `MinValue`, `MaxValue`, `IsUndo`, `TriggerTable`, `TriggerFieldId`, `TriggerFieldRate`, `TriggerFieldRateCount`.
    *   Pode ser cacheado.

*   **`map_row_to_rating_aggregate(db_row_map :: map() | nil, config :: map()) :: map()`**
    *   Mapeia uma linha da `TableMain` (ou `nil`) para a estrutura de resposta da API de avaliação.
    *   Calcula `average_rating`.
    *   Exemplo:

```sql
            INSERT INTO #{table_main} (object_id, count, sum)
            VALUES (?, #{count_delta}, ?)
            ON CONFLICT(object_id) DO UPDATE SET
              count = count + #{count_delta},
              sum = sum - #{old_value_to_adjust_sum} + ?;
```

```elixir
        defp map_row_to_rating_aggregate(agg_data, _config) do
          count = Map.get(agg_data, \"count\", 0)
          sum = Map.get(agg_data, \"sum\", 0)
          rate = if count > 0, do: sum / count, else: 0.0
          # Arredondar `rate` para uma casa decimal, por exemplo
          rate_rounded = Float.round(rate, 1)

          %{
            total_votes: count,
            sum_of_votes: sum, # Opcional para expor
            average_rating: rate_rounded
          }
        end
```

## Funções Públicas Principais e Lógica SQL:

*(Todas as funções públicas aceitarão `voting_object_name` como primeiro argumento para buscar a configuração correta).*

*   **`get_object_rating(voting_object_name :: String.t(), object_id :: integer(), current_user_profile_id :: integer() | nil) :: {:ok, rating_data :: map()} | {:error, any()}`**
    1.  `{:ok, config} = get_voting_system_config(voting_object_name)`
    2.  `table_main = config[\"TableMain\"]`
    3.  `table_track = config[\"TableTrack\"]`
    4.  Busca dados agregados:
        *   SQL: `SELECT count, sum FROM #{table_main} WHERE object_id = ? LIMIT 1;`
        *   `agg_data = resultado_da_query_ou_mapa_default_com_zeros`
    5.  `rating_map = map_row_to_rating_aggregate(agg_data, config)`
    6.  Se `current_user_profile_id` fornecido:
        *   SQL: `SELECT value FROM #{table_track} WHERE object_id = ? AND author_id = ? ORDER BY date DESC LIMIT 1;`
        *   `user_vote_value = resultado_ou_nil`
        *   `rating_map = Map.put(rating_map, :current_user_vote, user_vote_value)`
    7.  Retorna `{:ok, rating_map}`.

*   **`submit_vote(voting_object_name :: String.t(), author_profile_id :: integer(), author_nip :: integer() | nil, params :: map()) :: {:ok, new_rating_data :: map()} | {:error, any()}`**
    *   `params`: `object_id :: integer()`, `value :: integer()`.
    1.  `{:ok, config} = get_voting_system_config(voting_object_name)`
    2.  Valida `params.value` contra `config.MinValue` e `config.MaxValue`. Se inválido, `{:error, :invalid_vote_value}`.
    3.  `table_track = config[\"TableTrack\"]`
    4.  `table_main = config[\"TableMain\"]`
    5.  `current_time = System.os_time(:second)`
    6.  Busca o voto anterior do usuário (se houver):
        *   SQL: `SELECT value, date FROM #{table_track} WHERE object_id = ? AND author_id = ? ORDER BY date DESC LIMIT 1;`
        *   `previous_vote_data = resultado_ou_nil`
    7.  **Lógica de Permissão/Timeout/Undo:**
        *   Se `previous_vote_data` existe:
            *   Se `config.PostTimeout > 0` e `current_time - previous_vote_data[\"date\"] < config.PostTimeout`, retorna `{:error, :voting_timeout}`.
            *   Se `config.IsUndo == 0` (não pode refazer/alterar), retorna `{:error, :already_voted}`.
            *   Se `config.IsUndo == 1` e `params.value == previous_vote_data[\"value\"]` (tentando votar com o mesmo valor, pode ser interpretado como remover o voto). **Decidir comportamento: remover ou ignorar?** O UNA geralmente permite alterar o voto.
    8.  **Inicia Transação (`Repo.transaction/1`)**
    9.  `old_value_to_adjust_sum = 0`, `count_delta = 1`
    10. Se `previous_vote_data` existe e `config.IsUndo == 1`:
        *   `old_value_to_adjust_sum = previous_vote_data[\"value\"]`
        *   `count_delta = 0` (se o usuário está apenas mudando o voto, a contagem não aumenta)
        *   Opcional: Deletar o voto antigo de `table_track` ou marcar como obsoleto se a tabela não tiver `UNIQUE(object_id, author_id)`. Se tiver `UNIQUE`, o `INSERT OR REPLACE` abaixo lida com isso.
    11. Registra o novo voto:
        *   SQL: `INSERT OR REPLACE INTO #{table_track} (object_id, author_id, author_nip, value, date) VALUES (?, ?, ?, ?, ?);` (assume `UNIQUE(object_id, author_id)` ou que a lógica de `IsUndo` e timeout previne duplicatas indesejadas).
    12. Atualiza a tabela de agregação:
        *   SQL:

            (Os `?` são `params.object_id` e `params.value`).
    13. Busca os novos agregados de `table_main`:
        *   SQL: `SELECT count, sum FROM #{table_main} WHERE object_id = ?;`
        *   `new_agg_data = resultado`
    14. `new_rating_map = map_row_to_rating_aggregate(new_agg_data, config)`
    15. Se `config.TriggerTable` definido:
        *   SQL: `UPDATE #{config.TriggerTable} SET #{config.TriggerFieldRate} = ?, #{config.TriggerFieldRateCount} = ? WHERE #{config.TriggerFieldId} = ?;` (usando `new_rating_map.average_rating`, `new_rating_map.total_votes`, `params.object_id`).
    16. **Fim da Transação.**
    17. Retorna `{:ok, Map.put(new_rating_map, :current_user_vote, params.value)}`.

*   **(Opcional) `delete_vote(voting_object_name, author_profile_id, object_id)`**
    *   Somente se `config.IsUndo == 1`.
    1.  Busca `config`.
    2.  Verifica se o usuário tem um voto para remover.
    3.  **Inicia Transação.**
    4.  Remove de `table_track`.
    5.  Ajusta (decrementa) `count` e `sum` em `table_main`.
    6.  Atualiza `TriggerTable`.
    7.  **Fim da Transação.**
    8.  Retorna os novos dados de avaliação.

## Considerações:

*   **Chave Única em `TableTrack`:** Se `UNIQUE(object_id, author_id)` for usado em `TableTrack`, a lógica de `INSERT OR REPLACE` simplifica a atualização do voto de um usuário. Se não, a lógica de `IsUndo` e `PostTimeout` precisa garantir que não haja votos duplicados ou gerenciar qual é o voto \"ativo\". O schema original do UNA para `bx_persons_votes_track` não tem essa chave única, implicando que a lógica da aplicação (ou `PostTimeout` muito longo) previne múltiplos votos.
*   **Performance de Atualização de Gatilho:** Atualizar a `TriggerTable` em tempo real pode ser intensivo se houver muitos votos. Para sistemas de alta carga, essa atualização pode ser feita de forma assíncrona ou por jobs periódicos, embora a expectativa do usuário seja geralmente ver a média atualizada.
*   **`author_nip`:** A conversão e armazenamento do IP devem seguir as políticas de privacidade e segurança.

Este `VotingRepo` genérico permitirá que a API \"Deeper\" suporte sistemas de votação para diversos tipos de conteúdo de forma consistente.