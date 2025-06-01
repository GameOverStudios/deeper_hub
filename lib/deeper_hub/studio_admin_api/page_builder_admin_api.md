# API de Administração: Construtor de Páginas (`sys_objects_page`, `sys_pages_blocks`, etc.)

Esta seção da API de Administração \"Deeper\" fornece endpoints para que administradores gerenciem a estrutura e o conteúdo das páginas da plataforma. Isso é análogo ao \"Page Builder\" ou \"Construtor de Páginas\" do Studio do UNA e interage principalmente com as tabelas:

*   `sys_objects_page`: Define as páginas principais, suas URIs, layouts, etc.
*   `sys_pages_layouts`: Define os templates de layout de página disponíveis (ex: uma coluna, duas colunas).
*   `sys_pages_cells` (implícito na lógica, se o UNA tiver uma tabela para células de layout, ou se for apenas um conceito no `sys_pages_layouts.cells_number`).
*   `sys_pages_blocks`: Define os blocos de conteúdo que compõem cada página, seu tipo, conteúdo e em qual célula do layout aparecem.
*   `sys_pages_design_boxes`: Define os estilos visuais (design boxes) aplicáveis aos blocos.
*   `sys_objects_menu` e `sys_menu_items`: Para gerenciar menus que podem ser atribuídos a páginas ou blocos.

**Autenticação:** Requerida (nível de administrador do sistema ou permissões específicas de gerenciamento de páginas).

## Objetivos da API do Construtor de Páginas:

*   CRUD para Definições de Página (`sys_objects_page`).
*   Listar e selecionar Layouts de Página (`sys_pages_layouts`).
*   CRUD para Blocos de Conteúdo (`sys_pages_blocks`) dentro de uma página.
*   Permitir a reordenação de blocos dentro das células do layout.
*   Atribuir Design Boxes (`sys_pages_design_boxes`) aos blocos.
*   Configurar o conteúdo dos blocos (ex: HTML para blocos HTML, chamadas de serviço para blocos de serviço, IDs de menu para blocos de menu).

## 1. Layouts de Página (`/api/v1/admin/page-builder/layouts`)

Interage com `sys_pages_layouts`.

### `GET /api/v1/admin/page-builder/layouts`
*   **Descrição:** Lista todos os layouts de página disponíveis.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_pages_layouts.id
          \"name\": \"one_column\",
          \"icon\": \"fas fa-square\", // Classe do ícone
          \"title\": \"One Column Layout\",
          \"template_path\": \"page_1_col.html\", // Caminho para o template (informativo)
          \"cells_number\": 1
        },
        {
          \"id\": 2,
          \"name\": \"two_columns_thin_wide\",
          \"icon\": \"fas fa-columns\",
          \"title\": \"Two Columns (Thin/Wide)\",
          \"template_path\": \"page_2_cols_thin_wide.html\",
          \"cells_number\": 2
        }
        // ... mais layouts
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_pages_design_boxes.id
          \"title\": \"Default (No Box)\",
          \"template_path\": \"designbox_0.html\"
        },
        {
          \"id\": 11,
          \"title\": \"Standard Box with Title\",
          \"template_path\": \"designbox_11.html\"
        }
        // ... mais design boxes
      ]
    }
```

```json
    {
      \"object_uri\": \"my-custom-page\", // Obrigatório, sys_objects_page.uri (que se torna o 'object')
      \"url_path\": \"custom/page-path\", // Obrigatório, sys_objects_page.url (o caminho na URL do site)
      \"title_system\": \"My Custom Page (System)\", // sys_objects_page.title_system
      \"title\": \"My Custom Page\", // sys_objects_page.title (pode ser chave de tradução)
      \"module_name\": \"system\", // Ou nome do módulo que \"possui\" a página
      \"layout_id\": 2, // FK para sys_pages_layouts.id
      \"cache_lifetime_seconds\": 3600, // sys_objects_page.cache_lifetime
      \"visible_for_levels_mask\": 2147483647, // Máscara de bits dos níveis ACL
      \"meta_title\": \"SEO Title for Custom Page\",
      \"meta_description\": \"SEO description.\",
      // ... outros campos de sys_objects_page
    }
