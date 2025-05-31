# Documentação Deeper: Endpoints da API para Motor de Menus

Este documento especifica os endpoints RESTful da API \"Deeper\" para obter a estrutura e os itens dos menus definidos no sistema.

## Convenções Gerais:

*   **Base URL:** `/api/v1`
*   **Autenticação:** Os endpoints de leitura de menu são geralmente públicos, mas os itens de menu retornados serão filtrados com base no nível de ACL do usuário autenticado (se um token JWT for fornecido).
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme definido em `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Obter Estrutura de um Menu Específico

*   **Endpoint:** `GET /menus/{menu_object_name}`
*   **Status:** Público (com filtragem de itens baseada em ACL se autenticado)
*   **Descrição:** Retorna a estrutura hierárquica de um menu específico, incluindo seus itens visíveis e ativos para o usuário.
*   **Parâmetros de URL:**
    *   `{menu_object_name}`: O nome do \"objeto de menu\" (de `sys_objects_menu.object`, ex: `bx_persons_main_menu`, `sys_account_notifications`).
*   **Query Parameters (Opcionais):**
    *   `context_uri=<current_page_uri>`: A URI da página atual pode ser usada para destacar o item de menu ativo.
    *   `device_type=mobile|desktop`: Pode influenciar a visibilidade de itens baseada em `hidden_on`.
    *   `language=<lang_code>`: (Opcional) Para solicitar títulos de menu em um idioma específico, se `title_system` for usado como chave de tradução. Se omitido, usa o idioma padrão do usuário ou do sistema.
*   **Cabeçalhos da Requisição (Opcional):**
    *   `Authorization: Bearer <jwt_token>`: Se fornecido, o backend usará o `IDLevel` do token para filtrar itens de menu por `visible_for_levels`.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"object\": \"bx_persons_main_menu\",
        \"title\": \"Menu Principal de Pessoas\", // sys_objects_menu.title
        \"set_name\": \"bx_persons_main\",
        // ... outros metadados do sys_objects_menu ...
        \"items\": [
          {
            \"id\": 10,
            \"name\": \"home\",
            \"title\": \"Início\", // Título final (traduzido se aplicável)
            \"link\": \"/m/persons/home\",
            \"icon\": \"bx-home\",
            \"target\": null,
            \"onclick\": null,
            \"addon\": null, // Ou a definição do addon se for uma service call
            \"markers\": null,
            \"submenu_object\": \"bx_persons_submenu_browse\", // Nome do objeto de submenu, se houver
            \"is_active_item\": true, // Se este item corresponde ao context_uri
            \"primary_item\": false,
            \"collapsed\": false,
            \"sub_items\": [] // Lista de sub-itens diretos (se `parent_id` usado)
                           // Se submenu_object presente, o cliente busca este submenu separadamente
          },
          {
            \"id\": 12,
            \"name\": \"friends\",
            \"title\": \"Amigos\",
            \"link\": \"/m/persons/friends\",
            \"icon\": \"bx-group\",
            \"submenu_object\": null,
            \"is_active_item\": false,
            \"primary_item\": true,
            \"collapsed\": false,
            \"sub_items\": [
              {
                \"id\": 15,
                \"name\": \"friend_requests\",
                \"title\": \"Solicitações de Amizade\",
                \"link\": \"/m/persons/friend_requests\",
                \"icon\": \"bx-user-plus\",
                \"is_active_item\": false,
                \"primary_item\": false,
                \"collapsed\": false,
                \"sub_items\": []
              }
            ]
          }
          // ... outros itens de menu de nível superior ...
        ]
      }
    }
```

```json
    {
      \"data\": [
        {
          \"object\": \"bx_persons_main_menu\",
          \"title\": \"Menu Principal de Pessoas\",
          \"module\": \"bx_persons\",
          \"set_name\": \"bx_persons_main\"
        },
        {
          \"object\": \"sys_account_dashboard\",
          \"title\": \"Menu do Painel da Conta\",
          \"module\": \"system\",
          \"set_name\": \"sys_account_dashboard_manage\"
        }
        // ... outros objetos de menu
      ]
    }
```

*   **Erros Comuns:**
    *   `404 Not Found`: Se o objeto de menu `{menu_object_name}` não for encontrado ou não estiver ativo.
*   **Lógica do Backend (Controller):**
    1.  Obter `menu_object_name` da URL e query parameters.
    2.  Extrair `IDLevel` do usuário do token JWT (default para nível de visitante se não houver token).
    3.  Obter o código do idioma (do query param, do perfil do usuário ou do sistema).
    4.  Construir `context_params` (ex: com `current_uri`, `device_type`).
    5.  Chamar `MenusRepo.get_menu_structure/3` com `menu_object_name`, `user_level_id`, `context_params` (e talvez `language_code`).
    6.  A função do Repo já deve ter filtrado itens, traduzido títulos (se necessário) e construído a hierarquia.
    7.  (Opcional) Marcar o item de menu ativo (`is_active_item: true`) se o `link` do item corresponder ao `context_uri` fornecido.
    8.  Retornar a estrutura JSON.

### 2. Listar Objetos de Menu Disponíveis (Opcional)

*   **Endpoint:** `GET /menus/objects`
*   **Status:** Público (ou Admin)
*   **Descrição:** Retorna uma lista de todos os \"objetos de menu\" definidos e ativos. Pode ser útil para ferramentas de desenvolvimento ou para um cliente descobrir quais menus estão disponíveis.
*   **Query Parameters:**
    *   `module=<module_name>`: (Opcional) Filtrar objetos de menu por módulo.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    1.  Chamar `MenusRepo.list_menu_objects/1` com filtros opcionais.

### Considerações:

*   **Tratamento de `submenu_object`:** A API retorna o nome do `submenu_object`. É responsabilidade do cliente fazer uma nova chamada para `GET /menus/{submenu_object_name}` se precisar carregar e exibir esse submenu (ex: em um hover ou clique).
*   **`addon` Dinâmico:** Se o campo `addon` de um `sys_menu_items` no UNA PHP é preenchido dinamicamente por uma service call (ex: contador de notificações), a API \"Deeper\" pode:
    *   Retornar o `addon` como está (a string da service call), e o cliente ignora ou tenta interpretar.
    *   Omitir `addon` dinâmico.
    *   Idealmente, o cliente buscaria esses contadores de forma independente de endpoints específicos (ex: `GET /api/v1/notifications/unread-count`) e os injetaria no item de menu apropriado na UI.
*   **Ativação de Item (`is_active_item`):** A lógica para determinar qual item de menu está \"ativo\" com base na URL atual (`context_uri`) pode ser feita no backend ao construir a resposta, ou pode ser deixada para o cliente. Fazer no backend é mais conveniente para o cliente.
*   **Visibilidade e Permissões:** A filtragem de itens baseada em `visible_for_levels` e outras regras de visibilidade (`hidden_on*`, `visibility_custom`) é a parte mais complexa e deve ser implementada no `MenusRepo`.