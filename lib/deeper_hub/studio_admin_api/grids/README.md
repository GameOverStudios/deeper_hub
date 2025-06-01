# Documentação Deeper Studio API: Gerenciamento de Grids

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento completo de Grids do sistema, incluindo \"Objetos de Grid\" (`sys_objects_grid`), \"Campos de Grid\" (`sys_grid_fields`), e \"Ações de Grid\" (`sys_grid_actions`).

**Objetivo Principal:** Permitir que administradores criem, modifiquem e configurem como os dados são exibidos em formato tabular (grids) em várias partes da plataforma \"Deeper\", especialmente no painel de administração.

## Tabelas Relevantes (já definidas e migradas):

*   `sys_objects_grid`
*   `sys_grid_fields`
*   `sys_grid_actions`
*   Tabelas de tradução para títulos de grids, campos e ações.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Grids.GridsRepo`: Precisará de funções CRUD completas para as três tabelas de grids.
*   `Deeper.SystemCore.LocalizationRepo`: Para lidar com todos os textos traduzíveis.

## Endpoints da API de Administração para Grids (`/api/v1/admin/builder/grids`):

*(Mantendo `/builder/` para consistência, já que grids são elementos de UI/exibição de dados).*

---
### Gerenciamento de Objetos de Grid (`/api/v1/admin/builder/grid-objects`)

#### 1. Listar Todos os Objetos de Grid

*   **Endpoint:** `GET /api/v1/admin/builder/grid-objects`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `filter_object_like`, `sort_by`. `lang` para traduções.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"object_name\": \"bx_persons_administration\", // sys_objects_grid.object
          // \"title\": \"Gerenciamento de Perfis\", // O título da grid em si não está em sys_objects_grid,
          // mas pode ser inferido ou adicionado como um campo customizado se necessário.
          // Geralmente, o título é parte da página/bloco que usa a grid.
          \"source_table\": \"bx_persons_data\", // sys_objects_grid.table (tabela principal)
          \"paginate_per_page\": 20
        }
        // ... outros objetos de grid ...
      ]
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"object_name\": \"bx_persons_administration\",
        \"source_type\": \"Sql\",
        \"source_query\": \"SELECT `tp`.`id`, `tp`.`fullname`, `ta`.`email`, `ta`.`status` AS `acc_status`, `tp`.`added` FROM `bx_persons_data` AS `tp` LEFT JOIN `sys_profiles` AS `ts` ON `tp`.`id` = `ts`.`content_id` LEFT JOIN `sys_accounts` AS `ta` ON `ts`.`account_id` = `ta`.`id` WHERE `ts`.`type` = 'bx_persons'\",
        \"main_table\": \"bx_persons_data\",
        // ... outros campos de sys_objects_grid ...
        \"fields\": [ // Lista de sys_grid_fields para esta grid, ordenados
          {
            \"field_id_db\": 101, // sys_grid_fields.id
            \"name\": \"id\", // sys_grid_fields.name (corresponde a uma coluna na source_query)
            \"title_key\": \"_bx_persons_grid_id\",
            \"title_translated\": \"ID\",
            \"width\": \"5%\",
            \"is_translatable_cell\": false,
            \"chars_limit\": 0,
            \"params_json\": \"{}\", // sys_grid_fields.params (pode ser JSON)
            \"order_in_grid\": 0
          }
          // ... outros campos ...
        ],
        \"actions\": [ // Lista de sys_grid_actions para esta grid, ordenadas
          {
            \"action_id_db\": 201, // sys_grid_actions.id
            \"type\": \"single\", // single, bulk, independent
            \"name\": \"edit_person\",
            \"title_key\": \"_edit\",
            \"title_translated\": \"Editar\",
            \"icon\": \"far pen-to-square\",
            \"requires_confirmation\": false,
            \"order_in_grid\": 0
          }
          // ... outras ações ...
        ]
      }
    }
```

```json
    {
      \"grid_object_name\": \"bx_persons_administration\",
      \"ordered_field_ids\": [101, 103, 102] // Lista de IDs (PK de sys_grid_fields) na nova ordem
    }
```

```json
    {
      \"grid_object_name\": \"bx_persons_administration\",
      \"ordered_action_ids\": [201, 203, 202] // Lista de IDs (PK de sys_grid_actions) na nova ordem
    }
```

#### 2. Criar Novo Objeto de Grid

*   **Endpoint:** `POST /api/v1/admin/builder/grid-objects`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Todos os campos de `sys_objects_grid` (ex: `object_name`, `source_type`, `source` (query SQL), `table`, `field_id`, `field_order`, `paginate_per_page`, `filter_fields`, `sorting_fields`, `visible_for_levels_mask`).
*   **Resposta de Sucesso (201 Created):** Retorna o objeto de grid criado.

