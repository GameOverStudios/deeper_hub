# Documentação Deeper: Módulo de Acesso a Dados para Motor de Grades (GridRepo)

Este documento descreve o módulo Elixir `Deeper.Grids.GridRepo` (nome sugerido), responsável por encapsular toda a lógica de acesso ao banco de dados (SQLite) para as funcionalidades do motor de grades de dados.

Ele fornecerá funções para buscar definições de grades, seus campos e ações, e o mais importante, para buscar os dados dinamicamente, aplicando filtros, ordenação e paginação.

## Módulo: `Deeper.Grids.GridRepo`

### Responsabilidades:

*   Buscar a definição completa de um objeto de grade (`sys_objects_grid`) pelo seu nome.
*   Buscar os campos (`sys_grid_fields`) associados a um objeto de grade.
*   Buscar as ações (`sys_grid_actions`) associadas a um objeto de grade.
*   Construir e executar dinamicamente a query SQL para buscar os dados de uma grade, incorporando:
    *   A query `source` base definida em `sys_objects_grid`.
    *   Filtros baseados nos `filter_fields` da grade e nos parâmetros fornecidos pelo cliente.
    *   Ordenação baseada no `field_order` padrão ou nos parâmetros do cliente.
    *   Paginação (LIMIT/OFFSET).
*   Executar uma query `COUNT(*)` para obter o número total de registros (considerando os filtros) para fins de paginação.

### Funções Principais (Exemplos):

**1. Buscar Definição do Objeto de Grade**

```elixir
defmodule Deeper.Grids.GridRepo do
  alias Deeper.Core.Data.Repo # Seu módulo de acesso ao DB

  @doc \"\"\"
  Busca a definição de um objeto de grade pelo seu nome.
  \"\"\"
  @spec get_grid_definition(String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_grid_definition(object_name) do
    sql = \"SELECT * FROM sys_objects_grid WHERE object = ? LIMIT 1;\"
    case Repo.query(sql, [object_name]) do
      {:ok, %{rows: [grid_def_map]}} -> {:ok, grid_def_map} # Assumindo que Repo.query retorna mapas
      {:ok, %{rows: []}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end
```

```elixir
  @doc \"\"\"
  Busca todos os campos (colunas) para um determinado objeto de grade, ordenados.
  \"\"\"
  @spec get_grid_fields(String.t()) :: {:ok, [map()]} | {:error, any()}
  def get_grid_fields(object_name) do
    sql = \"\"\"
    SELECT name, title, width, translatable, chars_limit, params, hidden_on, \"order\"
    FROM sys_grid_fields
    WHERE object = ?
    ORDER BY \"order\" ASC;
    \"\"\"
    case Repo.query(sql, [object_name]) do
      {:ok, %{rows: fields_list}} -> {:ok, fields_list}
      {:error, reason} -> {:error, reason}
    end
  end
```

```elixir
  @doc \"\"\"
  Busca todas as ações ativas para um determinado objeto de grade, ordenadas.
  \"\"\"
  @spec get_grid_actions(String.t()) :: {:ok, [map()]} | {:error, any()}
  def get_grid_actions(object_name) do
    sql = \"\"\"
    SELECT type, name, title, icon, icon_only, confirm, \"order\", api_endpoint, api_method, id_placeholder_field
    FROM sys_grid_actions
    WHERE object = ? AND active = 1
    ORDER BY \"order\" ASC;
    \"\"\"
    case Repo.query(sql, [object_name]) do
      {:ok, %{rows: actions_list}} -> {:ok, actions_list}
      {:error, reason} -> {:error, reason}
    end
  end
```

