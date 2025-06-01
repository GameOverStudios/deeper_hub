# Documentação Deeper: API de Administração - Gerenciamento de Formulários e Grades

Este documento descreve os endpoints da API \"Deeper\" para administradores gerenciarem as definições de Formulários Dinâmicos (`sys_objects_form` e tabelas relacionadas) e Grades de Dados (`sys_objects_grid` e tabelas relacionadas).

## Escopo e Funcionalidades:

*   **Formulários:**
    *   CRUD para Objetos de Formulário (`sys_objects_form`).
    *   CRUD para Inputs de Formulário (`sys_form_inputs`) dentro de um objeto de formulário.
    *   Gerenciamento de Displays de Formulário (`sys_form_displays`, `sys_form_display_inputs`) para controlar quais campos são visíveis em diferentes contextos.
    *   CRUD para Listas de Pré-Valores (`sys_form_pre_lists`, `sys_form_pre_values`) usadas em selects, radios, etc.
*   **Grades:**
    *   CRUD para Objetos de Grade (`sys_objects_grid`).
    *   CRUD para Campos de Grade (`sys_grid_fields`) dentro de um objeto de grade.
    *   CRUD para Ações de Grade (`sys_grid_actions`) dentro de um objeto de grade.

## Tabelas Relevantes (Já Definidas em `docs/05_forms_and_grids/`):

*   **Formulários:**
    *   `sys_objects_form`
    *   `sys_form_inputs`
    *   `sys_form_displays`
    *   `sys_form_display_inputs`
    *   `sys_form_pre_lists`
    *   `sys_form_pre_values`
*   **Grades:**
    *   `sys_objects_grid`
    *   `sys_grid_fields`
    *   `sys_grid_actions`

## Módulos de Acesso a Dados (Já Definidos/Esboçados):

*   `Deeper.Forms.FormRepo`
*   `Deeper.Grids.GridRepo`

## Endpoints da API de Administração para Formulários e Grades

Todos os endpoints estão sob `/api/v1/admin/structure/...` (ou similar, para indicar gerenciamento da estrutura do site) e requerem autenticação de administrador.

### Gerenciamento de Listas de Pré-Valores (`sys_form_pre_lists`, `sys_form_pre_values`)

#### 1. Listar Listas de Pré-Valores
*   **Endpoint:** `GET /api/v1/admin/structure/form-pre-lists`
*   **Query Parameters:** `module_filter`, `search_term` (por `key` ou `title`).
*   **Resposta (200 OK):** Lista de `sys_form_pre_lists`.

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"module\": \"system\",
          \"key\": \"sys_boolean\",
          \"title\": \"_sys_pre_list_title_boolean\",
          \"title_resolved\": \"Yes/No\",
          \"use_for_sets\": 1,
          \"extendable\": 0
        }
      ]
    }
```

```json
    {
      \"list_info\": { /* ... dados de sys_form_pre_lists ... */ },
      \"values\": [ // Dados de sys_form_pre_values ordenados por 'Order'
        {
          \"id\": 101,
          \"value\": \"1\",
          \"lkey\": \"_sys_pre_value_yes\",
          \"lkey_resolved\": \"Yes\",
          \"order\": 1
        },
        {
          \"id\": 102,
          \"value\": \"0\",
          \"lkey\": \"_sys_pre_value_no\",
          \"lkey_resolved\": \"No\",
          \"order\": 2
        }
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"object\": \"bx_persons_add\",
          \"module\": \"bx_persons\",
          \"title\": \"_bx_persons_form_title_add\",
          \"title_resolved\": \"Add Person\",
          \"table_name\": \"bx_persons_data\",
          \"active\": 1
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"form_object\": { /* ... dados de sys_objects_form ... */ },
      \"inputs\": [ /* ... lista de sys_form_inputs para este form_object ... */ ],
      \"displays\": [
        {
          \"display_name\": \"bx_persons_add\", // sys_form_displays.display_name
          \"title\": \"_bx_persons_form_display_title_add\",
          // ... outros campos de sys_form_displays ...
          \"inputs\": [ // sys_form_display_inputs para este display
            { \"input_name\": \"fullname\", \"order\": 1, \"visible_for_levels\": -1 },
            { \"input_name\": \"description\", \"order\": 2, \"visible_for_levels\": -1 }
          ]
        }
      ],
      \"available_pre_lists\": [ /* ... lista de sys_form_pre_lists para selects ... */ ]
    }
