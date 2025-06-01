# Endpoints da API de Admin para Gerenciamento de Formulários

Endpoints para administrar Objetos de Formulário, Campos de Entrada, Exibições e Listas Pré-definidas. Todos os endpoints aqui requerem autenticação de Administrador.

## Base Path: `/api/v1/admin/builder/forms`

---
### Gerenciamento de Objetos de Formulário (`/objects`)

#### 1. Listar Objetos de Formulário
*   **Endpoint:** `GET /api/v1/admin/builder/forms/objects`
*   **Query Params:** `filter_module`, `filter_object_like`, `sort_by`, `lang`.
*   **Resposta:** Lista de `sys_objects_form`.

#### 2. Criar Objeto de Formulário
*   **Endpoint:** `POST /api/v1/admin/builder/forms/objects`
*   **Corpo (JSON):** Detalhes de `sys_objects_form`.
*   **Resposta (201 Created).**

#### 3. Obter Detalhes de um Objeto de Formulário
*   **Endpoint:** `GET /api/v1/admin/builder/forms/objects/{form_object_name}`
*   **Path Param:** `form_object_name`.
*   **Query Params:** `lang`.
*   **Resposta:** Detalhes do `sys_objects_form`, incluindo suas `sys_form_displays` e todos os `sys_form_inputs` associados (como descrito no `README.md` da Studio API para Forms).

#### 4. Atualizar Objeto de Formulário
*   **Endpoint:** `PUT /api/v1/admin/builder/forms/objects/{form_object_name}`
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK).**

#### 5. Deletar Objeto de Formulário
*   **Endpoint:** `DELETE /api/v1/admin/builder/forms/objects/{form_object_name}`
*   **Resposta (204 No Content).**

---
### Gerenciamento de Campos de Entrada (`/inputs`)

#### 6. Listar Campos de Entrada de um Formulário
*   **Endpoint:** `GET /api/v1/admin/builder/forms/inputs?form_object_name={name}`
*   **Query Param:** `form_object_name` (obrigatório). `lang`.
*   **Resposta:** Lista de `sys_form_inputs`.

#### 7. Criar Campo de Entrada
*   **Endpoint:** `POST /api/v1/admin/builder/forms/inputs`
*   **Corpo (JSON):** Detalhes de `sys_form_inputs`, incluindo `object` (form_object_name).
*   **Resposta (201 Created).**

#### 8. Obter Detalhes de um Campo de Entrada
*   **Endpoint:** `GET /api/v1/admin/builder/forms/inputs/{input_id}`
*   **Path Param:** `input_id` (PK de `sys_form_inputs`).
*   **Query Params:** `lang`.
*   **Resposta (200 OK).**

#### 9. Atualizar Campo de Entrada
*   **Endpoint:** `PUT /api/v1/admin/builder/forms/inputs/{input_id}`
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK).**

#### 10. Deletar Campo de Entrada
*   **Endpoint:** `DELETE /api/v1/admin/builder/forms/inputs/{input_id}`
*   **Resposta (204 No Content).**

---
### Gerenciamento de Exibições de Formulário (`/displays`)

#### 11. Listar Exibições de um Formulário
*   **Endpoint:** `GET /api/v1/admin/builder/forms/displays?form_object_name={name}`
*   **Query Param:** `form_object_name` (obrigatório). `lang`.
*   **Resposta:** Lista de `sys_form_displays`.

#### 12. Criar Exibição de Formulário
*   **Endpoint:** `POST /api/v1/admin/builder/forms/displays`
*   **Corpo (JSON):** Detalhes de `sys_form_displays`, incluindo `object` (form_object_name).
*   **Resposta (201 Created).**

#### 13. Obter Detalhes de uma Exibição de Formulário (incluindo seus campos configurados)
*   **Endpoint:** `GET /api/v1/admin/builder/forms/displays/{display_id}`
*   **Path Param:** `display_id` (PK de `sys_form_displays`).
*   **Query Params:** `lang`.
*   **Resposta:** Detalhes de `sys_form_displays` e a lista configurada de `sys_form_display_inputs` (com detalhes dos campos).

