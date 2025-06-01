# Documentação Deeper: Módulo de Acesso a Dados para Grids (`GridsRepo`)

Este documento descreve o módulo Elixir `Deeper.Grids.GridsRepo` (ou similar), responsável por encapsular a lógica de consulta para o sistema de grids de dados dinâmicos do UNA.

Ele interage com `sys_objects_grid` (para definições de grid), `sys_grid_fields` (para colunas), e `sys_grid_actions` (para ações). Uma parte crucial é a execução ou interpretação da fonte de dados (`sys_objects_grid.source`) para buscar os dados reais do grid, aplicando filtros, ordenação e paginação.

**Localização do Código:** `lib/deeper/grids/grids_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Definição de um Grid

*   **`get_grid_definition(grid_object_name :: String.t(), user_level_id :: integer() | nil) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a definição completa de um grid, incluindo seus atributos, campos/colunas e ações.
    *   **Argumentos:**
        *   `grid_object_name`: Nome do objeto de grid (de `sys_objects_grid.object`).
        *   `user_level_id`: (Opcional) Para filtrar o próprio grid ou suas ações/campos por `visible_for_levels`.
    *   **Retorno:** `{:ok, grid_definition_map}`. Exemplo da estrutura:

```sql
                SELECT #{selected_fields_string}
                FROM #{grid_def.\"table\"}
                -- JOINs podem ser necessários aqui se os campos vêm de múltiplas tabelas
                WHERE #{where_clause_string}
                ORDER BY #{order_by_clause_string}
                LIMIT ? OFFSET ?;
```

```sql
                SELECT COUNT(#{grid_def.field_id}) as total_count
                FROM #{grid_def.\"table\"}
                -- Mesmos JOINs e cláusula WHERE da query de dados
                WHERE #{where_clause_string};
```

```elixir
        %{
          object: \"bx_persons_administration\",
          source_type: \"Sql\", // sys_objects_grid.source_type
          table: \"bx_persons_data\", // sys_objects_grid.\"table\" (se aplicável)
          field_id: \"id\", // sys_objects_grid.field_id
          field_order_default: \"added\", // sys_objects_grid.field_order (campo padrão para ordenação)
          paginate_per_page: 10,
          filter_fields_available: [\"fullname\", \"email\", \"status\"], // Parseado de sys_objects_grid.filter_fields
          sorting_fields_available: [\"fullname\", \"email\", \"added\", \"status\"], // Parseado de sys_objects_grid.sorting_fields
          // ... outros atributos de sys_objects_grid ...
          fields: [
            %{
              name: \"id\",
              title: \"ID\",
              width: \"5%\",
              order: 1
            },
            %{
              name: \"fullname\",
              title: \"Nome Completo\", // Pode ser chave de tradução
              width: \"30%\",
              order: 2
            }
            // ... outros campos de sys_grid_fields
          ],
          actions: [
            %{
              type: \"single\", // 'single', 'bulk', 'independent'
              name: \"edit\",
              title: \"Editar\", // Pode ser chave de tradução
              icon: \"bx-edit\",
              confirm: true,
              order: 1
            },
            %{
              type: \"bulk\",
              name: \"delete\",
              title: \"Deletar Selecionados\",
              icon: \"bx-trash\",
              confirm: true,
              order: 2
            }
            // ... outras ações de sys_grid_actions
          ]
        }
```

```elixir
        {:ok, %{
          data: [
            %{ \"id\" => 1, \"fullname\" => \"John Doe\", \"email\" => \"john@example.com\", ... },
            %{ \"id\" => 2, \"fullname\" => \"Jane Roe\", \"email\" => \"jane@example.com\", ... }
          ],
          pagination: %{
            total_items: 150,
            total_pages: 8,
            current_page: 1,
            per_page: 20
          }
        }}
```

    *   **Lógica Interna Detalhada:**
        1.  **Buscar `sys_objects_grid`:**
            *   SQL: `SELECT * FROM sys_objects_grid WHERE object = ? LIMIT 1;`
            *   Filtrar por `visible_for_levels` vs `user_level_id` se necessário.
            *   Se não encontrado, `{:error, :not_found}`.
        2.  **Buscar Campos (`sys_grid_fields`):**
            *   SQL: `SELECT name, title, width, translatable, chars_limit, params, hidden_on, \"order\" FROM sys_grid_fields WHERE object = ? ORDER BY \"order\";`
            *   Traduzir `title` se for chave de linguagem.
        3.  **Buscar Ações (`sys_grid_actions`):**
            *   SQL: `SELECT type, name, title, icon, icon_only, confirm, active, \"order\" FROM sys_grid_actions WHERE object = ? AND active = 1 ORDER BY \"order\";`
            *   Traduzir `title` se for chave de linguagem.
        4.  Parsear `filter_fields` e `sorting_fields` de string CSV/JSON para listas Elixir.
        5.  Montar o mapa final da definição do grid.

