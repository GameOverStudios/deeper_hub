# Endpoints da API de Admin para Gerenciamento de Perfis de Pessoas (`bx_persons`)

Endpoints para administrar perfis de pessoas. O `{person_content_id}` geralmente se refere a `bx_persons_data.id`. O `{profile_id}` refere-se a `sys_profiles.id`.

## Endpoints (`/api/v1/admin/content/persons`):

### 1. Listar Todos os Perfis de Pessoas (Visão Administrativa)

*   **Endpoint:** `GET /api/v1/admin/content/persons`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:**
    *   `page`, `per_page`, `sort_by` (ex: `fullname_asc`, `added_desc`).
    *   Filtros: `filter_fullname_like`, `filter_email_like` (da conta), `filter_profile_status` (`active`, `pending`, `suspended` de `sys_profiles`), `filter_account_status` (`active`, `locked`, `pending_email_confirmation` de `sys_accounts`), `filter_is_featured`. `lang`.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"person_content_id\": 789, // bx_persons_data.id
          \"profile_id\": 456, // sys_profiles.id
          \"account_id\": 123, // sys_accounts.id
          \"fullname\": \"John Doe\",
          \"email\": \"john.doe@example.com\",
          \"profile_status\": \"active\",
          \"account_status\": \"active\",
          \"is_featured\": true,
          \"date_added_timestamp\": 1678886400
        }
        // ... outros perfis ...
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"fullname\": \"Johnathan Doe (Admin Edit)\",
      \"description\": \"Descrição atualizada pelo administrador.\",
      \"location\": \"Nova Localização Admin\",
      \"is_featured\": false, // Ex: remover de destaque
      \"settings_json\": \"{\\\"custom_admin_flag\\\": true}\" // Atualizar o campo settings
      // Não incluir campos de sys_profiles ou sys_accounts aqui, usar endpoints dedicados.
    }
```

### 2. Obter Detalhes Completos de um Perfil de Pessoa (Visão Administrativa)

*   **Endpoint:** `GET /api/v1/admin/content/persons/{person_content_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna um objeto JSON com todos os campos de `bx_persons_data`, informações relevantes de `sys_profiles` (como `status`, `type`), e informações relevantes de `sys_accounts` (como `email`, `status`, `role`, `locked`). Inclui também URLs de avatar/capa, contadores, etc.

### 3. Atualizar Dados de um Perfil de Pessoa (Administrativo)

*   **Endpoint:** `PUT /api/v1/admin/content/persons/{person_content_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Um objeto com os campos de `bx_persons_data` a serem atualizados. Administradores podem ter permissão para alterar mais campos do que o próprio usuário.

*   **Resposta de Sucesso (200 OK):** Retorna os dados do perfil de pessoa atualizado.
*   **Lógica do Backend:** Usa `PersonsRepo.update_person_data`.

### 4. Atualizar Status do Perfil (`sys_profiles.status`)

*   **Endpoint:** `PUT /api/v1/admin/content/persons/{person_content_id}/profile-status`
    *   Alternativamente, pode ser `PUT /api/v1/admin/profiles/{profile_id}/status` (como definido anteriormente na API de admin de usuários/perfis, o que é mais consistente). Se usarmos esta rota, o `person_content_id` seria usado para encontrar o `profile_id` correspondente.
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `{\"status\": \"suspended\"}` (Valores: `active`, `pending`, `suspended`).
*   **Resposta de Sucesso (200 OK).**
*   **Lógica do Backend:**
    1.  Encontra o `sys_profiles.id` associado ao `person_content_id` (onde `type='bx_persons'`).
    2.  Chama `ProfilesRepo.update_status(profile_id, new_status)`.

### 5. Gerenciar Status da Conta Associada (`sys_accounts`)

*   Estes endpoints já foram definidos em `07_studio_admin_api/users_and_profiles/api_endpoints.md` e seriam usados aqui:
    *   `PUT /api/v1/admin/users/{account_id}/activate`
    *   `PUT /api/v1/admin/users/{account_id}/deactivate`
    *   `PUT /api/v1/admin/users/{account_id}/lock`
    *   `PUT /api/v1/admin/users/{account_id}/unlock`
    *   `PUT /api/v1/admin/users/{account_id}/confirm-email`
*   A UI de admin para gerenciar um perfil `bx_persons` precisaria saber o `account_id` associado para invocar estas ações.

### 6. Deletar um Perfil de Pessoa (Administrativo)

*   **Endpoint:** `DELETE /api/v1/admin/content/persons/{person_content_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters (Opcionais):**
    *   `delete_account_if_last_profile=true` (boolean, default `false`): Se a conta `sys_accounts` associada deve ser deletada caso este seja seu único perfil.
*   **Resposta de Sucesso (204 No Content).**
*   **Lógica do Backend:**
    1.  Busca `sys_profiles` por `content_id = person_content_id` e `type = 'bx_persons'` para obter `profile_id` e `account_id`.
    2.  Deleta o registro de `bx_persons_data` (usando `PersonsRepo.delete_person_data(person_content_id)`).
    3.  Deleta o registro de `sys_profiles` (usando `ProfilesRepo.delete_profile(profile_id)`).
    4.  Se `delete_account_if_last_profile` for `true`:
        *   Verifica se existem outros perfis em `sys_profiles` para o `account_id`.
        *   Se não, deleta a conta `sys_accounts` (usando `AccountsRepo.delete_account(account_id)`).
    5.  Todas as operações devem ser transacionais.

### 7. Gerenciar Fotos de Perfil (Administrativo)

*   **Listar Fotos:** `GET /api/v1/admin/content/persons/{person_content_id}/pictures`
    *   Similar ao endpoint público, mas pode mostrar fotos privadas ou com status pendente.
*   **Aprovar Foto:** `PUT /api/v1/admin/files/meta/{storage_object_name}/{file_identifier}/approve` (endpoint genérico de arquivos com lógica de aprovação)
    *   Pode mudar um status na tabela de metadados da foto ou simplesmente torná-la visível.
*   **Deletar Foto:** `DELETE /api/v1/admin/files/{storage_object_name}/{file_identifier}` (endpoint genérico de arquivos, como já definido, mas usado por admin).

### 8. Definir/Remover Perfil como \"Destaque\" (Featured)

*   **Endpoint:** `PUT /api/v1/admin/content/persons/{person_content_id}/feature`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `{\"is_featured\": true}` ou `{\"is_featured\": false}`.
*   **Resposta de Sucesso (200 OK):** Retorna o status atualizado.
*   **Lógica do Backend:** Atualiza `bx_persons_data.featured`.

## Considerações:

*   **Ações em Lote:** Para listagens administrativas, a capacidade de realizar ações em lote (ex: deletar múltiplos perfis, marcar vários como spam) é muito útil. Isso exigiria endpoints como `POST /api/v1/admin/content/persons/bulk-action` com um corpo especificando a ação e uma lista de `person_content_id`s.
*   **Logs de Auditoria:** Todas as ações administrativas significativas devem ser registradas.

Esta API de gerenciamento para perfis de pessoas dá aos administradores as ferramentas necessárias para moderar e manter esta seção crucial da plataforma. Abordagens similares seriam aplicadas para gerenciar outros tipos de conteúdo (posts, eventos, etc.).