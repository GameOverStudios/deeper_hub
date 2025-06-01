# Documentação Deeper: Módulo de Acesso a Dados para Motor de Menus (MenuRepo)

Este documento descreve o módulo Elixir `Deeper.PageEngine.MenuRepo` (nome sugerido), responsável por encapsular toda a lógica de acesso ao banco de dados (SQLite) para as funcionalidades do motor de menus.

Ele fornecerá funções para buscar definições de menus e seus itens, lidar com a hierarquia, e auxiliar na resolução de títulos e visibilidade.

## Módulo: `Deeper.PageEngine.MenuRepo`

### Responsabilidades:

*   Buscar um objeto de menu (`sys_objects_menu`) pelo seu nome.
*   Buscar todos os itens de menu (`sys_menu_items`) para um determinado `set_name`, ordenados corretamente.
*   Construir a estrutura hierárquica dos itens de menu (itens e seus subitens).
*   Auxiliar na resolução de títulos internacionalizados (embora a tradução final possa ocorrer no controller da API ou no cliente, este módulo pode buscar as chaves de linguagem).
*   Fornecer informações de visibilidade (`visible_for_levels`) para que a camada da API ou o cliente possam filtrar os itens.

### Funções Principais (Exemplos):

A seguir, exemplos de funções que este módulo poderia conter, com os SQLs diretos correspondentes.

**1. Buscar Objeto de Menu por Nome**

```elixir
defmodule Deeper.PageEngine.MenuRepo do
  alias Deeper.Core.Data.Repo # Seu módulo de acesso ao DB

  @doc \"\"\"
  Busca a definição de um objeto de menu pelo seu nome (identificador 'object').
  Faz JOIN com sys_menu_sets e sys_menu_templates para obter informações completas.
  \"\"\"
  @spec get_menu_object(String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_menu_object(object_name) do
    sql = \"\"\"
    SELECT
      om.id AS object_id,
      om.object,
      om.title AS object_title,
      om.module AS object_module,
      om.active AS object_active,
      om.set_name,
      ms.title AS set_title,
      ms.module AS set_module,
      om.template_id,
      mt.template AS template_path,
      mt.title AS template_title
    FROM sys_objects_menu AS om
    JOIN sys_menu_sets AS ms ON om.set_name = ms.set_name
    JOIN sys_menu_templates AS mt ON om.template_id = mt.id
    WHERE om.object = ? AND om.active = 1
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [object_name]) do
      {:ok, %{rows: [row_map]}} -> {:ok, row_map} # Assumindo que Repo.query retorna mapas
      {:ok, %{rows: []}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end
```

```elixir
  @doc \"\"\"
  Busca todos os itens de menu ativos para um determinado set_name,
  ordenados por `parent_id` e depois por `order`.
  Retorna uma lista de mapas, cada um representando um item de menu.
  \"\"\"
  @spec get_menu_items_for_set(String.t()) :: {:ok, [map()]} | {:error, any()}
  def get_menu_items_for_set(set_name) do
    sql = \"\"\"
    SELECT
      id,
      parent_id,
      module,
      name,
      title_system,
      title,
      link,
      onclick,
      target,
      icon,
      addon,
      submenu_object,
      submenu_popup,
      visible_for_levels,
      hidden_on,
      \"order\"
    FROM sys_menu_items
    WHERE set_name = ? AND active = 1
    ORDER BY parent_id ASC, \"order\" ASC;
    \"\"\"
    case Repo.query(sql, [set_name]) do
      {:ok, %{rows: items_list}} -> {:ok, items_list} # items_list é uma lista de mapas
      {:error, reason} -> {:error, reason}
    end
  end
```

```elixir
  @doc \"\"\"
  Organiza uma lista plana de itens de menu (obtida de get_menu_items_for_set/1)
  em uma estrutura hierárquica (árvore).
  Cada item pode ter uma chave `:sub_items` contendo seus filhos.
  \"\"\"
  @spec build_menu_hierarchy([map()]) :: [map()]
  def build_menu_hierarchy(flat_items) do
    # Agrupa itens por parent_id
    items_by_parent =
      Enum.group_by(flat_items, fn item -> item.parent_id end, fn item -> item end)

    # Função recursiva para construir a árvore
    do_build_tree = fn parent_id, fun ->
      case Map.get(items_by_parent, parent_id) do
        nil ->
          [] # Sem filhos
        children ->
          Enum.map(children, fn child ->
            Map.put(child, :sub_items, fun.(child.id, fun)) # Chamada recursiva
          end)
      end
    end

    # Começa a construir a árvore a partir dos itens de nível raiz (parent_id == 0)
    do_build_tree.(0, do_build_tree)
  end

  # Exemplo de como seria chamado externamente (pelo controller da API, por exemplo):
  # with {:ok, menu_object} <- get_menu_object(\"sys_site_main_menu\"),
  #      {:ok, flat_items} <- get_menu_items_for_set(menu_object.set_name) do
  #   hierarchical_items = build_menu_hierarchy(flat_items)
  #   {:ok, %{object: menu_object, items: hierarchical_items}}
  # else
  #   error -> error
  # end
```

