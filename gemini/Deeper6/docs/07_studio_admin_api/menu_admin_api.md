# Documentação Deeper: API de Administração - Gerenciamento de Menus

Este documento descreve os endpoints da API \"Deeper\" para administradores gerenciarem os menus do site, incluindo Conjuntos de Menu (`sys_menu_sets`), Objetos de Menu (`sys_objects_menu`), e Itens de Menu (`sys_menu_items`). Os Templates de Menu (`sys_menu_templates`) são geralmente estruturais e menos frequentemente gerenciados pela UI de admin.

## Escopo e Funcionalidades:

*   CRUD para Conjuntos de Menu (útil para menus customizados).
*   CRUD para Objetos de Menu (definir instâncias de menu usadas no site).
*   CRUD para Itens de Menu (adicionar, remover, reordenar, configurar links, títulos, ícones, submenus, visibilidade).

## Tabelas Relevantes (Já Definidas em `docs/02_page_rendering_engine/sys_menu_engine/`):

*   `sys_menu_sets`
*   `sys_menu_templates` (Principalmente para listagem/seleção)
*   `sys_objects_menu`
*   `sys_menu_items`

## Módulo de Acesso a Dados (Já Definido/Esboçado):

*   `Deeper.PageEngine.MenuRepo` será utilizado para interações com o banco de dados.

## Endpoints da API de Administração para Menus

Todos os endpoints estão sob `/api/v1/admin/menus/...` e requerem autenticação de administrador.

### Gerenciamento de Conjuntos de Menu (`sys_menu_sets`)

#### 1. Listar Conjuntos de Menu
*   **Endpoint:** `GET /api/v1/admin/menus/sets`
*   **Query Parameters:** `module_filter` (String, Opcional).
*   **Resposta (200 OK):** Lista de `sys_menu_sets`.

```json
    {
      \"data\": [
        {
          \"set_name\": \"sys_site_main\",
          \"module\": \"system\",
          \"title\": \"_sys_set_title_site_main\", // Chave de tradução
          \"title_resolved\": \"Site Main Menu Set\", // Título traduzido
          \"deletable\": 0
        }
      ]
    }
```

```json
    {
      \"set_name\": \"my_custom_footer_menu\",
      \"module\": \"custom_module\", // ou \"system\"
      \"title\": \"_custom_set_title_footer\",
      \"deletable\": 1
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"object\": \"sys_site_main_menu\",
          \"title\": \"_sys_obj_title_site_main\",
          \"title_resolved\": \"Site Main Menu\",
          \"set_name\": \"sys_site_main\",
          \"module\": \"system\",
          \"template_id\": 1,
          \"template_path\": \"menu_main.html\", // JOIN com sys_menu_templates
          \"active\": 1
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"object\": \"my_profile_actions_menu\",
      \"title\": \"_prof_actions_title\",
      \"set_name\": \"profile_actions_set\", // Deve existir em sys_menu_sets
      \"module\": \"custom_module\",
      \"template_id\": 2, // ID de um sys_menu_templates
      \"active\": 1,
      \"deletable\": 1
    }
```

```json
    {
      \"menu_object\": { /* ... dados de sys_objects_menu ... */ },
      \"items\": [ /* ... lista hierárquica de sys_menu_items, similar à API pública ... */ ],
      \"available_sets\": [ /* ... lista de sys_menu_sets para seleção ... */ ],
      \"available_templates\": [ /* ... lista de sys_menu_templates para seleção ... */ ]
    }
```

```json
    {
      \"set_name\": \"sys_site_main\",
      \"items\": [
        {
          \"id\": 1,
          \"parent_id\": 0,
          \"module\": \"system\",
          \"name\": \"home_item\",
          \"title_system\": \"_sys_menu_item_home\",
          \"title\": \"Home\", // Resolvido
          \"link\": \"/\",
          \"icon\": \"home\",
          \"order\": 10,
          \"active\": 1,
          \"visible_for_levels\": 2147483647,
          \"submenu_object\": null,
          \"sub_items\": []
        }
        // ... mais itens ...
      ]
    }
```

```json
    {
      \"parent_id\": 0, // ou ID de um item pai existente neste set_name
      \"module\": \"custom_module\",
      \"name\": \"custom_link_1\",
      \"title_system\": \"_custom_item_title_link1\",
      \"title\": \"My Custom Link\",
      \"link\": \"/my-custom-url\",
      \"icon\": \"link-outline\",
      \"order\": 50,
      \"active\": 1,
      \"visible_for_levels\": 2147483647, // Bitmask ACL
      \"submenu_object\": null // ou nome de um sys_objects_menu para o submenu
    }
```

```json
    // Formato similar ao usado em build_menu_hierarchy, mas para definir a ordem
    // Ex: uma lista simples com id, parent_id, order
    [
      { \"id\": 101, \"parent_id\": 0, \"order\": 10 },
      { \"id\": 105, \"parent_id\": 101, \"order\": 10 }, // item 105 agora é filho de 101
      { \"id\": 102, \"parent_id\": 0, \"order\": 20 }
    ]
```

#### 2. Criar Novo Conjunto de Menu
*   **Endpoint:** `POST /api/v1/admin/menus/sets`
*   **Corpo da Requisição (JSON):**

*   **Resposta (201 Created):** Detalhes do conjunto criado.

#### 3. Obter Detalhes de um Conjunto de Menu
*   **Endpoint:** `GET /api/v1/admin/menus/sets/{setName}`
*   **Resposta (200 OK):** Detalhes do conjunto.