### 2. Obter Dados para um Grid

*   **`get_grid_data(grid_object_name :: String.t(), query_params :: map(), user_level_id :: integer() | nil) :: {:ok, %{data: list(map()), pagination: map()}} | {:error, :not_found | :invalid_query | any()}`**
    *   Busca os dados para preencher um grid, aplicando filtros, ordenação e paginação.
    *   **Argumentos:**
        *   `grid_object_name`: Nome do objeto de grid.
        *   `query_params`: Mapa contendo parâmetros de cliente como:
            *   `page` ou `offset`/`start` (nome conforme `paginate_get_start`).
            *   `per_page` ou `limit` (nome conforme `paginate_get_per_page`).
            *   `filter_term` (para o filtro geral, nome conforme `filter_get`).
            *   `field_filter_<fieldname>` (filtros por campo específico).
            *   `sort_by` (nome conforme `order_get_field`).
            *   `sort_dir` (nome conforme `order_get_dir`, ex: `asc`, `desc`).
        *   `user_level_id`: Para aplicar ACL na query de dados se necessário (ex: mostrar apenas itens do usuário).
    *   **Retorno:**

    *   **Lógica Interna Detalhada:**
        1.  **Buscar Definição do Grid:** Chamar `get_grid_definition(grid_object_name, user_level_id)` para obter `grid_def`. Se erro, propagar.
        2.  **Validar `query_params`:**
            *   Verificar se os campos de filtro e ordenação solicitados estão em `grid_def.filter_fields_available` e `grid_def.sorting_fields_available`.
        3.  **Construir a Query SQL Dinamicamente:**
            *   **Fonte de Dados:**
                *   Se `grid_def.source_type == \"Sql\"` e `grid_def.source` é uma query complexa, esta é a parte mais difícil. A query original do UNA pode precisar ser parseada ou, idealmente, a lógica é reconstruída de forma segura.
                *   **Abordagem Simplificada/Segura:** Assumir que `grid_def.table` é a tabela principal e construir uma query `SELECT` a partir dela.
            *   **Seleção de Colunas:** Selecionar as colunas listadas em `grid_def.fields`.
            *   **Cláusula `WHERE`:**
                *   Aplicar o filtro geral (`filter_term`) aos campos designados em `grid_def.filter_fields` (usando `LIKE %...%` ou `MATCH` se FTS habilitado, dependendo de `grid_def.filter_mode`).
                *   Aplicar filtros de campo específicos (`field_filter_<fieldname>`).
                *   (Opcional) Adicionar condições de ACL (ex: `WHERE author_id = current_user_id`).
            *   **Cláusula `ORDER BY`:** Com base em `query_params.sort_by` e `query_params.sort_dir`, default para `grid_def.field_order_default`.
            *   **Cláusulas `LIMIT` e `OFFSET`:** Com base em `query_params.page`/`per_page` e `grid_def.paginate_per_page`.
        4.  **Executar Query de Dados:**
            *   SQL (Exemplo conceitual para uma tabela `grid_def.table`):

            *   Passar valores de filtro e paginação como parâmetros seguros para `Repo.query`.
        5.  **Executar Query de Contagem Total (para paginação):**
            *   SQL:

        6.  Mapear os resultados da query de dados para uma lista de mapas.
        7.  Construir o mapa de paginação.
        8.  Retornar `%{data: ..., pagination: ...}`.

### Considerações:

*   **Segurança de SQL Dinâmico:** A construção de queries SQL dinamicamente, especialmente a cláusula `WHERE` e `ORDER BY` baseada em input do usuário (`query_params`), deve ser feita com extremo cuidado para evitar SQL injection.
    *   Sempre use placeholders (`?`) para valores de filtro.
    *   Valide nomes de colunas para `ORDER BY` e filtros de campo contra a lista de campos permitidos da definição do grid.
    *   Não injete diretamente strings de `query_params` na query SQL.
*   **Fonte de Dados `Sql` Complexa:** Se `sys_objects_grid.source` contiver uma query SQL completa e complexa do UNA, adaptá-la para incluir paginação, filtros e ordenação dinâmicos de forma segura é um desafio significativo. Pode ser necessário um parser SQL limitado ou uma reescrita completa da lógica de busca em Elixir. A abordagem mais segura é definir claramente a(s) tabela(s) base e os campos no `sys_objects_grid` e construir a query no `GridsRepo`.
*   **Performance:** Queries de grid podem ser pesadas. Índices apropriados nas tabelas de origem são cruciais, especialmente nas colunas usadas para filtros e ordenação.
*   **Tradução e Formatação de Campos:** O `GridsRepo` pode precisar aplicar traduções (se `field.translatable`) ou formatação (baseada em `field.params`) aos dados *antes* de retorná-los, ou retornar dados brutos e chaves de linguagem para o cliente lidar com isso. Retornar dados brutos é geralmente mais flexível para a API.