# Documentação Deeper Studio API: Gerenciamento de Controle de Acesso (ACL)

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento completo do Sistema de Controle de Acesso (ACL) do UNA. Isso inclui a criação, leitura, atualização e deleção de Níveis de ACL (`sys_acl_levels`), Ações ACL (`sys_acl_actions`), e as entradas na Matriz de Permissões (`sys_acl_matrix`).

**Objetivo Principal:** Permitir que administradores configurem finamente as permissões para diferentes níveis de usuários na plataforma \"Deeper\".

## Tabelas Relevantes (já definidas e migradas):

*   `sys_acl_levels`
*   `sys_acl_actions`
*   `sys_acl_matrix`
*   `sys_acl_levels_members` (gerenciada em `users_and_profiles/`, mas relevante aqui para entender o contexto dos níveis)
*   `sys_acl_actions_track` (gerenciada internamente, mas as configurações aqui afetam seu uso)

## Módulo de Acesso a Dados (`Deeper.SystemCore.AclRepo`):

O `AclRepo` (já parcialmente definido para leitura em `01_system_core/sys_acl/`) precisará ser estendido com funções CRUD completas para as tabelas `sys_acl_levels`, `sys_acl_actions`, e `sys_acl_matrix`.

**Funções Adicionais Chave no `AclRepo`:**

*   CRUD para `sys_acl_levels`: `create_level`, `get_level`, `list_levels`, `update_level`, `delete_level`.
*   CRUD para `sys_acl_actions`: `create_action`, `get_action_by_id_or_name`, `list_actions` (com filtros por módulo), `update_action`, `delete_action`.
*   CRUD para `sys_acl_matrix`: `set_matrix_permission` (cria ou atualiza), `get_matrix_permission_details`, `list_matrix_permissions` (filtrado por nível ou ação), `delete_matrix_permission`.

## Endpoints da API de Administração para ACL (`/api/v1/admin/acl`):

---
### Gerenciamento de Níveis de ACL (`/api/v1/admin/acl/levels`)

#### 1. Listar Todos os Níveis de ACL

*   **Endpoint:** `GET /api/v1/admin/acl/levels`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `sort_by` (ex: `Order_asc`, `Name_asc`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"Visitante\",
          \"description\": \"Usuários não logados\",
          \"icon\": \"far user\",
          \"order\": 1,
          \"is_active\": true, // Convertido de 'yes'/'no'
          \"is_purchasable\": false
        }
        // ... outros níveis ...
      ]
    }
```

```json
    {
      \"name\": \"Premium Member\",
      \"icon\": \"fas star\",
      \"description\": \"Membros com acesso a recursos premium.\",
      \"is_active\": true,
      \"is_purchasable\": true,
      \"is_removable\": true,
      \"quota_size\": 5368709120, // 5GB em bytes
      \"quota_number\": 1000,
      \"quota_max_file_size\": 104857600, // 100MB
      \"order\": 10,
      \"password_expired_days\": 90,
      \"password_expired_notify_days\": 7
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 10,
          \"module\": \"bx_persons\",
          \"name\": \"view_profile\",
          \"title\": \"Visualizar Perfil\", // Traduzido
          \"description\": \"Permite visualizar perfis de outros membros.\", // Traduzido
          \"is_countable\": false,
          \"disabled_for_levels_mask\": 3
        }
        // ... outras ações ...
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"level_id\": 2, // Ex: Membro
          \"level_name\": \"Membro\",
          \"action_id\": 10,
          \"action_module\": \"bx_persons\",
          \"action_name\": \"view_profile\",
          \"action_title\": \"Visualizar Perfil\",
          \"allowed_count\": null, // null para ilimitado/não aplicável
          \"allowed_period_len_days\": null,
          \"allowed_period_start\": null, // ISO8601 ou null
          \"allowed_period_end\": null,   // ISO8601 ou null
          \"additional_param_value\": null
        }
        // ... outras entradas da matriz ...
      ]
    }
```

```json
    {
      \"level_id\": 2,
      \"action_id\": 10,
      \"allowed_count\": 5, // null para ilimitado
      \"allowed_period_len_days\": 1, // null se não aplicável
      \"allowed_period_start\": \"2024-01-01T00:00:00Z\", // Opcional
      \"allowed_period_end\": null, // Opcional
      \"additional_param_value\": null // Opcional
    }
