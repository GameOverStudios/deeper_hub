# Documentação Deeper: Módulo de Acesso a Dados para Menus (`MenusRepo`)

Este documento descreve o módulo Elixir `Deeper.PageEngine.MenusRepo` (ou um nome similar), responsável por encapsular a lógica de consulta às tabelas que definem os menus do sistema UNA (`sys_objects_menu`, `sys_menu_sets`, `sys_menu_items`).

O objetivo principal deste Repo é fornecer os dados estruturados de um menu e seus itens para que a API \"Deeper\" possa expô-los de forma que um cliente possa reconstruir a navegação.

**Localização do Código:** `lib/deeper/page_engine/menus_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Estrutura de um Menu por Nome de Objeto

*   **`get_menu_structure(menu_object_name :: String.t(), user_level_id :: integer() | nil, context_params :: map() | nil) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a definição de um objeto de menu e todos os seus itens visíveis e ativos, estruturados hierarquicamente.
    *   **Argumentos:**
        *   `menu_object_name`: O nome do objeto de menu (de `sys_objects_menu.object`).
        *   `user_level_id`: (Opcional) O `IDLevel` do ACL do usuário atual. Se `nil`, considera o nível de visitante/público. Usado para filtrar itens por `visible_for_levels`.
        *   `context_params`: (Opcional) Um mapa com parâmetros de contexto (ex: `%{current_uri: \"/path\", device: \"mobile\"}`) que podem ser usados para avaliar `hidden_on`, `hidden_on_cxt`, etc. A lógica exata para `hidden_on*` pode ser complexa de replicar e pode ser simplificada inicialmente.
    *   **Retorno:**
        *   `{:ok, menu_data_map}`: Um mapa contendo os dados do objeto de menu e uma lista hierárquica de seus itens. Exemplo:

```sql
                SELECT
                    id, parent_id, name, title_system, title, link, onclick, target, icon, addon,
                    submenu_object, submenu_popup, visible_for_levels, visibility_custom,
                    hidden_on, hidden_on_cxt, hidden_on_pt, hidden_on_col, primary_item,
                    collapsed, active, active_api, \"order\"
                FROM sys_menu_items
                WHERE set_name = ? AND active = 1 -- AND active_api = 1 (se filtrar para API)
                ORDER BY parent_id, \"order\";
```

