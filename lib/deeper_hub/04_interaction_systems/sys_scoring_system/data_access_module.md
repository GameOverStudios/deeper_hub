# Documentação Deeper: Módulo de Acesso a Dados para Scores (`ScoringRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.ScoringRepo` (ou similar), responsável por encapsular a lógica de consulta e manipulação de dados para o sistema de scores (upvote/downvote) genérico do UNA.

Ele interage com `sys_objects_score` (para configuração) e dinamicamente com as tabelas de sumário (`table_main`) e rastreamento (`table_track`) especificadas na configuração do objeto de score.

**Localização do Código:** `lib/deeper/interaction_systems/scoring_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Configuração do Objeto de Score

*   **`get_score_system_config(object_score_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a configuração de um sistema de score específico de `sys_objects_score`.
    *   **Argumentos:**
        *   `object_score_name`: O nome do objeto de score (de `sys_objects_score.name`).
    *   **Retorno:** `{:ok, config_map}` contendo todas as colunas de `sys_objects_score`.
    *   **SQL:** `SELECT * FROM sys_objects_score WHERE name = ? AND is_on = 1 LIMIT 1;`
    *   Usada internamente por outras funções do `ScoringRepo`.

### 2. Obter Pontuação de um Item

*   **`get_item_score(object_score_name :: String.t(), item_id :: integer(), user_profile_id :: integer() | nil) :: {:ok, map()} | {:error, any()}`**
    *   Busca a pontuação agregada (upvotes, downvotes) para um item e o score do usuário atual (se houver).
    *   **Argumentos:**
        *   `object_score_name`: Nome do objeto de score.
        *   `item_id`: ID do item de conteúdo pontuado.
        *   `user_profile_id`: (Opcional) ID do perfil do usuário logado.
    *   **Retorno:**

```sql
            SELECT count_up, count_down FROM #{config.table_main} WHERE object_id = ?;
```

```sql
            SELECT type, date FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;
```

```sql
                        INSERT INTO #{config.table_main} (object_id, count_up, count_down) VALUES (?, 1, 0)
                        ON CONFLICT(object_id) DO UPDATE SET count_up = count_up + 1;
```

```elixir
        {:ok, %{
          item_id: item_id,
          object_score_name: object_score_name,
          up_votes: 80,       // Da TableMain.count_up
          down_votes: 15,     // Da TableMain.count_down
          total_score: 65,    // Calculado (up_votes - down_votes)
          config: %{is_undo_allowed: true}, // Da config
          user_score: %{type: \"up\", scored_at_timestamp: timestamp} // Ou \"down\", ou nil
        }}
```

    *   **Lógica Interna:**
        1.  Chamar `get_score_system_config(object_score_name)` para obter `config`.
        2.  SQL para buscar dados da `TableMain` (usando `config.table_main`):

            *   Parâmetros: `item_id`. Se não houver entrada, `count_up` e `count_down` são 0.
        3.  Se `user_profile_id` fornecido, buscar o score do usuário da `TableTrack` (usando `config.table_track`):

            *   Parâmetros: `item_id`, `user_profile_id`.
        4.  Combinar os resultados, calcular `total_score`.

### 3. Submeter/Alterar um Score para um Item

*   **`cast_score(object_score_name :: String.t(), item_id :: integer(), author_profile_id :: integer(), author_nip_integer :: integer(), score_type :: String.t()) :: {:ok, map()} | {:error, :invalid_score_type | :timeout | :cannot_change | any()}`**
    *   Registra ou altera o score ('up' ou 'down') de um usuário para um item.
    *   **Argumentos:**
        *   `score_type`: Deve ser \"up\" ou \"down\".
    *   **Retorno:** O novo estado da pontuação do item (similar a `get_item_score/3`).
    *   **Lógica Interna:**
        1.  Chamar `get_score_system_config(object_score_name)` para obter `config`.
        2.  Validar `score_type`. Se inválido, `{:error, :invalid_score_type}`.
        3.  **Em uma transação:**
            a.  Buscar o score existente do `author_profile_id` para `item_id` na `TableTrack`.
                *   SQL: `SELECT id, type, date FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;`
            b.  **Se existe score anterior (`existing_score`):**
                *   Se `config.is_undo == 0` E (`config.post_timeout == 0` OU `current_time - existing_score.date <= config.post_timeout`), retorna `{:error, :cannot_change_or_timeout}`.
                *   Se `existing_score.type == score_type` (tentando votar igual de novo):
                    *   Se `config.is_undo == 1`, remover o score existente (lógica de \"toggle off\").
                        *   `DELETE FROM #{config.table_track} WHERE id = ?;`
                        *   Ajustar `TableMain`: decrementar `count_up` ou `count_down`.
                    *   Senão (não pode remover), retorna `{:ok, :score_unchanged}` ou o estado atual.
                *   Se `existing_score.type != score_type` (mudando de up para down ou vice-versa):
                    *   Se `config.is_undo == 1` ou timeout permite:
                        *   `UPDATE #{config.table_track} SET type = ?, date = ?, author_nip = ? WHERE id = ?;`
                        *   Ajustar `TableMain`: decrementar o contador do tipo antigo, incrementar o contador do novo tipo.
                    *   Senão, `{:error, :cannot_change_or_timeout}`.
            c.  **Se não existe score anterior:**
                *   **Inserir em `TableTrack`:**
                    *   SQL: `INSERT INTO #{config.table_track} (object_id, author_id, author_nip, type, date) VALUES (?, ?, ?, ?, ?);`
                *   **Atualizar/Inserir em `TableMain`:**
                    *   Lógica de UPSERT para incrementar `count_up` ou `count_down`.
                    *   SQL (Exemplo UPSERT para 'up' vote):

            d.  **Atualizar `TriggerTable` (se configurado):**
                *   Buscar `count_up`, `count_down` atualizados de `TableMain`.
                *   Calcular `new_total_score = count_up - count_down`.
                *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_score} = ?, #{config.trigger_field_cup} = ?, #{config.trigger_field_cdown} = ? WHERE #{config.trigger_field_id} = ?;`
        4.  Chamar `get_item_score/3` para retornar o estado atualizado.

### 4. Remover Score de um Item (Se `is_undo == 1`)

*   **`remove_score(object_score_name :: String.t(), item_id :: integer(), author_profile_id :: integer()) :: {:ok, map()} | {:error, :not_scored | :cannot_undo | any()}`**
    *   Remove o score de um usuário para um item.
    *   **Lógica:**
        1.  Chamar `get_score_system_config(object_score_name)`. Verificar `config.is_undo`.
        2.  Buscar score existente em `TableTrack`. Se não houver, `{:error, :not_scored}`.
        3.  **Em transação:**
            a.  Deletar de `TableTrack`.
            b.  Ajustar `TableMain`: decrementar `count_up` ou `count_down` com base no `type` do score removido.
            c.  Atualizar `TriggerTable`.
        4.  Retornar novo estado da pontuação.

### Considerações:

*   **Nomes de Tabela Dinâmicos:** A validação e o uso seguro dos nomes de tabela são cruciais.
*   **Transações:** Todas as operações de escrita (`cast_score`, `remove_score`) devem ser transacionais.
*   **Lógica de \"Toggle\":** A função `cast_score` precisa de uma lógica cuidadosa para lidar com o caso em que um usuário clica no mesmo botão de score novamente (se `is_undo == 1`, isso deve remover o score). Se o usuário clica no score oposto, o score anterior é removido e o novo é aplicado.
*   **Atualização de Contadores e Score Total:** A atualização precisa dos contadores `count_up`, `count_down` em `TableMain` e dos campos `trigger_field_score`, `trigger_field_cup`, `trigger_field_cdown` na `TriggerTable` é essencial.