#### 3. Obter Detalhes de um Objeto de Grid (incluindo seus campos e ações)

*   **Endpoint:** `GET /api/v1/admin/builder/grid-objects/{grid_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `lang`.
*   **Resposta de Sucesso (200 OK):**

#### 4. Atualizar um Objeto de Grid

*   **Endpoint:** `PUT /api/v1/admin/builder/grid-objects/{grid_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_grid` a serem atualizados.
*   **Resposta de Sucesso (200 OK).**

#### 5. Deletar um Objeto de Grid

*   **Endpoint:** `DELETE /api/v1/admin/builder/grid-objects/{grid_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Deleta de `sys_objects_grid`. `ON DELETE CASCADE` (se definido) ou deleções manuais removeriam `sys_grid_fields` e `sys_grid_actions` associados.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Campos de Grid (`/api/v1/admin/builder/grid-fields`)

#### 6. Listar Campos de Grid para um Objeto de Grid

*   **Endpoint:** `GET /api/v1/admin/builder/grid-fields?grid_object_name={name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_grid_fields` para o `grid_object_name`.

#### 7. Criar Novo Campo de Grid

*   **Endpoint:** `POST /api/v1/admin/builder/grid-fields`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Todos os campos de `sys_grid_fields` (incluindo `object` (grid_object_name), `name`, `title_key`, `width`, `order`, etc.).
*   **Resposta de Sucesso (201 Created).**

#### 8. Obter Detalhes de um Campo de Grid

*   **Endpoint:** `GET /api/v1/admin/builder/grid-fields/{field_id_db}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK).**

#### 9. Atualizar um Campo de Grid

*   **Endpoint:** `PUT /api/v1/admin/builder/grid-fields/{field_id_db}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_grid_fields` a serem atualizados.
*   **Resposta de Sucesso (200 OK).**

#### 10. Reordenar Campos de Grid

*   **Endpoint:** `PUT /api/v1/admin/builder/grid-fields/reorder`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK).**

#### 11. Deletar um Campo de Grid

*   **Endpoint:** `DELETE /api/v1/admin/builder/grid-fields/{field_id_db}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Ações de Grid (`/api/v1/admin/builder/grid-actions`)

#### 12. Listar Ações de Grid para um Objeto de Grid

*   **Endpoint:** `GET /api/v1/admin/builder/grid-actions?grid_object_name={name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_grid_actions` para o `grid_object_name`.

#### 13. Criar Nova Ação de Grid

*   **Endpoint:** `POST /api/v1/admin/builder/grid-actions`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Todos os campos de `sys_grid_actions` (incluindo `object` (grid_object_name), `type`, `name`, `title_key`, `icon`, `order`, `confirm`, `active`).
*   **Resposta de Sucesso (201 Created).**

#### 14. Obter Detalhes de uma Ação de Grid

*   **Endpoint:** `GET /api/v1/admin/builder/grid-actions/{action_id_db}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK).**

#### 15. Atualizar uma Ação de Grid

*   **Endpoint:** `PUT /api/v1/admin/builder/grid-actions/{action_id_db}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_grid_actions` a serem atualizados.
*   **Resposta de Sucesso (200 OK).**

#### 16. Reordenar Ações de Grid

*   **Endpoint:** `PUT /api/v1/admin/builder/grid-actions/reorder`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK).**

#### 17. Deletar uma Ação de Grid

*   **Endpoint:** `DELETE /api/v1/admin/builder/grid-actions/{action_id_db}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (204 No Content).**

## Considerações:

*   **Edição da Query `source`:** Permitir que a query SQL (`sys_objects_grid.source`) seja editada diretamente via API é poderoso, mas arriscado. Requer validação rigorosa para prevenir SQL injection ou queries maliciosas.
*   **Validação de Nomes:** `object_name` em `sys_objects_grid`, e a combinação `object+name` em `sys_grid_fields`, e `object+type+name` em `sys_grid_actions` devem ser únicos.
*   **`params` em `sys_grid_fields`:** A API \"Deeper\" precisará definir como os `params` (que no UNA PHP eram para callbacks de formatação) serão interpretados. Pode ser um JSON que especifica um tipo de formatador (ex: \"date\", \"boolean_to_icon\", \"user_link\") que o cliente ou a API (antes de enviar ao cliente) aplicaria.
*   **Execução de Ações da Grid:** A API de admin define as ações. A API que *executa* essas ações (ex: deletar um item selecionado) seria um endpoint diferente, provavelmente específico do recurso que a grid está exibindo (ex: `DELETE /api/v1/admin/users/{user_id}`).

Esta API de gerenciamento de grids permite aos administradores controlar como os dados tabulares são apresentados e quais operações podem ser realizadas sobre eles.