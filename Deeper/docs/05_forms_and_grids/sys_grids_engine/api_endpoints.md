# Documentação Deeper: Endpoints da API para Motor de Grades

Este documento especifica os endpoints da API RESTful \"Deeper\" para interagir com o motor de grades de dados.

## Endpoints Principais

### 1. Obter Definição de uma Grade

*   **Endpoint:** `GET /api/v1/grids/{grid_object_name}/definition`
*   **Propósito:** Retorna a definição completa de uma grade, incluindo informações do objeto da grade, seus campos (colunas) e ações disponíveis.
*   **Autenticação:** Opcional/Obrigatória. A visibilidade da grade em si é verificada com base no `visible_for_levels` de `sys_objects_grid` e no `IDLevel` do usuário autenticado.
*   **Parâmetros de URL:**
    *   `{grid_object_name}` (String, Obrigatório): O nome do objeto de grade (campo `object` da tabela `sys_objects_grid`), por exemplo, `bx_persons_administration`.
*   **Query Parameters:**
    *   `lang` (String, Opcional): Código do idioma (ex: `en`, `pt-BR`) para tradução dos títulos dos campos e ações.
*   **Resposta de Sucesso (200 OK):**
    Um objeto JSON contendo a definição da grade.

```json
    {
      \"definition\": { // Dados de sys_objects_grid
        \"object\": \"bx_persons_administration\",
        \"source_type\": \"Sql\",
        // \"source\": \"SELECT id, fullname, email, status FROM bx_persons_data\", // Pode ser omitido da resposta se for sensível
        \"table_name\": \"bx_persons_data\",
        \"field_id\": \"id\",
        \"field_order\": \"added DESC\",
        \"paginate_per_page\": 20,
        \"paginate_get_start\": \"offset\",
        \"paginate_get_per_page\": \"limit\",
        \"filter_fields\": \"fullname,email\",
        \"filter_get\": \"q\", // Nome do query param para filtro geral
        \"sorting_fields\": \"fullname,email,added,status\",
        \"show_total_count\": 1
        // ... outros campos de sys_objects_grid ...
      },
      \"fields\": [ // Lista de sys_grid_fields
        {
          \"name\": \"id\",
          \"title\": \"ID\", // Título resolvido/traduzido
          \"width\": \"50px\",
          \"order\": 1
          // ... outros campos de sys_grid_fields ...
        },
        {
          \"name\": \"fullname\",
          \"title\": \"Full Name\",
          \"width\": \"auto\",
          \"order\": 2
        },
        {
          \"name\": \"email\",
          \"title\": \"Email\",
          \"width\": \"200px\",
          \"order\": 3
        }
        // ... mais campos ...
      ],
      \"actions\": [ // Lista de sys_grid_actions
        {
          \"type\": \"single\",
          \"name\": \"edit_person\",
          \"title\": \"Edit\", // Título resolvido/traduzido
          \"icon\": \"pencil-outline\",
          \"api_endpoint\": \"PUT /api/v1/profiles/{id}\", // Placeholder {id} será substituído
          \"api_method\": \"PUT\", // Ou pode ser um evento que o cliente trata para navegação/modal
          \"id_placeholder_field\": \"id\" // Campo da linha a ser usado no placeholder
        },
        {
          \"type\": \"single\",
          \"name\": \"delete_person\",
          \"title\": \"Delete\",
          \"icon\": \"trash-outline\",
          \"confirm\": 1,
          \"api_endpoint\": \"DELETE /api/v1/profiles/{id}\",
          \"api_method\": \"DELETE\",
          \"id_placeholder_field\": \"id\"
        },
        {
          \"type\": \"independent\",
          \"name\": \"add_person\",
          \"title\": \"Add New Person\",
          \"icon\": \"add-circle-outline\",
          \"api_endpoint\": \"EVENT:navigate_to_add_person_form\" // Cliente lida com este evento
        }
        // ... mais ações ...
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"fullname\": \"Alice Wonderland\",
          \"email\": \"alice@example.com\",
          \"status_key\": \"_bx_persons_status_active\", // Se o campo for translatável
          \"status_display\": \"Active\" // Título resolvido/traduzido (opcional, pode ser feito no cliente)
          // ... outros campos conforme definido em sys_grid_fields ...
        },
        {
          \"id\": 102,
          \"fullname\": \"Bob The Builder\",
          \"email\": \"bob@example.com\",
          \"status_key\": \"_bx_persons_status_pending\",
          \"status_display\": \"Pending\"
        }
        // ... mais linhas de dados ...
      ],
      \"pagination\": {
        \"total_items\": 153,
        \"offset\": 0,
        \"limit\": 20,
        \"current_page\": 1, // Calculado: (offset / limit) + 1
        \"total_pages\": 8 // Calculado: ceil(total_items / limit)
      }
    }
```

