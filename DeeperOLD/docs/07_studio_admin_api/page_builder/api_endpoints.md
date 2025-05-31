# Endpoints da API de Admin para Construtor de Páginas

Endpoints para administrar Páginas, Blocos, Layouts, etc. Todos os endpoints aqui requerem autenticação de Administrador.

## Base Path: `/api/v1/admin/builder`

---
### Gerenciamento de Objetos de Página (`/pages`)

#### 1. Listar Páginas
*   **Endpoint:** `GET /api/v1/admin/builder/pages`
*   **Query Params:** `filter_module`, `filter_uri_like`, `filter_title_like`, `sort_by`, `lang`.
*   **Resposta:** Lista de páginas.

#### 2. Criar Página
*   **Endpoint:** `POST /api/v1/admin/builder/pages`
*   **Corpo (JSON):** Detalhes da página (`object_name`, `uri`, `title_key`, `module`, `layout_id`, etc.).
*   **Resposta (201 Created):** A página criada.

#### 3. Obter Detalhes de uma Página (e seus blocos)
*   **Endpoint:** `GET /api/v1/admin/builder/pages/{page_object_name}`
*   **Path Param:** `page_object_name`.
*   **Query Params:** `lang`.
*   **Resposta (200 OK):** Detalhes da página e lista de seus blocos.

#### 4. Atualizar Página
*   **Endpoint:** `PUT /api/v1/admin/builder/pages/{page_object_name}`
*   **Path Param:** `page_object_name`.
*   **Corpo (JSON):** Campos de `sys_objects_page` a serem atualizados.
*   **Resposta (200 OK):** A página atualizada.

#### 5. Deletar Página
*   **Endpoint:** `DELETE /api/v1/admin/builder/pages/{page_object_name}`
*   **Path Param:** `page_object_name`.
*   **Resposta (204 No Content).**
*   **Erro (403 Forbidden):** Se a página não for deletável.

---
### Gerenciamento de Blocos de Página (`/pages/{page_object_name}/blocks` e `/blocks`)

#### 6. Adicionar Novo Bloco a uma Página
*   **Endpoint:** `POST /api/v1/admin/builder/pages/{page_object_name}/blocks`
*   **Path Param:** `page_object_name`.
*   **Corpo (JSON):** Detalhes do bloco (`cell_id`, `module`, `title_key`, `type`, `content_definition`, `designbox_id`, `order`, etc.).
*   **Resposta (201 Created):** O bloco criado.

#### 7. Obter Detalhes de um Bloco Específico
*   **Endpoint:** `GET /api/v1/admin/builder/blocks/{block_id}`
*   **Path Param:** `block_id` (PK de `sys_pages_blocks`).
*   **Query Params:** `lang`.
*   **Resposta (200 OK):** Detalhes do bloco.

#### 8. Atualizar um Bloco
*   **Endpoint:** `PUT /api/v1/admin/builder/blocks/{block_id}`
*   **Path Param:** `block_id`.
*   **Corpo (JSON):** Campos de `sys_pages_blocks` a serem atualizados.
*   **Resposta (200 OK):** O bloco atualizado.

#### 9. Reordenar Blocos em uma Página
*   **Endpoint:** `PUT /api/v1/admin/builder/pages/{page_object_name}/blocks/reorder`
*   **Path Param:** `page_object_name`.
*   **Corpo (JSON):** `{\"cell_orders\": { \"1\": [101, 103], \"2\": [102] }}` (cell_id => lista de block_ids ordenados).
*   **Resposta (200 OK).**

#### 10. Deletar um Bloco
*   **Endpoint:** `DELETE /api/v1/admin/builder/blocks/{block_id}`
*   **Path Param:** `block_id`.
*   **Resposta (204 No Content).**
*   **Erro (403 Forbidden):** Se o bloco não for deletável.

---
### Recursos do Construtor (Leitura) (`/builder-resources`)

#### 11. Listar Layouts de Página
*   **Endpoint:** `GET /api/v1/admin/builder/resources/layouts`
*   **Query Params:** `lang`.
*   **Resposta:** Lista de `sys_pages_layouts`.

#### 12. Listar Tipos de Página (se aplicável)
*   **Endpoint:** `GET /api/v1/admin/builder/resources/page-types`
*   **Query Params:** `lang`.
*   **Resposta:** Lista de `sys_pages_types`.

#### 13. Listar Design Boxes
*   **Endpoint:** `GET /api/v1/admin/builder/resources/design-boxes`
*   **Query Params:** `lang`.
*   **Resposta:** Lista de `sys_pages_design_boxes`.

## Considerações Importantes:

*   **`content_definition` para Blocos de Serviço:** Ao criar/editar um bloco do tipo `service`, a API de admin precisa aceitar uma forma estruturada (JSON) para definir `module`, `method`, e `params` do serviço, que o `PagesRepo` então serializaria para o formato esperado em `sys_pages_blocks.content` (seja a string serializada PHP por compatibilidade, ou um JSON interno da \"Deeper\").
*   **Traduções:** A gestão de `title_key` e as strings de tradução associadas é fundamental. A UI de admin pode permitir criar/selecionar chaves existentes ou inserir novas traduções (integrando com a API de Admin de Localização).
*   **Seleção de Módulos/Serviços:** Para blocos de serviço, a UI de admin precisaria de uma forma de listar módulos e seus serviços disponíveis para seleção.

Esta API para o Construtor de Páginas é complexa, mas oferece um controle poderoso sobre a estrutura e conteúdo visual da plataforma \"Deeper\".