```

```json
    {
      \"name\": \"new_field_name\",
      \"type\": \"text\", // text, textarea, select, checkbox, date, file, etc.
      \"caption_system\": \"_form_input_caption_new_field\",
      \"db_pass\": \"Xss\", // Tipo de sanitização/validação (ex: Xss, Int, Date)
      \"checker_func\": \"Avail\", // Função de validação (Avail = obrigatório)
      \"checker_error\": \"_form_input_error_new_field_avail\"
      // ... required, unique, values (para radios), attrs, etc. ...
    }
```

```json
    [
      { \"input_name\": \"fullname\", \"order\": 1, \"visible_for_levels\": -1, \"active\": 1 },
      { \"input_name\": \"description\", \"order\": 2, \"visible_for_levels\": -1, \"active\": 1 },
      { \"input_name\": \"secret_field\", \"order\": 3, \"visible_for_levels\": 4, \"active\": 0 } // Campo desativado no display
    ]
```

```json
    {
      \"grid_object\": { /* ... dados de sys_objects_grid ... */ },
      \"fields\": [ /* ... lista de sys_grid_fields para este grid_object ... */ ],
      \"actions\": [ /* ... lista de sys_grid_actions para este grid_object ... */ ]
    }
```

#### 2. Criar Nova Lista de Pré-Valores
*   **Endpoint:** `POST /api/v1/admin/structure/form-pre-lists`
*   **Corpo da Requisição (JSON):** Campos de `sys_form_pre_lists`.
*   **Resposta (201 Created):** Detalhes da lista criada.

#### 3. Obter Detalhes de uma Lista de Pré-Valores (incluindo seus valores)
*   **Endpoint:** `GET /api/v1/admin/structure/form-pre-lists/{preListKeyOrId}`
*   **Resposta (200 OK):**

#### 4. Atualizar Lista de Pré-Valores (informações da lista)
*   **Endpoint:** `PUT /api/v1/admin/structure/form-pre-lists/{preListKeyOrId}`
*   **Corpo da Requisição (JSON):** Campos de `sys_form_pre_lists` a atualizar.
*   **Resposta (200 OK):** Detalhes da lista atualizada.

#### 5. Deletar Lista de Pré-Valores
*   **Endpoint:** `DELETE /api/v1/admin/structure/form-pre-lists/{preListKeyOrId}`
*   **Lógica:** Deve também deletar os `sys_form_pre_values` associados (CASCADE).
*   **Resposta (204 No Content).**

#### 6. Adicionar/Editar/Remover Valores de uma Lista de Pré-Valores
*   **Adicionar:** `POST /api/v1/admin/structure/form-pre-lists/{preListKeyOrId}/values`
    *   Corpo: Campos de `sys_form_pre_values` (Value, LKey, Order, etc.).
*   **Atualizar:** `PUT /api/v1/admin/structure/form-pre-list-values/{valueId}`
    *   Corpo: Campos de `sys_form_pre_values` a atualizar.
*   **Deletar:** `DELETE /api/v1/admin/structure/form-pre-list-values/{valueId}`

### Gerenciamento de Objetos de Formulário (`sys_objects_form`)

#### 1. Listar Objetos de Formulário
*   **Endpoint:** `GET /api/v1/admin/structure/forms`
*   **Query Parameters:** `module_filter`, `search_term` (por `object` ou `title`).
*   **Resposta (200 OK):** Lista paginada de `sys_objects_form`.

#### 2. Criar Novo Objeto de Formulário
*   **Endpoint:** `POST /api/v1/admin/structure/forms`
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_form`.
*   **Resposta (201 Created):** Detalhes do formulário criado.

#### 3. Obter Detalhes de um Objeto de Formulário (Incluindo Inputs e Displays)
*   **Endpoint:** `GET /api/v1/admin/structure/forms/{formObjectIdOrName}`
*   **Resposta (200 OK):**

#### 4. Atualizar Objeto de Formulário
*   **Endpoint:** `PUT /api/v1/admin/structure/forms/{formObjectIdOrName}`
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_form` a atualizar.
*   **Resposta (200 OK):** Detalhes do formulário atualizado.

#### 5. Deletar Objeto de Formulário
*   **Endpoint:** `DELETE /api/v1/admin/structure/forms/{formObjectIdOrName}`
*   **Lógica:** Verificar `deletable`. Deve também deletar `sys_form_inputs`, `sys_form_displays`, `sys_form_display_inputs` associados (CASCADE).
*   **Resposta (204 No Content).**

### Gerenciamento de Inputs de Formulário (`sys_form_inputs`)

Inputs são gerenciados no contexto de um `sys_objects_form`.

#### 1. Adicionar Input a um Formulário
*   **Endpoint:** `POST /api/v1/admin/structure/forms/{formObjectIdOrName}/inputs`
*   **Corpo da Requisição (JSON):** Campos de `sys_form_inputs`.

*   **Resposta (201 Created):** Detalhes do input criado.

#### 2. Atualizar Input de Formulário
*   **Endpoint:** `PUT /api/v1/admin/structure/form-inputs/{inputId}`
*   **Corpo da Requisição (JSON):** Campos de `sys_form_inputs` a atualizar.
*   **Resposta (200 OK):** Detalhes do input atualizado.

#### 3. Deletar Input de Formulário
*   **Endpoint:** `DELETE /api/v1/admin/structure/form-inputs/{inputId}`
*   **Lógica:** Verificar `deletable`. Deve remover de `sys_form_display_inputs`.
*   **Resposta (204 No Content).**

#### 4. (Opcional) Reordenar Inputs em um Formulário
*   **Endpoint:** `PUT /api/v1/admin/structure/forms/{formObjectIdOrName}/inputs-order`
*   **Corpo (JSON):** `[{ \"input_id\": 123, \"order\": 10 }, { \"input_id\": 124, \"order\": 20 }]` (onde `order` é a ordem no `sys_form_inputs`, não no display)

### Gerenciamento de Displays de Formulário (`sys_form_displays`, `sys_form_display_inputs`)

#### 1. Criar Novo Display para um Formulário
*   **Endpoint:** `POST /api/v1/admin/structure/forms/{formObjectIdOrName}/displays`
*   **Corpo (JSON):** Campos de `sys_form_displays` (display_name, title, module, view_mode).
*   **Resposta (201 Created).**

#### 2. Atualizar Display de Formulário
*   **Endpoint:** `PUT /api/v1/admin/structure/form-displays/{displayId}` (ou por `display_name` + `object_form`)
*   **Corpo (JSON):** Campos de `sys_form_displays`.
*   **Resposta (200 OK).**

#### 3. Deletar Display de Formulário
*   **Endpoint:** `DELETE /api/v1/admin/structure/form-displays/{displayId}`
*   **Lógica:** Deleta também os `sys_form_display_inputs` associados.
*   **Resposta (204 No Content).**

#### 4. Gerenciar Inputs de um Display (Quais campos mostrar e em que ordem)
*   **Endpoint:** `PUT /api/v1/admin/structure/form-displays/{displayId}/inputs-layout`
*   **Corpo (JSON):** Uma lista de inputs para este display, com sua ordem e visibilidade.

*   **Lógica:** Atualiza/insere/deleta em `sys_form_display_inputs`.
*   **Resposta (200 OK).**

### Gerenciamento de Objetos de Grade (`sys_objects_grid`) e seus Componentes

As APIs de CRUD para `sys_objects_grid`, `sys_grid_fields`, e `sys_grid_actions` seguirão um padrão muito similar ao dos Formulários.

#### 1. Listar Objetos de Grade
*   **Endpoint:** `GET /api/v1/admin/structure/grids`
*   **Resposta:** Lista paginada de `sys_objects_grid`.

#### 2. Criar Novo Objeto de Grade
*   **Endpoint:** `POST /api/v1/admin/structure/grids`
*   **Corpo (JSON):** Campos de `sys_objects_grid`.
*   **Resposta (201 Created).**

#### 3. Obter Detalhes de um Objeto de Grade (Incluindo Fields e Actions)
*   **Endpoint:** `GET /api/v1/admin/structure/grids/{gridObjectIdOrName}`
*   **Resposta (200 OK):**

#### 4. Atualizar Objeto de Grade
*   **Endpoint:** `PUT /api/v1/admin/structure/grids/{gridObjectIdOrName}`
*   **Corpo (JSON):** Campos de `sys_objects_grid` a atualizar.
*   **Resposta (200 OK).**

#### 5. Deletar Objeto de Grade
*   **Endpoint:** `DELETE /api/v1/admin/structure/grids/{gridObjectIdOrName}`
*   **Lógica:** Deleta `sys_grid_fields` e `sys_grid_actions` associados (CASCADE).
*   **Resposta (204 No Content).**

### Gerenciamento de Campos de Grade (`sys_grid_fields`)

#### 1. Adicionar Campo a uma Grade
*   **Endpoint:** `POST /api/v1/admin/structure/grids/{gridObjectIdOrName}/fields`
*   **Corpo (JSON):** Campos de `sys_grid_fields`.
*   **Resposta (201 Created).**

#### 2. Atualizar Campo de Grade
*   **Endpoint:** `PUT /api/v1/admin/structure/grid-fields/{fieldId}`
*   **Corpo (JSON):** Campos de `sys_grid_fields`.
*   **Resposta (200 OK).**

#### 3. Deletar Campo de Grade
*   **Endpoint:** `DELETE /api/v1/admin/structure/grid-fields/{fieldId}`
*   **Resposta (204 No Content).**

#### 4. (Opcional) Reordenar Campos em uma Grade
*   **Endpoint:** `PUT /api/v1/admin/structure/grids/{gridObjectIdOrName}/fields-order`
*   **Corpo (JSON):** `[{ \"field_id\": 123, \"order\": 10 }, ...]`

### Gerenciamento de Ações de Grade (`sys_grid_actions`)

#### 1. Adicionar Ação a uma Grade
*   **Endpoint:** `POST /api/v1/admin/structure/grids/{gridObjectIdOrName}/actions`
*   **Corpo (JSON):** Campos de `sys_grid_actions`.
*   **Resposta (201 Created).**

#### 2. Atualizar Ação de Grade
*   **Endpoint:** `PUT /api/v1/admin/structure/grid-actions/{actionId}`
*   **Corpo (JSON):** Campos de `sys_grid_actions`.
*   **Resposta (200 OK).**

#### 3. Deletar Ação de Grade
*   **Endpoint:** `DELETE /api/v1/admin/structure/grid-actions/{actionId}`
*   **Resposta (204 No Content).**

#### 4. (Opcional) Reordenar Ações em uma Grade
*   **Endpoint:** `PUT /api/v1/admin/structure/grids/{gridObjectIdOrName}/actions-order`
*   **Corpo (JSON):** `[{ \"action_id\": 123, \"order\": 10 }, ...]`

### Considerações:

*   **Complexidade da UI de Admin:** Gerenciar formulários e grades pode ser complexo. A API deve fornecer todos os dados necessários para uma UI de administração rica (ex: listas de tipos de input, validadores disponíveis, tipos de ação de grade).
*   **Validação de Definições:** Ao criar/atualizar definições (ex: um `source` SQL para uma grade, um `checker_func` para um input), o backend pode precisar realizar validações para garantir que as definições são válidas.
*   **Módulos:** Muitas dessas definições (formulários, grades) são originalmente fornecidas por módulos UNA. A API de admin deve indicar qual módulo \"possui\" uma definição.

Esta API de administração para formulários e grades é extensa, mas reflete a flexibilidade e configurabilidade do sistema UNA.