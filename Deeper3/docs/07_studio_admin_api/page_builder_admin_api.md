# API de Administração: Gerenciamento do Construtor de Páginas

Endpoints da API para administradores gerenciarem a estrutura e o conteúdo das páginas da plataforma \"Deeper\". Isso é análogo ao Page Builder (Construtor de Páginas) do UNA Studio, que interage com as tabelas `sys_objects_page`, `sys_pages_blocks`, `sys_pages_layouts`, etc.

**Permissões:** Todos os endpoints aqui requerem um papel de administrador do site com plenos poderes sobre o design e estrutura das páginas.

## Contexto do Construtor de Páginas no UNA

O sistema de páginas do UNA permite:
*   Definir diferentes **Layouts de Página** (`sys_pages_layouts`): Estruturas com colunas e células (ex: 2 colunas, 3 colunas, cabeçalho-corpo-rodapé).
*   Definir **Tipos de Design Box** (`sys_pages_design_boxes`): Estilos visuais para os contêineres dos blocos.
*   Definir **Tipos de Página** (`sys_pages_types`): Templates gerais para páginas (ex: página padrão, página de erro, página inicial).
*   Criar e gerenciar **Objetos de Página** (`sys_objects_page`): Instâncias de páginas com URI, título, layout associado, configurações de cache, SEO, etc.
*   Adicionar e configurar **Blocos de Página** (`sys_pages_blocks`): Unidades de conteúdo (HTML, Menu, RSS, Serviço de Módulo) que são colocadas nas células dos layouts das páginas.

A API de administração \"Deeper\" fornecerá controle sobre esses elementos.

## Endpoints para Layouts, Design Boxes e Tipos de Página
(Estes são geralmente mais estáticos e definidos pelo sistema ou temas, mas a API pode permitir listagem e, opcionalmente, CRUD para flexibilidade máxima)

### 1. Gerenciamento de Layouts de Página (`sys_pages_layouts`)
*   **`GET /admin/page-builder/layouts`**: Listar layouts disponíveis.
    *   Resposta: `[{ \"id\": 1, \"name\": \"col2_1_2\", \"icon\": \"layout-icon.png\", \"title\": \"Duas Colunas (1/3 + 2/3)\", \"template\": \"layout_2_col_1_2.html\", \"cells_number\": 2 }, ...]`
*   (Opcional) `POST`, `PUT /admin/page-builder/layouts/{id}`, `DELETE /admin/page-builder/layouts/{id}` para CRUD completo.

### 2. Gerenciamento de Tipos de Design Box (`sys_pages_design_boxes`)
*   **`GET /admin/page-builder/design-boxes`**: Listar design boxes disponíveis.
    *   Resposta: `[{ \"id\": 11, \"title\": \"Box Padrão (com título)\", \"template\": \"designbox_11.html\" }, ...]`
*   (Opcional) `POST`, `PUT /admin/page-builder/design-boxes/{id}`, `DELETE /admin/page-builder/design-boxes/{id}`.

### 3. Gerenciamento de Tipos de Página (`sys_pages_types`)
*   **`GET /admin/page-builder/page-types`**: Listar tipos de página.
    *   Resposta: `[{ \"id\": 1, \"title\": \"Página Padrão\", \"template\": \"page_type_standard.html\" }, ...]`
*   (Opcional) `POST`, `PUT /admin/page-builder/page-types/{id}`, `DELETE /admin/page-builder/page-types/{id}`.

## Endpoints para Objetos de Página (`sys_objects_page`)

### 1. Listar Todas as Páginas (Objetos de Página)

*   **`GET /admin/page-builder/pages`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `q` (buscar por título/URI), `module_name`, `page`, `per_page`, `sort_by`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de objetos de página.

```json
    {
      \"data\": [
        {
          \"id\": 10,
          \"object\": \"index\", // Nome único do objeto de página
          \"uri\": \"home\",
          \"title_system\": \"_sys_page_title_home\",
          \"title\": \"Página Inicial\",
          \"module_name\": \"system\",
          \"layout_id\": 1,
          \"layout_name\": \"col1\", // Incluído via JOIN
          \"cache_lifetime\": 0,
          \"visible_for_levels_mask\": 2147483647
        }
        // ...
      ]
    }
```

```json
    {
      \"object\": \"my_custom_page\",
      \"uri\": \"custom-page\",
      \"title_system\": \"_custom_page_title\",
      \"title\": \"Minha Página Customizada\",
      \"module_name\": \"custom\", // Ou um módulo específico
      \"layout_id\": 2, // ID de um layout existente
      \"visible_for_levels_mask\": 2147483647,
      \"cache_lifetime\": 3600,
      \"meta_title\": \"Título SEO\",
      \"meta_description\": \"Descrição SEO\",
      \"inj_head\": \"<script>console.log('head');</script>\"
    }
```

