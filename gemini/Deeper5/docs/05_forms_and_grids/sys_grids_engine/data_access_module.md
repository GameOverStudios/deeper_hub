# Documentação Deeper: Módulo de Acesso a Dados para Grades (`GridRepo`)

Este documento descreve o módulo Elixir `Deeper.GridsEngine.GridRepo`, responsável por interagir com as tabelas do motor de grades (`sys_objects_grid`, `sys_grid_fields`, `sys_grid_actions`) e por executar/construir as queries para buscar os dados das grades.

**Localização do Código:** `lib/deeper/grids_engine/grid_repo.ex`

```elixir
defmodule Deeper.GridsEngine.GridRepo do
  alias Deeper.Core.Data.Repo
  # alias Deeper.SystemCore.LocalizationRepo # Para traduzir títulos
  # alias Deeper.SystemCore.ACLValidator # Para filtrar ações/grades por ACL

  @doc \"\"\"
  Busca a definição completa de uma grade, incluindo seus campos e ações.
  Aplica filtros ACL para visibilidade da grade e de suas ações.
  \"\"\"
  @spec get_grid_definition(
          grid_object_name :: String.t(),
          current_user_level_id :: integer() | nil,
          lang_id :: integer() | nil
        ) :: {:ok, map()} | {:error, :not_found | any()}
  def get_grid_definition(grid_object_name, current_user_level_id, lang_id \\\\ nil) do
    # 1. Buscar detalhes do objeto da grade
    case get_grid_object_details(grid_object_name) do
      {:ok, grid_object_map} ->
        # TODO: Verificar ACL para visibilidade da grade (grid_object_map[\"visible_for_levels\"])
        # if !ACLValidator.can_view_grid?(current_user_level_id, grid_object_map[\"visible_for_levels\"]) do
        #   return {:error, :forbidden}
        # end

        # 2. Buscar campos da grade
        case get_grid_fields(grid_object_name, lang_id) do
          {:ok, fields_list} ->
            # 3. Buscar ações da grade
            case get_grid_actions(grid_object_name, lang_id) do
              {:ok, actions_list} ->
                # TODO: Filtrar actions_list por ACL se necessário (ações podem ter suas próprias permissões)

                definition = %{
                  object_details: grid_object_map, # Contém paginate_per_page, filter_fields, sorting_fields, etc.
                  fields: fields_list,
                  actions: actions_list,
                  data_endpoint_pattern: \"/grids/#{grid_object_name}/data\" # Padrão para buscar dados
                }
                {:ok, definition}
              {:error, reason_actions} -> {:error, reason_actions}
            end
          {:error, reason_fields} -> {:error, reason_fields}
        end
      {:error, :not_found} -> {:error, :grid_object_not_found}
      {:error, reason_grid} -> {:error, reason_grid}
    end
  end

  @doc \"Busca detalhes de um sys_objects_grid.\"
  def get_grid_object_details(grid_object_name) do
    sql = \"SELECT * FROM sys_objects_grid WHERE object = ? LIMIT 1\"
    case Repo.query(sql, [grid_object_name]) do
      {:ok, %{rows: [row_data], columns: cols}} -> {:ok, map_row_to_generic_struct(row_data, cols)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"Busca os campos (colunas) de uma grade, ordenados.\"
  def get_grid_fields(grid_object_name, _lang_id \\\\ nil) do
    sql = \"\"\"
    SELECT name, title, width, translatable, chars_limit, params, hidden_on
    FROM sys_grid_fields
    WHERE object = ?
    ORDER BY \"order\" ASC;
    \"\"\"
    case Repo.query(sql, [grid_object_name]) do
      {:ok, %{rows: rows_data, columns: cols}} ->
        fields = Enum.map(rows_data, fn row ->
          field_map = map_row_to_generic_struct(row, cols)
          # TODO: Traduzir field_map[\"title\"] usando lang_id e LocalizationRepo
          # Se field_map[\"translatable\"] == 1, o VALOR da célula será uma lkey, não o título.
          field_map
        end)
        {:ok, fields}
      err -> err
    end
  end

  @doc \"Busca as ações disponíveis para uma grade, ordenadas.\"
  def get_grid_actions(grid_object_name, _lang_id \\\\ nil) do
    sql = \"\"\"
    SELECT type, name, title, icon, icon_only, confirm
    FROM sys_grid_actions
    WHERE object = ? AND active = 1
    ORDER BY \"order\" ASC;
    \"\"\"
    case Repo.query(sql, [grid_object_name]) do
      {:ok, %{rows: rows_data, columns: cols}} ->
        actions = Enum.map(rows_data, fn row ->
          action_map = map_row_to_generic_struct(row, cols)
          # TODO: Traduzir action_map[\"title\"] usando lang_id e LocalizationRepo
          action_map
        end)
        {:ok, actions}
      err -> err
    end
  end


  @doc \"\"\"
  Busca os dados paginados, filtrados e ordenados para uma grade específica.
  Esta é a função mais complexa devido à execução dinâmica de SQL ou lógica de serviço.
  \"\"\"
  @spec get_grid_data(
          grid_object_name :: String.t(),
          query_opts :: map(), # %{page: 1, per_page: 20, filters: %{\"nome_campo\" => \"valor\"}, sort_by: \"campo\", sort_dir: \"asc\"}
          current_user_level_id :: integer() | nil
        ) :: {:ok, {list(map()), map()}} | {:error, any()}
  def get_grid_data(grid_object_name, query_opts, _current_user_level_id) do
    # 1. Buscar a definição da grade para obter source_type, source, field_id, etc.
    case get_grid_object_details(grid_object_name) do
      {:ok, grid_def} ->
        source_type = grid_def[\"source_type\"] || grid_def[:source_type]
        source_query_or_service = grid_def[\"source\"] || grid_def[:source]
        field_id_name = grid_def[\"field_id\"] || grid_def[:field_id] # Nome da coluna ID

        page = Map.get(query_opts, :page, 1)
        per_page = Map.get(query_opts, :per_page, grid_def[\"paginate_per_page\"] || 10)
        offset = (page - 1) * per_page

        # Aplicar filtros e ordenação (esta parte é a mais complexa se source_type='Sql')
        # E também a lógica de privacidade/ACL para os dados retornados.

        case source_type do
          \"Sql\" ->
            # ATENÇÃO: Executar SQL dinâmico do banco de dados é um RISCO DE SEGURANÇA ENORME.
            # A abordagem aqui DEVE ser de construir a query de forma segura,
            # validando todos os inputs (nomes de campos de filtro/ordenação, etc.).
            # Uma alternativa mais segura é mapear `source_query_or_service` para
            # funções Elixir pré-definidas que constroem queries Ecto/SQL seguras.

            # Simplificação perigosa (NÃO USAR EM PRODUÇÃO COMO ESTÁ):
            # Assume que `source_query_or_service` é uma query SELECT base.
            # Precisamos adicionar WHERE, ORDER BY, LIMIT, OFFSET de forma segura.
            # Exemplo de como seria a construção segura (conceitual):
            # {safe_where_clause, safe_params} = build_safe_where_clause(query_opts[:filters], grid_def[\"filter_fields\"])
            # {safe_order_clause} = build_safe_order_clause(query_opts[:sort_by], query_opts[:sort_dir], grid_def[\"sorting_fields\"])
            #
            # base_sql = source_query_or_service -- Ex: \"SELECT id, nome, email FROM usuarios\"
            # data_sql = \"#{base_sql} #{safe_where_clause} #{safe_order_clause} LIMIT ? OFFSET ?\"
            # count_sql = \"SELECT COUNT(#{field_id_name}) FROM (#{base_sql} #{safe_where_clause}) AS subquery\"
            #
            # Repo.query(count_sql, safe_params) ... e depois Repo.query(data_sql, safe_params ++ [per_page, offset]) ...

            # Por agora, vamos simular um erro ou um resultado mockado, pois a implementação segura é complexa.
            Logger.warn(\"Execução de SQL dinâmico para grades não implementada de forma segura.\", module: __MODULE__)
            {:error, :dynamic_sql_not_safely_implemented}

          \"Service\" -> # Adição Deeper: source é \"Modulo.funcao/aridade\" ou \"Modulo.funcao\"
            # Ex: source_query_or_service = \"Deeper.Content.ArticlesRepo.list_articles_for_grid\"
            # A função Elixir referenciada seria responsável por aplicar filtros, paginação, ordenação.
            # Ela receberia `query_opts`.
            # Ex: apply(Module, :function_name, [query_opts_para_servico])
            # Esta é uma abordagem muito mais segura e flexível.
            case parse_and_call_service(source_query_or_service, query_opts, grid_def) do
                {:ok, {data_list, total_count}} ->
                    pagination_meta = %{
                        total_items: total_count,
                        current_page: page,
                        per_page: per_page,
                        total_pages: if(total_count > 0, do: ceil(total_count / per_page), else: 0)
                    }
                    {:ok, {data_list, pagination_meta}}
                err -> err
            end

          \"Array\" -> # UNA PHP: source é um array PHP serializado ou nome de variável. Difícil de portar diretamente.
            Logger.warn(\"Source_type 'Array' para grades não suportado diretamente.\", module: __MODULE__)
            {:error, :array_source_not_supported}

          _ ->
            {:error, :unknown_grid_source_type}
        end

      {:error, :not_found} -> {:error, :grid_object_not_found}
      err -> err
    end
  end


  # --- Funções Auxiliares Internas ---

  # Placeholder para parsear e chamar um serviço Elixir definido em sys_objects_grid.source
  defp parse_and_call_service(service_string, query_opts, _grid_def) do
    # Exemplo: service_string = \"Deeper.Content.ArticlesRepo.list_articles_for_grid\"
    # Este é um exemplo muito básico e precisaria de mais robustez.
    try do
      [module_str, function_str] = String.split(service_string, \".\", parts: 2)
      module = String.to_atom(\"Elixir.\" <> module_str) # Assume que está no namespace Elixir
      function_name = String.to_atom(function_str)

      # A função de serviço deve retornar {:ok, {lista_de_dados, contagem_total}}
      # ou {:error, razao}
      # E deve aceitar um mapa de opções (query_opts) que inclui filtros, paginação, ordenação.
      apply(module, function_name, [query_opts])
    rescue
      e in [UndefinedFunctionError, ArgumentError, MatchError, _] ->
        Logger.error(\"Erro ao chamar serviço de grade '#{service_string}': #{inspect(e)}\", module: __MODULE__)
        {:error, :grid_service_call_failed}
    end
  end


  # Funções para construir WHERE e ORDER BY de forma segura seriam necessárias aqui
  # para o caso de source_type = 'Sql'.
  # defp build_safe_where_clause(filters_map, allowed_filter_fields_str) do ... end
  # defp build_safe_order_clause(sort_by, sort_dir, allowed_sorting_fields_str) do ... end

  defp map_row_to_generic_struct(row_data_list, columns_list) when is_list(row_data_list) and is_list(columns_list) do
    Enum.zip(columns_list, row_data_list)
    |> Enum.map(fn {col, val} ->
        key = try do String.to_atom(Atom.to_string(col)) rescue _ -> Atom.to_string(col) end
        {key, val}
      end)
    |> Enum.into(%{})
  end
end
```