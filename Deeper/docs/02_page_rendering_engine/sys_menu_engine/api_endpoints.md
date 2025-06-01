# Documentação Deeper: Endpoints da API para Motor de Menus

Este documento especifica os endpoints da API RESTful \"Deeper\" para acessar dados de menus de navegação.

## Endpoint Principal

### 1. Obter Estrutura de um Menu Específico

*   **Endpoint:** `GET /api/v1/menus/{menu_object_name}`
*   **Propósito:** Retorna a estrutura completa e hierárquica de um objeto de menu específico, filtrada pelas permissões de visibilidade do usuário autenticado.
*   **Autenticação:** Opcional. Se autenticado, os itens do menu são filtrados com base no `visible_for_levels` e no `IDLevel` do usuário. Se não autenticado, apenas itens visíveis para o nível \"não membro\" (geralmente o bit menos significativo, ou um nível padrão para visitantes) são retornados.
*   **Parâmetros de URL:**
    *   `{menu_object_name}` (String, Obrigatório): O nome do objeto de menu (campo `object` da tabela `sys_objects_menu`), por exemplo, `sys_site_main_menu` ou `bx_persons_view_submenu`.
*   **Query Parameters:**
    *   `lang` (String, Opcional): Código do idioma (ex: `en`, `pt-BR`) para tradução dos títulos dos itens. Se não fornecido, usa o idioma padrão do sistema ou o idioma do usuário autenticado.
*   **Resposta de Sucesso (200 OK):**
    Um objeto JSON contendo informações sobre o menu e seus itens hierárquicos.

```json
    {
      \"menu_object\": {
        \"name\": \"sys_site_main_menu\",
        \"title\": \"Main Menu Site\", // Título resolvido (traduzido) do objeto de menu
        \"set_name\": \"sys_std_site\",
        \"template_id\": 1, // ID do template (informativo para o cliente, se relevante)
        \"template_path\": \"menu_main_site.html\" // Path do template (informativo)
      },
      \"items\": [
        {
          \"id\": 1,
          \"name\": \"home\",
          \"title\": \"Home\", // Título resolvido (traduzido) do item
          \"link\": \"/home\", // Link processado/final para o cliente
          \"icon\": \"home-outline\",
          \"target\": null,
          \"onclick\": null,
          \"addon\": null,
          \"submenu_object_name\": null, // Se este item tivesse um submenu direto
          \"sub_items\": [] // Array de objetos de item para submenus
        },
        {
          \"id\": 2,
          \"name\": \"browse\",
          \"title\": \"Browse\",
          \"link\": \"/browse\",
          \"icon\": \"grid-outline\",
          \"target\": null,
          \"onclick\": null,
          \"addon\": null,
          \"submenu_object_name\": \"sys_browse_submenu\",
          \"sub_items\": [ // Itens do submenu, se a API optar por aninhar diretamente
            {
              \"id\": 15,
              \"name\": \"profiles\",
              \"title\": \"Profiles\",
              \"link\": \"/browse/profiles\",
              \"icon\": \"people-outline\",
              // ... outros campos ...
              \"sub_items\": []
            }
            // ... mais sub-itens ...
          ]
        },
        {
          \"id\": 3,
          \"name\": \"account\",
          \"title\": \"My Account\",
          \"link\": null, // Item pai de um submenu que pode não ter link próprio
          \"icon\": \"person-circle-outline\",
          // ...
          \"submenu_object_name\": \"sys_account_popup_links\", // Ou os itens são listados diretamente em sub_items
          \"sub_items\": [
            {
              \"id\": 20,
              \"name\": \"dashboard\",
              \"title\": \"Dashboard\",
              \"link\": \"/account/dashboard\",
              // ...
              \"sub_items\": []
            },
            {
              \"id\": 21,
              \"name\": \"logout\",
              \"title\": \"Logout\",
              \"link\": \"/auth/logout\", // Pode ser um link especial ou uma ação para o cliente
              // ...
              \"sub_items\": []
            }
          ]
        }
        // ... mais itens de nível raiz ...
      ]
    }
```

*   **Respostas de Erro:**
    *   `401 Unauthorized`: Se o token JWT for inválido ou ausente e o menu requer autenticação para ser visualizado (embora a maioria dos menus principais tenha itens públicos).
    *   `404 Not Found`: Se o `{menu_object_name}` não existir ou não estiver ativo.
    *   `500 Internal Server Error`: Para erros inesperados no servidor.

#### Lógica do Controller da API para `GET /api/v1/menus/{menu_object_name}`:

1.  Extrair `{menu_object_name}` da URL.
2.  Obter o idioma solicitado (`lang` query param) ou o idioma do usuário/sistema.
3.  Obter o `IDLevel` do usuário autenticado (se houver). Se não autenticado, usar um `IDLevel` padrão para \"visitante\".
4.  Chamar `Deeper.PageEngine.MenuRepo.get_menu_object(menu_object_name)`:
    *   Se retornar `{:error, :not_found}`, responder com `404 Not Found`.
    *   Se retornar erro, responder com `500 Internal Server Error`.
5.  Com o `menu_object` obtido (que inclui `set_name`), chamar `Deeper.PageEngine.MenuRepo.get_menu_items_for_set(menu_object.set_name)`.
6.  Processar a lista plana de `menu_items`:
    *   **Resolver Títulos:** Para cada item, se `item.title_system` existir, usar `Deeper.SystemCore.LocalizationRepo.get_string(item.title_system, lang_code)` para obter o título traduzido. Se não, usar `item.title`.
    *   **Filtrar por Visibilidade:** Para cada item, verificar se o `IDLevel` do usuário tem permissão com base em `item.visible_for_levels`. Remover itens não permitidos. *Cuidado: se um item pai é removido, seus filhos também devem ser, ou a hierarquia pode quebrar.*
    *   **Resolver Links:** Os links na tabela `sys_menu_items` podem ser no formato do UNA (ex: `page.php?i=...`). Pode ser necessário um passo para traduzi-los para rotas da API \"Deeper\" ou rotas que o cliente entenda, ou simplesmente passá-los como estão se o cliente souber interpretá-los.
7.  Chamar `Deeper.PageEngine.MenuRepo.build_menu_hierarchy(processed_flat_items)` para obter a estrutura hierárquica.
8.  **Opcional: Aninhamento de `submenu_object`**:
    *   Decidir se a API irá buscar e aninhar automaticamente os itens de menus referenciados em `submenu_object_name`.
    *   Se sim: para cada item que tem `submenu_object_name`, repetir os passos 4-7 para aquele submenu e popular o campo `sub_items` correspondente. Adicionar proteção contra recursão infinita.
    *   Se não: o cliente será responsável por fazer uma nova chamada à API para `/api/v1/menus/{submenu_object_name}` quando necessário. (Esta é geralmente a abordagem mais simples e performática para a API).
9.  Construir a resposta JSON final com `menu_object` e a lista hierárquica de `items`.
10. Enviar a resposta.

## Outros Endpoints Potenciais (Menos Prioritários Inicialmente):

*   `GET /api/v1/menus`: Listar todos os objetos de menu disponíveis no sistema (útil para administração ou descoberta).
*   `GET /api/v1/menu-sets`: Listar todos os conjuntos de menu (`sys_menu_sets`).
*   `GET /api/v1/menu-sets/{set_name}/items`: Listar todos os itens para um `set_name` específico (sem a camada de `sys_objects_menu`).

Estes seriam mais para fins de depuração ou para uma interface de administração que precise manipular diretamente essas entidades. Para o cliente de front-end, o endpoint `GET /api/v1/menus/{menu_object_name}` é o mais crucial.