```json
    {
      \"data\": [ // Poderia ser um mapa { \"cell_1\": [...blocks...], \"cell_2\": [...blocks...] }
        {
          \"id\": 101,
          \"page_object\": \"home\", // Referência ao sys_objects_page.object
          \"cell_id\": 1, // Célula do layout onde o bloco está
          \"module_name\": \"system\",
          \"title_system\": \"_sys_block_title_splash\",
          \"title\": \"Bem-vindo!\",
          \"designbox_id\": 11,
          \"type\": \"html\", // \"html\", \"service\", \"menu\", \"rss\", \"image\", \"lang\", \"raw\"
          \"content\": \"<h1>Olá Mundo!</h1>\", // Para tipo 'html', 'raw'
          // \"service_call\": {\"module\": \"bx_persons\", \"method\": \"service_latest_profiles\", \"params\": [5]}, // Para tipo 'service' (formato JSON)
          \"cache_lifetime\": 0,
          \"order_index\": 0,
          \"active\": 1
        }
      ]
    }
```

```json
    {
      \"cell_id\": 2,
      \"module_name\": \"deeper_articles\",
      \"title\": \"Últimos Artigos\",
      \"designbox_id\": 13,
      \"type\": \"service\",
      \"content\": \"{\\\"module\\\":\\\"deeper_articles\\\",\\\"method\\\":\\\"service_latest_articles_block\\\",\\\"params\\\":[3]}\", // Para tipo 'service', content é o JSON da chamada de serviço
      \"order_index\": 1
    }
```

```json
    {
      \"ordered_block_ids\": [105, 102, 108] // Lista de IDs de blocos na nova ordem para esta célula
    }
```

### 2. Criar Nova Página (Objeto de Página)

*   **`POST /admin/page-builder/pages`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_page`.

*   **Resposta de Sucesso (201 Created):** Objeto da página criada.

### 3. Obter Detalhes de uma Página Específica

*   **`GET /admin/page-builder/pages/{page_object_or_id}`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include=layout_details,blocks`.
    *   Se `include=blocks`, retorna também a lista de blocos desta página.
*   **Resposta de Sucesso (200 OK):** Objeto da página.

### 4. Atualizar uma Página

*   **`PUT /admin/page-builder/pages/{page_object_or_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Campos a atualizar.
*   **Resposta de Sucesso (200 OK):** Objeto da página atualizado.

### 5. Excluir uma Página
    (Cuidado: O que acontece com os blocos associados? Devem ser excluídos por CASCADE ou desassociados?)
*   **`DELETE /admin/page-builder/pages/{page_object_or_id}`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:** Remove a página e, idealmente, seus blocos (`sys_pages_blocks`) associados.
*   **Resposta de Sucesso (200 OK / 204 No Content):**

## Endpoints para Blocos de Página (`sys_pages_blocks`)
(Geralmente aninhados sob uma página específica)

### 1. Listar Blocos de uma Página

*   **`GET /admin/page-builder/pages/{page_object_or_id}/blocks`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):** Lista de blocos da página, possivelmente agrupados por `cell_id`.

### 2. Adicionar Novo Bloco a uma Página

*   **`POST /admin/page-builder/pages/{page_object_or_id}/blocks`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Campos de `sys_pages_blocks`.

*   **Resposta de Sucesso (201 Created):** Objeto do bloco criado.

### 3. Obter Detalhes de um Bloco Específico

*   **`GET /admin/page-builder/blocks/{block_id}`** (Rota não aninhada para acesso direto)
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):** Objeto do bloco.

### 4. Atualizar um Bloco

*   **`PUT /admin/page-builder/blocks/{block_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Campos a atualizar (ex: `title`, `content`, `cell_id`, `order_index`, `designbox_id`, `active`).
*   **Resposta de Sucesso (200 OK):** Objeto do bloco atualizado.

### 5. Excluir um Bloco

*   **`DELETE /admin/page-builder/blocks/{block_id}`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK / 204 No Content):**

### 6. Reordenar Blocos dentro de uma Célula de Página

*   **`PUT /admin/page-builder/pages/{page_object_or_id}/cells/{cell_id}/blocks/order`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Ação do Backend:** Atualiza o campo `order_index` dos blocos especificados.
*   **Resposta de Sucesso (200 OK):** `{ \"message\": \"Ordem dos blocos atualizada.\" }`

## Considerações para Repositórios e Contextos:

*   **`Deeper.SystemCore.PageBuilderRepo` (ou similar):**
    *   CRUD para `sys_objects_page`, `sys_pages_blocks`, `sys_pages_layouts`, `sys_pages_design_boxes`, `sys_pages_types`.
    *   Funções para listar blocos por página e célula.
    *   Função para reordenar blocos.
*   **`Deeper.SystemCore.PageBuilder` (Contexto/Serviço):**
    *   Verificará permissões de admin.
    *   Orquestrará operações (ex: ao criar uma página, pode permitir a adição de blocos iniciais).
    *   Validará a consistência dos dados (ex: `cell_id` existe no layout da página).
    *   **Importante:** Ao atualizar blocos do tipo \"service\", o campo `content` (que armazena a chamada de serviço como JSON) precisa ser validado (o módulo e método existem? os parâmetros são válidos?). Esta validação pode ser complexa e exigir que o Contexto possa inspecionar ou interagir com os módulos de conteúdo referenciados.
*   **Cache:** Alterações na estrutura da página ou nos blocos (especialmente aqueles com cache) devem invalidar os caches de página relevantes. O Contexto `PageBuilder` pode disparar eventos para o sistema de cache.

Esta API de administração do Construtor de Páginas é complexa, mas essencial para permitir a customização da interface da plataforma \"Deeper\" de forma dinâmica, similar ao Studio do UNA.