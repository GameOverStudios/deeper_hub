# Documentação Deeper: Endpoints da API para o Motor de Grades Dinâmicas

Este documento especifica os endpoints RESTful para que um cliente possa obter as definições de grades de dados dinâmicas e buscar os dados para popular essas grades no sistema \"Deeper\".

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas em JSON.
*   Autenticação JWT pode ser necessária para obter definições/dados de grades que têm visibilidade restrita por ACL.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).

---

## 1. Obter Definição da Grade

*   **Endpoint:** `GET /grids/{grid_object_name}/definition`
    *   `grid_object_name`: O nome do objeto de grade de `sys_objects_grid.object` (ex: `bx_persons_administration`, `deeper_articles_manage`).

*   **Autenticação:** Opcional/Requerida (baseado no `visible_for_levels` do objeto da grade).
*   **Query Parameters (Opcionais):**
    *   `lang={lang_code}` (ex: `en`, `pt-BR`): Para solicitar títulos de colunas e ações traduzidos.

*   **Descrição:** Retorna a definição completa de uma grade, incluindo detalhes do objeto da grade, lista de colunas (campos) e lista de ações disponíveis.

*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"object_details\": { // Dados de sys_objects_grid
          \"object\": \"bx_persons_administration\",
          \"source_type\": \"Service\", // Ou 'Sql'
          // \"source\": \"Deeper.Admin.UsersGridService.get_data\", // Se Service
          \"table_name\": \"sys_accounts\", // Tabela principal (informativo)
          \"field_id\": \"id\", // Nome da coluna ID
          \"paginate_per_page\": 10,
          \"filter_fields\": \"name,email,status\", // Campos filtráveis
          \"sorting_fields\": \"name,email,added,status\", // Campos ordenáveis
          \"responsive\": true,
          \"show_total_count\": true
          // ... outros campos relevantes de sys_objects_grid ...
        },
        \"fields\": [ // Lista de sys_grid_fields
          {
            \"name\": \"id\",
            \"title\": \"ID\", // Traduzido ou chave
            \"width\": \"5%\",
            \"translatable\": false,
            \"params\": null // Parâmetros de formatação
          },
          {
            \"name\": \"name\", // Corresponde a sys_accounts.name
            \"title\": \"Nome de Usuário\",
            \"width\": \"20%\",
            \"chars_limit\": 50,
            \"params\": {\"link_to_profile_pattern\": \"/profiles/persons/{id}\"} // Exemplo de parâmetro customizado
          },
          {
            \"name\": \"email\",
            \"title\": \"Email\",
            \"width\": \"25%\"
          },
          {
            \"name\": \"status_lkey\", // Exemplo se o status for uma chave de tradução
            \"title\": \"Status\",
            \"width\": \"10%\",
            \"translatable\": true // Indica que o valor desta coluna é uma lkey
          }
          // ... mais campos ...
        ],
        \"actions\": [ // Lista de sys_grid_actions
          {
            \"type\": \"single\", // 'bulk', 'single', 'independent'
            \"name\": \"edit_user\",
            \"title\": \"Editar\", // Traduzido ou chave
            \"icon\": \"pencil-alt\",
            \"icon_only\": true,
            \"confirm\": false
            // A API Deeper não executa a ação, apenas a descreve.
            // O cliente usaria esta info para renderizar um botão que chama
            // um endpoint específico (ex: PUT /admin/users/{id}).
          },
          {
            \"type\": \"bulk\",
            \"name\": \"delete_selected_users\",
            \"title\": \"Deletar Selecionados\",
            \"icon\": \"trash\",
            \"confirm\": true
          }
          // ... mais ações ...
        ],
        \"data_endpoint_pattern\": \"/api/v1/grids/bx_persons_administration/data\" // Endpoint para buscar os dados desta grade
      }
    }
```

```json
    {
      \"data\": [ // Lista de linhas, cada linha é um mapa de {field_name: value}
        {
          \"id\": 1,
          \"name\": \"JohnDoe\",
          \"email\": \"john.doe@example.com\",
          \"status_lkey\": \"_status_active\", // Valor é uma chave de tradução se a coluna é translatable
          \"added_ts\": 1678800000 // Exemplo de campo de data como timestamp
        },
        {
          \"id\": 2,
          \"name\": \"JaneSmith\",
          \"email\": \"jane.smith@example.com\",
          \"status_lkey\": \"_status_pending\",
          \"added_ts\": 1678810000
        }
        // ... mais linhas ...
      ],
      \"pagination\": {
        \"total_items\": 150,
        \"current_page\": 1,
        \"per_page\": 10,
        \"total_pages\": 15
      }
    }
```

*   **Respostas de Erro:**
    *   `404 Not Found`: Objeto de grade não encontrado ou não ativo.
    *   `401 Unauthorized`/`403 Forbidden`: Se o acesso à definição da grade for restrito.
    *   `500 Internal Server Error`.

*   **Lógica de Backend (Controller):**
    1.  Controller recebe `grid_object_name`.
    2.  Obtém `current_user_level_id` e `lang_code`.
    3.  Chamar `Deeper.GridsEngine.GridRepo.get_grid_definition/3`.
    4.  O `GridRepo` busca e monta os detalhes, traduzindo títulos se `lang_code` fornecido.

---

## 2. Obter Dados da Grade

*   **Endpoint:** `GET /grids/{grid_object_name}/data`
    *   `grid_object_name`: O nome do objeto de grade.

*   **Autenticação:** Opcional/Requerida (baseado no `visible_for_levels` do objeto da grade e na natureza dos dados).

*   **Descrição:** Retorna os dados paginados, filtrados e ordenados para uma grade específica.

*   **Query Parameters:**
    *   `page={integer}` (default: 1, ou o `paginate_per_page` da definição da grade).
    *   `per_page={integer}` (default: definido em `sys_objects_grid.paginate_per_page`).
    *   `sort_by={string}` (nome do campo para ordenar, ex: `name`). O nome do parâmetro pode ser configurado em `sys_objects_grid.order_get_field`.
    *   `sort_dir={string}` (`asc` ou `desc`). O nome do parâmetro pode ser configurado em `sys_objects_grid.order_get_dir`.
    *   **Filtros:**
        *   `filter={string}`: Para filtro geral em múltiplos campos (se `sys_objects_grid.filter_fields` e `filter_mode` suportarem). O nome do parâmetro pode ser configurado em `sys_objects_grid.filter_get`.
        *   `filter_{field_name}={string}`: Para filtros específicos por campo (ex: `filter_email=test@example.com`, `filter_status=active`). Os `field_name`s devem ser dos `filter_fields` da grade.
    *   `lang={lang_code}` (opcional, se os dados retornados precisarem de tradução no lado do servidor, ex: valores de colunas \"translatable\").

*   **Resposta de Sucesso (200 OK):**