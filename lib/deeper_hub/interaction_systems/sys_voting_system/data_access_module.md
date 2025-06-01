# Documentação Deeper: Módulo de Acesso a Dados para Votos/Avaliações (`VotingRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.VotingRepo` (ou similar), responsável por encapsular a lógica de consulta e manipulação de dados para o sistema de votos/avaliações genérico do UNA.

Ele interage com `sys_objects_vote` (para configuração) e dinamicamente com as tabelas de sumário (`TableMain`) e rastreamento (`TableTrack`) especificadas na configuração do objeto de voto.

**Localização do Código:** `lib/deeper/interaction_systems/voting_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Configuração do Objeto de Voto

*   **`get_vote_system_config(object_vote_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a configuração de um sistema de votos específico de `sys_objects_vote`.
    *   **Argumentos:**
        *   `object_vote_name`: O nome do objeto de voto (de `sys_objects_vote.Name`).
    *   **Retorno:** `{:ok, config_map}` contendo todas as colunas de `sys_objects_vote` (ex: `%{name: \"bx_persons_ratings\", table_main: \"bx_persons_votes\", table_track: \"bx_persons_votes_track\", min_value: 1, max_value: 5, ...}}`).
    *   **SQL:** `SELECT * FROM sys_objects_vote WHERE Name = ? AND IsOn = 1 LIMIT 1;`
    *   Usada internamente por outras funções do `VotingRepo`.

### 2. Obter Avaliação de um Item

*   **`get_item_rating(object_vote_name :: String.t(), item_id :: integer(), user_profile_id :: integer() | nil) :: {:ok, map()} | {:error, any()}`**
    *   Busca a avaliação agregada (média, contagem) para um item e o voto do usuário atual (se houver).
    *   **Argumentos:**
        *   `object_vote_name`: Nome do objeto de voto.
        *   `item_id`: ID do item de conteúdo votado.
        *   `user_profile_id`: (Opcional) ID do perfil do usuário logado para buscar seu voto específico.
    *   **Retorno:**

```sql
            SELECT count, sum FROM #{config.table_main} WHERE object_id = ?;
```

```sql
            SELECT value, date FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;
```

```sql
                        -- Tentar atualizar primeiro (se a linha já existe)
                        UPDATE #{config.table_main} SET count = count + 1, sum = sum + ? WHERE object_id = ?;
                        -- Se nenhuma linha foi afetada (porque não existia), inserir:
                        -- (A query acima pode ser feita com `changes()` para verificar se afetou linhas no SQLite)
                        -- Alternativa: INSERT OR IGNORE, depois SELECT e UPDATE.
                        -- Ou, usando UPSERT (SQLite 3.24.0+):
                        INSERT INTO #{config.table_main} (object_id, count, sum) VALUES (?, 1, ?)
                        ON CONFLICT(object_id) DO UPDATE SET count = count + 1, sum = sum + excluded.sum;
```

```elixir
        {:ok, %{
          average_rating: 4.25, // Calculado (sum / count)
          total_votes: 100,     // Da TableMain.count
          sum_of_votes: 425,    // Da TableMain.sum
          min_value: 1,         // Da config
          max_value: 5,         // Da config
          user_vote: %{value: 5, date: timestamp} // Ou nil, se o usuário não votou (da TableTrack)
        }}
```

    *   **Lógica Interna:**
        1.  Chamar `get_vote_system_config(object_vote_name)` para obter `config`.
        2.  SQL para buscar dados da `TableMain` (usando `config.table_main`):

            *   Parâmetros: `item_id`. Se não houver entrada, `count` e `sum` são 0.
        3.  Calcular `average_rating = if count > 0, do: sum / count, else: 0`.
        4.  Se `user_profile_id` fornecido, buscar o voto do usuário da `TableTrack` (usando `config.table_track`):

            *   Parâmetros: `item_id`, `user_profile_id`.
        5.  Combinar os resultados.

### 3. Adicionar/Atualizar Voto de um Usuário

*   **`cast_vote(object_vote_name :: String.t(), item_id :: integer(), author_profile_id :: integer(), author_nip_integer :: integer(), vote_value :: integer()) :: {:ok, map()} | {:error, :invalid_value | :timeout | :already_voted_unchanged | any()}`**
    *   Registra ou atualiza o voto de um usuário para um item.
    *   **Argumentos:**
        *   `vote_value`: O valor do voto.
    *   **Retorno:** O novo estado da avaliação do item (similar a `get_item_rating/3`).
    *   **Lógica Interna:**
        1.  Chamar `get_vote_system_config(object_vote_name)` para obter `config`.
        2.  Validar `vote_value` contra `config.min_value` e `config.max_value`. Se inválido, `{:error, :invalid_value}`.
        3.  **Em uma transação:**
            a.  Verificar o voto existente do `author_profile_id` para `item_id` na `TableTrack`.
                *   SQL: `SELECT value, date FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;`
            b.  Se existe voto anterior (`existing_vote`):
                *   Se `config.is_undo == 0` (não pode mudar/desfazer) E `config.post_timeout == 0` (sem timeout para novo voto, o que é raro se `is_undo == 0`), retorna `{:error, :cannot_change_vote}`.
                *   Se `config.is_undo == 1` OU (`config.post_timeout > 0` E `current_time - existing_vote.date > config.post_timeout`):
                    *   Se `existing_vote.value == vote_value`, retorna `{:ok, :already_voted_unchanged}` (ou o estado atual).
                    *   **Atualizar `TableTrack`:**
                        *   SQL: `UPDATE #{config.table_track} SET value = ?, date = ?, author_nip = ? WHERE object_id = ? AND author_id = ?;`
                    *   **Ajustar `TableMain`:** `sum = sum - existing_vote.value + vote_value`. (O `count` não muda).
                        *   SQL: `UPDATE #{config.table_main} SET sum = sum - ? + ? WHERE object_id = ?;`
                *   Senão (não pode mudar ainda devido ao timeout), retorna `{:error, :timeout, %{time_left: ...}}`.
            c.  Se não existe voto anterior:
                *   **Inserir em `TableTrack`:**
                    *   SQL: `INSERT INTO #{config.table_track} (object_id, author_id, author_nip, value, date) VALUES (?, ?, ?, ?, ?);`
                *   **Atualizar/Inserir em `TableMain`:**
                    *   SQL (tentar update, se falhar, insert - ou `INSERT OR IGNORE` seguido de `UPDATE`):

                        (Parâmetros para UPSERT: `item_id`, `vote_value` para a parte de `INSERT`; `vote_value` para `excluded.sum` na parte de `UPDATE`).
            d.  **Atualizar `TriggerTable` (se configurado):**
                *   Buscar `count` e `sum` atualizados de `TableMain`.
                *   Calcular `new_average_rate`.
                *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_rate} = ?, #{config.trigger_field_rate_count} = ? WHERE #{config.trigger_field_id} = ?;`
        4.  Chamar `get_item_rating/3` para retornar o estado atualizado.

