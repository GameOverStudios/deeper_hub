# Endpoints da API de Admin para Gerenciamento de Grids

Endpoints para administrar Objetos de Grid, Campos de Grid e Ações de Grid. Todos os endpoints aqui requerem autenticação de Administrador.

## Base Path: `/api/v1/admin/builder/grids`

---
### Gerenciamento de Objetos de Grid (`/objects`)

#### 1. Listar Objetos de Grid
*   **Endpoint:** `GET /api/v1/admin/builder/grids/objects`
*   **Query Params:** `filter_object_like`, `sort_by`.
*   **Resposta:** Lista de `sys_objects_grid`.

#### 2. Criar Objeto de Grid
*   **Endpoint:** `POST /api/v1/admin/builder/grids/objects`
*   **Corpo (JSON):** Detalhes de `sys_objects_grid`.
*   **Resposta (201 Created).**

#### 3. Obter Detalhes de um Objeto de Grid
*   **Endpoint:** `GET /api/v1/admin/builder/grids/objects/{grid_object_name}`
*   **Path Param:** `grid_object_name`.
*   **Query Params:** `lang`.
*   **Resposta:** Detalhes do `sys_objects_grid`, incluindo seus `sys_grid_fields` e `sys_grid_actions` (como descrito no `README.md` da Studio API para Grids).

#### 4. Atualizar Objeto de Grid
*   **Endpoint:** `PUT /api/v1/admin/builder/grids/objects/{grid_object_name}`
*   **Corpo (JSON):** Campos a serem atualizados. Cuidado especial com o campo `source` (query SQL).
*   **Resposta (200 OK).**

#### 5. Deletar Objeto de Grid
*   **Endpoint:** `DELETE /api/v1/admin/builder/grids/objects/{grid_object_name}`
*   **Resposta (204 No Content).**

---
### Gerenciamento de Campos de Grid (`/fields`)

#### 6. Listar Campos de Grid de um Objeto de Grid
*   **Endpoint:** `GET /api/v1/admin/builder/grids/fields?grid_object_name={name}`
*   **Query Param:** `grid_object_name` (obrigatório). `lang`.
*   **Resposta:** Lista de `sys_grid_fields`.

#### 7. Criar Campo de Grid
*   **Endpoint:** `POST /api/v1/admin/builder/grids/fields`
*   **Corpo (JSON):** Detalhes de `sys_grid_fields`, incluindo `object` (grid_object_name).
*   **Resposta (201 Created).**

#### 8. Obter Detalhes de um Campo de Grid
*   **Endpoint:** `GET /api/v1/admin/builder/grids/fields/{field_id_db}`
*   **Path Param:** `field_id_db` (PK de `sys_grid_fields`).
*   **Query Params:** `lang`.
*   **Resposta (200 OK).**

#### 9. Atualizar Campo de Grid
*   **Endpoint:** `PUT /api/v1/admin/builder/grids/fields/{field_id_db}`
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK).**

#### 10. Reordenar Campos de Grid
*   **Endpoint:** `PUT /api/v1/admin/builder/grids/fields/reorder`
*   **Corpo (JSON):** `{\"grid_object_name\": \"...\", \"ordered_field_ids\": [1,3,2]}`.
*   **Resposta (200 OK).**

#### 11. Deletar Campo de Grid
*   **Endpoint:** `DELETE /api/v1/admin/builder/grids/fields/{field_id_db}`
*   **Resposta (204 No Content).**

---
### Gerenciamento de Ações de Grid (`/actions`)

#### 12. Listar Ações de Grid de um Objeto de Grid
*   **Endpoint:** `GET /api/v1/admin/builder/grids/actions?grid_object_name={name}`
*   **Query Param:** `grid_object_name` (obrigatório). `lang`.
*   **Resposta:** Lista de `sys_grid_actions`.

#### 13. Criar Ação de Grid
*   **Endpoint:** `POST /api/v1/admin/builder/grids/actions`
*   **Corpo (JSON):** Detalhes de `sys_grid_actions`, incluindo `object` (grid_object_name).
*   **Resposta (201 Created).**

#### 14. Obter Detalhes de uma Ação de Grid
*   **Endpoint:** `GET /api/v1/admin/builder/grids/actions/{action_id_db}`
*   **Path Param:** `action_id_db` (PK de `sys_grid_actions`).
*   **Query Params:** `lang`.
*   **Resposta (200 OK).**

#### 15. Atualizar Ação de Grid
*   **Endpoint:** `PUT /api/v1/admin/builder/grids/actions/{action_id_db}`
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK).**

#### 16. Reordenar Ações de Grid
*   **Endpoint:** `PUT /api/v1/admin/builder/grids/actions/reorder`
*   **Corpo (JSON):** `{\"grid_object_name\": \"...\", \"ordered_action_ids\": [1,3,2]}`.
*   **Resposta (200 OK).**

#### 17. Deletar Ação de Grid
*   **Endpoint:** `DELETE /api/v1/admin/builder/grids/actions/{action_id_db}`
*   **Resposta (204 No Content).**

## Considerações:

*   **Segurança da Query `source`:** Permitir a edição da query SQL (`sys_objects_grid.source`) via API é uma funcionalidade poderosa, mas deve ser restrita a administradores com alto nível de confiança e conhecimento, devido ao risco de SQL injection ou queries que causem problemas de performance. A validação do SQL no backend é complexa.
*   **`params` em `sys_grid_fields`:** A API de admin precisa permitir a configuração desses `params`. Se eles forem JSON, a UI de admin pode fornecer um editor JSON ou campos específicos para os tipos de formatadores que a API \"Deeper\" suportará.
*   **Traduções:** Títulos de grids, campos e ações são chaves de tradução.

Esta API de gerenciamento de grids fornece as ferramentas para configurar como os dados tabulares são apresentados e quais ações são disponibilizadas aos usuários (geralmente administradores) que visualizam essas grids.