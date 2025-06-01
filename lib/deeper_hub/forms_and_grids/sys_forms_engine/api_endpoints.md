# Documentação Deeper: Endpoints da API para Motor de Formulários

Este documento especifica os endpoints RESTful da API \"Deeper\" para obter definições de formulários e para submeter dados de formulários.

## Convenções Gerais:

*   **Base URL:** `/api/v1/forms`
*   **Identificadores:**
    *   `{form_object_name}`: O nome do \"objeto de formulário\" (de `sys_objects_form.object`, ex: `bx_persons_add_profile`, `bx_events_edit_event`).
*   **Autenticação:** A obtenção da definição de um formulário pode ser pública ou protegida dependendo do formulário. A submissão de formulários (POST/PUT) é geralmente protegida.
*   **Formato de Resposta/Requisição:** JSON.
*   **Códigos de Status e Erros:** Conforme `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Obter Definição de um Formulário

*   **Endpoint:** `GET /forms/{form_object_name}/definition`
*   **Status:** Público ou Protegido (dependendo do formulário e permissões ACL para visualizá-lo)
*   **Descrição:** Retorna a estrutura completa de um formulário, incluindo seus atributos, campos, e opções para campos de seleção.
*   **Parâmetros de URL:**
    *   `{form_object_name}`: Nome do objeto de formulário.
*   **Query Parameters:**
    *   `display_name=<name>`: (Opcional) Nome da exibição do formulário (de `sys_form_displays.display_name`). Se omitido, o backend pode usar uma exibição padrão ou retornar todos os campos base.
    *   `context_entity_id=<id>`: (Opcional) Se o formulário for para editar uma entidade existente, este é o ID da entidade. Usado para pré-preencher o formulário com os valores atuais.
    *   `language=<lang_code>`: (Opcional) Para obter legendas e opções de lista no idioma especificado.
*   **Cabeçalhos da Requisição (Opcional):**
    *   `Authorization: Bearer <jwt_token>`: Se o formulário ou seus campos tiverem visibilidade restrita por ACL.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"object\": \"bx_persons_edit_profile\",
        \"title\": \"Editar Perfil\",
        \"action_intent_url\": \"/api/v1/persons/me\", // URL da API para submeter este formulário
        \"action_intent_method\": \"PUT\",
        \"submit_label\": \"Salvar Alterações\",
        \"fields\": [
          {
            \"name\": \"fullname\",
            \"type\": \"text\",
            \"label\": \"Nome Completo\",
            \"value\": \"John Doe Existing\", // Pré-preenchido
            \"required\": true,
            \"info\": \"Seu nome como aparecerá no perfil.\",
            \"validation_rules\": {\"required\": true, \"min_length\": 3},
            \"error_message_key\": \"_bx_persons_err_fullname_required\"
          },
          {
            \"name\": \"gender\",
            \"type\": \"select\",
            \"label\": \"Gênero\",
            \"value\": \"male\", // Valor atual selecionado
            \"options\": [
              {\"value\": \"male\", \"label\": \"Masculino\"},
              {\"value\": \"female\", \"label\": \"Feminino\"},
              {\"value\": \"other\", \"label\": \"Outro\"}
            ]
          }
          // ... outros campos
        ]
      }
    }
```

```json
    {
      \"fullname\": \"Johnathan Doe Updated\",
      \"gender\": \"male\",
      \"description\": \"Uma nova descrição.\"
      // ... outros campos e seus valores
    }
```

```json
    {
      \"data\": {
        \"record_id\": 789, // ID do registro criado/atualizado na tabela de destino
        \"message\": \"Dados salvos com sucesso!\",
        // \"redirect_url\": \"/profiles/johnathan-doe-updated\" // Opcional, se o UNA especificava um redirecionamento
        // \"updated_entity\": { ... } // Opcional, o registro atualizado
      }
    }
```

```json
    {
      \"error\": {
        \"code\": \"VALIDATION_ERROR\",
        \"message\": \"Um ou mais campos falharam na validação.\",
        \"field_errors\": {
          \"fullname\": \"O nome completo deve ter pelo menos 3 caracteres.\",
          \"email\": \"Formato de email inválido.\"
        },
        \"global_errors\": [] // Erros não específicos de um campo
      }
    }
```

```json
    {
      \"data\": {
        \"list_key\": \"{list_key}\",
        \"values\": [
          {\"value\": \"male\", \"label\": \"Masculino\"},
          {\"value\": \"female\", \"label\": \"Feminino\"}
        ]
      }
    }
```

