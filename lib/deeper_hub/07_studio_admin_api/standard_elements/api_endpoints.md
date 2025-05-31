# Endpoints da API de Admin para Gerenciamento de Elementos Padrão do Sistema

Endpoints para administrar Páginas Padrão, Widgets Padrão e Papéis Padrão. Todos os endpoints aqui requerem autenticação de Administrador.

## Base Path: `/api/v1/admin/standard-elements`

---
### Gerenciamento de Páginas Padrão (`/std-pages`)

#### 1. Listar Páginas Padrão
*   **Endpoint:** `GET /api/v1/admin/standard-elements/std-pages`
*   **Query Params:** `sort_by` (ex: `index_asc`, `name_asc`), `lang`.
*   **Resposta:** Lista de `sys_std_pages` (com `header`, `caption` traduzidos).

#### 2. Criar Página Padrão
*   **Endpoint:** `POST /api/v1/admin/standard-elements/std-pages`
*   **Corpo (JSON):** `name` (único), `index`, `header_key`, `caption_key`, `icon`.
*   **Resposta (201 Created):** A página padrão criada.

#### 3. Obter Detalhes de uma Página Padrão (e seus widgets associados)
*   **Endpoint:** `GET /api/v1/admin/standard-elements/std-pages/{std_page_id_or_name}`
*   **Path Param:** `std_page_id_or_name` (ID ou `name` da `sys_std_pages`).
*   **Query Params:** `lang`.
*   **Resposta (200 OK):** Detalhes da página padrão e uma lista de widgets associados (de `sys_std_pages_widgets` e `sys_std_widgets`, ordenados e com legendas traduzidas).

#### 4. Atualizar Página Padrão
*   **Endpoint:** `PUT /api/v1/admin/standard-elements/std-pages/{std_page_id}`
*   **Corpo (JSON):** Campos a serem atualizados (ex: `index`, `header_key`, `caption_key`, `icon`). `name` geralmente não é alterado.
*   **Resposta (200 OK).**

#### 5. Deletar Página Padrão
*   **Endpoint:** `DELETE /api/v1/admin/standard-elements/std-pages/{std_page_id}`
*   **Lógica:** Deleta a página e suas associações em `sys_std_pages_widgets`.
*   **Resposta (204 No Content).**

#### 6. Atualizar Widgets de uma Página Padrão
*   **Endpoint:** `PUT /api/v1/admin/standard-elements/std-pages/{std_page_id}/widgets`
*   **Corpo (JSON):** `{\"ordered_widget_ids\": [10, 5, 12]}` (lista de IDs de `sys_std_widgets` na nova ordem).
*   **Lógica:** Usa `StdElementsRepo.set_widgets_for_std_page`.
*   **Resposta (200 OK).**

---
### Gerenciamento de Widgets Padrão (`/std-widgets`)

#### 7. Listar Widgets Padrão
*   **Endpoint:** `GET /api/v1/admin/standard-elements/std-widgets`
*   **Query Params:** `filter_module`, `filter_page_id_std_name`, `sort_by`, `lang`.
*   **Resposta:** Lista de `sys_std_widgets` (com `caption` traduzido).

#### 8. Criar Widget Padrão
*   **Endpoint:** `POST /api/v1/admin/standard-elements/std-widgets`
*   **Corpo (JSON):** `page_id_std_name` (opcional), `module`, `type`, `url`, `click`, `icon`, `caption_key`, `cnt_notices_config` (string), `cnt_actions_config` (string), `is_featured`.
*   **Resposta (201 Created).**

#### 9. Obter Detalhes de um Widget Padrão
*   **Endpoint:** `GET /api/v1/admin/standard-elements/std-widgets/{widget_id}`
*   **Path Param:** `widget_id`.
*   **Query Params:** `lang`.
*   **Resposta (200 OK).**

#### 10. Atualizar Widget Padrão
*   **Endpoint:** `PUT /api/v1/admin/standard-elements/std-widgets/{widget_id}`
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK).**

#### 11. Deletar Widget Padrão
*   **Endpoint:** `DELETE /api/v1/admin/standard-elements/std-widgets/{widget_id}`
*   **Lógica:** Deleta o widget e suas associações em `sys_std_pages_widgets`.
*   **Resposta (204 No Content).**

---
### Gerenciamento de Papéis Padrão (`/std-roles`)

#### 12. Listar Papéis Padrão
*   **Endpoint:** `GET /api/v1/admin/standard-elements/std-roles`
*   **Query Params:** `sort_by` (`order_asc`, `name_asc`), `lang`.
*   **Resposta:** Lista de `sys_std_roles`.

