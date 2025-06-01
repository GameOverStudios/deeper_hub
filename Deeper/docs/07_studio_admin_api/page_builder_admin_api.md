# Documentação Deeper: API de Administração - Construtor de Páginas (Page Builder)

Este documento descreve os endpoints da API \"Deeper\" para administradores gerenciarem a estrutura das páginas do site, incluindo Objetos de Página (`sys_objects_page`), Blocos de Página (`sys_pages_blocks`), Layouts (`sys_pages_layouts`), Tipos de Página (`sys_pages_types`) e Design Boxes (`sys_pages_design_boxes`).

## Escopo e Funcionalidades:

*   CRUD para Objetos de Página: criar novas páginas, definir suas URIs, títulos, layouts, etc.
*   Gerenciamento de Blocos de Página: adicionar, remover, reordenar e configurar blocos dentro das células de layout de uma página.
*   CRUD para Layouts de Página (geralmente menos frequente, mais estrutural).
*   CRUD para Tipos de Página e Design Boxes (também mais estrutural).
*   Gerenciamento do conteúdo de blocos específicos (ex: blocos HTML, blocos Wiki).

## Tabelas Relevantes (Já Definidas em `docs/02_page_rendering_engine/`):

*   `sys_objects_page`
*   `sys_pages_blocks`
*   `sys_pages_layouts`
*   `sys_pages_types`
*   `sys_pages_design_boxes`
*   `sys_pages_wiki_blocks` (se a funcionalidade de blocos wiki for portada)

## Módulo de Acesso a Dados (Já Definido/Esboçado):

*   `Deeper.PageEngine.PageRepo` será utilizado para interações com o banco de dados.

## Endpoints da API de Administração para o Construtor de Páginas

Todos os endpoints estão sob `/api/v1/admin/page-builder/...` e requerem autenticação de administrador.

### Gerenciamento de Tipos de Página (`sys_pages_types`)

Estes são geralmente predefinidos, mas a API pode permitir listagem e, raramente, modificação.

#### 1. Listar Tipos de Página
*   **Endpoint:** `GET /api/v1/admin/page-builder/page-types`
*   **Resposta (200 OK):** Lista de `sys_pages_types` (id, title, template, order).

#### 2. (Opcional) Criar/Atualizar/Deletar Tipo de Página
*   Endpoints como `POST`, `PUT /.../{typeId}`, `DELETE /.../{typeId}`. Menos comum para admin.

### Gerenciamento de Layouts de Página (`sys_pages_layouts`)

Similar aos Tipos, geralmente predefinidos.

#### 1. Listar Layouts de Página
*   **Endpoint:** `GET /api/v1/admin/page-builder/layouts`
*   **Resposta (200 OK):** Lista de `sys_pages_layouts` (id, name, icon, title, template, cells_number).

#### 2. (Opcional) Criar/Atualizar/Deletar Layout
*   Endpoints como `POST`, `PUT /.../{layoutId}`, `DELETE /.../{layoutId}`.

### Gerenciamento de Design Boxes (`sys_pages_design_boxes`)

Define os \"contêineres\" visuais para os blocos.

#### 1. Listar Design Boxes
*   **Endpoint:** `GET /api/v1/admin/page-builder/design-boxes`
*   **Resposta (200 OK):** Lista de `sys_pages_design_boxes` (id, title, template, order).

#### 2. (Opcional) Criar/Atualizar/Deletar Design Box
*   Endpoints como `POST`, `PUT /.../{boxId}`, `DELETE /.../{boxId}`.

### Gerenciamento de Objetos de Página (`sys_objects_page`)