```

```json
    {
      \"data\": {
        \"id\": 5, // sys_objects_page.id
        \"object_uri\": \"my-custom-page\",
        // ... outros campos de sys_objects_page ...
        \"blocks\": [ // Se preload=\"blocks\"
          {
            \"id\": 101, // sys_pages_blocks.id
            \"cell_id\": 1,
            \"title\": \"Welcome Block\",
            \"type\": \"html\",
            \"order_index\": 0
            // ... mais detalhes do bloco
          }
        ]
      }
    }
```

```json
    {
      \"cell_id\": 1, // Célula do layout onde o bloco será inserido
      \"module_name\": \"system\", // Módulo que fornece o bloco (ou 'system' para tipos genéricos)
      \"title_system\": \"New HTML Block (System)\",
      \"title\": \"My New HTML Block\", // Pode ser chave de tradução
      \"designbox_id\": 11, // FK para sys_pages_design_boxes.id
      \"type\": \"html\", // \"html\", \"service\", \"menu\", \"rss\", \"lang\", \"image\", \"raw\", \"custom\", \"wiki\"
      \"content\": \"<h1>Hello World</h1>\", // Conteúdo do bloco (para tipo 'html')
                                       // Para 'service': \"a:4:{s:6:\\\"module\\\";s:X:\\\"...\\\";s:6:\\\"method\\\";s:Y:\\\"...\\\";...}\" (string PHP serializada)
                                       // Para 'menu': nome do objeto de menu (sys_objects_menu.object)
      \"cache_lifetime_seconds\": 0,
      \"visible_for_levels_mask\": 2147483647,
      \"order_index\": 10 // Ordem dentro da célula
    }
```

```json
    {
      \"data\": {
        \"page_object_uri\": \"my-custom-page\",
        \"cells\": {
          \"1\": [ // cell_id = 1
            {
              \"id\": 101, // sys_pages_blocks.id
              \"title\": \"Welcome Block\",
              \"type\": \"html\",
              \"order_index\": 0,
              \"designbox_id\": 11
              // ...
            }
          ],
          \"2\": [ // cell_id = 2
            // ... blocos da célula 2
          ]
        }
      }
    }
