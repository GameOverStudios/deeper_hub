# Documentação Deeper: Módulo de Acesso a Dados para Páginas (`PageRepo`)

Este documento descreve o módulo Elixir `Deeper.PageEngine.PageRepo`, responsável por interagir com as tabelas do motor de páginas (`sys_objects_page`, `sys_pages_layouts`, `sys_pages_blocks`, `sys_pages_design_boxes`, `sys_pages_types`) no banco de dados SQLite. Sua principal função é buscar todos os componentes de uma página para que a API possa retornar uma definição completa para o cliente.

**Consideração Importante: Tratamento de Blocos de Serviço**
A lógica para lidar com blocos do tipo `service` é fundamental. Este `PageRepo` buscará a *definição* do serviço (módulo, método, parâmetros) do campo `sys_pages_blocks.content`. A execução da lógica *equivalente* a esse serviço em Elixir para obter os dados JSON que o serviço produziria pode residir:
1.  Dentro deste `PageRepo` (se a lógica for simples e puramente de busca de dados).
2.  Em módulos de \"serviço\" Elixir dedicados (ex: `Deeper.Services.ArticlesService.get_latest_articles/1`), que seriam chamados pelo `PageRepo` ou por uma camada superior.
3.  A API pode retornar apenas a definição do serviço, e o cliente faz chamadas subsequentes (menos ideal).

Para este documento, assumiremos que o `PageRepo` tentará orquestrar a busca dos dados para serviços comuns ou retornará a definição clara do serviço para o controller da API lidar.

**Localização do Código:** `lib/deeper/page_engine/page_repo.ex`

