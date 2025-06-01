# Documentação Deeper: API de Administração - Gerenciamento de Controle de Acesso (ACL)

Este documento descreve os endpoints da API \"Deeper\" para administradores gerenciarem o sistema de Controle de Acesso (ACL), incluindo Níveis de ACL, Ações de ACL, a Matriz de Permissões e as associações de membros a níveis.

## Escopo e Funcionalidades:

*   CRUD para Níveis de ACL (`sys_acl_levels`).
*   CRUD para Ações de ACL (`sys_acl_actions`) - Embora a criação de ações seja geralmente feita por módulos programaticamente, a API pode permitir visualização e talvez edição limitada.
*   Gerenciamento da Matriz de Permissões (`sys_acl_matrix`) - Definir quais níveis têm quais permissões.
*   Gerenciamento da associação de membros a Níveis de ACL (`sys_acl_levels_members`).
*   Visualização/Gerenciamento do rastreamento de uso de ações (`sys_acl_actions_track`).

## Tabelas Relevantes (Já Definidas em `docs/01_system_core/sys_acl/`):

*   `sys_acl_levels`
*   `sys_acl_actions`
*   `sys_acl_levels_members`
*   `sys_acl_matrix`
*   `sys_acl_actions_track`

## Módulo de Acesso a Dados (Já Definido em `docs/01_system_core/sys_acl/data_access_module.md`):

*   `Deeper.SystemCore.ACLRepo` será utilizado para todas as interações com o banco de dados.

## Endpoints da API de Administração para ACL

Todos os endpoints estão sob `/api/v1/admin/acl/...` e requerem autenticação de administrador com permissões apropriadas para gerenciar ACL.

### Gerenciamento de Níveis de ACL (`sys_acl_levels`)

#### 1. Listar Níveis de ACL
*   **Endpoint:** `GET /api/v1/admin/acl/levels`
    *   (Já definido em `docs/01_system_core/sys_acl/api_endpoints.md` - pode ser referenciado ou duplicado aqui para completude da seção de admin).

#### 2. Criar Novo Nível de ACL
*   **Endpoint:** `POST /api/v1/admin/acl/levels`
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"name_key\": \"_adm_acl_level_new_premium\", // Chave de linguagem para o nome
      \"name_default\": \"New Premium Level\", // Nome padrão se a chave não for encontrada
      \"icon\": \"bx-star\", // Classe do ícone
      \"description_key\": \"_adm_acl_level_new_premium_desc\",
      \"description_default\": \"A new premium membership level.\",
      \"order\": 50,
      \"purchasable\": 1, // 0 ou 1
      \"removable\": 1,   // 0 ou 1
      \"quota_size_mb\": 5000, // Em MB
      \"quota_number_files\": 1000,
      \"quota_max_filesize_mb\": 100
      // ... outros campos de sys_acl_levels ...
    }
```

```json
    {
      \"title_key\": \"_bx_persons_action_edit_profile_title_updated\",
      \"description_key\": \"_bx_persons_action_edit_profile_desc_updated\"
    }
```

```json
    {
      \"data\": [
        {
          \"level_id\": 1,
          \"action_id\": 101,
          \"level_name\": \"Standard Member\", // JOIN com sys_acl_levels
          \"action_name\": \"bx_persons_view_profile\", // JOIN com sys_acl_actions
          \"allowed_count\": null,
          \"period_len_seconds\": null,
          \"period_start\": null,
          \"period_end\": null,
          \"additional_param_value\": null
        }
        // ... mais entradas da matriz ...
      ]
      // Paginação pode ser necessária
    }
```

```json
    {
      \"level_id\": 1,
      \"action_id\": 101,
      \"allowed_count\": 10, // null para ilimitado
      \"period_len_seconds\": 86400, // null para sem período
      \"period_start\": \"2024-01-01T00:00:00Z\", // Opcional
      \"period_end\": \"2024-12-31T23:59:59Z\",   // Opcional
      \"additional_param_value\": null // Se a ação usar parâmetro adicional
    }
```

```json
    {
      \"level_id\": 1,
      \"action_id\": 101
    }
```

```json
    {
      \"data\": [
        {
          \"account_id\": 123, // ou member_id se sys_acl_levels_members.IDMember é account_id
          \"level_id\": 4,
          \"level_name\": \"Administrator\", // JOIN com sys_acl_levels
          \"date_starts\": \"2023-01-01T00:00:00Z\",
          \"date_expires\": null, // ou \"YYYY-MM-DDTHH:MM:SSZ\"
          \"transaction_id\": \"txn_abc123\", // Opcional
          \"state\": \"active\" // Opcional
        }
      ]
    }
```

```json
    {
      \"level_id\": 4,
      \"date_starts\": \"2024-01-01T00:00:00Z\", // Opcional, default now
      \"date_expires\": null, // Opcional, para associação vitalícia
      \"transaction_id\": \"manual_admin_grant_xyz\", // Opcional
      \"state\": \"active\" // Opcional
    }
```

```json
    {
      \"data\": [
        {
          \"action_id\": 101,
          \"action_name\": \"bx_persons_create_profile\",
          \"account_id\": 123, // Ou member_id
          \"actions_left\": 8,
          \"valid_since\": \"2024-01-15T10:00:00Z\"
        }
      ]
    }
```

```json
    {
      \"account_id\": 123,
      \"action_id\": 101 // Opcional, se não fornecido, reseta todos para a conta
    }
