# Documentação Deeper Studio API: Construtor de Páginas

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento de páginas do sistema, incluindo a criação e modificação de \"Objetos de Página\" (`sys_objects_page`), a gestão de \"Blocos de Página\" (`sys_pages_blocks`), e a configuração de \"Layouts de Página\" (`sys_pages_layouts`).

**Objetivo Principal:** Permitir que administradores criem novas páginas, modifiquem páginas existentes, adicionem, removam, reordenem e configurem blocos de conteúdo dentro dessas páginas, através de uma interface de administração visual ou baseada em formulários.

## Tabelas Relevantes (já definidas e migradas):

*   `sys_objects_page`: Define cada página única.
*   `sys_pages_layouts`: Define as estruturas de layout disponíveis (colunas, etc.).
*   `sys_pages_types`: Define tipos de página (embora menos usado para configuração direta pelo admin no UNA Studio, mais para a lógica interna).
*   `sys_pages_blocks`: Define os blocos de conteúdo dentro de cada página.
*   `sys_pages_design_boxes`: Define os estilos visuais (design boxes) para os blocos.
*   `sys_menu_objects` (para `sys_objects_page.submenu` e `sys_pages_blocks.submenu`).
*   Tabelas de tradução para títulos e conteúdos de blocos.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.PageEngine.PagesRepo`: Precisará de funções CRUD completas para `sys_objects_page` e `sys_pages_blocks`.
*   `Deeper.PageEngine.LayoutsRepo`: Funções para listar e obter `sys_pages_layouts`. (Pode ser parte do `PagesRepo`).
*   `Deeper.PageEngine.DesignBoxesRepo`: Funções para listar `sys_pages_design_boxes`. (Pode ser parte do `PagesRepo`).
*   `Deeper.SystemCore.LocalizationRepo`: Para lidar com títulos e conteúdos traduzíveis.

## Endpoints da API de Administração para o Construtor de Páginas (`/api/v1/admin/builder/pages` e `/api/v1/admin/builder/layouts` etc.):

---
### Gerenciamento de Objetos de Página (`/api/v1/admin/builder/pages`)

#### 1. Listar Todas as Páginas

*   **Endpoint:** `GET /api/v1/admin/builder/pages`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `filter_module`, `filter_uri_like`, `filter_title_like`, `sort_by`. `lang` para traduções.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"object_name\": \"bx_persons_home\", // sys_objects_page.object
          \"uri\": \"persons-home\", // sys_objects_page.uri
          \"title\": \"Página Inicial de Pessoas\", // Traduzido de sys_objects_page.title
          \"module\": \"bx_persons\",
          \"layout_id\": 2,
          \"deletable\": true
        }
        // ... outras páginas ...
      ]
      // \"pagination\": { ... }
    }
```

```json
    {
      \"object_name\": \"my_custom_page_object\", // Deve ser único
      \"uri\": \"custom-page-uri\", // Deve ser único
      \"title_key\": \"_my_custom_page_title\", // Chave para sys_localization_keys
      \"module\": \"meu_modulo_custom\", // Módulo ao qual pertence
      \"layout_id\": 1, // ID de um sys_pages_layouts existente
      \"submenu_object_name\": null, // Opcional: nome de um sys_objects_menu
      \"visible_for_levels_mask\": 2147483647,
      \"cache_lifetime_seconds\": 0,
      \"deletable\": true
      // Outros campos de sys_objects_page
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"object_name\": \"bx_persons_home\",
        \"uri\": \"persons-home\",
        \"title_key\": \"_bx_persons_home_title\",
        \"title_translated\": \"Página Inicial de Pessoas\",
        \"module\": \"bx_persons\",
        \"layout_id\": 2,
        \"layout_name\": \"layout_2_columns_thin_right\", // Do JOIN com sys_pages_layouts
        \"submenu_object_name\": \"bx_persons_submenu\",
        \"visible_for_levels_mask\": 2147483647,
        \"cache_lifetime_seconds\": 3600,
        // ... outros campos de sys_objects_page ...
        \"blocks\": [ // Lista de blocos desta página, ordenados
          {
            \"block_id\": 101, // sys_pages_blocks.id
            \"cell_id\": 1,
            \"title_key\": \"_bx_persons_block_latest_title\",
            \"title_translated\": \"Últimos Membros\",
            \"type\": \"service\",
            \"content_definition\": \"a:3:{s:6:\\\"module\\\";s:10:\\\"bx_persons\\\";s:6:\\\"method\\\";s:14:\\\"service_latest\\\";s:6:\\\"params\\\";a:1:{s:5:\\\"count\\\";i:5;}}\", // Conteúdo bruto
            \"designbox_id\": 11,
            \"order\": 0
            // ... outros campos de sys_pages_blocks ...
          }
          // ... outros blocos ...
        ]
      }
    }
```

