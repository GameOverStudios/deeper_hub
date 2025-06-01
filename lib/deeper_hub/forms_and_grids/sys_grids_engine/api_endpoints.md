# Documentação Deeper: Endpoints da API para Motor de Grids de Dados

Este documento especifica os endpoints RESTful da API \"Deeper\" para obter definições de grids de dados e os próprios dados para preenchê-los.

## Convenções Gerais:

*   **Base URL:** `/api/v1/grids`
*   **Identificadores:**
    *   `{grid_object_name}`: O nome do \"objeto de grid\" (de `sys_objects_grid.object`, ex: `bx_persons_administration`, `bx_posts_manage`).
*   **Autenticação:** A obtenção da definição de um grid pode ser pública ou protegida. A obtenção dos dados é geralmente protegida ou, no mínimo, a query subjacente aplicará filtros de ACL.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Obter Definição de um Grid

*   **Endpoint:** `GET /grids/{grid_object_name}/definition`
*   **Status:** Público ou Protegido (dependendo do grid e suas permissões `visible_for_levels`)
*   **Descrição:** Retorna a estrutura completa de um grid, incluindo seus atributos, colunas (campos) e ações disponíveis.
*   **Parâmetros de URL:**
    *   `{grid_object_name}`: Nome do objeto de grid.
*   **Cabeçalhos da Requisição (Opcional):**
    *   `Authorization: Bearer <jwt_token>`: Para filtrar a visibilidade do grid ou de suas ações/campos com base no ACL do usuário.
    *   `Accept-Language: pt-BR`: Para solicitar títulos de colunas/ações traduzidos.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"object\": \"bx_persons_administration\",
        \"paginate_per_page\": 10,
        \"filter_fields_available\": [\"fullname\", \"email\", \"status\"],
        \"sorting_fields_available\": [\"fullname\", \"email\", \"added\", \"status\"],
        \"default_sort_field\": \"added\",
        \"default_sort_direction\": \"desc\", // Inferido ou explicitado
        // ... outros atributos de sys_objects_grid ...
        \"fields\": [
          {
            \"name\": \"id\",
            \"title\": \"ID\", // Traduzido
            \"width\": \"5%\",
            \"order\": 1
            // ... outros atributos de sys_grid_fields
          },
          {
            \"name\": \"fullname\",
            \"title\": \"Nome Completo\",
            \"width\": \"30%\",
            \"order\": 2
          }
          // ...
        ],
        \"actions\": [
          {
            \"type\": \"single\",
            \"name\": \"edit_person\", // Nome da ação
            \"title\": \"Editar\", // Traduzido
            \"icon\": \"bx-edit\",
            \"confirm\": true
            // Ação real: o cliente mapeia 'edit_person' para uma rota UI ou uma chamada API específica (ex: PUT /persons/{id})
          },
          {
            \"type\": \"bulk\",
            \"name\": \"delete_selected_persons\",
            \"title\": \"Deletar Selecionados\",
            \"icon\": \"bx-trash\"
            // Ação real: o cliente envia uma lista de IDs para um endpoint como DELETE /persons/bulk-delete
          }
          // ...
        ]
      }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1, // Os nomes das chaves correspondem aos 'name' dos sys_grid_fields
          \"fullname\": \"John Doe\",
          \"email\": \"john@example.com\",
          \"status_formatted\": \"Ativo\" // Exemplo se houver formatação/tradução de campo
        },
        {
          \"id\": 2,
          \"fullname\": \"Jane Roe\",
          \"email\": \"jane@example.com\",
          \"status_formatted\": \"Pendente\"
        }
        // ...
      ],
      \"pagination\": {
        \"total_items\": 150,
        \"total_pages\": 15, // total_items / per_page
        \"current_page\": 1, // Calculado a partir de start/offset
        \"per_page\": 10
      }
    }
