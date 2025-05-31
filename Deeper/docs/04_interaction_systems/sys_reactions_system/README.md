# Documentação Deeper: Sistema de Reações Genérico

Este documento descreve a API \"Deeper\" para o sistema genérico de \"Reações\", permitindo que os usuários expressem uma variedade de reações (como \"like\", \"love\", \"haha\", \"wow\", \"sad\", \"angry\") a diferentes tipos de conteúdo.

## Sistema de Reações no UNA:

O UNA possui tabelas que sugerem um sistema de reações, como:
*   `sys_cmts_reactions` e `sys_cmts_reactions_track` (para comentários).
*   `sys_form_fields_reaction` e `sys_form_fields_reaction_track` (para campos de formulário).

Podemos generalizar essa ideia. Um sistema de reações configurável poderia usar:

*   **`sys_objects_reaction`** (Tabela Hipotética/Generalizada a partir dos existentes ou uma nova se `sys_objects_vote`/`sys_objects_score` não cobrirem bem):
    *   `name`: Nome único do sistema de reações (ex: `bx_posts_reactions`, `sys_cmts_default_reactions`).
    *   `module`: Módulo associado.
    *   `available_reactions`: Uma lista (possivelmente JSON ou texto delimitado) das reações permitidas para este objeto (ex: `[\"like\", \"love\", \"haha\"]`). Se não definido, pode usar um conjunto padrão.
    *   `table_main`: Tabela que armazena os dados agregados das reações (ex: `bx_posts_reactions_summary`). Contém `object_id`, `reaction_type`, `count`.
    *   `table_track`: Tabela que armazena as reações individuais dos usuários (ex: `bx_posts_reactions_track`). Contém `object_id`, `author_id`, `reaction_type`, `date`.
    *   `is_undo`: Se o usuário pode remover/alterar sua reação (geralmente sim, e mudar para outra reação conta como undo da anterior e add da nova).
    *   `trigger_table`, `trigger_field_id`, `trigger_field_reactions_summary` (ou campos individuais por tipo de reação): Para atualizar um resumo das reações no conteúdo pai (ex: em `bx_posts` poderia ter um campo JSON `reactions_summary`).

