# Documentação Deeper: Endpoints da API para Objetos de Página e Blocos

Este documento especifica os endpoints RESTful da API \"Deeper\" para obter as definições de \"Objetos de Página\" e seus blocos de conteúdo associados. Isso permite que um cliente reconstrua a estrutura de uma página do UNA.

## Convenções Gerais:

*   **Base URL:** `/api/v1`
*   **Autenticação:** Estes endpoints podem ser públicos, mas a visibilidade dos blocos retornados será filtrada com base no nível de ACL do usuário autenticado (se um token JWT for fornecido).
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme definido em `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Obter Definição de Página

*   **Endpoint:** `GET /pages/definition`
*   **Status:** Público (com filtragem de blocos baseada em ACL se autenticado)
*   **Descrição:** Retorna a definição completa de uma página, incluindo seus metadados e a lista de seus blocos ativos e visíveis para o usuário. A página é identificada por um query parameter (`uri` ou `object_name`).
*   **Query Parameters:**
    *   `uri=<page_uri>`: (Obrigatório, OU `object_name`) O URI da página (ex: `/m/persons/home`).
    *   `object_name=<page_object_name>`: (Obrigatório, OU `uri`) O nome do objeto de página (ex: `persons_home`).
    *   `context_profile_id=<id>`: (Opcional) ID do perfil de contexto (se a página for, por exemplo, a página de um perfil específico). Isso pode influenciar quais blocos são visíveis ou como os blocos de serviço obtêm seus dados.
*   **Cabeçalhos da Requisição (Opcional):**
    *   `Authorization: Bearer <jwt_token>`: Se fornecido, o backend usará o `IDLevel` do token para filtrar blocos com base em `visible_for_levels`.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"id\": 10, // sys_objects_page.id
        \"object\": \"persons_home\",
        \"uri\": \"m/persons/home\",
        \"title\": \"Pessoas\", // sys_objects_page.title
        \"module\": \"bx_persons\",
        \"layout_id\": 2,
        \"layout_name\": \"layout_2_columns\",
        \"layout_template\": \"layout_2_columns.html\",
        \"layout_cells_number\": 2,
        \"submenu_object\": \"bx_persons_submenu_member\", // Nome do objeto de menu para o submenu da página
        \"meta_title\": \"Comunidade de Pessoas\",
        \"meta_description\": \"Navegue pelos perfis de nossa comunidade.\",
        \"meta_keywords\": \"pessoas, perfis, comunidade\",
        \"cache_lifetime\": 0,
        // ... outros campos relevantes de sys_objects_page ...
        \"blocks\": [
          {
            \"id\": 101, // sys_pages_blocks.id
            \"cell_id\": 1,
            \"module\": \"bx_persons\",
            \"title\": \"Novos Perfis\", // sys_pages_blocks.title
            \"designbox_id\": 11,
            \"designbox_template\": \"designbox_11.html\", // Template do design box
            \"type\": \"service\", // sys_pages_blocks.type
            \"content\": { // Conteúdo interpretado/parseado
              \"module\": \"bx_persons\",
              \"method\": \"service_latest_profiles\", // Para blocos tipo 'service'
              \"params\": {\"count\": 5, \"context_profile_id\": null} // Params do serviço
            },
            \"async\": false, // sys_pages_blocks.async (convertido para booleano)
            \"tabs\": false,  // sys_pages_blocks.tabs (convertido para booleano)
            \"order\": 1     // sys_pages_blocks.order
            // ... outros campos relevantes de sys_pages_blocks ...
          },
          {
            \"id\": 102,
            \"cell_id\": 2,
            \"module\": \"system\",
            \"title\": \"Bem-vindo!\",
            \"designbox_id\": 1,
            \"designbox_template\": \"designbox_bare.html\",
            \"type\": \"html\",
            \"content\": \"<h1>Olá Mundo!</h1><p>Este é um bloco HTML.</p>\", // Conteúdo HTML direto
            \"async\": false,
            \"tabs\": false,
            \"order\": 1
          }
          // ... mais blocos visíveis para o usuário ...
        ]
      }
    }
```

*   **Erros Comuns:**
    *   `400 Bad Request`: Se nem `uri` nem `object_name` forem fornecidos.
    *   `404 Not Found`: Se a página identificada não for encontrada.
*   **Lógica do Backend (Controller):**
    1.  Validar query parameters: garantir que `uri` ou `object_name` esteja presente.
    2.  Extrair `IDLevel` do usuário do token JWT, se presente (default para nível de visitante se não houver token).
    3.  Chamar `PagesRepo.get_page_definition/2` passando o identificador e o tipo de identificador.
    4.  Filtrar a lista de `blocks` retornada pelo `PagesRepo` com base no `IDLevel` do usuário e nas colunas `visible_for_levels` e `hidden_on` de cada bloco. (Esta lógica de filtragem pode residir no `PagesRepo` ou no controller/serviço).
    5.  Garantir que o campo `content` dos blocos seja formatado adequadamente (ex: parsear strings serializadas de PHP para JSON/mapas para blocos de serviço).
    6.  Retornar a estrutura JSON.

### Opcional: Endpoints para Listar Layouts, Design Boxes, Tipos de Página

Se for útil para o cliente ter conhecimento prévio desses elementos (por exemplo, para um construtor de páginas no cliente ou para ferramentas de desenvolvimento), endpoints adicionais podem ser criados:

*   **`GET /pages/layouts`**
    *   Retorna: Lista de todos os layouts de `sys_pages_layouts`.
    *   Lógica: Chama `PagesRepo.list_page_layouts/0`.

*   **`GET /pages/design-boxes`**
    *   Retorna: Lista de todos os design boxes de `sys_pages_design_boxes`.
    *   Lógica: Chama `PagesRepo.list_design_boxes/0`.

*   **`GET /pages/types`**
    *   Retorna: Lista de todos os tipos de página de `sys_pages_types`.
    *   Lógica: Chama `PagesRepo.list_page_types/0`.

### Considerações:

*   **Parse do Conteúdo do Bloco de Serviço:** A forma como o campo `content` para blocos do tipo `service` é parseado e retornado é crucial. Retornar um mapa estruturado (`%{module: ..., method: ..., params: ...}`) é o ideal.
*   **Dados para Blocos de Serviço:** Este endpoint retorna a *definição* da página e dos blocos. Para blocos de serviço, o cliente precisará fazer chamadas subsequentes a outros endpoints da API \"Deeper\" para buscar os dados reais que o serviço forneceria. Esses endpoints de \"dados de serviço\" serão definidos conforme os módulos de conteúdo são implementados (ex: em `03_content_modules/`).
*   **Segurança e Visibilidade:** A lógica de filtragem de blocos baseada em `visible_for_levels` e `hidden_on` (que pode depender do tipo de dispositivo - mobile/desktop, o que é mais difícil para uma API pura determinar sem input do cliente) deve ser cuidadosamente implementada para respeitar as configurações de privacidade e visibilidade do UNA.