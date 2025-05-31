# Documentação Deeper: Módulo de Acesso a Dados para Permalinks (`PermalinksRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.PermalinksRepo`, responsável por interagir com a tabela `sys_permalinks` no banco de dados SQLite. Sua principal função será resolver permalinks para URLs padrão (ou os parâmetros contidos nelas) e vice-versa.

**Localização do Código:** `lib/deeper/system_core/permalinks_repo.ex`

```elixir
defmodule Deeper.SystemCore.PermalinksRepo do
  alias Deeper.Core.Data.Repo

  @doc \"\"\"
  Busca a URL padrão do UNA associada a um permalink (URL amigável).
  Pode também retornar o ID do permalink e a coluna 'check'.
  \"\"\"
  @spec get_standard_url_from_permalink(permalink_uri :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_standard_url_from_permalink(permalink_uri) do
    # TODO: Cache (permalinks raramente mudam)
    # Pode ser necessário lidar com 'compare_by_prefix' se as buscas não forem exatas.
    # Para uma API, uma busca exata no permalink é mais provável.
    sql = \"SELECT id, standard, \\\"check\\\", compare_by_prefix FROM sys_permalinks WHERE permalink = ? LIMIT 1\"
    case Repo.query(sql, [permalink_uri]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Busca o permalink (URL amigável) associado a uma URL padrão do UNA.
  \"\"\"
  @spec get_permalink_from_standard_url(standard_uri :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_permalink_from_standard_url(standard_uri) do
    # TODO: Cache
    sql = \"SELECT id, permalink, \\\"check\\\" FROM sys_permalinks WHERE standard = ? LIMIT 1\"
    case Repo.query(sql, [standard_uri]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Extrai o parâmetro principal (ex: nome do objeto de página) da URL 'standard' do UNA.
  Ex: 'page.php?i=bx_persons_home' -> 'bx_persons_home'
  Ex: 'm/photos/view_entry/123' (se este fosse um 'standard') -> '123' (depende do formato)
  Esta função precisará de uma lógica de parsing robusta.
  \"\"\"
  @spec extract_param_from_standard_url(standard_uri :: String.t()) :: {:ok, String.t()} | {:error, :parse_error}
  def extract_param_from_standard_url(standard_uri) do
    # Exemplo simples para 'page.php?i=OBJECT_NAME'
    # URI.decode_query(URI.parse(standard_uri).query || \"\") |> Map.get(\"i\")
    try do
      query_params = standard_uri |> URI.parse() |> Map.get(:query) |> URI.decode_query()
      case Map.get(query_params, \"i\") do # Parâmetro 'i' é comum no UNA para objeto de página
        nil ->
          # Tentar outros padrões comuns do UNA se 'i' não estiver presente
          # Ex: pode haver permalinks para visualização de entry onde o 'standard' é diferente.
          # Esta lógica precisa ser baseada nos formatos de 'standard' URLs que você espera resolver.
          # Por exemplo, para 'm/module/action/param':
          parts = String.split(standard_uri, \"/\", trim: true)
          # Uma lógica mais específica seria necessária aqui.
          # Exemplo: se o padrão for \"m/nome_modulo/view_entry/ID_ENTRADA\"
          # e você só quer o ID_ENTRADA, você precisaria de um regex ou split mais inteligente.
          # Se for para identificar o 'object_name' de uma página:
          if String.starts_with?(standard_uri, \"page.php?i=\") do
             {:ok, String.trim_leading(standard_uri, \"page.php?i=\")}
          else
             # Adicionar mais lógicas de parsing aqui conforme necessário
             {:error, :unknown_standard_format}
          end
        object_name -> {:ok, object_name}
      end
    rescue
      _e -> {:error, :parse_error} # Erro ao parsear a URI
    end
  end

  # Função auxiliar de mapeamento (pode ser movida para um helper comum)
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