```elixir
            %{
              object: \"bx_persons_main_menu\",
              title: \"Menu Principal de Pessoas\",
              set_name: \"bx_persons_main\",
              template_id: 1, // Ou o nome do template
              // ... outros campos de sys_objects_menu ...
              items: [
                %{
                  id: 10,
                  name: \"home\",
                  title: \"Início\", // Já traduzido ou a chave de linguagem
                  link: \"/m/persons/home\",
                  icon: \"bx-home\",
                  parent_id: 0,
                  order: 1,
                  submenu_object: nil, // Ou \"bx_persons_submenu_browse\"
                  active: true,
                  // ... outros campos de sys_menu_items ...
                  sub_items: [ // Se houver subitens diretos (parent_id)
                    %{ id: 15, name: \"sub_action\", title: \"Sub Ação\", ... sub_items: [] }
                  ]
                },
                // ... outros itens de nível superior ...
              ]
            }
```

        *   `{:error, :not_found}`: Objeto de menu não encontrado ou inativo.
        *   `{:error, reason}`: Outro erro de banco de dados.
    *   **Lógica Interna Detalhada:**
        1.  **Buscar `sys_objects_menu`:**
            *   SQL: `SELECT id, object, title, set_name, module, template_id, active FROM sys_objects_menu WHERE object = ? AND active = 1 LIMIT 1;`
            *   Parâmetro: `menu_object_name`.
            *   Se não encontrar ou não estiver ativo, retorna `{:error, :not_found}`.
        2.  **Buscar todos os Itens de Menu para o `set_name`:**
            *   SQL:

            *   Parâmetro: `set_name` do objeto de menu.
        3.  **Filtrar Itens por Visibilidade (ACL e Contexto):**
            *   Iterar sobre os itens obtidos.
            *   Para cada item, verificar `visible_for_levels` contra `user_level_id`.
                *   Lógica de Bitmask: `item.visible_for_levels == 0 OR item.visible_for_levels == 2147483647 OR (item.visible_for_levels && (1 <<< (user_level_id - 1))) != 0`. (O UNA tem uma lógica específica para `2147483647` como \"todos os membros\").
            *   (Avançado/Opcional) Avaliar `hidden_on`, `hidden_on_cxt`, `hidden_on_pt`, `hidden_on_col` contra `context_params`. Esta lógica pode ser complexa de replicar fielmente. Inicialmente, pode-se focar apenas em `visible_for_levels`.
            *   (Avançado/Opcional) Avaliar `visibility_custom` (que no UNA é uma service call PHP). Para a API \"Deeper\", isso exigiria um mapeamento para uma lógica Elixir ou uma chamada a um microsserviço se essa lógica for mantida em PHP. Inicialmente, pode ser ignorado ou assumido como visível se não houver regra ACL.
            *   Descartar itens não visíveis.
        4.  **Traduzir Títulos (se `title_system` for usado como chave):**
            *   Para cada item visível, se `item.title_system` for uma chave de linguagem (ex: `_bx_persons_menu_home`), chamar `LocalizationRepo.get_string_for_key_and_language(item.title_system, current_language_code)` para obter o `title` traduzido. Se `item.title` já contiver o texto final, este passo não é necessário.
        5.  **Construir a Estrutura Hierárquica:**
            *   Processar a lista de itens filtrados e traduzidos para construir a árvore (itens com `parent_id = 0` no nível superior, e seus filhos recursivamente).
            *   Cada item no mapa de retorno deve ter uma chave `sub_items: []` que será populada.
        6.  Combinar os dados do objeto de menu (passo 1) com a lista hierárquica de itens (passo 5).

### 2. Listar Objetos de Menu Disponíveis (Opcional)

*   **`list_menu_objects(filter_opts :: map() | nil) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista todos os \"objetos de menu\" definidos.
    *   `filter_opts` pode incluir `module`, `active`.
    *   **SQL:** `SELECT id, object, title, set_name, module, template_id, active FROM sys_objects_menu WHERE active = 1 ORDER BY title;`
    *   Retorna: `{:ok, [%{object: \"bx_persons_main_menu\", title: \"...\", ...}, ...]}`

### 3. Listar Conjuntos de Menu Disponíveis (Opcional)

*   **`list_menu_sets(filter_opts :: map() | nil) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista todos os \"conjuntos de menu\".
    *   **SQL:** `SELECT set_name, module, title, deletable FROM sys_menu_sets ORDER BY title;`

### Funções Auxiliares (Internas):

*   `build_menu_tree(flat_list_of_items :: list(map()), parent_id :: integer()) :: list(map())`
    *   Função recursiva para transformar a lista plana de itens de menu em uma estrutura de árvore.

### Considerações:

*   **Tradução de Títulos:** A responsabilidade pela tradução (usar `title` diretamente ou `title_system` + `LocalizationRepo`) precisa ser clara. Se `title_system` for a chave, o idioma atual do usuário é necessário.
*   **`addon` e `markers`:** Estes campos podem conter HTML ou chaves de linguagem no UNA. A API \"Deeper\" pode retorná-los como estão, e o cliente decide como renderizá-los. Para `addon` que representa contadores (ex: notificações), o UNA PHP frequentemente usa uma service call para obter o valor dinamicamente. A API \"Deeper\" pode:
    *   Retornar a *definição* da service call (similar aos blocos de página).
    *   Omitir addons dinâmicos inicialmente.
    *   Ter endpoints específicos para buscar esses contadores (ex: `GET /api/v1/notifications/count`).
*   **`submenu_object`:** Se um item de menu aponta para outro `submenu_object`, a API deve retornar o nome desse objeto. O cliente então decide se e quando buscar a estrutura desse submenu com uma nova chamada à API (ex: `GET /api/v1/menus/{submenu_object_name}`).
*   **Performance:** Para menus grandes ou com muita lógica de visibilidade, a performance da construção da árvore e filtragem é importante. As queries SQL devem ser otimizadas com índices em `set_name`, `parent_id`, `order`.
*   **Caching:** Estruturas de menu, especialmente para usuários não autenticados ou para menus comuns, são excelentes candidatas para caching. O cache precisaria ser invalidado por `(menu_object_name, user_level_id)` se a visibilidade for dinâmica.