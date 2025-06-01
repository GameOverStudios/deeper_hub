# Documentação Deeper: Módulo de Acesso a Dados para Configurações (`OptionsRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.OptionsRepo`, responsável por interagir com as tabelas de configurações (`sys_options`, `sys_options_categories`, `sys_options_types`) no banco de dados SQLite. Ele fornecerá funções para ler valores de configuração, detalhes e listas de configurações.

**Consideração Importante: Cache**
Como os valores de configuração são frequentemente acessados e mudam raramente, este módulo (ou uma camada acima dele) idealmente implementaria um cache (ex: usando um GenServer com ETS) para armazenar as configurações após a primeira leitura do banco de dados. As funções descritas abaixo mostrariam a lógica de busca no DB; a camada de cache seria adicional. Por simplicidade, o cache não está detalhado no código SQL/Elixir abaixo, mas sua necessidade é anotada.

**Localização do Código:** `lib/deeper/system_core/options_repo.ex`

```elixir
defmodule Deeper.SystemCore.OptionsRepo do
  alias Deeper.Core.Data.Repo # Seu módulo de acesso ao DB

  # --- Funções para ler opções individuais ---

  @doc \"\"\"
  Busca o valor de uma opção específica pelo seu nome programático.
  Tenta converter o valor para um tipo Elixir mais apropriado baseado em `sys_options.type`.
  Ideal para cache.
  \"\"\"
  @spec get_option_value(option_name :: String.t()) :: {:ok, any()} | {:error, :not_found | any()}
  def get_option_value(option_name) do
    # TODO: Implementar lógica de cache aqui primeiro
    # Se cache miss, buscar no DB:
    sql = \"SELECT value, type FROM sys_options WHERE name = ? LIMIT 1\"
    case Repo.query(sql, [option_name]) do
      {:ok, %{rows: [[value_str, type_str]], columns: _}} ->
        {:ok, parse_option_value(value_str, type_str)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Busca todos os detalhes de uma opção específica pelo seu nome programático.
  Ideal para cache.
  \"\"\"
  @spec get_option_details(option_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_option_details(option_name) do
    # TODO: Cache
    sql = \"\"\"
    SELECT o.id, o.category_id, o.name, o.caption, o.info, o.value, o.type, o.extra,
           o.\"check\", o.check_params, o.check_error, o.\"order\",
           c.name as category_name, c.caption as category_caption,
           t.name as type_name, t.caption as type_caption
    FROM sys_options o
    JOIN sys_options_categories c ON o.category_id = c.id
    JOIN sys_options_types t ON c.type_id = t.id
    WHERE o.name = ?
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [option_name]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        # Mapear e também parsear o 'value' com base no 'type'
        parsed_option =
          map_row_to_generic_struct(row_data, columns)
          |> Map.update(\"value\", nil, &parse_option_value(&1, Map.get(map_row_to_generic_struct(row_data, columns), \"type\")))
        {:ok, parsed_option}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # --- Funções para listar opções, categorias e tipos ---

  @doc \"Lista todas as opções (nome e valor parseado) de uma categoria específica.\"
  @spec list_options_by_category_name(category_name :: String.t()) :: {:ok, list(map())} | {:error, any()}
  def list_options_by_category_name(category_name) do
    # TODO: Cache
    sql = \"\"\"
    SELECT o.name, o.value, o.type
    FROM sys_options o
    JOIN sys_options_categories c ON o.category_id = c.id
    WHERE c.name = ?
    ORDER BY o.\"order\" ASC;
    \"\"\"
    case Repo.query(sql, [category_name]) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        options =
          Enum.map(rows_data, fn row ->
            mapped_row = map_row_to_generic_struct(row, columns)
            %{
              name: Map.get(mapped_row, \"name\"),
              value: parse_option_value(Map.get(mapped_row, \"value\"), Map.get(mapped_row, \"type\"))
              # type: Map.get(mapped_row, \"type\") # Opcional retornar o tipo original
            }
          end)
        {:ok, options}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Lista todas as opções (detalhes) de um tipo de configuração específico.\"
  @spec list_options_details_by_type_name(type_name :: String.t()) :: {:ok, list(map())} | {:error, any()}
  def list_options_details_by_type_name(type_name) do
    # TODO: Cache
    sql = \"\"\"
    SELECT o.id, o.name, o.caption, o.info, o.value, o.type, o.extra, o.\"order\",
           c.name as category_name, c.caption as category_caption
    FROM sys_options o
    JOIN sys_options_categories c ON o.category_id = c.id
    JOIN sys_options_types t ON c.type_id = t.id
    WHERE t.name = ?
    ORDER BY c.\"order\" ASC, o.\"order\" ASC;
    \"\"\"
    case Repo.query(sql, [type_name]) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        options =
          Enum.map(rows_data, fn row ->
            map_row_to_generic_struct(row, columns)
            |> Map.update(\"value\", nil, &parse_option_value(&1, Map.get(map_row_to_generic_struct(row, columns), \"type\")))
          end)
        {:ok, options}
      {:error, reason} ->
        {:error, reason}
    end
  end


  @doc \"Lista todas as categorias de opções, opcionalmente filtradas por ID ou nome do tipo.\"
  @spec list_option_categories(type_filter :: integer() | String.t() | nil) :: {:ok, list(map())} | {:error, any()}
  def list_option_categories(type_filter \\\\ nil) do
    # TODO: Cache
    base_sql = \"\"\"
    SELECT c.id, c.type_id, c.name, c.caption, c.hidden, c.\"order\", t.name as type_name
    FROM sys_options_categories c
    JOIN sys_options_types t ON c.type_id = t.id
    \"\"\"
    params = []

    {final_sql, final_params} =
      cond do
        is_integer(type_filter) ->
          {base_sql <> \" WHERE c.type_id = ? ORDER BY c.\\\"order\\\" ASC\", [type_filter]}
        is_binary(type_filter) ->
          {base_sql <> \" WHERE t.name = ? ORDER BY c.\\\"order\\\" ASC\", [type_filter]}
        true ->
          {base_sql <> \" ORDER BY t.\\\"order\\\" ASC, c.\\\"order\\\" ASC\", params}
      end

    case Repo.query(final_sql, final_params) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        categories = Enum.map(rows_data, &map_row_to_generic_struct(&1, columns))
        {:ok, categories}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Lista todos os tipos de opções.\"
  @spec list_option_types() :: {:ok, list(map())} | {:error, any()}
  def list_option_types() do
    # TODO: Cache
    sql = \"\"\"
    SELECT id, \"group\", name, caption, icon, \"order\"
    FROM sys_options_types
    ORDER BY \"order\" ASC;
    \"\"\"
    case Repo.query(sql, []) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        types = Enum.map(rows_data, &map_row_to_generic_struct(&1, columns))
        {:ok, types}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # --- Funções Auxiliares ---

  @doc \"\"\"
  Parseia o valor string de uma opção para um tipo Elixir apropriado.
  \"\"\"
  defp parse_option_value(value_str, \"checkbox\") do
    # No UNA, checkbox 'on' é verdadeiro. Outros valores podem ser string vazia ou ausente.
    value_str == \"on\"
  end
  defp parse_option_value(value_str, \"digit\") do
    case Integer.parse(value_str) do
      {int_val, \"\"} -> int_val
      _ -> value_str # Retorna string se não for um inteiro válido
    end
  end
  defp parse_option_value(value_str, \"value\") do # 'value' pode ser numérico ou string
    case Integer.parse(value_str) do
      {int_val, \"\"} -> int_val
      _ ->
        case Float.parse(value_str) do
          {float_val, \"\"} -> float_val
          _ -> value_str
        end
    end
  end
  # Para 'list', 'rlist', 'select', 'combobox', o 'value' é a chave selecionada.
  # O 'extra' contém as opções, que podem ser parseadas se necessário para validação ou UI.
  # Para a API de leitura, geralmente só retornamos o 'value' (chave selecionada).
  # Se o cliente precisar das opções do 'extra', um endpoint específico ou
  # o `get_option_details` pode retornar o `extra` bruto ou parseado.
  defp parse_option_value(value_str, _type_str) do
    # Default para string para outros tipos como 'text', 'code', 'select' (valor é a chave), etc.
    value_str
  end

  # Função auxiliar de mapeamento (mesma do ACLRepo, pode ser movida para um helper comum)
  defp map_row_to_generic_struct(row_data_list, columns_list) when is_list(row_data_list) and is_list(columns_list) do
    Enum.zip(columns_list, row_data_list)
    |> Enum.map(fn {col, val} ->
        # Tenta converter o nome da coluna para atom.
        # O nome original da coluna do DB (string) pode ser útil em alguns casos.
        # Se as colunas já são atoms do `Repo.query`, esta conversão pode ser simplificada.
        key = try do String.to_atom(Atom.to_string(col)) rescue _ -> Atom.to_string(col) end
        {key, val}
      end)
    |> Enum.into(%{})
  end
end
```