```elixir
%{
  id: 10,
  parent_id: 0,
  module: \"bx_persons\",
  name: \"view_profiles\",
  title_system: \"_bx_persons_menu_item_view_all\", # Chave de linguagem
  title: \"Browse Profiles\", # Fallback ou título direto
  link: \"page.php?i=bx_persons-home\", # O cliente precisará traduzir para rotas do lado dele
  onclick: nil,
  target: nil,
  icon: \"user\",
  addon: nil,
  submenu_object: nil, # Ou \"bx_persons_submenu_filter\"
  submenu_popup: 0,
  visible_for_levels: 2147483647, # Bitmask
  hidden_on: \"xs\",
  order: 1,
  sub_items: [] # Lista de mapas de sub-itens, preenchida por build_menu_hierarchy
}
```

*   **SQL:** Seleciona dados de `sys_objects_menu` e faz `JOIN` com `sys_menu_sets` e `sys_menu_templates`.
*   **Retorno:** Um mapa contendo os detalhes do objeto de menu ou `{:error, :not_found}`.

**2. Buscar Itens de Menu para um `set_name`**

*   **SQL:** Seleciona todos os campos relevantes de `sys_menu_items` para um `set_name` e onde `active = 1`.
*   **Ordenação:** `ORDER BY parent_id ASC, \"order\" ASC` é crucial para facilitar a construção da hierarquia posteriormente.
*   **Retorno:** Uma lista de mapas, onde cada mapa representa um item de menu.

**3. Construir Hierarquia de Menu (Lógica Elixir)**

Esta função não executa SQL diretamente, mas processa a lista de itens obtida por `get_menu_items_for_set/1`.

*   **Lógica:** Usa `Enum.group_by` para agrupar itens por `parent_id` e depois uma função recursiva para montar a árvore.
*   **Retorno:** Uma lista de itens de menu de nível raiz, onde cada item pode conter uma chave `:sub_items` com seus filhos.

**4. Considerações Adicionais:**

*   **Resolução de Títulos (`title_system`, `title`):**
    *   Se `title_system` for preenchido, ele geralmente é uma chave de linguagem (ex: `_sys_menu_item_title_home`).
    *   Este `MenuRepo` pode buscar o `title_system`. O `LocalizationRepo` (a ser definido) seria então usado pelo controller da API para obter a string traduzida para o idioma do usuário antes de enviar a resposta JSON.
    *   Alternativamente, a API pode enviar `title_system` e `title` para o cliente, e o cliente lida com a priorização e tradução se `title_system` for uma chave.
*   **Filtragem por `visible_for_levels`:**
    *   A função `get_menu_items_for_set/1` busca todos os itens ativos.
    *   A filtragem baseada no `visible_for_levels` do usuário autenticado (e seu `IDLevel` de ACL) deve ser feita *após* buscar os dados, preferencialmente na camada da API (controller) ou na função que chama `build_menu_hierarchy`.
    *   Isso envolve obter o `IDLevel` do usuário (do JWT), e para cada item de menu, verificar se o bit correspondente ao `IDLevel` do usuário está setado na máscara `visible_for_levels` do item. Itens não visíveis (e seus submenus) seriam removidos da árvore final.
*   **Processamento de `addon` e `submenu_object`:**
    *   **`submenu_object`**: Se um item tem um `submenu_object` preenchido, a API pode, opcionalmente, fazer uma chamada recursiva para `get_menu_object` e `get_menu_items_for_set` para buscar e aninhar os dados desse submenu. Isso deve ser tratado com cuidado para evitar loops e complexidade excessiva na resposta da API. Uma abordagem mais simples é o cliente fazer uma nova requisição para o `submenu_object` quando o item pai é clicado.
    *   **`addon`**: Se o `addon` for dinâmico (ex: uma contagem de notificações que vem de outra parte do sistema), este `MenuRepo` não seria responsável por resolvê-lo. A API ou o cliente teriam que buscar essa informação separadamente e injetá-la. Se for um texto estático ou HTML simples, ele pode ser retornado como está.

### Estrutura de Dados para Itens de Menu (Exemplo de Mapa Elixir):

Este módulo `MenuRepo` fornecerá os blocos de construção de dados para que a camada da API (controllers Phoenix) possa buscar, processar e formatar os dados do menu para serem consumidos pelo cliente. A otimização das queries SQL e a lógica de construção da hierarquia são pontos chave aqui.