```

#### 2. Criar Novo Nível de ACL

*   **Endpoint:** `POST /api/v1/admin/acl/levels`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Retorna o nível criado.

#### 3. Obter Detalhes de um Nível de ACL

*   **Endpoint:** `GET /api/v1/admin/acl/levels/{level_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do nível.

#### 4. Atualizar um Nível de ACL

*   **Endpoint:** `PUT /api/v1/admin/acl/levels/{level_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Retorna o nível atualizado.

#### 5. Deletar um Nível de ACL

*   **Endpoint:** `DELETE /api/v1/admin/acl/levels/{level_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:**
    *   Verificar se o nível não está em uso (`sys_acl_levels_members`, `sys_acl_matrix`).
    *   Se `Removable` for `false` no DB, pode impedir a deleção.
*   **Resposta de Sucesso (204 No Content).**
*   **Respostas de Erro:** `409 Conflict` (se em uso e não puder ser deletado).

---
### Gerenciamento de Ações ACL (`/api/v1/admin/acl/actions`)

#### 6. Listar Todas as Ações ACL

*   **Endpoint:** `GET /api/v1/admin/acl/actions`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `filter_module`, `filter_name_like`, `sort_by` (ex: `Module_asc`, `Name_asc`).
*   **Resposta de Sucesso (200 OK):**

#### 7. Criar Nova Ação ACL (Menos comum, geralmente ações são definidas por módulos)

*   **Endpoint:** `POST /api/v1/admin/acl/actions`
*   **Autenticação:** Requer JWT de Super Admin.
*   **Corpo da Requisição (JSON):** `module`, `name`, `title`, `description`, `is_countable`, `disabled_for_levels_mask`, `additional_param_name`.
*   **Resposta de Sucesso (201 Created):** Retorna a ação criada.

#### 8. Obter Detalhes de uma Ação ACL

*   **Endpoint:** `GET /api/v1/admin/acl/actions/{action_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes da ação.

#### 9. Atualizar uma Ação ACL

*   **Endpoint:** `PUT /api/v1/admin/acl/actions/{action_id}`
*   **Autenticação:** Requer JWT de Super Admin.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Retorna a ação atualizada.

#### 10. Deletar uma Ação ACL (Raro e perigoso)

*   **Endpoint:** `DELETE /api/v1/admin/acl/actions/{action_id}`
*   **Autenticação:** Requer JWT de Super Admin.
*   **Lógica:** Também precisaria remover entradas associadas em `sys_acl_matrix` e `sys_acl_actions_track`.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento da Matriz de Permissões (`/api/v1/admin/acl/matrix`)

#### 11. Listar Permissões da Matriz

*   **Endpoint:** `GET /api/v1/admin/acl/matrix`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:**
    *   `level_id`: Filtrar por nível de ACL.
    *   `action_id`: Filtrar por ação ACL.
    *   `module_name`: Filtrar por ações de um módulo específico (requer JOIN com `sys_acl_actions`).
*   **Resposta de Sucesso (200 OK):**

#### 12. Definir/Atualizar Permissão na Matriz

*   **Endpoint:** `PUT /api/v1/admin/acl/matrix`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:** Usa `AclRepo.set_matrix_permission` que faz um `INSERT OR REPLACE` (ou `UPDATE` e `INSERT` se não existir) em `sys_acl_matrix`.
*   **Resposta de Sucesso (200 OK):** Retorna a entrada da matriz atualizada/criada.

#### 13. Remover Permissão da Matriz

*   **Endpoint:** `DELETE /api/v1/admin/acl/matrix/level/{level_id}/action/{action_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (204 No Content).**
*   **Lógica do Backend:** Deleta a entrada de `sys_acl_matrix`.

## Considerações:

*   **Traduções:** Títulos de níveis e ações são chaves de tradução e devem ser fornecidos traduzidos pela API (usando o `lang` query param e `LocalizationRepo`).
*   **Validação:** Entradas para `allowed_count`, `allowed_period_len`, e datas devem ser validadas.
*   **Interface de Usuário:** Gerenciar a matriz de ACL pode ser complexo. A UI de admin geralmente exibe isso como uma tabela grande (níveis vs. ações). A API deve facilitar a obtenção dos dados para construir tal UI.
*   **Impacto:** Alterações na matriz de ACL têm impacto imediato nas permissões dos usuários.
*   **Cache:** Se as permissões da matriz são cacheadas no backend \"Deeper\" (pelo `AclService`), o cache deve ser invalidado após qualquer modificação na matriz.

Esta API de gerenciamento de ACL dá aos administradores o poder de definir com precisão o que cada nível de usuário pode fazer na plataforma \"Deeper\".