*   **Respostas de Erro:**
    *   `401 Unauthorized`: Se o token JWT for inválido ou ausente e a autenticação for necessária.
    *   `403 Forbidden`: Se o usuário autenticado não tiver permissão para ver esta grade (baseado em `visible_for_levels`).
    *   `404 Not Found`: Se o `{grid_object_name}` não existir.

#### Lógica do Controller da API:
1.  Verificar autenticação e autorização (permissão para ver a grade).
2.  Chamar `Deeper.Grids.GridRepo.get_grid_definition(grid_object_name)`.
3.  Chamar `Deeper.Grids.GridRepo.get_grid_fields(grid_object_name)`.
4.  Chamar `Deeper.Grids.GridRepo.get_grid_actions(grid_object_name)`.
5.  Resolver títulos dos campos e ações usando o `LocalizationRepo` e o `lang` param.
6.  Construir e retornar a resposta JSON.

### 2. Obter Dados de uma Grade (com Paginação, Filtros, Ordenação)

*   **Endpoint:** `GET /api/v1/grids/{grid_object_name}/data`
*   **Propósito:** Retorna os dados a serem exibidos na grade, já paginados, filtrados e ordenados conforme os query parameters.
*   **Autenticação:** Opcional/Obrigatória (mesma lógica do endpoint de definição).
*   **Parâmetros de URL:**
    *   `{grid_object_name}` (String, Obrigatório).
*   **Query Parameters:**
    *   `offset` (Integer, Opcional, Default: 0): Para paginação. Nome pode ser configurado em `sys_objects_grid.paginate_get_start`.
    *   `limit` (Integer, Opcional, Default: conforme `sys_objects_grid.paginate_per_page`): Para paginação. Nome pode ser configurado em `sys_objects_grid.paginate_get_per_page`.
    *   `{filter_get}` (String, Opcional, Default: `filter` ou conforme `sys_objects_grid.filter_get`): Termo de busca geral para os campos definidos em `sys_objects_grid.filter_fields`.
    *   `sort_by` (String, Opcional): Campo e direção para ordenação (ex: `title_asc`, `added_desc`). O campo deve estar listado em `sys_objects_grid.sorting_fields`.
    *   *Outros query parameters para filtros específicos podem ser adicionados conforme a definição da grade (ex: `status=active`).*
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: Se os parâmetros de paginação/filtro/ordenação forem inválidos.
    *   `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (para o `grid_object_name`).

#### Lógica do Controller da API:
1.  Verificar autenticação e autorização.
2.  Chamar `Deeper.Grids.GridRepo.get_grid_definition(grid_object_name)` para obter a definição da grade (necessária para construir a query de dados). Se não encontrada, 404.
3.  Coletar todos os query parameters relevantes (paginação, filtros, ordenação). Validá-los.
4.  Chamar `Deeper.Grids.GridRepo.get_grid_data(grid_definition, collected_params)`.
5.  A função `get_grid_data` no Repo constrói e executa as queries SQL (uma para dados, uma para contagem total).
6.  Opcionalmente, processar os `data_rows` retornados para traduzir campos marcados como `translatable` em `sys_grid_fields`.
7.  Construir a resposta JSON com `data` e `pagination` (calculada a partir de `total_items`, `offset`, `limit`).
8.  Enviar a resposta.

Com estes dois endpoints, um cliente pode obter a estrutura de qualquer grade definida no sistema e depois popular essa grade com dados, incluindo todas as funcionalidades interativas esperadas.