# Documentação Deeper: Módulo de Acesso a Dados para Motor de Grids (`Deeper.Grids.GridsRepo`)

Este documento descreve o módulo Elixir `Deeper.Grids.GridsRepo`. Ele é responsável por interagir com as tabelas do banco de dados relacionadas ao sistema de grids do UNA (`sys_objects_grid`, `sys_grid_fields`, `sys_grid_actions`) e por executar as queries SQL dinâmicas para buscar os dados a serem exibidos nas grids.

## Responsabilidades Principais:

*   Buscar a definição de um `sys_objects_grid` específico, incluindo seus campos (`sys_grid_fields`) e ações (`sys_grid_actions`).
*   Construir e executar a query SQL principal (definida em `sys_objects_grid.source`) de forma segura, aplicando filtros, ordenação e paginação fornecidos pelo cliente.
*   Executar uma query de contagem para suportar a paginação.
*   Processar os resultados da query, aplicando traduções e limites de caracteres conforme definido nos campos da grid.

## Funções Auxiliares Chave (Internas):

*   **`get_grid_config_details(grid_object_name :: String.t(), lang_code :: String.t()) :: {:ok, config_details :: map()} | {:error, :not_found}`**
    1.  Busca a configuração da grid de `sys_objects_grid`:
        *   SQL: `SELECT * FROM sys_objects_grid WHERE object = ? LIMIT 1;`
        *   `grid_main_config = resultado`.
    2.  Busca os campos da grid de `sys_grid_fields`:
        *   SQL: `SELECT name, title, width, translatable, chars_limit, params, \"order\" FROM sys_grid_fields WHERE object = ? ORDER BY \"order\";`
        *   Traduz `title` para cada campo usando `LocalizationRepo`.
        *   `grid_fields_config = lista_de_campos_processados`.
    3.  Busca as ações da grid de `sys_grid_actions`:
        *   SQL: `SELECT type, name, title, icon, confirm, \"order\" FROM sys_grid_actions WHERE object = ? AND active = 1 ORDER BY \"order\";`
        *   Traduz `title` para cada ação.
        *   `grid_actions_config = lista_de_ações_processadas`.
    4.  Retorna `{:ok, %{main: grid_main_config, fields: grid_fields_config, actions: grid_actions_config}}`.
    5.  Este resultado pode ser cacheado.

*   **`build_grid_data_query(base_sql_source :: String.t(), main_table :: String.t(), pk_field :: String.t(), filterable_fields_str :: String.t() | nil, sortable_fields_str :: String.t() | nil, default_order_field :: String.t(), query_params :: map()) :: {data_sql :: String.t(), count_sql :: String.t(), bind_params :: list()}`**
    *   Esta é a função mais complexa.
    *   `base_sql_source`: A query SQL de `sys_objects_grid.source`.
    *   `main_table`: A tabela principal da query (usada para construir a query de contagem se `base_sql_source` for complexa).
    *   `pk_field`: Campo chave primária.
    *   `filterable_fields_str`, `sortable_fields_str`: Strings CSV ou JSON dos campos permitidos para filtro/ordenação (de `sys_objects_grid`).
    *   `default_order_field`: Ordenação padrão.
    *   `query_params`: Parâmetros da requisição da API (`page`, `per_page`, `sort_by`, `sort_order`, `filter_FIELDNAME_OPERATOR`).
    1.  **Parse `filterable_fields` e `sortable_fields`**: Cria listas de campos permitidos.
    2.  **Constrói Cláusula `WHERE`**:
        *   Itera sobre `query_params` que começam com `filter_`.
        *   Valida se o `FIELDNAME` está nos `filterable_fields`.
        *   Determina o operador (ex: `_like`, `_eq`, `_gt`, `_lt`, `_in`). Se nenhum operador, assume `_eq`.
        *   Constrói a condição SQL (ex: `fieldname LIKE ?`, `fieldname = ?`). Cuidado com SQL Injection; use placeholders e valide nomes de campos.
        *   Coleta `bind_params` para a cláusula `WHERE`.
    3.  **Constrói Cláusula `ORDER BY`**:
        *   Usa `query_params[\"sort_by\"]` e `query_params[\"sort_order\"]`.
        *   Valida se `sort_by` está nos `sortable_fields`.
        *   Se não fornecido, usa `default_order_field`.
    4.  **Constrói Cláusulas `LIMIT` e `OFFSET`**:
        *   Usa `query_params[\"page\"]`, `query_params[\"per_page\"]` (e `paginate_per_page` da config da grid como default).
    5.  **Monta `data_sql`**:
        *   O `base_sql_source` pode já ter `WHERE` e `ORDER BY`. A lógica precisa ser inteligente para adicionar/modificar estas cláusulas. Uma abordagem comum é envolver a `base_sql_source` como uma subquery se ela for complexa, e aplicar filtros/ordenação/limite na query externa.
        *   Exemplo simplificado: `SELECT * FROM (#{base_sql_source}) AS base_data WHERE #{where_clause} ORDER BY #{order_clause} LIMIT ? OFFSET ?;`
    6.  **Monta `count_sql`**:
        *   Idealmente: `SELECT COUNT(#{pk_field}) FROM (#{base_sql_source}) AS base_data WHERE #{where_clause};`
        *   Se `base_sql_source` for muito complexa ou contiver `GROUP BY` que dificulte a contagem direta, pode ser necessário `SELECT COUNT(*) FROM (SELECT DISTINCT #{pk_field} FROM (#{base_sql_source}) AS base_data WHERE #{where_clause}) AS distinct_count;` ou uma estratégia mais simples baseada na `main_table` com os mesmos filtros.
    7.  Retorna `{data_sql, count_sql, bind_params_combinados}`.

