# Documentação Deeper Studio API: Gerenciamento de Formulários

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento completo de Formulários do sistema, incluindo \"Objetos de Formulário\" (`sys_objects_form`), \"Campos de Entrada\" (`sys_form_inputs`), \"Exibições de Formulário\" (`sys_form_displays` e `sys_form_display_inputs`), e \"Listas Pré-definidas\" (`sys_form_pre_lists` e `sys_form_pre_values`).

**Objetivo Principal:** Permitir que administradores criem, modifiquem e configurem formulários que são usados para entrada de dados em toda a plataforma \"Deeper\".

## Tabelas Relevantes (já definidas e migradas):

*   `sys_objects_form`
*   `sys_form_inputs`
*   `sys_form_displays`
*   `sys_form_display_inputs`
*   `sys_form_pre_lists`
*   `sys_form_pre_values`
*   Tabelas de tradução para legendas, informações de ajuda, erros de validação, etc.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Forms.FormsRepo`: Precisará de funções CRUD completas para todas as tabelas de formulários mencionadas acima.
*   `Deeper.SystemCore.LocalizationRepo`: Para lidar com todos os textos traduzíveis.

## Endpoints da API de Administração para Formulários (`/api/v1/admin/builder/forms`):

*(Mantendo `/builder/` para consistência com Páginas e Menus, já que formulários são parte da construção da UI/UX).*

---
### Gerenciamento de Objetos de Formulário (`/api/v1/admin/builder/form-objects`)

#### 1. Listar Todos os Objetos de Formulário

*   **Endpoint:** `GET /api/v1/admin/builder/form-objects`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `filter_module`, `filter_object_like`, `sort_by`. `lang` para traduções.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"object_name\": \"bx_persons_add\", // sys_objects_form.object
          \"module\": \"bx_persons\",
          \"title\": \"Adicionar Perfil de Pessoa\", // Traduzido
          \"target_table\": \"bx_persons_data\", // sys_objects_form.table
          \"is_active\": true
        }
        // ... outros objetos de formulário ...
      ]
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"object_name\": \"bx_persons_add\",
        \"module\": \"bx_persons\",
        \"title_key\": \"_bx_persons_form_add_title\",
        \"title_translated\": \"Adicionar Perfil de Pessoa\",
        // ... outros campos de sys_objects_form ...
        \"displays\": [ // Lista de sys_form_displays associadas
          {
            \"display_id\": 10,
            \"display_name\": \"bx_persons_add_profile_form_display\",
            \"title_key\": \"_bx_persons_form_display_add_profile\",
            \"title_translated\": \"Adicionar Perfil (Exibição)\",
            \"inputs\": [ // Lista de sys_form_display_inputs para esta exibição
              {
                \"input_name\": \"fullname\", // sys_form_inputs.name
                \"order\": 1,
                \"is_active_in_display\": true,
                \"visible_for_levels_mask\": 2147483647,
                // Detalhes do input (pode ser um objeto aninhado ou o cliente busca separado)
                \"input_details\": {
                    \"input_id\": 101, // sys_form_inputs.id
                    \"type\": \"text\",
                    \"caption_key\": \"_bx_persons_form_field_fullname\",
                    \"caption_translated\": \"Nome Completo\",
                    \"is_required\": true
                }
              }
              // ... outros inputs na exibição ...
            ]
          }
          // ... outras exibições para este formulário ...
        ],
        \"all_defined_inputs\": [ // Lista de todos os sys_form_inputs para este form_object_name
            {
                \"input_id\": 101,
                \"name\": \"fullname\",
                \"type\": \"text\",
                \"caption_key\": \"_bx_persons_form_field_fullname\",
                \"caption_translated\": \"Nome Completo\",
                // ... todos os campos de sys_form_inputs ...
            }
            // ...
        ]
      }
    }
```

```json
    {
      \"inputs\": [
        {\"input_name\": \"fullname\", \"order\": 1, \"is_active_in_display\": true, \"visible_for_levels_mask\": 2147483647},
        {\"input_name\": \"gender\", \"order\": 2, \"is_active_in_display\": true, \"visible_for_levels_mask\": 2}, // Ex: só para membros (nível 2)
        {\"input_name\": \"secret_field\", \"order\": 3, \"is_active_in_display\": false, \"visible_for_levels_mask\": 0} // Não ativo nesta exibição
      ]
    }
```

```json
    {
      \"values\": [
        {\"value_data\": \"male\", \"lkey_data\": \"_gender_male\", \"order_data\": 1, \"extra_data\": \"\"},
        {\"value_data\": \"female\", \"lkey_data\": \"_gender_female\", \"order_data\": 2, \"extra_data\": \"\"}
      ]
    }
```

#### 2. Criar Novo Objeto de Formulário

*   **Endpoint:** `POST /api/v1/admin/builder/form-objects`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Todos os campos de `sys_objects_form` (ex: `object_name`, `module`, `title_key`, `action_original` (referência), `target_table`, `target_key`, `submit_name_key`, `is_active`).
*   **Resposta de Sucesso (201 Created):** Retorna o objeto de formulário criado.

#### 3. Obter Detalhes de um Objeto de Formulário (incluindo seus campos e exibições)