```json
    {
      \"cell_id\": 1,
      \"module\": \"bx_persons\", // Módulo que fornece o bloco (ou 'system' para HTML/Custom)
      \"title_key\": \"_my_custom_block_title\",
      \"type\": \"html\", // html, service, menu, rss, etc.
      \"content_definition\": \"<h1>Olá Mundo Customizado</h1>\", // Para HTML, ou definição de serviço/menu
      \"designbox_id\": 1,
      \"cache_lifetime_seconds\": 0,
      \"order\": 10,
      \"active\": true,
      \"active_api\": true // Se o bloco deve ser processado/retornado pela API Deeper
      // ... outros campos de sys_pages_blocks ...
    }
```

```json
    {
      \"cell_1_order\": [101, 103, 105],
      \"cell_2_order\": [102, 104]
    }
```

#### 2. Criar Nova Página

*   **Endpoint:** `POST /api/v1/admin/builder/pages`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Retorna a página criada.
*   **Lógica do Backend:** Insere em `sys_objects_page`. Cria a string de tradução para `title_key` se não existir.

#### 3. Obter Detalhes de uma Página (incluindo seus blocos)

*   **Endpoint:** `GET /api/v1/admin/builder/pages/{page_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `lang`.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Busca de `sys_objects_page` e faz JOIN ou busca separada de `sys_pages_blocks` para `object = page_object_name`.

#### 4. Atualizar uma Página

*   **Endpoint:** `PUT /api/v1/admin/builder/pages/{page_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_page` a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Retorna a página atualizada.

#### 5. Deletar uma Página

*   **Endpoint:** `DELETE /api/v1/admin/builder/pages/{page_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Verifica `deletable`. Deleta de `sys_objects_page`. `ON DELETE CASCADE` (se definido) ou uma deleção manual removeria os blocos de `sys_pages_blocks`.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Blocos de Página (`/api/v1/admin/builder/pages/{page_object_name}/blocks`)

#### 6. Listar Blocos de uma Página (já incluído no GET da página)

#### 7. Adicionar Novo Bloco a uma Página

*   **Endpoint:** `POST /api/v1/admin/builder/pages/{page_object_name}/blocks`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Retorna o bloco criado.
*   **Lógica do Backend:** Insere em `sys_pages_blocks` associando ao `page_object_name`.

#### 8. Obter Detalhes de um Bloco Específico

*   **Endpoint:** `GET /api/v1/admin/builder/blocks/{block_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do bloco.

#### 9. Atualizar um Bloco

*   **Endpoint:** `PUT /api/v1/admin/builder/blocks/{block_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_pages_blocks` a serem atualizados.
    *   Particularmente importante para `content_definition` (ex: editar HTML, mudar serviço), `cell_id`, `order`.
*   **Resposta de Sucesso (200 OK):** Retorna o bloco atualizado.

#### 10. Reordenar Blocos em uma Página

*   **Endpoint:** `PUT /api/v1/admin/builder/pages/{page_object_name}/blocks/reorder`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Lista de IDs de blocos na nova ordem, possivelmente agrupados por `cell_id`.

*   **Resposta de Sucesso (200 OK).**
*   **Lógica do Backend:** Atualiza o campo `order` (e possivelmente `cell_id`) dos blocos em `sys_pages_blocks`.

#### 11. Deletar um Bloco

*   **Endpoint:** `DELETE /api/v1/admin/builder/blocks/{block_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Recursos do Construtor (Layouts, Tipos de Página, Design Boxes)

Estes são geralmente apenas para leitura pela API de Admin, pois são definidos no sistema.

#### 12. Listar Layouts de Página

*   **Endpoint:** `GET /api/v1/admin/builder/layouts`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_pages_layouts` (id, name, title_key, cells_number, icon).

#### 13. Listar Tipos de Página

*   **Endpoint:** `GET /api/v1/admin/builder/page-types`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_pages_types` (id, title_key, template).

#### 14. Listar Design Boxes

*   **Endpoint:** `GET /api/v1/admin/builder/design-boxes`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_pages_design_boxes` (id, title_key, template).

## Considerações:

*   **Validação:** Entradas para nomes de objetos (`object_name`, `uri`) devem ser únicas e seguir padrões. IDs referenciados (layout_id, designbox_id) devem existir.
*   **Conteúdo de Blocos de Serviço:** Ao criar/editar um bloco do tipo `service`, a `content_definition` precisa ser uma string que o `PagesRepo` da API \"Deeper\" possa parsear para extrair `module`, `method`, e `params` para a lógica de pré-busca de dados. O formato serializado PHP do UNA é uma opção, ou um formato JSON mais limpo.
*   **Traduções:** Títulos de páginas e blocos são chaves de tradução. A API de Admin pode precisar de endpoints para gerenciar as strings de tradução associadas (integrando com a API de Localização de Admin).
*   **Impacto Visual:** Alterações feitas aqui têm impacto direto na aparência e estrutura do site para os usuários finais.

Esta API de Construtor de Páginas fornece as ferramentas para que uma interface de administração possa recriar a funcionalidade de construção de páginas do UNA Studio.