# Documentação Deeper: Módulo de Acesso a Dados para Sistema de Reações Genérico (`Deeper.Interactions.ReactionsRepo`)

Este documento descreve o módulo Elixir `Deeper.Interactions.ReactionsRepo`. Ele é projetado para ser um repositório genérico que lida com operações de reações (like, love, etc.) para diferentes sistemas definidos em `sys_objects_reaction` (ou uma tabela de configuração similar).

Ele operará dinamicamente nas tabelas `table_main` e `table_track` corretas e usará as configurações apropriadas (como `trigger_table` para atualizar resumos) com base no `reaction_object_name` fornecido.

## Responsabilidades Principais:

*   Obter configurações de um sistema de reações específico.
*   Buscar o resumo das reações (contagem por tipo) para um `object_id`.
*   Buscar a reação individual de um usuário para um `object_id`.
*   Registrar/Alterar/Remover uma reação de um usuário, atualizando a tabela de rastreamento, a tabela de agregação e, opcionalmente, um campo de resumo na tabela \"trigger\" do conteúdo pai.

## Funções Auxiliares Chave (Internas):

*   **`get_reaction_system_config(reaction_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração completa de `sys_objects_reaction`.
    *   SQL: `SELECT * FROM sys_objects_reaction WHERE name = ? LIMIT 1;`
    *   Pode ser cacheado.

*   **`parse_available_reactions(reactions_string :: String.t() | nil) :: list(String.t())`**
    *   Converte a string JSON `available_reactions` da config em uma lista de strings. Retorna uma lista padrão se `nil` ou erro.

## Funções Públicas Principais e Lógica SQL:

*(Todas as funções públicas aceitarão `reaction_object_name` como primeiro argumento).*

*   **`get_reactions_summary(reaction_object_name :: String.t(), object_id :: integer(), current_user_profile_id :: integer() | nil) :: {:ok, summary_map :: map()} | {:error, any()}`**
    1.  `{:ok, config} = get_reaction_system_config(reaction_object_name)`
    2.  `table_main = config[\"table_main\"]`, `table_track = config[\"table_track\"]`
    3.  Busca contagens agregadas:
        *   SQL: `SELECT reaction_type, count FROM #{table_main} WHERE object_id = ?;`
        *   Converte para `reactions_map = %{\"like\" => 10, \"love\" => 5}`.
    4.  `user_reaction = nil`. Se `current_user_profile_id`:
        *   SQL: `SELECT reaction_type FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
        *   `user_reaction = resultado[\"reaction_type\"] ou nil`.
    5.  Retorna `{:ok, %{object_id: object_id, reactions: reactions_map, current_user_reaction: user_reaction, available_reactions: parse_available_reactions(config[\"available_reactions\"])}}`.

*   **`submit_reaction(reaction_object_name :: String.t(), author_profile_id :: integer(), params :: map()) :: {:ok, new_summary_map :: map()} | {:error, any()}`**
    *   `params`: `object_id :: integer()`, `reaction_type :: String.t() | nil` (`nil` ou um tipo de reação vazio para remover).
    1.  `{:ok, config} = get_reaction_system_config(reaction_object_name)`
    2.  `available_reactions = parse_available_reactions(config[\"available_reactions\"])`
    3.  Se `params.reaction_type` não for `nil` e não estiver em `available_reactions`, retorna `{:error, :invalid_reaction_type}`.
    4.  `table_track = config[\"table_track\"]`, `table_main = config[\"table_main\"]`
    5.  `current_time = System.os_time(:second)`
    6.  Busca a reação anterior do usuário:
        *   SQL: `SELECT id AS track_id, reaction_type FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
        *   `previous_reaction_data = resultado_ou_nil`
    7.  **Inicia Transação.**
    8.  `delta_main = %{}`. `action_taken_msg = \"\"`. `final_user_reaction = params.reaction_type`.
    9.  Se `previous_reaction_data` existe: // Havia uma reação anterior
        *   `old_type = previous_reaction_data[\"reaction_type\"]`
        *   `delta_main = Map.put(delta_main, old_type, Map.get(delta_main, old_type, 0) - 1)` // Decrementa a antiga
        *   SQL: `DELETE FROM #{table_track} WHERE id = ?;` (usando `previous_reaction_data[\"track_id\"]`).
        *   Se `params.reaction_type == old_type` ou `is_nil(params.reaction_type)`: // Clicou na mesma para remover, ou passou nil
            *   `action_taken_msg = :reaction_removed`. `final_user_reaction = nil`.
        *   Else (mudou para uma nova reação, `params.reaction_type` não é nulo e é diferente):
            *   SQL: `INSERT INTO #{table_track} (object_id, author_id, reaction_type, date) VALUES (?, ?, ?, ?);` (com `params.reaction_type`).
            *   `delta_main = Map.put(delta_main, params.reaction_type, Map.get(delta_main, params.reaction_type, 0) + 1)`
            *   `action_taken_msg = :reaction_changed`.
    10. Else (`previous_reaction_data` não existe E `params.reaction_type` não é `nil`): // Nova reação
        *   SQL: `INSERT INTO #{table_track} (object_id, author_id, reaction_type, date) VALUES (?, ?, ?, ?);` (com `params.reaction_type`).
        *   `delta_main = Map.put(delta_main, params.reaction_type, Map.get(delta_main, params.reaction_type, 0) + 1)`
        *   `action_taken_msg = :reaction_added`.
    11. Else (não havia reação e tentou remover com `nil`): // Nenhuma ação
        *   `action_taken_msg = :no_action`.
    12. Para cada `{type, delta_count}` em `delta_main` onde `delta_count != 0`:
        *   SQL:

```sql
            INSERT INTO #{table_main} (object_id, reaction_type, count)
            VALUES (?, ?, MAX(0, #{delta_count})) -- Inserir com o delta se for positivo
            ON CONFLICT(object_id, reaction_type) DO UPDATE SET
              count = MAX(0, count + #{delta_count});
```

            (Usando `params.object_id`, `type`).
    13. (Opcional) Atualizar `trigger_table` com `trigger_field_reactions_summary`:
        *   Busca todas as reações de `table_main` para `params.object_id`.
        *   Formata como JSON string.
        *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_reactions_summary} = ? WHERE #{config.trigger_field_id} = ?;`
    14. **Commita Transação.**
    15. `{:ok, summary_after_change} = get_reactions_summary(reaction_object_name, params.object_id, author_profile_id)`
    16. Retorna `{:ok, Map.put(summary_after_change, :message, action_taken_msg)}`.

## Considerações:

*   **`UNIQUE (object_id, author_id)` na `table_track`:** Esta constraint é fundamental para a lógica de que um usuário tem apenas uma reação por objeto.
*   **Atualização de `table_main`:** A lógica `ON CONFLICT` do SQLite é útil aqui. Após o update, se `count` for 0 para um `reaction_type`, essa linha pode ser removida de `table_main` para economizar espaço, ou mantida.

Este `ReactionsRepo` genérico permitirá uma funcionalidade de reações rica e consistente.