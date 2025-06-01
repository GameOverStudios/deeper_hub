# Documentação Deeper: Módulo de Acesso a Dados para Menus (`MenuRepo`)

Este documento descreve o módulo Elixir `Deeper.PageEngine.MenuRepo`, responsável por interagir com as tabelas de menu (`sys_objects_menu`, `sys_menu_items`, `sys_menu_sets`, `sys_menu_templates`) no banco de dados SQLite. Sua principal função é buscar a estrutura hierárquica completa de um menu para a API.

**Localização do Código:** `lib/deeper/page_engine/menu_repo.ex`

```elixir
defmodule Deeper.PageEngine.MenuRepo do
  alias Deeper.Core.Data.Repo
  # Assumindo que existe um módulo para validação ACL
  # alias Deeper.SystemCore.ACLValidator

  @doc \"\"\"
  Busca a estrutura completa de um menu pelo seu nome de objeto (sys_objects_menu.object).
  Retorna um mapa com detalhes do menu e uma lista hierárquica de itens de menu visíveis.
  Precisa do `current_user_level_id` para filtrar itens por ACL.
  \"\"\"
  @spec get_menu_structure(menu_object_name :: String.t(), current_user_level_id :: integer() | nil) :: {:ok, map()} | {:error, :not_found | any()}
  def get_menu_structure(menu_object_name, current_user_level_id) do
    # TODO: Cache para estruturas de menu (chave: menu_object_name + user_level_id)
    case get_menu_object_details(menu_object_name) do
      {:ok, menu_object} ->
        set_name = Map.get(menu_object, \"set_name\") || Map.get(menu_object, :set_name)
        case get_menu_items_for_set(set_name, current_user_level_id) do
          {:ok, all_items} ->
            # Construir a hierarquia
            # Filtramos por active=1 e visible_for_levels na query,
            # mas a lógica de visibilidade customizada do UNA é complexa e não portada aqui.
            hierarchical_items = build_menu_hierarchy(all_items)

            menu_structure = %{
              menu_details: menu_object,
              items: hierarchical_items
            }
            {:ok, menu_structure}
          {:error, reason_items} -> {:error, reason_items}
        end
      {:error, :not_found} -> {:error, :menu_not_found}
      {:error, reason_menu} -> {:error, reason_menu}
    end
  end

  @doc \"Busca detalhes de um objeto de menu e seu template.\"
  def get_menu_object_details(menu_object_name) do
    sql = \"\"\"
    SELECT
      som.id, som.object, som.title, som.set_name, som.module, som.template_id,
      som.persistent, som.active,
      smt.template as template_file, smt.title as template_title
    FROM sys_objects_menu som
    JOIN sys_menu_templates smt ON som.template_id = smt.id
    WHERE som.object = ? AND som.active = 1;
    \"\"\"
    case Repo.query(sql, [menu_object_name]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca todos os itens ativos para um set_name, filtrados por ACL.\"
  def get_menu_items_for_set(set_name, current_user_level_id) do
    # A lógica de `visible_for_levels` é um bitmask.
    # Se current_user_level_id for nil (visitante), assumimos level_id = 1 (padrão UNA).
    # A query para `visible_for_levels` seria: `(visible_for_levels & (1 << (level_id - 1))) > 0`
    # ou se `visible_for_levels` for 2147483647 (todos os níveis).
    # Por simplicidade, a query abaixo não implementa o bitmask exato, mas deve ser feito.
    # Para um placeholder, vamos assumir que `visible_for_levels` contém um ID de nível mínimo ou uma flag \"todos\".
    # Uma implementação real usaria Bitwise operations.

    # Simplificação para o exemplo:
    # Se user_level_id é X, queremos `(smi.visible_for_levels & pow(2,X-1)) != 0 OR smi.visible_for_levels = 0x7FFFFFFF`
    # Esta query é complexa para SQL direto sem funções bitwise específicas do dialeto.
    # SQLite tem operadores bitwise (`&`, `|`, `<<`, `>>`).

    # O ID do nível do visitante geralmente é 1.
    # 2147483647 é 0x7FFFFFFF, todos os bits ligados para um inteiro de 31 bits (níveis 1 a 31).
    level_mask_check =
      if is_nil(current_user_level_id) or current_user_level_id < 1 do
        # Visitante (nível 1)
        \"(smi.visible_for_levels & 1 OR smi.visible_for_levels = 2147483647)\"
      else
        mask_value = Bitwise.bsl(1, current_user_level_id - 1)
        \"(smi.visible_for_levels & #{mask_value} OR smi.visible_for_levels = 2147483647)\"
      end

    sql = \"\"\"
    SELECT
      smi.id, smi.parent_id, smi.set_name, smi.module, smi.name, smi.title_system, smi.title,
      smi.link, smi.onclick, smi.target, smi.icon, smi.addon, smi.addon_cache, smi.markers,
      smi.submenu_object, smi.submenu_popup, smi.visible_for_levels, smi.hidden_on,
      smi.primary_item as \"primary\", smi.collapsed, smi.active, smi.\"order\"
      -- Omitido: visibility_custom, hidden_on_cxt, hidden_on_pt, hidden_on_col (complexidade UNA PHP)
    FROM sys_menu_items smi
    WHERE smi.set_name = ?
      AND smi.active = 1
      AND #{level_mask_check} -- Aplica a verificação de ACL
    ORDER BY smi.\"order\" ASC;
    \"\"\"
    case Repo.query(sql, [set_name]) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        items = Enum.map(rows_data, &map_row_to_generic_struct(&1, columns))
        {:ok, items}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # --- Construção da Hierarquia ---
  defp build_menu_hierarchy(flat_items_list, parent_id \\\\ 0) do
    flat_items_list
    |> Enum.filter(fn item -> (Map.get(item, \"parent_id\") || Map.get(item, :parent_id)) == parent_id end)
    |> Enum.map(fn item ->
      item_id = Map.get(item, \"id\") || Map.get(item, :id)
      children = build_menu_hierarchy(flat_items_list, item_id)
      if Enum.empty?(children) do
        item # Sem filhos
      else
        Map.put(item, :sub_items, children) # Adiciona :sub_items se houver filhos
      end
    end)
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