```

```json
    {
      \"page_object_uri\": \"my-custom-page\",
      \"block_orders\": [
        { \"block_id\": 101, \"cell_id\": 1, \"order_index\": 1 },
        { \"block_id\": 105, \"cell_id\": 1, \"order_index\": 0 },
        { \"block_id\": 102, \"cell_id\": 2, \"order_index\": 0 }
      ]
    }
```

*(Endpoints para CRUD de layouts são menos comuns, pois geralmente são definidos pelo tema/sistema base).*

## 2. Design Boxes (`/api/v1/admin/page-builder/design-boxes`)

Interage com `sys_pages_design_boxes`.

### `GET /api/v1/admin/page-builder/design-boxes`
*   **Descrição:** Lista todos os design boxes (estilos de bloco) disponíveis.
*   **Resposta de Sucesso (200 OK):**

*(Endpoints para CRUD de design boxes são menos comuns).*

## 3. Definições de Página (`/api/v1/admin/page-builder/pages`)

Interage com `sys_objects_page`.

### `POST /api/v1/admin/page-builder/pages`
*   **Descrição:** Cria uma nova definição de página.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Detalhes da página criada (incluindo seu `id` de `sys_objects_page`).

### `GET /api/v1/admin/page-builder/pages`
*   **Descrição:** Lista todas as definições de página.
*   **Query Parameters:** `module_name`, `search_term` (em `title` ou `object_uri`), `page`, `per_page`.
*   **Resposta de Sucesso (200 OK):** Lista de páginas.

### `GET /api/v1/admin/page-builder/pages/{page_object_uri_or_id}`
*   **Descrição:** Obtém detalhes de uma definição de página específica (pelo seu `object_uri` ou `id`).
*   **Query Parameters:** `preload` (ex: `\"blocks\"`)
*   **Resposta de Sucesso (200 OK):** Detalhes da página. Se `preload=\"blocks\"`, inclui a lista de blocos associados.

### `PUT /api/v1/admin/page-builder/pages/{page_object_uri_or_id}`
*   **Descrição:** Atualiza uma definição de página existente.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Detalhes da página atualizada.

### `DELETE /api/v1/admin/page-builder/pages/{page_object_uri_or_id}`
*   **Descrição:** Deleta uma definição de página e todos os seus blocos associados (devido a FKs ou lógica da aplicação).
*   **Resposta de Sucesso (204 No Content).**

## 4. Blocos de Página (`/api/v1/admin/page-builder/pages/{page_object_uri}/blocks`)

Interage com `sys_pages_blocks`, sempre no contexto de uma página específica. `{page_object_uri}` é o `sys_objects_page.object` (ou `uri` na tabela).

### `POST /api/v1/admin/page-builder/pages/{page_object_uri}/blocks`
*   **Descrição:** Adiciona um novo bloco a uma página.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Detalhes do bloco criado (incluindo seu `id` de `sys_pages_blocks`).

### `GET /api/v1/admin/page-builder/pages/{page_object_uri}/blocks`
*   **Descrição:** Lista todos os blocos de uma página específica, agrupados por `cell_id` e ordenados por `order_index`.
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/admin/page-builder/blocks/{block_id}`
*   **Descrição:** Obtém detalhes de um bloco específico pelo seu ID.
*   **Resposta de Sucesso (200 OK):** Detalhes completos do bloco, incluindo seu `content` ou `text`.

### `PUT /api/v1/admin/page-builder/blocks/{block_id}`
*   **Descrição:** Atualiza um bloco existente.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (incluindo `cell_id`, `order_index`, `title`, `type`, `content`, `designbox_id`, etc.).
*   **Resposta de Sucesso (200 OK):** Detalhes do bloco atualizado.

### `DELETE /api/v1/admin/page-builder/blocks/{block_id}`
*   **Descrição:** Deleta um bloco de uma página.
*   **Resposta de Sucesso (204 No Content).**

### `POST /api/v1/admin/page-builder/blocks/reorder`
*   **Descrição:** Permite reordenar múltiplos blocos dentro de uma página ou mover entre células.
*   **Corpo da Requisição (JSON):** Uma lista de objetos especificando o `block_id`, novo `cell_id` e novo `order_index`.

*   **Lógica do Backend:** Atualiza os campos `cell_id` e `order` para cada bloco na tabela `sys_pages_blocks`.
*   **Resposta de Sucesso (200 OK):** Status da operação.

## 5. Gerenciamento de Menus (Reutilização/Referência)

A API de Administração de Menus será detalhada separadamente (ex: em `menus_admin_api.md`), mas é referenciada aqui porque blocos do tipo \"menu\" usarão objetos de menu.

*   `GET /api/v1/admin/menus` (para listar menus disponíveis para seleção em um bloco)
*   CRUD para `sys_objects_menu` e `sys_menu_items`.

## Considerações para API do Construtor de Páginas:

*   **Conteúdo de Bloco de Serviço:** Para blocos do tipo `service`, o campo `content` armazena uma string PHP serializada no UNA. A API \"Deeper\" pode:
    *   Receber e armazenar essa string como está. A UI de admin precisaria de uma forma de construir essa string.
    *   Ou, a API pode ter uma estrutura JSON mais amigável para definir chamadas de serviço, que o backend Elixir então traduziria para o formato serializado do UNA para armazenamento (ou para um novo formato se \"Deeper\" não executar serviços PHP). Para o MVP, armazenar como está pode ser mais simples.
*   **Blocos de Texto (Wiki):** Blocos do tipo `wiki` ou `text` usam a tabela `sys_pages_wiki_blocks` no UNA para conteúdo versionado e multi-idioma. A API de admin precisará de endpoints para gerenciar esse conteúdo textual (ex: `PUT /api/v1/admin/page-builder/blocks/{block_id}/text-content`).
*   **Visualização (Preview):** A API de admin não renderiza a página, mas fornece os dados. A interface de admin pode ter uma funcionalidade de preview que usa a API pública para renderizar a página com as alterações antes de salvar.
*   **Cache:** Alterações em páginas ou blocos devem invalidar os caches de página relevantes.

Esta API fornecerá uma base poderosa para administrar a estrutura visual e de conteúdo das páginas na plataforma \"Deeper\".