### 4. (Opcional) Remover Voto de um Usuário

*   **`remove_vote(object_vote_name :: String.t(), item_id :: integer(), author_profile_id :: integer()) :: {:ok, map()} | {:error, :not_voted | :cannot_undo | any()}`**
    *   Permite que um usuário remova seu voto, se `config.is_undo == 1`.
    *   **Lógica:**
        1.  Verificar `config.is_undo`.
        2.  Buscar voto existente em `TableTrack`. Se não existir, `{:error, :not_voted}`.
        3.  **Em transação:**
            a.  Deletar de `TableTrack`.
            b.  Ajustar `TableMain`: `count = count - 1`, `sum = sum - existing_vote.value`.
            c.  Atualizar `TriggerTable`.
        4.  Retornar novo estado da avaliação.

### Considerações:

*   **Nomes de Tabela Dinâmicos:** Similar ao `CommentsRepo`, a validação ou mapeamento seguro dos nomes de tabela de `config.table_main` e `config.table_track` é crucial.
*   **Transações:** Operações de escrita (`cast_vote`, `remove_vote`) que afetam múltiplas tabelas (`TableTrack`, `TableMain`, `TriggerTable`) devem ser executadas dentro de uma transação de banco de dados.
*   **Atualização de Contadores na `TriggerTable`:** A lógica para calcular a média e atualizar a tabela de conteúdo principal é uma parte importante.
*   **Performance:** A consulta para `get_item_rating` deve ser rápida. Índices em `object_id` nas tabelas `TableMain` e `TableTrack`, e em `(object_id, author_id)` na `TableTrack` são essenciais.
*   **Pruning:** A coluna `Pruning` em `sys_objects_vote` sugere que pode haver uma tarefa de limpeza para votos antigos. Isso estaria fora do escopo direto do `VotingRepo` para operações de usuário, mas pode ser uma tarefa de manutenção do sistema.