```elixir
  @doc \"\"\"
  Busca os dados para um objeto de grade, aplicando filtros, ordenação e paginação.

  `grid_definition` é o mapa obtido de `get_grid_definition/1`.
  `params` é um mapa de query parameters da API, como:
    %{
      \"filter\" => \"termo de busca\",
      \"status_filter\" => \"active\", (exemplo de filtro específico)
      \"sort_by\" => \"title_asc\",
      \"offset\" => 0,
      \"limit\" => 20
    }
  \"\"\"
  @spec get_grid_data(grid_definition :: map(), params :: map()) ::
          {:ok, %{data: [map()], total_items: integer()}} | {:error, any()}
  def get_grid_data(grid_definition, params) do
    base_sql_source = grid_definition.source # Ex: \"SELECT id, title, author, status FROM articles WHERE published = 1\"

    # --- Construir Cláusula WHERE ---
    {where_clause_sql, where_params} = build_where_clause(grid_definition, params)

    # --- Construir Cláusula ORDER BY ---
    order_by_sql = build_order_by_clause(grid_definition, params)

    # --- Construir SQL para Contagem Total ---
    # Importante: O `source` pode já ter um WHERE. Precisamos adicionar nosso `where_clause_sql` a ele.
    # Se `source` é \"SELECT ... FROM table\", então fica \"SELECT COUNT(*) FROM table #{where_clause_sql}\"
    # Se `source` é \"SELECT ... FROM table WHERE x=1\", então fica \"SELECT COUNT(*) FROM table WHERE x=1 #{adapt_where_for_existing(where_clause_sql)}\"
    # Isso requer uma análise mais robusta do `grid_definition.source`
    # Por simplicidade aqui, vamos assumir que podemos anexar nosso where_clause_sql.
    # Uma abordagem mais segura é envolver o `source` em uma subquery para contagem e dados.

    count_sql_base = \"SELECT COUNT(*) AS total FROM (#{base_sql_source}) AS base_query_for_count\"
    # Nota: Se base_sql_source já tem ORDER BY, pode ser necessário removê-lo para a contagem.
    # E se base_sql_source já tem LIMIT/OFFSET, também precisa ser removido.

    count_sql = \"#{count_sql_base} #{where_clause_sql}\" # Simplificado; pode precisar de ajuste

    # --- Construir SQL para Dados Paginados ---
    limit = Map.get(params, \"limit\", grid_definition.paginate_per_page) |> String.to_integer()
    offset = Map.get(params, \"offset\", 0) |> String.to_integer()

    # Envolver a query source para aplicar filtros e ordenação antes da paginação final
    # Isso garante que a paginação ocorra no conjunto de resultados correto.
    data_sql_template = \"\"\"
    SELECT * FROM (
      #{base_sql_source}
    ) AS base_query_for_data
    #{where_clause_sql}
    #{order_by_sql}
    LIMIT ? OFFSET ?;
    \"\"\"
    data_params = where_params ++ [limit, offset]

    # --- Executar Queries ---
    with {:ok, %{rows: [%{\"total\" => total_items}]}} <- Repo.query(count_sql, where_params),
         {:ok, %{rows: data_rows}} <- Repo.query(data_sql_template, data_params) do
      {:ok, %{data: data_rows, total_items: total_items}}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :count_query_failed} # Caso a query de contagem não retorne o esperado
    end
  end

  # --- Funções Auxiliares para construir SQL dinâmico ---

  defp build_where_clause(grid_definition, params) do
    clauses = []
    values = []

    # Filtro geral (textual)
    general_filter_key = grid_definition.filter_get || \"filter\"
    if filter_term = Map.get(params, general_filter_key), String.trim(filter_term) != \"\" do
      filter_fields =
        (grid_definition.filter_fields || \"\")
        |> String.split(\",\", trim: true)
        |> Enum.filter(&(&1 != \"\"))

      if Enum.any?(filter_fields) do
        # Construir (field1 LIKE ? OR field2 LIKE ? ...)
        like_clauses = Enum.map(filter_fields, fn field -> \"#{field} LIKE ?\" end)
        clauses = clauses ++ [\"(#{Enum.join(like_clauses, \" OR \")})\"]
        values = values ++ Enum.map(filter_fields, fn _ -> \"%#{filter_term}%\" end)
      end
    end

    # Adicionar aqui lógica para filtros específicos se a grade os definir
    # Ex: se params tem \"status_filter\" e a grade suporta filtrar por status
    # if status_val = Map.get(params, \"status_filter\"), status_val != \"\" do
    #   clauses = clauses ++ [\"status_column = ?\"] # status_column vem da definição da grade
    #   values = values ++ [status_val]
    # end

    if Enum.empty?(clauses) do
      {\"\", []}
    else
      # Determina se o `source` já tem um WHERE. Se sim, usa \"AND\", senão \"WHERE\".
      # Esta lógica é complexa e depende da estrutura do `source`.
      # Para simplificar, assumiremos que o `source` é uma subquery ou tabela simples
      # e podemos sempre iniciar com WHERE, ou o `source` é envolvido numa subquery
      # como feito em `get_grid_data`.
      where_sql = \"WHERE \" <> Enum.join(clauses, \" AND \")
      {where_sql, values}
    end
  end

  defp build_order_by_clause(grid_definition, params) do
    default_order = grid_definition.field_order # Ex: \"added DESC\"

    sort_by_param = Map.get(params, \"sort_by\") # Ex: \"title_asc\" ou \"name_desc\"

    order_clause =
      cond do
        sort_by_param && sort_by_param != \"\" ->
          # Validar se o campo de ordenação está em `grid_definition.sorting_fields`
          # e construir \"ORDER BY field DIR\"
          # Ex: \"title_asc\" -> \"ORDER BY title ASC\"
          case String.split(sort_by_param, \"_\", parts: 2) do
            [field, \"asc\"] -> \"ORDER BY #{sanitize_field_name(field)} ASC\"
            [field, \"desc\"] -> \"ORDER BY #{sanitize_field_name(field)} DESC\"
            [field] -> \"ORDER BY #{sanitize_field_name(field)} ASC\" # Default to ASC
            _ -> \"ORDER BY #{default_order}\" # Fallback para o default
          end
        default_order && default_order != \"\" ->
          \"ORDER BY #{default_order}\"
        true ->
          \"\" # Sem ordenação
      end

    order_clause
  end

  # Função simples para evitar SQL injection em nomes de colunas (melhorar conforme necessidade)
  defp sanitize_field_name(field_name) do
    # Permitir apenas alfanuméricos e underscore. Não é 100% seguro para todos os casos.
    # Idealmente, validar contra uma lista de campos permitidos (grid_definition.sorting_fields).
    String.replace(field_name, ~r/[^a-zA-Z0-9_]/, \"\")
  end
```