*   **Tabelas de Reações:**
    *   **Tabela de Agregação (ex: `bx_posts_reactions_summary`):** `object_id`, `reaction_type` (ex: \"like\", \"love\"), `count`. Chave primária em `(object_id, reaction_type)`.
    *   **Tabela de Rastreamento (ex: `bx_posts_reactions_track`):** `id` (PK), `object_id`, `author_id`, `reaction_type`, `date`. `UNIQUE (object_id, author_id)` para garantir que um usuário só tenha uma reação por objeto.

## Estratégia da API \"Deeper\" para Reações:

A API \"Deeper\" fornecerá endpoints genéricos para usuários submeterem/alterarem/removerem reações e para obter o resumo das reações de um item. A rota incluirá um `reaction_object_name`.

### Módulo de Acesso a Dados (`Deeper.Interactions.ReactionsRepo`):

**Funções Principais e SQLs Esperados:**

*   **`get_reaction_system_config(reaction_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração de `sys_objects_reaction` (ou uma tabela de configuração similar).
    *   SQL: `SELECT * FROM sys_objects_reaction WHERE name = ? LIMIT 1;`

*   **`get_reactions_summary(reaction_object_name, object_id, current_user_profile_id :: integer() | nil)`**
    1.  Busca `config`. `table_main = config[\"table_main\"]`, `table_track = config[\"table_track\"]`.
    2.  SQL (agregação): `SELECT reaction_type, count FROM #{table_main} WHERE object_id = ?;`
    3.  `reactions_summary = resultado_em_formato_mapa (ex: %{\"like\" => 10, \"love\" => 5})`
    4.  `user_reaction_type = nil`. Se `current_user_profile_id`:
        *   SQL (reação do usuário): `SELECT reaction_type FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
        *   `user_reaction_type = resultado[\"reaction_type\"] ou nil`.
    5.  Retorna `%{object_id: object_id, reactions: reactions_summary, current_user_reaction: user_reaction_type}`.

*   **`submit_reaction(reaction_object_name, author_profile_id, params :: map())`**
    *   `params`: `object_id :: integer()`, `reaction_type :: String.t()`.
    1.  Busca `config`. Valida `params.reaction_type` contra `config.available_reactions`.
    2.  `table_track = config[\"table_track\"]`, `table_main = config[\"table_main\"]`.
    3.  `current_time = System.os_time(:second)`.
    4.  Busca a reação anterior do usuário:
        *   SQL: `SELECT id AS track_id, reaction_type FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
        *   `previous_reaction = resultado_ou_nil`.
    5.  **Inicia Transação.**
    6.  `delta_reactions = %{}`. // Para rastrear mudanças nas contagens
    7.  Se `previous_reaction` existe:
        *   // Ajustar contagem da reação antiga
        *   `old_reaction_type = previous_reaction[\"reaction_type\"]`
        *   `delta_reactions = Map.put(delta_reactions, old_reaction_type, Map.get(delta_reactions, old_reaction_type, 0) - 1)`
        *   Se `params.reaction_type == old_reaction_type`: // Usuário clicou na mesma reação (desfazendo)
            *   SQL: `DELETE FROM #{table_track} WHERE id = ?;` (usando `previous_reaction[\"track_id\"]`).
            *   `action_result = :reaction_removed`, `new_user_reaction = nil`.
        *   Else: // Usuário mudou para uma nova reação
            *   SQL: `UPDATE #{table_track} SET reaction_type = ?, date = ? WHERE id = ?;` (usando `params.reaction_type`, `current_time`, `previous_reaction[\"track_id\"]`).
            *   `new_reaction_type = params.reaction_type`
            *   `delta_reactions = Map.put(delta_reactions, new_reaction_type, Map.get(delta_reactions, new_reaction_type, 0) + 1)`
            *   `action_result = :reaction_changed`, `new_user_reaction = new_reaction_type`.
    8.  Else (`previous_reaction` não existe): // Nova reação
        *   `new_reaction_type = params.reaction_type`
        *   SQL: `INSERT INTO #{table_track} (object_id, author_id, reaction_type, date) VALUES (?, ?, ?, ?);`
        *   `delta_reactions = Map.put(delta_reactions, new_reaction_type, Map.get(delta_reactions, new_reaction_type, 0) + 1)`
        *   `action_result = :reaction_added`, `new_user_reaction = new_reaction_type`.
    9.  Para cada `{type, delta}` em `delta_reactions` onde `delta != 0`:
        *   SQL:

```json
        {
          \"data\": {
            \"object_id\": 123,
            \"reactions\": { // Contagem para cada tipo de reação
              \"like\": 55,
              \"love\": 23,
              \"haha\": 5
            },
            \"current_user_reaction\": \"like\" // ou null
          }
        }
```

```json
        {
          \"reaction_type\": \"love\" // Para adicionar/mudar para 'love'
        }
```

```json
        {
          \"reaction_type\": null // ou \"\" ou um valor especial como \"undo\"
                                 // ou o cliente pode enviar o mesmo reaction_type para \"desfazer\"
        }
```

```json
        {
          \"data\": { // Novo estado das reações
            \"object_id\": 123,
            \"reactions\": { \"like\": 54, \"love\": 24, \"haha\": 5 },
            \"current_user_reaction\": \"love\",
            \"message\": \"Reaction changed.\" // ou \"Reaction added.\", \"Reaction removed.\"
          }
        }
```

```sql
            INSERT INTO #{table_main} (object_id, reaction_type, count)
            VALUES (?, ?, CASE WHEN #{delta} > 0 THEN #{delta} ELSE 0 END) -- Só para o primeiro insert de um tipo
            ON CONFLICT(object_id, reaction_type) DO UPDATE SET
              count = count + #{delta};
```

```sql
    CREATE TABLE IF NOT EXISTS sys_objects_reaction (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      available_reactions TEXT, -- JSON array: '[\"like\", \"love\", \"haha\"]' ou CSV
      table_main TEXT NOT NULL, -- Tabela de agregação, ex: module_reactions_summary
      table_track TEXT NOT NULL, -- Tabela de rastreamento, ex: module_reactions_track
      is_undo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_reactions_summary TEXT -- Coluna para JSON summary
    );
```

```sql
    CREATE TABLE IF NOT EXISTS module_reactions_summary (
      object_id INTEGER NOT NULL,
      reaction_type TEXT NOT NULL, -- 'like', 'love', etc.
      count INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (object_id, reaction_type)
      -- FOREIGN KEY (object_id) REFERENCES target_content_table(id) ON DELETE CASCADE -- Opcional
    );
```

```sql
    CREATE TABLE IF NOT EXISTS module_reactions_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL,
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id)
      reaction_type TEXT NOT NULL,
      date INTEGER NOT NULL, -- Unix Timestamp
      UNIQUE (object_id, author_id) -- Um usuário só pode ter uma reação por objeto
    );
    CREATE INDEX IF NOT EXISTS idx_module_reactions_track_obj_author ON module_reactions_track(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_module_reactions_track_obj_type ON module_reactions_track(object_id, reaction_type);
```

            (Depois de atualizar, deletar se `count <= 0`).
            *   SQL Alternativo (mais simples se a linha sempre existe ou é criada com 0): `UPDATE #{table_main} SET count = count + #{delta} WHERE object_id = ? AND reaction_type = ?;` (precisa garantir que a linha `(object_id, reaction_type)` exista em `table_main`, talvez inserindo com count 0 se não existir).
    10. Se `config.trigger_table` definido e `config.trigger_field_reactions_summary`:
        *   Busca todas as reações de `table_main` para o `object_id`.
        *   Formata como JSON string (ex: `{\"like\": 10, \"love\": 5}`).
        *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_reactions_summary} = ? WHERE #{config.trigger_field_id} = ?;`
    11. **Commita Transação.**
    12. Busca o novo resumo de reações (`get_reactions_summary`).
    13. Retorna `{:ok, Map.put(new_summary, :action_taken, action_result)}`.

### Endpoints da API (`/api/v1/reactions/{reaction_object_name}`):

*   **Obter Resumo de Reações de um Objeto:**
    *   **Endpoint:** `GET /api/v1/reactions/{reaction_object_name}/object/{object_id}`
    *   **Autenticação:** Opcional.
    *   **Resposta de Sucesso (200 OK):**

*   **Submeter/Alterar/Remover uma Reação:**
    *   **Endpoint:** `POST /api/v1/reactions/{reaction_object_name}/object/{object_id}`
    *   **Autenticação:** Requer JWT.
    *   **Corpo da Requisição (JSON):**

        Ou para remover a reação atual:

    *   **Resposta de Sucesso (200 OK):**

*   **(Opcional) Listar Usuários que Reagiram (por tipo):**
    *   **Endpoint:** `GET /api/v1/reactions/{reaction_object_name}/object/{object_id}/who/{reaction_type}`
    *   **Autenticação:** Opcional (depende da política de privacidade).
    *   **Resposta:** Lista paginada de perfis que deram aquela reação.

## Tabelas de Reações (Esquema SQLite):

*   **`sys_objects_reaction` (Configuração Hipotética/Generalizada):**

*   **Exemplo de Tabela de Agregação (`module_reactions_summary`):**

*   **Exemplo de Tabela de Rastreamento (`module_reactions_track`):**

## Considerações:

*   **Lista de Reações Disponíveis:** A `config.available_reactions` é importante para validação e para o cliente saber quais botões de reação exibir.
*   **Atomicidade e Performance:** A lógica de `submit_reaction` envolve múltiplas atualizações e deve ser transacional. Atualizar um campo JSON (`trigger_field_reactions_summary`) na `trigger_table` pode ser menos performático do que atualizar colunas numéricas individuais se o SGBD não tiver bom suporte para updates parciais de JSON. SQLite tem suporte JSON1.

Este sistema de reações adiciona uma camada rica de interação do usuário.