#### 13. Criar Papel Padrão
*   **Endpoint:** `POST /api/v1/admin/standard-elements/std-roles`
*   **Corpo (JSON):** `name` (único), `title_key`, `description_key`, `is_active`, `order`.
*   **Resposta (201 Created).**

#### 14. Obter Detalhes de um Papel Padrão (e suas ações associadas)
*   **Endpoint:** `GET /api/v1/admin/standard-elements/std-roles/{role_id_or_name}`
*   **Query Params:** `lang`.
*   **Resposta:** Detalhes do papel e lista de `sys_std_roles_actions` associadas.

#### 15. Atualizar Papel Padrão
*   **Endpoint:** `PUT /api/v1/admin/standard-elements/std-roles/{role_id}`
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK).**

#### 16. Deletar Papel Padrão
*   **Endpoint:** `DELETE /api/v1/admin/standard-elements/std-roles/{role_id}`
*   **Lógica:** Deleta o papel e associações em `sys_std_roles_actions2roles` e `sys_std_roles_members`.
*   **Resposta (204 No Content).**

#### 17. Atualizar Ações de um Papel Padrão
*   **Endpoint:** `PUT /api/v1/admin/standard-elements/std-roles/{role_id}/actions`
*   **Corpo (JSON):** `{\"action_ids\": [1, 5, 7]}` (lista de IDs de `sys_std_roles_actions`).
*   **Lógica:** Usa `StdElementsRepo.set_actions_for_std_role`.
*   **Resposta (200 OK).**

---
### Gerenciamento de Ações de Papel Padrão (`/std-role-actions`)

#### 18. Listar Ações de Papel Padrão
*   **Endpoint:** `GET /api/v1/admin/standard-elements/std-role-actions`
*   **Query Params:** `sort_by`, `lang`.
*   **Resposta:** Lista de `sys_std_roles_actions`.

#### 19. Criar Ação de Papel Padrão
*   **Endpoint:** `POST /api/v1/admin/standard-elements/std-role-actions`
*   **Corpo (JSON):** `name` (único), `title_key`, `description_key`.
*   **Resposta (201 Created).**

#### 20. Obter Detalhes de uma Ação de Papel Padrão
*   **Endpoint:** `GET /api/v1/admin/standard-elements/std-role-actions/{action_id_or_name}`
*   **Query Params:** `lang`.
*   **Resposta (200 OK).**

#### 21. Atualizar Ação de Papel Padrão
*   **Endpoint:** `PUT /api/v1/admin/standard-elements/std-role-actions/{action_id}`
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK).**

#### 22. Deletar Ação de Papel Padrão
*   **Endpoint:** `DELETE /api/v1/admin/standard-elements/std-role-actions/{action_id}`
*   **Lógica:** Deleta a ação e suas associações em `sys_std_roles_actions2roles`.
*   **Resposta (204 No Content).**

---
### Gerenciamento de Atribuição de Papel Padrão a Contas (`/account-std-roles`)

#### 23. Listar Atribuições de Papel Padrão
*   **Endpoint:** `GET /api/v1/admin/standard-elements/account-std-roles`
*   **Query Params:** `filter_account_id`, `filter_role_id`, `page`, `per_page`.
*   **Resposta:** Lista de `sys_std_roles_members` com detalhes da conta e do papel.

#### 24. Atribuir/Mudar Papel Padrão de uma Conta
*   **Endpoint:** `PUT /api/v1/admin/standard-elements/account-std-roles/account/{account_id}`
*   **Corpo (JSON):** `{\"role_id\": 3}`.
*   **Lógica:** Usa `StdElementsRepo.set_std_role_for_account`.
*   **Resposta (200 OK).**

#### 25. Remover Atribuição de Papel Padrão de uma Conta
*   **Endpoint:** `DELETE /api/v1/admin/standard-elements/account-std-roles/account/{account_id}`
*   **Lógica:** Usa `StdElementsRepo.remove_std_role_from_account`.
*   **Resposta (204 No Content).**

## Considerações:

*   **`page_id` em `sys_std_widgets`:** No UNA, esta coluna pode ser o `name` de `sys_std_pages` ou um identificador de dashboard dinâmico. A API precisará de uma convenção clara.
*   **Lógica Dinâmica em Widgets (`cnt_notices`, `cnt_actions`):** A API de Admin para widgets listará as configurações originais. Se a API \"Deeper\" reimplementar a funcionalidade de contagem, a UI de admin pode precisar de campos para configurar os equivalentes Elixir.
*   **Relação `sys_std_roles` vs `sys_acl_levels`:** A UI de admin deve deixar claro como esses dois sistemas de \"papel/nível\" interagem ou se são independentes na lógica da API \"Deeper\".

Esta API de gerenciamento de Elementos Padrão permite aos administradores configurar aspectos fundamentais da estrutura e dos papéis no sistema \"Deeper\".