#### 4. Atualizar Conjunto de Menu
*   **Endpoint:** `PUT /api/v1/admin/menus/sets/{setName}`
*   **Corpo da Requisição (JSON):** Campos a atualizar (ex: `title`, `deletable`).
*   **Resposta (200 OK):** Detalhes do conjunto atualizado.

#### 5. Deletar Conjunto de Menu
*   **Endpoint:** `DELETE /api/v1/admin/menus/sets/{setName}`
*   **Lógica:** Verificar `deletable`. A exclusão deve (via `ON DELETE CASCADE` na FK de `sys_menu_items` e `sys_objects_menu`) remover itens e objetos de menu associados.
*   **Resposta (204 No Content).**

### Gerenciamento de Templates de Menu (`sys_menu_templates`)

#### 1. Listar Templates de Menu
*   **Endpoint:** `GET /api/v1/admin/menus/templates`
*   **Resposta (200 OK):** Lista de `sys_menu_templates` (id, template, title, visible). Útil para seleção ao criar/editar `sys_objects_menu`.

### Gerenciamento de Objetos de Menu (`sys_objects_menu`)

#### 1. Listar Objetos de Menu
*   **Endpoint:** `GET /api/v1/admin/menus/objects`
*   **Query Parameters:** `module_filter`, `set_name_filter`.
*   **Resposta (200 OK):** Lista paginada de `sys_objects_menu`.

#### 2. Criar Novo Objeto de Menu
*   **Endpoint:** `POST /api/v1/admin/menus/objects`
*   **Corpo da Requisição (JSON):**

*   **Resposta (201 Created):** Detalhes do objeto criado.

#### 3. Obter Detalhes de um Objeto de Menu (Incluindo seus Itens)
*   **Endpoint:** `GET /api/v1/admin/menus/objects/{menuObjectIdOrName}` (onde `{menuObjectIdOrName}` é `sys_objects_menu.id` ou `sys_objects_menu.object`)
*   **Resposta (200 OK):** Detalhes completos do objeto de menu e a lista hierárquica de seus `sys_menu_items`.

#### 4. Atualizar Objeto de Menu
*   **Endpoint:** `PUT /api/v1/admin/menus/objects/{menuObjectIdOrName}`
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_menu` a atualizar.
*   **Resposta (200 OK):** Detalhes do objeto atualizado.

#### 5. Deletar Objeto de Menu
*   **Endpoint:** `DELETE /api/v1/admin/menus/objects/{menuObjectIdOrName}`
*   **Lógica:** Verificar `deletable`.
*   **Resposta (204 No Content).**

### Gerenciamento de Itens de Menu (`sys_menu_items`)

Os itens são geralmente gerenciados no contexto de um `set_name` (e, por extensão, de um `sys_objects_menu` que usa esse `set_name`).

#### 1. Listar Itens de Menu para um Conjunto (`set_name`)
*   **Endpoint:** `GET /api/v1/admin/menus/sets/{setName}/items`
*   **Query Parameters:** `lang` (para resolver `title_system`).
*   **Resposta (200 OK):** Lista hierárquica de `sys_menu_items` para o `set_name` especificado.

#### 2. Adicionar Item de Menu a um Conjunto
*   **Endpoint:** `POST /api/v1/admin/menus/sets/{setName}/items`
*   **Corpo da Requisição (JSON):** Campos de `sys_menu_items`.

*   **Resposta (201 Created):** Detalhes do item criado.

#### 3. Obter Detalhes de um Item de Menu
*   **Endpoint:** `GET /api/v1/admin/menus/items/{itemId}`
*   **Resposta (200 OK):** Detalhes completos do item.

#### 4. Atualizar Item de Menu
*   **Endpoint:** `PUT /api/v1/admin/menus/items/{itemId}`
*   **Corpo da Requisição (JSON):** Campos de `sys_menu_items` a serem atualizados.
*   **Resposta (200 OK):** Detalhes do item atualizado.

#### 5. Atualizar Ordem/Hierarquia dos Itens de Menu em um Conjunto
*   **Endpoint:** `PUT /api/v1/admin/menus/sets/{setName}/items-order`
*   **Propósito:** Permite reordenar itens e alterar sua hierarquia (mudar `parent_id`).
*   **Corpo da Requisição (JSON):** Uma lista de itens com seus `id`, novo `parent_id` e novo `order`.

*   **Lógica do Backend:** Itera sobre a lista, atualizando `parent_id` e `order` para cada `sys_menu_items.id`.
*   **Resposta (200 OK):** Mensagem de sucesso.

#### 6. Deletar Item de Menu
*   **Endpoint:** `DELETE /api/v1/admin/menus/items/{itemId}`
*   **Lógica:** A exclusão de um item com `sub_items` pode exigir que os filhos sejam também deletados ou promovidos. `ON DELETE CASCADE` na FK de `parent_id` (se auto-referencial) poderia cuidar disso se a estrutura permitir.
*   **Resposta (204 No Content).**

### Considerações:

*   **Traduções:** Títulos (`title_system`) são chaves de linguagem. A API de admin deve permitir visualizar/editar essas chaves e, ao listar, mostrar o título resolvido para o idioma de admin padrão ou um `lang` param.
*   **Visibilidade (`visible_for_levels`):** A UI de admin precisará de um seletor para os níveis de ACL. O valor armazenado é uma bitmask.
*   **Submenus (`submenu_object`):** Ao configurar um item para ter um submenu, a UI de admin deve permitir selecionar um `sys_objects_menu` existente.
*   **Cache:** Alterações em menus devem invalidar caches relevantes (ex: cache de renderização de cabeçalho/menu).

Esta API de administração de menus oferece um controle granular sobre a navegação do site \"Deeper\".