#### 1. Listar Objetos de Página
*   **Endpoint:** `GET /api/v1/admin/page-builder/pages`
*   **Query Parameters:** `search_term` (por `object` ou `title`), `module_filter`.
*   **Resposta (200 OK):** Lista paginada de `sys_objects_page`.

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"object\": \"bx_persons_home\",
          \"uri\": \"persons\",
          \"title_system\": \"_bx_persons_page_title_home\",
          \"title\": \"People Home\", // Resolvido
          \"module\": \"bx_persons\",
          \"layout_id\": 5,
          \"active\": 1 // Adicionar o campo 'active' se ele existir na tabela portadapara sys_objects_page
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"object\": \"my_custom_page\",
      \"uri\": \"custom-page-url\",
      \"title_system\": \"_custom_page_title_my_page\",
      \"title\": \"My Custom Page\",
      \"module\": \"system\", // Ou um módulo específico
      \"layout_id\": 3,
      \"type_id\": 1, // ID de sys_pages_types
      \"visible_for_levels\": 2147483647,
      \"cache_lifetime\": 0,
      \"deletable\": 1
      // ... outros campos como cover, meta tags, injections ...
    }
```

```json
    {
      \"page_object\": { /* ... dados de sys_objects_page ... */ },
      \"cells\": {
        \"1\": [ // cell_id = 1
          { /* ... dados do primeiro bloco na célula 1 ... */ },
          { /* ... dados do segundo bloco na célula 1 ... */ }
        ],
        \"2\": [ /* ... blocos da célula 2 ... */ ]
      },
      \"available_layouts\": [ /* ... lista de layouts para seleção ... */ ],
      \"available_design_boxes\": [ /* ... lista de design boxes ... */ ]
    }
```

```json
    {
      \"cell_id\": 1,
      \"module\": \"system\", // Ou módulo do serviço
      \"title_system\": \"_block_title_custom_html\",
      \"title\": \"My HTML Block\",
      \"designbox_id\": 11, // Padrão
      \"type\": \"html\", // html, service, menu, rss, etc.
      \"content\": \"<h1>Hello World</h1>\", // Se type=html. Se type=service, a definição do serviço
      \"order\": 10, // Ordem dentro da célula
      \"cache_lifetime\": 0,
      \"visible_for_levels\": 2147483647
    }
```

```json
    {
      \"cells\": {
        \"1\": [ // cell_id = 1
          { \"block_id\": 101, \"order\": 1 }, // Bloco com ID 101 agora é o primeiro na célula 1
          { \"block_id\": 105, \"order\": 2 }
        ],
        \"2\": [
          { \"block_id\": 102, \"order\": 1 } // Bloco 102 movido para célula 2
        ]
      }
    }
```

```json
    {
      \"language\": \"en\",
      \"content\": \"## Novo Conteúdo Wiki\\nIsso é uma atualização.\",
      \"notes\": \"Atualização de conteúdo pelo admin.\"
    }
```

#### 2. Criar Novo Objeto de Página
*   **Endpoint:** `POST /api/v1/admin/page-builder/pages`
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_page`.

*   **Resposta (201 Created):** Detalhes da página criada.

#### 3. Obter Detalhes de um Objeto de Página
*   **Endpoint:** `GET /api/v1/admin/page-builder/pages/{pageObjectId}` (onde `{pageObjectId}` é `sys_objects_page.id` ou `sys_objects_page.object`)
*   **Resposta (200 OK):** Detalhes completos da página, incluindo uma lista de seus blocos (`sys_pages_blocks`) agrupados por célula de layout.

    *   Incluir `available_layouts` e `available_design_boxes` ajuda a UI do construtor de páginas.

#### 4. Atualizar Objeto de Página
*   **Endpoint:** `PUT /api/v1/admin/page-builder/pages/{pageObjectId}`
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_page` a serem atualizados.
*   **Resposta (200 OK):** Detalhes da página atualizada.

#### 5. Deletar Objeto de Página
*   **Endpoint:** `DELETE /api/v1/admin/page-builder/pages/{pageObjectId}`
*   **Lógica:** Verificar `deletable`. A exclusão deve também remover os `sys_pages_blocks` associados (CASCADE).
*   **Resposta (204 No Content).**

### Gerenciamento de Blocos de Página (`sys_pages_blocks`)

Os blocos são gerenciados no contexto de um objeto de página.

#### 1. Listar Blocos de uma Página (Geralmente incluído no GET da Página)
*   Pode não ser necessário um endpoint separado se `GET /.../pages/{pageObjectId}` já retorna os blocos.
*   Alternativa: `GET /api/v1/admin/page-builder/pages/{pageObjectId}/blocks`

#### 2. Adicionar Bloco a uma Página
*   **Endpoint:** `POST /api/v1/admin/page-builder/pages/{pageObjectId}/blocks`
*   **Corpo da Requisição (JSON):** Campos de `sys_pages_blocks`.

    *   Se `type` for `service`, o campo `content` conteria algo como:
        `\"content\": \"a:4:{s:6:\\\"module\\\";s:10:\\\"bx_persons\\\";s:6:\\\"method\\\";s:20:\\\"service_latest_added\\\";s:6:\\\"params\\\";a:1:{i:0;i:5;}s:5:\\\"class\\\";s:18:\\\"ModuleServiceBlock\\\";}\"` (Formato serializado PHP UNA, a API \"Deeper\" pode usar JSON para isso: `{\"module\": \"bx_persons\", \"method\": \"service_latest_added\", \"params\": [5]}`)
