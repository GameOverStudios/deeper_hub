# Documentação Deeper: Módulo de Acesso a Dados para Localização (`LocalizationRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.LocalizationRepo`, responsável por interagir com as tabelas de localização (`sys_localization_languages`, `sys_localization_categories`, `sys_localization_keys`, `sys_localization_strings`) no banco de dados SQLite. Ele fornecerá funções para buscar idiomas, chaves e, o mais importante, as strings traduzidas.

**Consideração Importante: Cache**
Strings de tradução e listas de idiomas são altamente cacheadáveis. Este módulo (ou uma camada de serviço acima dele) deve implementar um cache robusto (ex: GenServer com ETS) para evitar acessos repetidos ao banco de dados. As funções abaixo mostram a lógica de busca no DB; a camada de cache seria adicional.

**Localização do Código:** `lib/deeper/system_core/localization_repo.ex`

```elixir
defmodule Deeper.SystemCore.LocalizationRepo do
  alias Deeper.Core.Data.Repo # Seu módulo de acesso ao DB

  # --- Funções para Idiomas ---

  @doc \"Busca um idioma pelo seu código (ex: 'en', 'pt-BR').\"
  @spec get_language_by_code(lang_code :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_language_by_code(lang_code) do
    # TODO: Cache
    sql = \"SELECT ID, Name, Title, Flag, Direction, LanguageCountry, Enabled FROM sys_localization_languages WHERE Name = ? LIMIT 1\"
    case Repo.query(sql, [lang_code]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca um idioma pelo seu ID.\"
  @spec get_language_by_id(lang_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_language_by_id(lang_id) do
    # TODO: Cache
    sql = \"SELECT ID, Name, Title, Flag, Direction, LanguageCountry, Enabled FROM sys_localization_languages WHERE ID = ? LIMIT 1\"
    case Repo.query(sql, [lang_id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Lista todos os idiomas habilitados no sistema.\"
  @spec list_enabled_languages() :: {:ok, list(map())} | {:error, any()}
  def list_enabled_languages() do
    # TODO: Cache
    sql = \"\"\"
    SELECT ID, Name, Title, Flag, Direction, LanguageCountry
    FROM sys_localization_languages
    WHERE Enabled = 1
    ORDER BY Title ASC;
    \"\"\"
    case Repo.query(sql, []) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        languages = Enum.map(rows_data, &map_row_to_generic_struct(&1, columns))
        {:ok, languages}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # --- Funções para Strings Traduzidas ---

  @doc \"\"\"
  Busca uma string traduzida específica por sua chave e código/ID do idioma.
  Retorna apenas a string traduzida.
  \"\"\"
  @spec get_string(key_string :: String.t(), lang_id_or_code :: integer() | String.t()) :: {:ok, String.t()} | {:error, :not_found | any()}
  def get_string(key_string, lang_id_or_code) do
    # TODO: Cache (pode cachear chaves individuais ou todo o pacote de um idioma)
    with {:ok, lang_id} <- resolve_lang_id(lang_id_or_code) do
      sql = \"\"\"
      SELECT ls.String
      FROM sys_localization_strings ls
      JOIN sys_localization_keys lk ON ls.IDKey = lk.ID
      WHERE lk.\"Key\" = ? AND ls.IDLanguage = ?
      LIMIT 1;
      \"\"\"
      case Repo.query(sql, [key_string, lang_id]) do
        {:ok, %{rows: [[translated_string]], columns: _}} ->
          {:ok, translated_string}
        {:ok, %{rows: []}} ->
          # Opcional: Tentar fallback para idioma padrão antes de retornar :not_found
          {:error, :not_found_for_language} # Ou :not_found se a chave não existe
        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason} # Erro ao resolver lang_id
    end
  end

  @doc \"\"\"
  Busca todas as strings traduzidas para um idioma específico.
  Opcionalmente, pode filtrar por categoria de chaves ou por nome de módulo (que corresponde a uma categoria).
  Retorna um mapa onde as chaves são as `sys_localization_keys.\"Key\"` e os valores são as strings traduzidas.
  Ideal para cachear \"pacotes de idioma\".
  \"\"\"
  @spec get_strings_for_language(
          lang_id_or_code :: integer() | String.t(),
          opts :: keyword()
        ) :: {:ok, map()} | {:error, any()}
  def get_strings_for_language(lang_id_or_code, opts \\\\ []) do
    # opts pode conter:
    #   category_id: integer()
    #   category_name: String.t() (que pode ser um nome de módulo UNA, ex: 'bx_persons')

    # TODO: Cache (chave do cache: lang_id + category_id/name)
    with {:ok, lang_id} <- resolve_lang_id(lang_id_or_code) do
      base_sql = \"\"\"
      SELECT lk.\"Key\", ls.String
      FROM sys_localization_strings ls
      JOIN sys_localization_keys lk ON ls.IDKey = lk.ID
      \"\"\"
      join_category_sql = \" JOIN sys_localization_categories lc ON lk.IDCategory = lc.ID \"
      where_clauses = [\"ls.IDLanguage = ?\"]
      query_params = [lang_id]

      {final_where_clauses, final_query_params, final_joins} =
        cond do
          category_id = opts[:category_id] ->
            {where_clauses ++ [\"lk.IDCategory = ?\"], query_params ++ [category_id], join_category_sql}
          category_name = opts[:category_name] ->
            {where_clauses ++ [\"lc.Name = ?\"], query_params ++ [category_name], join_category_sql}
          true ->
            {where_clauses, query_params, \"\"} # Sem filtro de categoria, não precisa do JOIN com categories
        end

      where_sql = \"WHERE \" <> Enum.join(final_where_clauses, \" AND \")
      final_sql = base_sql <> final_joins <> where_sql <> \";\"

      case Repo.query(final_sql, final_query_params) do
        {:ok, %{rows: rows_data, columns: _columns}} ->
          # rows_data será uma lista de [key_string, translated_string]
          strings_map =
            Enum.into(rows_data, %{}, fn [key, translated_str] -> {key, translated_str} end)
          {:ok, strings_map}
        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason} # Erro ao resolver lang_id
    end
  end

  # --- Funções Auxiliares ---

  @doc \"Resolve um ID de idioma a partir de um código de idioma ou retorna o ID se já for um inteiro.\"
  defp resolve_lang_id(lang_id) when is_integer(lang_id), do: {:ok, lang_id}
  defp resolve_lang_id(lang_code) when is_binary(lang_code) do
    case get_language_by_code(lang_code) do
      {:ok, %{\"ID\" => id}} -> {:ok, id}
      {:ok, %{id: id}} -> {:ok, id} # Se map_row_to_generic_struct atomizar
      {:error, :not_found} -> {:error, :language_not_found}
      err -> err
    end
  end
  defp resolve_lang_id(_other), do: {:error, :invalid_language_identifier}


  # Função auxiliar de mapeamento (mesma do ACLRepo e OptionsRepo, pode ser movida para um helper comum)
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