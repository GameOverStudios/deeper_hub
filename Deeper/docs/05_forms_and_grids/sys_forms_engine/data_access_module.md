# Documentação Deeper: Módulo de Acesso a Dados para Formulários (`FormRepo`)

Este documento descreve o módulo Elixir `Deeper.FormsEngine.FormRepo`, responsável por interagir com as tabelas do motor de formulários (`sys_objects_form`, `sys_form_inputs`, `sys_form_displays`, `sys_form_display_inputs`, `sys_form_pre_lists`, `sys_form_pre_values`) no banco de dados SQLite. Sua principal função é buscar a definição completa de um formulário, incluindo seus campos, atributos e opções de valores pré-definidos, para que a API possa retornar essa estrutura ao cliente.

**Localização do Código:** `lib/deeper/forms_engine/form_repo.ex`

```elixir
defmodule Deeper.FormsEngine.FormRepo do
  alias Deeper.Core.Data.Repo
  # alias Deeper.SystemCore.ACLValidator # Para verificar visible_for_levels dos campos
  # alias Deeper.SystemCore.LocalizationRepo # Para traduzir legendas, infos, etc.

  @doc \"\"\"
  Busca a definição completa de um formulário e seus campos para um display específico.
  Aplica filtros ACL para visibilidade de campos.
  Traduz legendas e outras strings de UI (opcional, pode ser feito na camada da API).
  \"\"\"
  @spec get_form_definition(
          form_object_name :: String.t(),
          display_name :: String.t(), # Ex: 'bx_persons_add', 'bx_persons_edit_profile'
          current_user_level_id :: integer() | nil,
          lang_id :: integer() | nil # Para traduções
        ) :: {:ok, map()} | {:error, :not_found | any()}
  def get_form_definition(form_object_name, display_name, current_user_level_id, lang_id \\\\ nil) do
    # 1. Buscar detalhes do objeto do formulário
    case get_form_object_details(form_object_name) do
      {:ok, form_object_map} ->
        # 2. Buscar detalhes do display específico
        case get_form_display_details(form_object_name, display_name) do
          {:ok, _form_display_map} -> # _form_display_map pode ser usado para título do display, etc.
            # 3. Buscar os inputs definidos para este display, ordenados e filtrados por ACL
            case get_display_inputs_with_details(form_object_name, display_name, current_user_level_id, lang_id) do
              {:ok, inputs_list} ->
                # 4. Enriquecer inputs com valores de pre_lists, se aplicável
                enriched_inputs = Enum.map(inputs_list, &enrich_input_with_pre_values(&1, lang_id))

                form_definition = %{
                  form_attributes: parse_form_attrs(form_object_map[\"form_attrs\"]),
                  action_target: form_object_map[\"action\"], # Endpoint da API Deeper para submissão
                  submit_name: form_object_map[\"submit_name\"], // Pode ser uma lkey para tradução
                  // title: _form_display_map[\"title\"], // Título do display, traduzido
                  fields: enriched_inputs
                }
                {:ok, form_definition}
              {:error, reason_inputs} -> {:error, reason_inputs}
            end
          {:error, :display_not_found} -> {:error, :form_display_not_found}
          {:error, reason_display} -> {:error, reason_display}
        end
      {:error, :not_found} -> {:error, :form_object_not_found}
      {:error, reason_form} -> {:error, reason_form}
    end
  end

  @doc \"Busca detalhes de um sys_objects_form.\"
  def get_form_object_details(form_object_name) do
    sql = \"SELECT * FROM sys_objects_form WHERE object = ? AND active = 1 LIMIT 1\"
    case Repo.query(sql, [form_object_name]) do
      {:ok, %{rows: [row_data], columns: cols}} -> {:ok, map_row_to_generic_struct(row_data, cols)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"Busca detalhes de um sys_form_displays.\"
  def get_form_display_details(form_object_name, display_name) do
    sql = \"SELECT * FROM sys_form_displays WHERE object = ? AND display_name = ? LIMIT 1\"
    case Repo.query(sql, [form_object_name, display_name]) do
      {:ok, %{rows: [row_data], columns: cols}} -> {:ok, map_row_to_generic_struct(row_data, cols)}
      {:ok, %{rows: []}} -> {:error, :display_not_found}
      err -> err
    end
  end

  @doc \"\"\"
  Busca os campos (sys_form_inputs) para um display específico,
  ordenados e já filtrados por ACL (visible_for_levels).
  \"\"\"
  def get_display_inputs_with_details(form_object_name, display_name, current_user_level_id, _lang_id) do
    # Lógica ACL para visible_for_levels (bitmask)
    # Se current_user_level_id é nil, assume nível de visitante (ex: 1)
    level_id_for_acl = current_user_level_id || 1
    # (1 << (level_id_for_acl - 1))
    level_mask_value = Bitwise.bsl(1, level_id_for_acl - 1)

    sql = \"\"\"
    SELECT
      sfi.* -- Todos os campos de sys_form_inputs
      -- sfdi.visible_for_levels AS display_input_visibility -- Já aplicado no WHERE
    FROM sys_form_display_inputs sfdi
    JOIN sys_form_inputs sfi ON sfdi.input_name = sfi.name AND sfi.object = ?
    WHERE sfdi.display_name = ?
      AND sfi.object = ? -- Garante que o input_name é do mesmo form_object
      AND sfdi.active = 1
      AND ( (sfdi.visible_for_levels & ?) > 0 OR sfdi.visible_for_levels = 2147483647 )
    ORDER BY sfdi.\"order\" ASC;
    \"\"\"
    params = [form_object_name, display_name, form_object_name, level_mask_value]

    case Repo.query(sql, params) do
      {:ok, %{rows: rows_data, columns: cols}} ->
        inputs = Enum.map(rows_data, fn row ->
          input_map = map_row_to_generic_struct(row, cols)
          # TODO: Traduzir caption, info, help, checker_error usando lang_id e LocalizationRepo
          # Ex: input_map |> Map.put(\"caption\", LocalizationRepo.get_string(input_map[\"caption\"], lang_id))
          # Por agora, retornamos as chaves de tradução.
          input_map
          |> Map.put(\"is_required\", (input_map[\"required\"] || 0) == 1) # Converte para booleano
          |> Map.put(\"is_unique\", (input_map[\"unique_input\"] || 0) == 1)
          |> Map.drop([\"required\", \"unique_input\"]) # Remove campos originais se convertidos
        end)
        {:ok, inputs}
      err -> err
    end
  end

  @doc \"Busca valores de uma lista pré-definida (sys_form_pre_values).\"
  def get_pre_list_values(list_key_name, lang_id \\\\ nil) do
    # TODO: Cache para pre_lists
    sql = \"\"\"
    SELECT value, lkey, lkey2, data
    FROM sys_form_pre_values
    WHERE list_key_name = ?
    ORDER BY \"order\" ASC;
    \"\"\"
    case Repo.query(sql, [list_key_name]) do
      {:ok, %{rows: rows_data, columns: cols}} ->
        values = Enum.map(rows_data, fn row ->
          value_map = map_row_to_generic_struct(row, cols)
          # TODO: Traduzir lkey, lkey2 usando lang_id e LocalizationRepo
          # Ex: %{value: value_map[\"value\"], label: LocalizationRepo.get_string(value_map[\"lkey\"], lang_id)}
          # Por agora, retornamos a chave de tradução como label.
          %{
            value: value_map[\"value\"],
            label: value_map[\"lkey\"], # Chave de tradução
            label2: value_map[\"lkey2\"], # Chave de tradução
            data: parse_json_string(value_map[\"data\"]) # Se 'data' for JSON
          }
        end)
        {:ok, values}
      err -> err
    end
  end

  # --- Funções Auxiliares ---

  defp enrich_input_with_pre_values(input_map, lang_id) do
    values_list_key = Map.get(input_map, \"values_list\") || Map.get(input_map, :values_list)
    input_type = Map.get(input_map, \"type\") || Map.get(input_map, :type)

    # Tipos que usam listas de valores
    list_types = [\"select\", \"select_multiple\", \"radio\", \"checkbox_set\"]

    if values_list_key && Enum.member?(list_types, input_type) do
      options =
        cond do
          # Se values_list começa com '#', é uma lista embutida (ex: #!val1=Label1\\nval2=Label2)
          String.starts_with?(values_list_key, \"#!\") ->
            parse_embedded_values_list(String.trim_leading(values_list_key, \"#!\"))
          # Senão, é uma chave para sys_form_pre_lists
          true ->
            case get_pre_list_values(values_list_key, lang_id) do
              {:ok, pre_values} -> pre_values
              _ -> []
            end
        end
      Map.put(input_map, \"options\", options)
    else
      input_map # Sem alterações
    end
  end

  defp parse_embedded_values_list(list_string) do
    # Exemplo: \"val1=Label1\\nval2=Label2\" ou \"Val1\\nVal2\"
    list_string
    |> String.split(\"\\n\", trim: true)
    |> Enum.map(fn item_str ->
      case String.split(item_str, \"=\", parts: 2) do
        [value_key, label_key] -> %{value: String.trim(value_key), label: String.trim(label_key)} # Assumindo que label é a própria string
        [value_key_as_label] -> %{value: String.trim(value_key_as_label), label: String.trim(value_key_as_label)}
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_form_attrs(attrs_string) do
    # Atributos de formulário podem ser JSON ou uma string serializada de outra forma.
    # Se for JSON:
    # Jason.decode(attrs_string || \"{}\") |> elem(1)
    # Por agora, retornamos a string bruta, o cliente pode precisar parsear.
    attrs_string
  end

  defp parse_json_string(json_string) do
    if json_string && String.length(json_string) > 0 do
      case Jason.decode(json_string) do
        {:ok, map} -> map
        _ -> json_string # Retorna string original se não for JSON válido
      end
    else
      nil
    end
  end

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