*   **Resposta (201 Created):** Detalhes do bloco criado.

#### 3. Obter Detalhes de um Bloco
*   **Endpoint:** `GET /api/v1/admin/page-builder/blocks/{blockId}`
*   **Resposta (200 OK):** Detalhes completos do bloco.

#### 4. Atualizar Bloco
*   **Endpoint:** `PUT /api/v1/admin/page-builder/blocks/{blockId}`
*   **Corpo da Requisição (JSON):** Campos de `sys_pages_blocks` a serem atualizados.
    *   Particularmente importante para atualizar `content` de blocos HTML ou Wiki, ou a definição de serviço/menu.
*   **Resposta (200 OK):** Detalhes do bloco atualizado.

#### 5. Atualizar Ordem/Célula dos Blocos em uma Página
*   **Endpoint:** `PUT /api/v1/admin/page-builder/pages/{pageObjectId}/blocks-layout`
*   **Propósito:** Permite reordenar blocos dentro das células ou mover blocos entre células.
*   **Corpo da Requisição (JSON):** Uma estrutura que representa o novo layout dos blocos.

*   **Lógica do Backend:** Itera sobre a estrutura, atualizando `cell_id` e `order` para cada `sys_pages_blocks.id`.
*   **Resposta (200 OK):** Mensagem de sucesso.

#### 6. Deletar Bloco
*   **Endpoint:** `DELETE /api/v1/admin/page-builder/blocks/{blockId}`
*   **Lógica:** Verificar `deletable`.
*   **Resposta (204 No Content).**

### Gerenciamento de Conteúdo de Blocos Wiki (`sys_pages_wiki_blocks`)

Se a funcionalidade de blocos Wiki for portada.

#### 1. Obter Conteúdo de um Bloco Wiki (última revisão ou específica)
*   **Endpoint:** `GET /api/v1/admin/page-builder/blocks/{blockId}/wiki-content`
*   **Query Parameters:** `revision` (Integer, Opcional), `language` (String, Opcional).
*   **Resposta (200 OK):** Conteúdo de `sys_pages_wiki_blocks`.

#### 2. Salvar Conteúdo de um Bloco Wiki (nova revisão)
*   **Endpoint:** `POST /api/v1/admin/page-builder/blocks/{blockId}/wiki-content`
*   **Corpo da Requisição (JSON):**

*   **Lógica:** Cria uma nova entrada em `sys_pages_wiki_blocks` com um número de revisão incrementado.
*   **Resposta (201 Created):** Detalhes da nova revisão.

### Considerações:

*   **Cache:** Alterações na estrutura das páginas ou no conteúdo dos blocos devem invalidar os caches de página correspondentes.
*   **Serviços de Módulos:** Para blocos do tipo `service`, a API de administração pode precisar de um endpoint para listar os serviços disponíveis nos módulos (ex: `GET /api/v1/admin/system/module-services?module_name=bx_persons`) para popular um seletor na UI do construtor de páginas.
*   **Validação:** Validar os tipos de blocos, os parâmetros dos serviços, etc.

Esta API de Page Builder é complexa, mas essencial para dar aos administradores controle sobre a aparência e estrutura do site \"Deeper\".