```elixir
defmodule Deeper.PageEngine.PageRepo do
  alias Deeper.Core.Data.Repo
  # Importar outros Repos se necessário para buscar dados de serviços
  # alias Deeper.Content.ArticlesRepo # Exemplo

  @doc \"\"\"
  Busca a estrutura completa de uma página pelo seu nome de objeto (ex: 'bx_persons_home').
  Retorna um mapa contendo detalhes da página, layout, e uma lista de blocos agrupados por célula.
  \"\"\"
  @spec get_page_structure(page_object_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_page_structure(page_object_name) do
    # TODO: Implementar cache para estruturas de página (chave: page_object_name)
    # O cache pode ser complexo devido aos dados dinâmicos de blocos de serviço.
    # Um cache TTL mais curto ou cache apenas dos metadados da página/blocos estáticos.

    # 1. Buscar dados do objeto da página
    case get_page_object_details(page_object_name) do
      {:ok, page_object} ->
        # 2. Buscar blocos para esta página
        case get_page_blocks(page_object_name) do
          {:ok, blocks_data} ->
            # 3. Processar blocos (especialmente os de serviço) e agrupar por célula
            processed_blocks = process_and_group_blocks(blocks_data, page_object)

            # 4. Buscar informações do layout (opcional, pode ser parte de page_object se já joinado)
            #    ou retornar apenas layout_id e deixar o cliente interpretar.
            #    Para este exemplo, vamos assumir que o cliente pode precisar de detalhes do layout.
            layout_details =
              case Map.get(page_object, \"layout_id\") || Map.get(page_object, :layout_id) do
                nil -> nil
                layout_id -> get_layout_details(layout_id) |> elem(1) # Pega o valor de {:ok, val}
              end

            page_structure = %{
              page: page_object,
              layout: layout_details, # Ou apenas page_object.layout_id e page_object.layout_template_name
              cells: processed_blocks # Mapa onde chave é cell_id e valor é lista de blocos
            }
            {:ok, page_structure}

          {:error, reason_blocks} -> {:error, reason_blocks}
        end
      {:error, :not_found} -> {:error, :page_not_found}
      {:error, reason_page} -> {:error, reason_page}
    end
  end

  @doc \"Busca detalhes de um objeto de página e seu tipo e layout associados.\"
  def get_page_object_details(page_object_name) do
    sql = \"\"\"
    SELECT
      sop.*,
      spt.title as page_type_title, spt.template as page_type_template,
      spl.name as layout_name, spl.icon as layout_icon, spl.title as layout_title,
      spl.template as layout_template, spl.cells_number as layout_cells_number
    FROM sys_objects_page sop
    JOIN sys_pages_types spt ON sop.type_id = spt.id
    JOIN sys_pages_layouts spl ON sop.layout_id = spl.id
    WHERE sop.object = ? AND sop.deletable >= 0 -- 'deletable >= 0' é uma condição comum no UNA para páginas ativas/não deletadas
    LIMIT 1;
    \"\"\"
    # No UNA, deletable=0 significa não deletável, deletable=1 significa deletável.
    # Se há um status \"deleted\", a query seria diferente. Assumindo deletable >= 0 é visível.
    case Repo.query(sql, [page_object_name]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca todos os blocos ativos para um determinado objeto de página, com detalhes do design box.\"
  def get_page_blocks(page_object_name) do
    sql = \"\"\"
    SELECT
      spb.*,
      spdb.title as design_box_title, spdb.template as design_box_template
    FROM sys_pages_blocks spb
    JOIN sys_pages_design_boxes spdb ON spb.designbox_id = spdb.id
    WHERE spb.object = ? AND spb.active = 1
    ORDER BY spb.cell_id ASC, spb.\"order\" ASC;
    \"\"\"
    case Repo.query(sql, [page_object_name]) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        blocks = Enum.map(rows_data, &map_row_to_generic_struct(&1, columns))
        {:ok, blocks}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca detalhes de um layout de página pelo ID.\"
  def get_layout_details(layout_id) do
    sql = \"SELECT * FROM sys_pages_layouts WHERE id = ? LIMIT 1\"
    case Repo.query(sql, [layout_id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :layout_not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end


  # --- Processamento de Blocos ---
  defp process_and_group_blocks(blocks_data, page_object_map) do
    Enum.map(blocks_data, &process_single_block(&1, page_object_map))
    |> Enum.group_by(fn block -> Map.get(block, \"cell_id\") || Map.get(block, :cell_id) end, fn block -> block end)
  end

  defp process_single_block(block_map, page_object_map) do
    block_type = Map.get(block_map, \"type\") || Map.get(block_map, :type)
    block_content_str = Map.get(block_map, \"content\") || Map.get(block_map, :content)

    # Adicionar ACL check para o bloco
    # visible = Deeper.SystemCore.ACLValidator.can_view_block?(current_user_level_id, block_map.\"visible_for_levels\")
    # if !visible, return %{block_map | visible: false, processed_content: nil}

    processed_content =
      case block_type do
        \"service\" ->
          parse_and_fetch_service_data(block_content_str, block_map, page_object_map)
        \"menu\" ->
          %{type: \"menu_object\", object_name: block_content_str} # Cliente busca o menu separadamente
        \"lang\" ->
          %{type: \"lang_key\", key: block_content_str} # Cliente resolve a tradução
        \"html\" ->
          %{type: \"html_content\", html: block_content_str}
        \"raw\" ->
          %{type: \"raw_content\", text: block_content_str}
        \"wiki\" ->
          # Se usando sys_pages_wiki_blocks, buscaria o conteúdo mais recente.
          # Por agora, assume que `block_map.\"text\"` ou `block_content_str` tem o conteúdo wiki.
          wiki_content = Map.get(block_map, \"text\") || Map.get(block_map, :text) || block_content_str
          %{type: \"wiki_content\", markdown: wiki_content} # Ou HTML se já processado
        # TODO: Lidar com outros tipos de bloco: 'image', 'rss', 'custom', 'creative', 'bento_grid'
        _other_type ->
          %{type: \"unknown_block_type\", definition: block_content_str}
      end

    # Retornar o mapa do bloco original com o conteúdo processado/definido
    # e remover/substituir o campo 'content' original se apropriado.
    block_map
    |> Map.put(\"processed_content\", processed_content)
    |> Map.drop([\"content\"]) # Opcional, para limpar a resposta
  end

  defp parse_and_fetch_service_data(service_call_str, block_map, page_object_map) do
    # No UNA, service_call_str é uma string PHP serializada (a:4:{s:6:\"module\";s:10:\"bx_persons\";...})
    # Precisamos de um parser para isso ou de uma convenção diferente para armazenar no DB Deeper.
    # Para este exemplo, vamos simular um parser simples e uma chamada de serviço.

    # TODO: Implementar um parser robusto para a string de serviço do UNA.
    # Exemplo de estrutura esperada após parse:
    # %{module: \"bx_persons\", method: \"service_latest_profiles\", params: [5], context_object_id: nil}
    # O context_object_id pode vir do page_object_map se a página for de um item específico.
    
    # Simulação:
    parsed_service_call = simulate_parse_php_serialized_service(service_call_str)

    # Com base em parsed_service_call.module e .method, chamar a lógica Elixir equivalente.
    # Esta é a parte mais complexa que requer mapear serviços PHP para funções Elixir.
    case {parsed_service_call[:module], parsed_service_call[:method]} do
      {\"bx_persons\", \"service_latest_profiles\"} ->
        # count = List.first(parsed_service_call[:params] || [5])
        # {:ok, profiles_data} = Deeper.Content.PersonsRepo.list_persons_data(%{limit: count, sort_by: :added_desc})
        # %{type: \"service_data\", service_name: \"latest_profiles\", data: profiles_data}
        %{type: \"service_definition\", service_name: \"latest_profiles\", definition: parsed_service_call, note: \"Data fetching not yet implemented for this service.\"} # Placeholder

      {\"bx_articles\", \"service_latest_entries\"} ->
        %{type: \"service_definition\", service_name: \"latest_articles\", definition: parsed_service_call, note: \"Data fetching not yet implemented for this service.\"}

      # Adicionar mais casos para outros serviços comuns...
      # Ex: formulário de login, bloco de busca, etc.

      _other_service ->
        %{type: \"service_definition\", service_name: \"unknown\", definition: parsed_service_call, original_string: service_call_str}
    end
  end

  # Função de simulação/placeholder
  defp simulate_parse_php_serialized_service(str) do
    # Esta é uma GRANDE simplificação. Não use em produção.
    # Um parser real para `serialize()` do PHP é necessário.
    # Exemplo: se str for \"module=bx_persons;method=service_latest_profiles;params=5\" (formato customizado)
    if String.contains?(str, \"bx_persons\") && String.contains?(str, \"service_latest_profiles\") do
      %{module: \"bx_persons\", method: \"service_latest_profiles\", params: [5]}
    else
      %{module: \"unknown\", method: \"unknown\", original_string: str}
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