*   **Erros Comuns:**
    *   `404 Not Found`: Formulário `{form_object_name}` ou exibição `display_name` não encontrado.
    *   `403 Forbidden`: Usuário não tem permissão para acessar a definição deste formulário.
*   **Lógica do Backend (Controller):**
    1.  Extrair `user_level_id` do JWT (se presente).
    2.  Coletar `context_params` (ex: `%{entity_id: context_entity_id}`).
    3.  Chamar `FormsRepo.get_form_definition/4` com `form_object_name`, `display_name`, `user_level_id`, `context_params` (e `language_code`).
    4.  Mapear `sys_objects_form.action` para uma `action_intent_url` e `action_intent_method` da API \"Deeper\".
    5.  Formatar e retornar a resposta.

### 2. Submeter Dados de um Formulário

*   **Endpoint:** `POST /forms/{form_object_name}/submit`
    *   (Nota: O cliente também pode submeter diretamente para endpoints de recursos, ex: `POST /api/v1/persons` ou `PUT /api/v1/persons/me`, se a UI do cliente for construída dessa forma. Este endpoint `/forms/.../submit` é mais genérico se o cliente não souber o endpoint de recurso específico de antemão e depender da `action_intent_url` retornada pela definição do formulário).
*   **Status:** Protegido
*   **Descrição:** Recebe dados submetidos de um formulário, valida-os e processa a ação principal (geralmente criar ou atualizar um registro).
*   **Parâmetros de URL:**
    *   `{form_object_name}`: Nome do objeto de formulário.
*   **Corpo da Requisição (JSON):** Um mapa de `{field_name: value}`.

*   **Query Parameters (Opcional):**
    *   `context_entity_id=<id>`: Se for um formulário de edição, para identificar o registro a ser atualizado.
*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Resposta de Erro de Validação (422 Unprocessable Entity):**

*   **Outros Erros Comuns:**
    *   `401 Unauthorized`/`403 Forbidden`.
    *   `404 Not Found`: Formulário não encontrado.
*   **Lógica do Backend (Controller):**
    1.  Extrair `user_profile_id` do JWT.
    2.  Chamar `FormsRepo.submit_form_data/3` com `form_object_name`, dados submetidos, e `user_profile_id` (o Repo pode usar `context_entity_id` para determinar se é INSERT ou UPDATE).
    3.  Se `{:ok, result}`, formatar resposta de sucesso.
    4.  Se `{:error, validation_result}`, formatar resposta de erro de validação.

### 3. Obter Valores de uma Lista Pré-definida (Utilitário)

*   **Endpoint:** `GET /forms/predefined-lists/{list_key}`
*   **Status:** Público
*   **Descrição:** Retorna os valores e legendas para uma lista pré-definida específica.
*   **Parâmetros de URL:**
    *   `{list_key}`: A chave da lista (de `sys_form_pre_lists.\"key\"`).
*   **Query Parameters:**
    *   `language=<lang_code>`: (Opcional) Para obter legendas traduzidas.
*   **Resposta de Sucesso (200 OK):**

*   **Erros Comuns:**
    *   `404 Not Found`: Lista `{list_key}` não encontrada.
*   **Lógica do Backend (Controller):**
    1.  Chamar `FormsRepo.get_predefined_list_values/2`.

### Considerações:

*   **Mapeamento de `sys_objects_form.action`:** A `action` original no UNA é uma URL PHP. A API \"Deeper\" precisa de uma forma de mapear isso para uma \"intenção\" ou para um endpoint de API \"Deeper\" específico. A resposta da definição do formulário deve incluir essa `action_intent_url` e `action_intent_method` para o cliente.
*   **Upload de Arquivos:** Para formulários com campos de upload de arquivo, a submissão provavelmente será `multipart/form-data`. O endpoint de submissão precisará lidar com isso. A API de definição do formulário deve indicar quais campos são de arquivo e qual endpoint de upload de arquivo usar (ver `06_file_management/`). Após o upload, o ID/referência do arquivo seria incluído na submissão JSON principal para o formulário.
*   **Validação:** O cliente pode usar as `validation_rules` retornadas na definição para validação do lado do cliente, mas o backend *sempre* revalidará.
*   **Complexidade dos Campos:** Campos como `input_set` (conjuntos de campos repetíveis) ou `location` (com mapa) exigirão estruturas de dados específicas na requisição/resposta e lógica de processamento no `FormsRepo`.