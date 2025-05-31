# Documentação Deeper Studio API: Gerenciamento de Menus

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento completo de menus do sistema, incluindo \"Conjuntos de Menu\" (`sys_menu_sets`), \"Objetos de Menu\" (`sys_objects_menu`), e \"Itens de Menu\" (`sys_menu_items`).

**Objetivo Principal:** Permitir que administradores criem, modifiquem, reordenem e deletem menus e seus itens, controlando a navegação e as ações disponíveis em várias partes da plataforma \"Deeper\".

## Tabelas Relevantes (já definidas e migradas):

*   `sys_menu_sets`: Define grupos de menus, geralmente por módulo.
*   `sys_objects_menu`: Define instâncias de menu específicas que podem ser renderizadas.
*   `sys_menu_items`: Define os itens individuais dentro de cada objeto de menu, incluindo submenus.
*   `sys_menu_templates`: Define os templates visuais para menus (no UNA PHP; para a API \"Deeper\", isso é mais informativo, já que o cliente renderiza).
*   Tabelas de tradução para títulos de menus e itens.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.PageEngine.MenusRepo` (ou `Deeper.SystemCore.MenusRepo`): Precisará de funções CRUD completas para as três tabelas principais de menus (`sys_menu_sets`, `sys_objects_menu`, `sys_menu_items`).
*   `Deeper.SystemCore.LocalizationRepo`: Para lidar com títulos traduzíveis.

## Endpoints da API de Administração para Menus (`/api/v1/admin/builder/menus`):

*(Usando `/builder/` para manter consistência com o Page Builder, já que menus são parte da construção da UI)*

---
### Gerenciamento de Conjuntos de Menu (`/api/v1/admin/builder/menu-sets`)

#### 1. Listar Todos os Conjuntos de Menu

*   **Endpoint:** `GET /api/v1/admin/builder/menu-sets`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `filter_module`, `sort_by`. `lang` para traduções.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"set_name\": \"sys_account_notifications\",
          \"module\": \"system\",
          \"title\": \"Notificações da Conta\", // Traduzido
          \"is_deletable\": false
        },
        {
          \"set_name\": \"bx_persons_profile_submenu\",
          \"module\": \"bx_persons\",
          \"title\": \"Submenu do Perfil de Pessoa\", // Traduzido
          \"is_deletable\": true
        }
        // ... outros conjuntos ...
      ]
    }
```

```json
    {
      \"set_name\": \"my_custom_menu_set\", // Deve ser único
      \"module\": \"my_module\",
      \"title_key\": \"_my_custom_menu_set_title\",
      \"is_deletable\": true
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"object_name\": \"bx_persons_profile_actions\", // sys_objects_menu.object
          \"title\": \"Ações do Perfil de Pessoa\", // Traduzido
          \"set_name\": \"bx_persons_profile_actions_set\",
          \"module\": \"bx_persons\",
          \"template_id\": 1, // ID do sys_menu_templates
          \"is_active\": true
        }
        // ... outros objetos de menu ...
      ]
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"object_name\": \"bx_persons_profile_actions\",
        \"title_key\": \"_bx_persons_actions_menu\",
        \"title_translated\": \"Ações do Perfil\",
        \"set_name\": \"bx_persons_profile_actions_set\",
        // ... outros campos de sys_objects_menu ...
        \"items\": [ // Lista de sys_menu_items para este objeto/set, hierarquizada
          {
            \"item_id\": 10, // sys_menu_items.id
            \"parent_item_id\": 0,
            \"name\": \"add_friend\",
            \"title_key\": \"_bx_persons_action_add_friend\",
            \"title_translated\": \"Adicionar Amigo\",
            \"link\": \"/connections/add_friend/{profile_id}\",
            \"icon\": \"fas user-plus\",
            \"order\": 1,
            \"is_active\": true,
            \"visible_for_levels_mask\": 2147483647,
            \"children\": []
          }
          // ... outros itens ...
        ]
      }
    }
```

```json
    {
      \"set_name\": \"my_custom_menu_set\",
      \"parent_item_id\": 0, // Ou o ID do item pai para reordenar sub-itens
      \"ordered_item_ids\": [15, 12, 18] // Lista de IDs de sys_menu_items na nova ordem
    }
```

#### 2. Criar Novo Conjunto de Menu

*   **Endpoint:** `POST /api/v1/admin/builder/menu-sets`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Retorna o conjunto criado.

#### 3. Obter Detalhes de um Conjunto de Menu

*   **Endpoint:** `GET /api/v1/admin/builder/menu-sets/{set_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do conjunto.

#### 4. Atualizar um Conjunto de Menu

*   **Endpoint:** `PUT /api/v1/admin/builder/menu-sets/{set_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos `title_key`, `is_deletable`. O `module` e `set_name` geralmente não são alterados.
*   **Resposta de Sucesso (200 OK):** Retorna o conjunto atualizado.

#### 5. Deletar um Conjunto de Menu

*   **Endpoint:** `DELETE /api/v1/admin/builder/menu-sets/{set_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Verifica `is_deletable`. Se deletar, também precisaria deletar `sys_objects_menu` e `sys_menu_items` associados a este `set_name` (ou impedir se houver objetos/itens).
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Objetos de Menu (`/api/v1/admin/builder/menu-objects`)

#### 6. Listar Todos os Objetos de Menu

*   **Endpoint:** `GET /api/v1/admin/builder/menu-objects`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `filter_set_name`, `filter_module`, `sort_by`. `lang`.
*   **Resposta de Sucesso (200 OK):**

#### 7. Criar Novo Objeto de Menu

*   **Endpoint:** `POST /api/v1/admin/builder/menu-objects`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `object_name`, `title_key`, `set_name`, `module`, `template_id`, `is_active`, `is_deletable`.
*   **Resposta de Sucesso (201 Created).**

#### 8. Obter Detalhes de um Objeto de Menu (incluindo seus itens)

*   **Endpoint:** `GET /api/v1/admin/builder/menu-objects/{menu_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `lang`.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Busca de `sys_objects_menu` e depois busca e hierarquiza `sys_menu_items` para o `set_name` correspondente.

#### 9. Atualizar um Objeto de Menu

*   **Endpoint:** `PUT /api/v1/admin/builder/menu-objects/{menu_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_menu` a serem atualizados.
*   **Resposta de Sucesso (200 OK).**

#### 10. Deletar um Objeto de Menu

*   **Endpoint:** `DELETE /api/v1/admin/builder/menu-objects/{menu_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Verifica `deletable`. *Não* deleta os `sys_menu_items` automaticamente, pois eles pertencem a um `set_name`.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Itens de Menu (`/api/v1/admin/builder/menu-items`)

Estes endpoints operam diretamente nos `sys_menu_items`.

#### 11. Listar Itens de Menu (para um `set_name` específico)

*   **Endpoint:** `GET /api/v1/admin/builder/menu-items`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `set_name` (obrigatório), `filter_module`, `lang`.
*   **Resposta de Sucesso (200 OK):** Lista hierarquizada de itens para o `set_name`.

#### 12. Criar Novo Item de Menu

*   **Endpoint:** `POST /api/v1/admin/builder/menu-items`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Todos os campos de `sys_menu_items` (ex: `set_name`, `module`, `name`, `title_key`, `link`, `icon`, `parent_id`, `order`, `visible_for_levels_mask`, `is_active`, etc.).
*   **Resposta de Sucesso (201 Created).**

#### 13. Obter Detalhes de um Item de Menu

*   **Endpoint:** `GET /api/v1/admin/builder/menu-items/{item_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `lang`.
*   **Resposta de Sucesso (200 OK).**

#### 14. Atualizar um Item de Menu

*   **Endpoint:** `PUT /api/v1/admin/builder/menu-items/{item_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_menu_items` a serem atualizados.
*   **Resposta de Sucesso (200 OK).**

#### 15. Reordenar Itens de Menu (dentro de um `set_name` e `parent_id`)

*   **Endpoint:** `PUT /api/v1/admin/builder/menu-items/reorder`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK).**
*   **Lógica do Backend:** Atualiza o campo `order` dos `sys_menu_items` especificados.

#### 16. Deletar um Item de Menu

*   **Endpoint:** `DELETE /api/v1/admin/builder/menu-items/{item_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Deleta o item. Se o item tiver `children` (sub-itens), eles também devem ser deletados (ou re-parentados, ou a deleção impedida).
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Templates de Menu (`/api/v1/admin/builder/menu-templates`)

#### 17. Listar Templates de Menu

*   **Endpoint:** `GET /api/v1/admin/builder/menu-templates`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_menu_templates` (id, template, title_key, visible).
*   *Nota: Estes são principalmente informativos para a API \"Deeper\", pois a renderização é feita pelo cliente.*

## Considerações:

*   **Traduções:** Muitos campos `title` são chaves de tradução. A API de Admin deve permitir a edição dessas chaves ou das strings associadas (integrando com a API de Admin de Localização).
*   **`visible_for_levels_mask`:** A UI de Admin deve fornecer uma forma amigável de selecionar os níveis de ACL (ex: checkboxes) e a API converteria isso para a máscara de bits.
*   **Validação:** `set_name` e `object_name` devem ser únicos. `item_id`s e `parent_id`s devem ser válidos.
*   **Hierarquia:** O `MenusRepo` precisa de lógica para construir e retornar a estrutura hierárquica dos itens de menu.
*   **`addon` em `sys_menu_items`:** Se `addon` for usado para contadores dinâmicos, a API de Admin para itens de menu pode precisar de uma forma de configurar a chamada de serviço PHP original (ou seu equivalente \"Deeper\").

Esta API de gerenciamento de menus oferece controle granular sobre a navegação e as ações disponíveis na plataforma \"Deeper\".