**2. Buscar Campos da Grade**

**3. Buscar Ações da Grade**

**4. Buscar Dados da Grade (Função Principal e Complexa)**

Esta é a função mais crítica, pois constrói a SQL dinamicamente.

### Pontos Chave e Complexidades:

*   **Construção Dinâmica de SQL:**
    *   A função `get_grid_data/2` é complexa porque precisa construir a query SQL final dinamicamente.
    *   **Segurança:** É VITAL garantir que os parâmetros do cliente (`params`) não sejam injetados diretamente no SQL. Use placeholders (`?`) para todos os valores. Nomes de colunas para `ORDER BY` devem ser validados contra uma lista de campos permitidos (`grid_definition.sorting_fields`) para evitar SQL injection. A função `sanitize_field_name` é um exemplo muito básico e precisaria ser robustecida.
    *   **Análise do `source`:** A query `source` em `sys_objects_grid` pode ser complexa. Adicionar `WHERE` e `ORDER BY` dinamicamente a ela requer cuidado. Envolver o `source` em uma subquery (`SELECT * FROM (#{grid_definition.source}) AS sub ...`) é uma técnica comum para simplificar a adição de cláusulas dinâmicas.
*   **Contagem Total (`total_items`):**
    *   Requer uma segunda query (`COUNT(*)`). Essa query de contagem deve aplicar os mesmos filtros da query de dados, mas sem `LIMIT`, `OFFSET`, e geralmente sem `ORDER BY` (embora alguns SGBDs otimizem isso).
    *   Garantir que o `COUNT(*)` opere sobre o mesmo conjunto de dados filtrados é crucial para a paginação correta.
*   **Validação de Parâmetros:**
    *   `limit`, `offset`, `sort_by` e nomes de campos de filtro vindos do cliente devem ser validados e sanitizados.
*   **Mapeamento de Resultados:**
    *   As funções `Repo.query` devem retornar os dados de forma consistente (ex: lista de mapas), para que os controllers da API possam processá-los facilmente.
*   **Translatable Fields:** A lógica de tradução de campos marcados como `translatable` em `sys_grid_fields` precisaria ser aplicada após a busca dos dados, similarmente aos títulos de menu, provavelmente na camada do controller da API usando o `LocalizationRepo`.

Este módulo `GridRepo` será um dos mais desafiadores de implementar corretamente devido à natureza dinâmica das queries, mas é fundamental para fornecer a funcionalidade de grades de dados da API \"Deeper\".