#### 14. Atualizar Detalhes de uma Exibição de Formulário (ex: título)
*   **Endpoint:** `PUT /api/v1/admin/builder/forms/displays/{display_id}`
*   **Corpo (JSON):** `title_key`.
*   **Resposta (200 OK).**

#### 15. Atualizar Configuração de Campos de uma Exibição
*   **Endpoint:** `PUT /api/v1/admin/builder/forms/displays/{display_id}/inputs`
*   **Path Param:** `display_id`.
*   **Corpo (JSON):** `{\"inputs\": [{\"input_name\": ..., \"order\": ..., \"is_active_in_display\": ..., \"visible_for_levels_mask\": ...}, ...]}`.
*   **Resposta (200 OK).**

#### 16. Deletar Exibição de Formulário
*   **Endpoint:** `DELETE /api/v1/admin/builder/forms/displays/{display_id}`
*   **Resposta (204 No Content).**

---
### Gerenciamento de Listas Pré-definidas (`/prelists`)

#### 17. Listar Listas Pré-definidas
*   **Endpoint:** `GET /api/v1/admin/builder/forms/prelists`
*   **Query Params:** `lang`.
*   **Resposta:** Lista de `sys_form_pre_lists`.

#### 18. Criar Lista Pré-definida
*   **Endpoint:** `POST /api/v1/admin/builder/forms/prelists`
*   **Corpo (JSON):** Detalhes de `sys_form_pre_lists`.
*   **Resposta (201 Created).**

#### 19. Obter Detalhes de uma Lista Pré-definida (e seus valores)
*   **Endpoint:** `GET /api/v1/admin/builder/forms/prelists/{prelist_key}`
*   **Path Param:** `prelist_key` (de `sys_form_pre_lists.key`).
*   **Query Params:** `lang`.
*   **Resposta:** Detalhes da lista e seus `sys_form_pre_values` (traduzidos).

#### 20. Atualizar Lista Pré-definida
*   **Endpoint:** `PUT /api/v1/admin/builder/forms/prelists/{prelist_key}`
*   **Corpo (JSON):** Campos de `sys_form_pre_lists`.
*   **Resposta (200 OK).**

#### 21. Atualizar Valores de uma Lista Pré-definida
*   **Endpoint:** `PUT /api/v1/admin/builder/forms/prelists/{prelist_key}/values`
*   **Path Param:** `prelist_key`.
*   **Corpo (JSON):** `{\"values\": [{\"value_data\": ..., \"lkey_data\": ..., \"order_data\": ...}, ...]}`.
*   **Resposta (200 OK).**

#### 22. Deletar Lista Pré-definida
*   **Endpoint:** `DELETE /api/v1/admin/builder/forms/prelists/{prelist_key}`
*   **Resposta (204 No Content).**

## Considerações:

*   **Validação de Chaves de Tradução:** Ao criar/atualizar títulos, legendas, etc., que são chaves de tradução, a API pode opcionalmente verificar se a chave já existe ou permitir a criação \"on-the-fly\" de uma nova chave (que precisaria então de traduções).
*   **Replicação da Lógica de Validação (`checker_func`) e Processamento (`db_pass`):** A UI de admin para campos de formulário deve permitir a configuração dessas lógicas. A API \"Deeper\" precisará de mapeamentos Elixir para as funções PHP comuns.
*   **Interface do Usuário:** A UI de admin para o construtor de formulários pode ser complexa, envolvendo arrastar e soltar campos, configurar validações, etc. A API deve fornecer os dados necessários para tal interface.

Esta API de gerenciamento de formulários é fundamental para permitir que os administradores definam como os dados são coletados em toda a plataforma \"Deeper\".