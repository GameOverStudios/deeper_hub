# Endpoints da API de Admin para Gerenciamento de Menus

Endpoints para administrar Conjuntos de Menu, Objetos de Menu e Itens de Menu. Todos os endpoints aqui requerem autenticação de Administrador.

## Base Path: `/api/v1/admin/builder` (Consistente com Page Builder)

---
### Gerenciamento de Conjuntos de Menu (`/menu-sets`)

#### 1. Listar Conjuntos de Menu
*   **Endpoint:** `GET /api/v1/admin/builder/menu-sets`
*   **Query Params:** `filter_module`, `sort_by`, `lang`.
*   **Resposta:** Lista de `sys_menu_sets`.

#### 2. Criar Conjunto de Menu
*   **Endpoint:** `POST /api/v1/admin/builder/menu-sets`
*   **Corpo (JSON):** `set_name`, `module`, `title_key`, `is_deletable`.
*   **Resposta (201 Created).**

#### 3. Obter Detalhes de um Conjunto de Menu
*   **Endpoint:** `GET /api/v1/admin/builder/menu-sets/{set_name}`
*   **Path Param:** `set_name`.
*   **Query Params:** `lang`.
*   **Resposta (200 OK).**

#### 4. Atualizar Conjunto de Menu
*   **Endpoint:** `PUT /api/v1/admin/builder/menu-sets/{set_name}`
*   **Corpo (JSON):** `title_key`, `is_deletable`.
*   **Resposta (200 OK).**

#### 5. Deletar Conjunto de Menu
*   **Endpoint:** `DELETE /api/v1/admin/builder/menu-sets/{set_name}`
*   **Resposta (204 No Content).**
*   **Erro (403 Forbidden/409 Conflict):** Se não deletável ou em uso.

---
### Gerenciamento de Objetos de Menu (`/menu-objects`)

#### 6. Listar Objetos de Menu
*   **Endpoint:** `GET /api/v1/admin/builder/menu-objects`
*   **Query Params:** `filter_set_name`, `filter_module`, `sort_by`, `lang`.
*   **Resposta:** Lista de `sys_objects_menu`.

#### 7. Criar Objeto de Menu
*   **Endpoint:** `POST /api/v1/admin/builder/menu-objects`
*   **Corpo (JSON):** Detalhes de `sys_objects_menu`.
*   **Resposta (201 Created).**

#### 8. Obter Detalhes de um Objeto de Menu (e seus itens para o `set_name` associado)
*   **Endpoint:** `GET /api/v1/admin/builder/menu-objects/{menu_object_name}`
*   **Path Param:** `menu_object_name`.
*   **Query Params:** `lang`.
*   **Resposta (200 OK):** Detalhes do objeto e lista hierarquizada de `sys_menu_items` do seu `set_name`.

#### 9. Atualizar Objeto de Menu
*   **Endpoint:** `PUT /api/v1/admin/builder/menu-objects/{menu_object_name}`
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK).**

#### 10. Deletar Objeto de Menu
*   **Endpoint:** `DELETE /api/v1/admin/builder/menu-objects/{menu_object_name}`
*   **Resposta (204 No Content).**

---
### Gerenciamento de Itens de Menu (`/menu-items`)

#### 11. Listar Itens de Menu (para um `set_name`)
*   **Endpoint:** `GET /api/v1/admin/builder/menu-items`
*   **Query Params:** `set_name` (obrigatório), `lang`.
*   **Resposta:** Lista hierarquizada de `sys_menu_items`.

#### 12. Criar Item de Menu
*   **Endpoint:** `POST /api/v1/admin/builder/menu-items`
*   **Corpo (JSON):** Detalhes de `sys_menu_items`.
*   **Resposta (201 Created).**

#### 13. Obter Detalhes de um Item de Menu
*   **Endpoint:** `GET /api/v1/admin/builder/menu-items/{item_id}`
*   **Path Param:** `item_id` (PK de `sys_menu_items`).
*   **Query Params:** `lang`.
*   **Resposta (200 OK).**

#### 14. Atualizar Item de Menu
*   **Endpoint:** `PUT /api/v1/admin/builder/menu-items/{item_id}`
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK).**

#### 15. Reordenar Itens de Menu
*   **Endpoint:** `PUT /api/v1/admin/builder/menu-items/reorder`
*   **Corpo (JSON):** `{\"set_name\": \"...\", \"parent_item_id\": 0, \"ordered_item_ids\": [1,3,2]}`.
*   **Resposta (200 OK).**

#### 16. Deletar Item de Menu
*   **Endpoint:** `DELETE /api/v1/admin/builder/menu-items/{item_id}`
*   **Resposta (204 No Content).**

---
### Templates de Menu (Leitura - `/menu-templates`)

#### 17. Listar Templates de Menu
*   **Endpoint:** `GET /api/v1/admin/builder/menu-templates`
*   **Query Params:** `lang`.
*   **Resposta:** Lista de `sys_menu_templates`.

## Considerações:

*   **Interface de Admin:** Uma interface de arrastar e soltar para reordenar itens de menu é comum. A API de reordenação deve suportar isso.
*   **Validação de `visible_for_levels_mask`:** A UI de admin deve facilitar a seleção de níveis ACL para a máscara de bits.
*   **Traduções:** Gerenciamento integrado de chaves de tradução para títulos.
*   **Impacto de Deleções:** Deletar um `set_name` pode ter um grande impacto se ele for usado por muitos `sys_objects_menu`. A API deve ter verificações ou a UI deve alertar.

Esta API de gerenciamento de menus dá aos administradores controle sobre a estrutura de navegação e ações da interface \"Deeper\".