```

*   **Resposta de Sucesso (201 Created):** Corpo do nível criado.

#### 3. Obter Detalhes de um Nível de ACL
*   **Endpoint:** `GET /api/v1/admin/acl/levels/{levelId}`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{levelId}` (Integer).
*   **Resposta de Sucesso (200 OK):** Detalhes completos do nível.

#### 4. Atualizar Nível de ACL
*   **Endpoint:** `PUT /api/v1/admin/acl/levels/{levelId}`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{levelId}` (Integer).
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (similar ao POST).
*   **Resposta de Sucesso (200 OK):** Corpo do nível atualizado.

#### 5. Deletar Nível de ACL
*   **Endpoint:** `DELETE /api/v1/admin/acl/levels/{levelId}`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{levelId}` (Integer).
*   **Lógica do Backend:**
    *   Verificar se o nível é `Removable`.
    *   Verificar se há membros ou entradas na matriz de permissões usando este nível. A exclusão pode ser impedida se houver dependências, ou as dependências podem precisar ser tratadas (ex: mover membros para um nível padrão).
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**

### Gerenciamento de Ações de ACL (`sys_acl_actions`)

A criação de ações é geralmente feita programaticamente por módulos. A API de admin focaria em listagem e talvez edição limitada de descrições/títulos.

#### 1. Listar Ações de ACL
*   **Endpoint:** `GET /api/v1/admin/acl/actions`
    *   (Já definido em `docs/01_system_core/sys_acl/api_endpoints.md`).

#### 2. Atualizar Detalhes de uma Ação de ACL (Limitado)
*   **Endpoint:** `PUT /api/v1/admin/acl/actions/{actionId}`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{actionId}` (Integer).
*   **Corpo da Requisição (JSON):** Apenas campos como `Title`, `Desc`, `DisabledForLevels` (se aplicável para edição manual).

*   **Resposta de Sucesso (200 OK):** Corpo da ação atualizada.

### Gerenciamento da Matriz de Permissões (`sys_acl_matrix`)

#### 1. Listar Permissões da Matriz (com filtros)
*   **Endpoint:** `GET /api/v1/admin/acl/matrix`
*   **Autenticação:** Administrador.
*   **Query Parameters:**
    *   `level_id` (Integer, Opcional): Filtrar por ID do Nível.
    *   `action_id` (Integer, Opcional): Filtrar por ID da Ação.
*   **Resposta de Sucesso (200 OK):**

#### 2. Adicionar/Atualizar Permissão na Matriz
*   **Endpoint:** `POST /api/v1/admin/acl/matrix` (Pode ser `PUT` se a combinação `level_id` e `action_id` for a chave para atualização).
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:** Usa UPSERT (INSERT OR REPLACE ou INSERT ON CONFLICT UPDATE) na tabela `sys_acl_matrix`.
*   **Resposta de Sucesso (201 Created ou 200 OK):** Corpo da entrada da matriz criada/atualizada.

#### 3. Remover Permissão da Matriz
*   **Endpoint:** `DELETE /api/v1/admin/acl/matrix`
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):** (Para identificar a entrada a ser removida)

    *Alternativamente, um endpoint como `DELETE /api/v1/admin/acl/matrix/levels/{levelId}/actions/{actionId}` pode ser mais RESTful.*
*   **Resposta de Sucesso (204 No Content).**

### Gerenciamento de Membros de Níveis ACL (`sys_acl_levels_members`)

Estes endpoints seriam mais logicamente agrupados sob o gerenciamento de usuários (`users_and_profiles_admin_api.md`), mas são listados aqui por se relacionarem diretamente com ACL.

#### 1. Listar Associações de Nível para um Usuário
*   **Endpoint:** `GET /api/v1/admin/users/{accountId}/acl-memberships`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{accountId}` (Integer).
*   **Resposta de Sucesso (200 OK):**

#### 2. Adicionar Usuário a um Nível de ACL
*   **Endpoint:** `POST /api/v1/admin/users/{accountId}/acl-memberships`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:** `{accountId}` (Integer).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Detalhes da nova associação.

#### 3. Atualizar Associação de Nível de um Usuário
*   **Endpoint:** `PUT /api/v1/admin/users/{accountId}/acl-memberships/{levelId}` (Ou usando um ID da própria tabela `sys_acl_levels_members` se ela tiver um PK simples).
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (ex: `date_expires`, `state`).
*   **Resposta de Sucesso (200 OK):** Detalhes da associação atualizada.

#### 4. Remover Usuário de um Nível de ACL
*   **Endpoint:** `DELETE /api/v1/admin/users/{accountId}/acl-memberships/{levelId}`
*   **Autenticação:** Administrador.
*   **Resposta de Sucesso (204 No Content).**

### Gerenciamento de Rastreamento de Ações (`sys_acl_actions_track`)

Geralmente é mais para visualização ou reset.

#### 1. Listar Rastreamento de Ações para um Usuário/Ação
*   **Endpoint:** `GET /api/v1/admin/acl/actions-track`
*   **Autenticação:** Administrador.
*   **Query Parameters:**
    *   `account_id` (Integer, Opcional).
    *   `action_id` (Integer, Opcional).
*   **Resposta de Sucesso (200 OK):**

#### 2. Resetar Contadores de Ação para um Usuário (Opcional)
*   **Endpoint:** `POST /api/v1/admin/acl/actions-track/reset`
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Mensagem de confirmação.

Esta API fornece um controle administrativo abrangente sobre o sistema de permissões \"Deeper\". A invalidação de caches relacionados a permissões de usuários pode ser necessária após modificações aqui.