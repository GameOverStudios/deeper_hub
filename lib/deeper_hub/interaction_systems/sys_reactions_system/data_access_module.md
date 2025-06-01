# Documentação Deeper: Módulo de Acesso a Dados para Reações (`ReactionsRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.ReactionsRepo` (ou similar), responsável por encapsular a lógica de consulta e manipulação de dados para um sistema de reações genérico.

Ele interage com `sys_objects_reaction` (para configuração, incluindo a lista de reações disponíveis) e dinamicamente com as tabelas de sumário (`table_summary`) e rastreamento (`table_track`) especificadas na configuração do objeto de reação.

**Localização do Código:** `lib/deeper/interaction_systems/reactions_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Configuração do Objeto de Reação

*   **`get_reaction_system_config(object_reaction_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a configuração de um sistema de reações específico de `sys_objects_reaction`.
    *   **Argumentos:**
        *   `object_reaction_name`: O nome do objeto de reação (de `sys_objects_reaction.name`).
    *   **Retorno:** `{:ok, config_map}` contendo todas as colunas de `sys_objects_reaction`. O campo `reactions_available` pode precisar ser parseado (ex: de JSON string para lista Elixir).
    *   **SQL:** `SELECT * FROM sys_objects_reaction WHERE name = ? AND is_on = 1 LIMIT 1;`
    *   Usada internamente por outras funções do `ReactionsRepo`.

### 2. Obter Sumário de Reações para um Item

*   **`get_item_reactions_summary(object_reaction_name :: String.t(), item_id :: integer(), user_profile_id :: integer() | nil) :: {:ok, map()} | {:error, any()}`**
    *   Busca o sumário de todas as reações para um item e a reação do usuário atual (se houver).
    *   **Argumentos:**
        *   `object_reaction_name`: Nome do objeto de reação.
        *   `item_id`: ID do item de conteúdo.
        *   `user_profile_id`: (Opcional) ID do perfil do usuário logado.
    *   **Retorno:**

```sql
            SELECT reaction_type, count FROM #{config.table_summary} WHERE object_id = ?;
```

```sql
            SELECT reaction_type, date FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;
```

```sql
                        INSERT INTO #{config.table_summary} (object_id, reaction_type, count) VALUES (?, ?, 1)
                        ON CONFLICT(object_id, reaction_type) DO UPDATE SET count = count + 1;
```

```sql
            SELECT
                rt.author_id, rt.reaction_type, rt.date as reacted_date,
                author_prof.id as profile_id,
                author_pdata.fullname as author_fullname,
                author_pdata.picture as author_picture_id
            FROM #{config.table_track} rt
            JOIN sys_profiles author_prof ON rt.author_id = author_prof.id
            LEFT JOIN bx_persons_data author_pdata ON author_prof.content_id = author_pdata.id AND author_prof.type = 'bx_persons'
            WHERE rt.object_id = ?
              -- AND rt.reaction_type = ? -- Adicionar dinamicamente se reaction_type_filter presente
            ORDER BY rt.date DESC
            LIMIT ? OFFSET ?;
```

```elixir
        {:ok, %{
          item_id: item_id,
          object_reaction_name: object_reaction_name,
          reactions: %{ // Contagem de cada tipo de reação
            \"like\" => 50,
            \"love\" => 25,
            \"haha\" => 10
            // ... outras reações disponíveis e suas contagens
          },
          total_reactions: 85, // Soma de todas as contagens
          available_reactions: [\"like\", \"love\", \"haha\", \"wow\", \"sad\", \"angry\"], // Da config
          config: %{is_undo_allowed: true}, // Da config
          user_reaction: %{type: \"love\", reacted_at_timestamp: timestamp} // Ou nil
        }}
```

    *   **Lógica Interna:**
        1.  Chamar `get_reaction_system_config(object_reaction_name)` para obter `config`. Parsear `config.reactions_available`.
        2.  SQL para buscar dados da `TableSummary` (usando `config.table_summary`):

            *   Parâmetros: `item_id`.
            *   Construir o mapa `reactions` e calcular `total_reactions`.
        3.  Se `user_profile_id` fornecido, buscar a reação do usuário da `TableTrack` (usando `config.table_track`):

            *   Parâmetros: `item_id`, `user_profile_id`.
        4.  Combinar os resultados.

### 3. Adicionar/Alterar/Remover Reação de um Usuário (Toggle Logic)

*   **`cast_reaction(object_reaction_name :: String.t(), item_id :: integer(), author_profile_id :: integer(), reaction_type :: String.t()) :: {:ok, map()} | {:error, :invalid_reaction_type | :cannot_react | any()}`**
    *   Registra, altera ou remove a reação de um usuário para um item.
    *   **Argumentos:**
        *   `reaction_type`: O tipo da reação (ex: \"like\", \"love\").
    *   **Retorno:** O novo estado do sumário de reações do item (similar a `get_item_reactions_summary/3`).
    *   **Lógica Interna:**
        1.  Chamar `get_reaction_system_config(object_reaction_name)` para obter `config`.
        2.  Validar `reaction_type` contra `config.reactions_available`. Se inválido, `{:error, :invalid_reaction_type}`.
        3.  **Em uma transação:**
            a.  Buscar a reação existente do `author_profile_id` para `item_id` na `TableTrack`.
                *   SQL: `SELECT id, reaction_type FROM #{config.table_track} WHERE object_id = ? AND author_id = ?;`
            b.  **Se existe reação anterior (`existing_reaction`):**
                *   Se `config.is_undo == 0` (não pode mudar/desfazer), retorna `{:error, :cannot_change_reaction}` (a menos que o timeout permita, se houvesse timeout para reações).
                *   Se `existing_reaction.reaction_type == reaction_type` (clicou na mesma reação novamente):
                    *   Remover a reação (toggle off).
                        *   `DELETE FROM #{config.table_track} WHERE id = ?;` (usando `existing_reaction.id`).
                        *   Ajustar `TableSummary`: decrementar `count` para `existing_reaction.reaction_type`.
                *   Se `existing_reaction.reaction_type != reaction_type` (mudando de uma reação para outra):
                    *   `UPDATE #{config.table_track} SET reaction_type = ?, date = ? WHERE id = ?;` (date é timestamp atual).
                    *   Ajustar `TableSummary`: decrementar `count` para `existing_reaction.reaction_type`, incrementar `count` para o novo `reaction_type`.
            c.  **Se não existe reação anterior:**
                *   **Inserir em `TableTrack`:**
                    *   SQL: `INSERT INTO #{config.table_track} (object_id, author_id, reaction_type, date) VALUES (?, ?, ?, ?);`
                *   **Atualizar/Inserir em `TableSummary`:**
                    *   Lógica de UPSERT para incrementar o `count` para o `reaction_type`.
                    *   SQL (Exemplo UPSERT):

            d.  **Atualizar `TriggerTable` (se configurado):**
                *   Buscar o sumário atualizado de `TableSummary`.
                *   Atualizar `config.trigger_field_reactions_count` na `config.trigger_table` (pode ser uma contagem total ou um JSON com contagens por tipo).
        4.  Chamar `get_item_reactions_summary/3` para retornar o estado atualizado.

### 4. Listar Usuários que Reagiram a um Item (com um tipo específico ou todos)

*   **`list_users_who_reacted_to_item(object_reaction_name :: String.t(), item_id :: integer(), reaction_type_filter :: String.t() | nil, opts :: map()) :: {:ok, %{data: list(map()), pagination: map()}} | {:error, any()}`**
    *   Lista os perfis dos usuários que reagiram a um item, opcionalmente filtrando por tipo de reação.
    *   **Argumentos:**
        *   `opts`: Mapa para paginação (`page`, `per_page`).
    *   **Retorno:** Lista de perfis (ID, nome, avatar) e o tipo de reação que deram.
    *   **Lógica Interna:**
        1.  Chamar `get_reaction_system_config(object_reaction_name)`.
        2.  SQL (para `config.table_track`):

        3.  Query para contagem total para paginação.

### Considerações:

*   **Estrutura da `TableSummary`:** A forma como o sumário é armazenado (uma linha por `object_id` com colunas para cada tipo de reação, ou múltiplas linhas por `object_id` e `reaction_type`) afeta as queries de UPSERT e leitura. O exemplo acima assume múltiplas linhas.
*   **`reactions_available`:** A lista de reações permitidas (`config.reactions_available`) deve ser usada para validar `reaction_type` e para inicializar contagens em `get_item_reactions_summary` (para mostrar todas as reações disponíveis com contagem 0 se ninguém reagiu com elas ainda).
*   **Transações:** `cast_reaction` deve ser transacional.
*   **Atualização de Contadores na `TriggerTable`:** Se `trigger_field_reactions_count` for um campo JSON na `TriggerTable`, a atualização envolveria ler o JSON, modificar as contagens e reescrever. Se forem campos separados (ex: `trigger_field_like_count`, `trigger_field_love_count`), a atualização é mais direta.