*   **`process_grid_row(row_map :: map(), fields_config :: list(map()), lang_code :: String.t()) :: map()`**
    *   Para cada `field_config` em `fields_config`:
        *   Extrai o valor correspondente de `row_map` usando `field_config[\"name\"]`.
        *   Se `field_config[\"translatable\"] == 1`, traduz o valor usando `LocalizationRepo`.
        *   Aplica `field_config[\"chars_limit\"]`.
        *   Interpreta `field_config[\"params\"]`:
            *   No UNA PHP, `params` pode ser um callback. A API \"Deeper\" não executará PHP.
            *   **Abordagem \"Deeper\"**: A API pode definir um conjunto de \"formatadores\" padrão que podem ser especificados em `params` (ex: `{\"formatter\": \"date\", \"format\": \"YYYY-MM-DD\"}` ou `{\"formatter\": \"boolean_icon\"}`). O `process_grid_row` aplicaria esses formatadores.
            *   Inicialmente, pode apenas retornar o valor bruto ou aplicar formatações simples.
    *   Retorna o `row_map` processado.

## Funções Públicas Principais e Lógica SQL:

*   **`get_grid_data(grid_object_name :: String.t(), user_acl_level_id :: integer(), lang_code :: String.t(), query_params :: map()) :: {:ok, grid_response :: map()} | {:error, :not_found | :forbidden | any()}`**
    1.  `{:ok, %{main: grid_main_config, fields: grid_fields_config, actions: grid_actions_config}} = get_grid_config_details(grid_object_name, lang_code)`
    2.  Verifica `grid_main_config[\"visible_for_levels\"]` contra `user_acl_level_id`. Se não permitido, `{:error, :forbidden}`.
    3.  `{data_sql, count_sql, bind_params} = build_grid_data_query(grid_main_config[\"source\"], grid_main_config[\"table\"], grid_main_config[\"field_id\"], grid_main_config[\"filter_fields\"], grid_main_config[\"sorting_fields\"], grid_main_config[\"field_order\"], query_params)`
    4.  Executa `count_sql` com `bind_params` (apenas os de filtro): `{:ok, %{rows: [[total_items]]}} = Repo.query(count_sql, filter_bind_params)`.
    5.  Executa `data_sql` com `bind_params` (filtro, paginação, ordenação): `{:ok, %{rows: data_rows, columns: data_columns}} = Repo.query(data_sql, all_bind_params)`.
        *   `data_rows` será uma lista de tuplas ou mapas, dependendo do `Repo.query`.
    6.  Converte `data_rows` para uma lista de mapas se forem tuplas, usando `data_columns`.
    7.  `processed_items = Enum.map(data_rows_as_maps, &process_grid_row(&1, grid_fields_config, lang_code))`
    8.  Constrói `pagination_meta` com `total_items`, `page`, `per_page`.
    9.  Monta a resposta da API:

```elixir
        grid_api_response = %{
          grid_object_name: grid_object_name,
          config: %{
            title: LocalizationRepo.get_string(lang_code, grid_main_config[\"title\"] || \"\"), # Título da grid, se houver
            fields: grid_fields_config, # Já processados (com títulos traduzidos)
            actions: grid_actions_config, # Já processados
            default_sort_by: ..., # Extraído de field_order
            default_sort_order: ...
          },
          items: processed_items,
          pagination: pagination_meta
        }
        {:ok, grid_api_response}
```

## Considerações:

*   **Segurança da Query SQL Dinâmica:** Esta é a maior preocupação. `build_grid_data_query` deve ser extremamente cuidadoso para validar todos os inputs do cliente (nomes de campos para filtro/ordenação, operadores) contra as definições da grid (`filter_fields`, `sorting_fields`) antes de injetá-los no SQL. Nomes de colunas devem vir da configuração do DB, não do cliente. Placeholders (`?`) devem ser usados para todos os *valores* dos filtros.
*   **Complexidade da `source` SQL:** Se a query `sys_objects_grid.source` for muito complexa (múltiplos JOINs, subqueries, UNIONs), modificá-la dinamicamente para adicionar mais `WHERE`, `ORDER BY`, `LIMIT`/`OFFSET` pode ser desafiador e propenso a erros. Envolver a `source` original como uma subquery (`SELECT * FROM (...) AS base_data WHERE ...`) é uma técnica comum para simplificar isso.
*   **Performance da Query de Contagem:** Se a query de dados for complexa, a query de contagem também será. Às vezes, para grids muito grandes, a contagem exata pode ser omitida ou aproximada para melhorar a performance da primeira carga, mas isso é uma decisão de UX.
*   **Formatação de Células (`params`):** Como mencionado, a API \"Deeper\" não executará callbacks PHP. O cliente precisará de mais responsabilidade na formatação, ou a API precisará de um sistema de \"formatadores\" mais explícito que possa ser configurado e interpretado.
*   **Ações (`sys_grid_actions`):** A API retorna a definição das ações. O cliente é responsável por, ao clicar em uma ação, fazer a chamada API apropriada para o endpoint que realmente executa essa ação (ex: `DELETE /api/v1/resource/{id}`). O `GridsRepo` não executa as ações da grid, apenas fornece os dados para exibi-las.

Este `GridsRepo` é uma peça central para muitas interfaces administrativas e de listagem de dados, exigindo um equilíbrio cuidadoso entre flexibilidade e segurança/performance.