*   **Endpoint:** `GET /api/v1/admin/builder/form-objects/{form_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `lang`.
*   **Resposta de Sucesso (200 OK):**

#### 4. Atualizar um Objeto de Formulário

*   **Endpoint:** `PUT /api/v1/admin/builder/form-objects/{form_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_form` a serem atualizados.
*   **Resposta de Sucesso (200 OK).**

#### 5. Deletar um Objeto de Formulário

*   **Endpoint:** `DELETE /api/v1/admin/builder/form-objects/{form_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Deleta de `sys_objects_form`. `ON DELETE CASCADE` (se definido) ou deleções manuais removeriam `sys_form_inputs`, `sys_form_displays`, `sys_form_display_inputs` associados.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Campos de Entrada (`/api/v1/admin/builder/form-inputs`)

#### 6. Listar Campos de Entrada para um Objeto de Formulário

*   **Endpoint:** `GET /api/v1/admin/builder/form-inputs?form_object_name={name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_form_inputs` para o `form_object_name` especificado.

#### 7. Criar Novo Campo de Entrada

*   **Endpoint:** `POST /api/v1/admin/builder/form-inputs`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Todos os campos de `sys_form_inputs` (incluindo `object` (form_object_name), `name`, `type`, `caption_key`, `values` (para select/radio, pode ser `#prelist_key` ou JSON de opções), `required`, `checker_func`, `db_pass`, etc.).
*   **Resposta de Sucesso (201 Created).**

#### 8. Obter Detalhes de um Campo de Entrada

*   **Endpoint:** `GET /api/v1/admin/builder/form-inputs/{input_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK).**

#### 9. Atualizar um Campo de Entrada

*   **Endpoint:** `PUT /api/v1/admin/builder/form-inputs/{input_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_form_inputs` a serem atualizados.
*   **Resposta de Sucesso (200 OK).**

#### 10. Deletar um Campo de Entrada

*   **Endpoint:** `DELETE /api/v1/admin/builder/form-inputs/{input_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Também precisaria remover entradas associadas em `sys_form_display_inputs`.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Exibições de Formulário (`/api/v1/admin/builder/form-displays`)

#### 11. Listar Exibições para um Objeto de Formulário

*   **Endpoint:** `GET /api/v1/admin/builder/form-displays?form_object_name={name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_form_displays` para o `form_object_name`.

#### 12. Criar Nova Exibição de Formulário

*   **Endpoint:** `POST /api/v1/admin/builder/form-displays`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `display_name`, `module`, `object` (form_object_name), `title_key`.
*   **Resposta de Sucesso (201 Created).**

#### 13. Atualizar Exibição de Formulário

*   **Endpoint:** `PUT /api/v1/admin/builder/form-displays/{display_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `title_key`.
*   **Resposta de Sucesso (200 OK).**

#### 14. Deletar Exibição de Formulário

*   **Endpoint:** `DELETE /api/v1/admin/builder/form-displays/{display_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Também deletar `sys_form_display_inputs` associados.
*   **Resposta de Sucesso (204 No Content).**

#### 15. Gerenciar Campos em uma Exibição (Adicionar, Remover, Reordenar, Configurar Visibilidade ACL)

*   **Endpoint:** `PUT /api/v1/admin/builder/form-displays/{display_id}/inputs`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Uma lista de objetos, cada um representando um campo na exibição.

*   **Lógica do Backend:** Deleta todos os `sys_form_display_inputs` existentes para o `display_id` e recria com base na lista fornecida.
*   **Resposta de Sucesso (200 OK).**

---
### Gerenciamento de Listas Pré-definidas (`/api/v1/admin/builder/form-prelists`)

#### 16. Listar Todas as Listas Pré-definidas

*   **Endpoint:** `GET /api/v1/admin/builder/form-prelists`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_form_pre_lists`.

#### 17. Criar Nova Lista Pré-definida

*   **Endpoint:** `POST /api/v1/admin/builder/form-prelists`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `key`, `module`, `title_key`, `use_for_sets`, `extendable`.
*   **Resposta de Sucesso (201 Created).**

#### 18. Obter Detalhes de uma Lista Pré-definida (incluindo seus valores)

*   **Endpoint:** `GET /api/v1/admin/builder/form-prelists/{prelist_key}`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `lang`.
*   **Resposta:** Detalhes de `sys_form_pre_lists` e a lista de `sys_form_pre_values` associados (com `LKey` traduzido).

#### 19. Atualizar uma Lista Pré-definida

*   **Endpoint:** `PUT /api/v1/admin/builder/form-prelists/{prelist_key}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_form_pre_lists`.
*   **Resposta de Sucesso (200 OK).**

#### 20. Deletar uma Lista Pré-definida

*   **Endpoint:** `DELETE /api/v1/admin/builder/form-prelists/{prelist_key}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Deleta de `sys_form_pre_lists` e `sys_form_pre_values` associados.
*   **Resposta de Sucesso (204 No Content).**

#### 21. Gerenciar Valores de uma Lista Pré-definida

*   **Endpoint:** `PUT /api/v1/admin/builder/form-prelists/{prelist_key}/values`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Lista completa de objetos `sys_form_pre_values` para este `prelist_key`.

*   **Lógica do Backend:** Deleta todos os `sys_form_pre_values` existentes para o `prelist_key` e recria com base na lista fornecida.
*   **Resposta de Sucesso (200 OK).**

## Considerações:

*   **Complexidade da UI de Admin:** Construir uma UI para gerenciar todas essas interdependências de formulários é complexo. A API deve ser projetada para facilitar isso o máximo possível.
*   **Mapeamento de Validação PHP (`checker_func`):** A API de Admin para campos precisa de uma forma de apresentar e permitir a configuração dessas validações de forma compreensível, mesmo que a lógica de validação Elixir por trás seja um mapeamento.
*   **Traduções:** A interface de admin precisará permitir a edição das chaves de tradução (`title_key`, `caption_key`, `LKey`, etc.) ou das strings de tradução diretamente.

Esta API de gerenciamento de formulários é essencial para permitir que os administradores configurem como os dados são inseridos e validados no sistema \"Deeper\".