```

*   **Erros Comuns:**
    *   `404 Not Found`: Grid `{grid_object_name}` não encontrado.
    *   `403 Forbidden`: Usuário não tem permissão para acessar a definição deste grid.
*   **Lógica do Backend (Controller):**
    1.  Extrair `user_level_id` do JWT (se presente).
    2.  Chamar `GridsRepo.get_grid_definition/2` com `grid_object_name` e `user_level_id`.
    3.  O Repo traduz os títulos (se aplicável, usando `LocalizationRepo` e o idioma da requisição/usuário).
    4.  Formatar e retornar a resposta.

### 2. Obter Dados para um Grid

*   **Endpoint:** `GET /grids/{grid_object_name}/data`
*   **Status:** Protegido (ou Público com filtros ACL nos dados)
*   **Descrição:** Retorna os dados paginados, filtrados e ordenados para preencher o grid.
*   **Parâmetros de URL:**
    *   `{grid_object_name}`: Nome do objeto de grid.
*   **Query Parameters (Nomes dos parâmetros são definidos em `sys_objects_grid`):**
    *   `start=0` (ou `offset=0`, `page=1` - conforme `paginate_get_start`): Para paginação.
    *   `per_page=10` (ou `limit=10` - conforme `paginate_get_per_page`): Número de itens por página.
    *   `filter=<search_term>` (conforme `filter_get`): Termo para filtro geral.
    *   `filter_field_<fieldname>=<value>`: (Opcional) Filtros específicos por campo (ex: `filter_field_status=active`).
    *   `order_field=fullname` (conforme `order_get_field`): Campo para ordenação.
    *   `order_dir=asc` (conforme `order_get_dir`): Direção da ordenação (`asc` ou `desc`).
*   **Cabeçalhos da Requisição (Opcional):**
    *   `Authorization: Bearer <jwt_token>`: Para aplicar ACL aos dados retornados.
*   **Resposta de Sucesso (200 OK):**

*   **Erros Comuns:**
    *   `400 Bad Request`: Parâmetros de query inválidos (ex: campo de ordenação não permitido).
    *   `404 Not Found`: Grid `{grid_object_name}` não encontrado.
    *   `403 Forbidden`: Usuário não tem permissão para acessar os dados deste grid.
*   **Lógica do Backend (Controller):**
    1.  Extrair `user_level_id` do JWT (se presente).
    2.  Coletar e validar os `query_params` (filtros, ordenação, paginação).
    3.  Chamar `GridsRepo.get_grid_data/3` com `grid_object_name`, `query_params`, e `user_level_id`.
    4.  O Repo constrói e executa a query SQL, aplicando os filtros, ordenação, paginação e ACL.
    5.  Formatar e retornar a resposta.

### Considerações:

*   **Nomes dos Query Parameters:** Os nomes reais dos query parameters para paginação, filtro e ordenação (`start`, `per_page`, `filter`, `order_field`, `order_dir`) são configuráveis em `sys_objects_grid` (`paginate_get_start`, `paginate_get_per_page`, `filter_get`, `order_get_field`, `order_get_dir`). A API \"Deeper\" deve respeitar esses nomes configurados ao interpretar os query params do cliente, ou padronizar para um conjunto fixo e mapear internamente. Usar um conjunto fixo na API (ex: `page`, `per_page`, `sort_by`, `sort_dir`, `q` para filtro geral) e mapear para os nomes do `sys_objects_grid` no `GridsRepo` pode ser mais consistente para os clientes da API.
*   **Execução de Ações do Grid:**
    *   As ações definidas em `sys_grid_actions` (ex: \"delete\", \"edit\") não são executadas por este endpoint.
    *   O cliente, ao receber a definição do grid e as ações, será responsável por:
        *   Renderizar os botões/links de ação.
        *   Quando uma ação é acionada (ex: clique em \"Deletar\" para o item com ID 5), o cliente fará uma chamada separada para o endpoint RESTful apropriado que executa essa ação (ex: `DELETE /api/v1/resource_type_do_grid/5`).
        *   Para ações em massa, o cliente coletaria os IDs dos itens selecionados e os enviaria para um endpoint de ação em massa (ex: `POST /api/v1/resource_type_do_grid/bulk-delete` com corpo `{\"ids\": [1, 5, 10]}`).
*   **Segurança da Fonte de Dados SQL:** Se `sys_objects_grid.source` contiver SQL complexo, o `GridsRepo` deve ter muito cuidado ao modificá-lo para adicionar filtros/ordenação para evitar injeção de SQL. Idealmente, o `GridsRepo` reconstrói a query de forma segura com base na tabela principal e nos campos definidos.