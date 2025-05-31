# API de Administração: Gerenciamento de ACL (Níveis de Controle de Acesso)

Endpoints da API para administradores gerenciarem os Níveis de Controle de Acesso (ACL), as Ações disponíveis e a Matriz de Permissões da plataforma \"Deeper\". Isso é análogo ao sistema ACL do UNA (tabelas `sys_acl_*`).

**Permissões:** Todos os endpoints aqui requerem um papel de administrador do site com plenos poderes sobre a configuração do sistema de permissões.

## Contexto do ACL no UNA (e Adaptação para \"Deeper\")

O sistema ACL do UNA é composto por:
*   **`sys_acl_levels`**: Define os diferentes níveis de membresia (ex: Convidado, Membro Padrão, Membro Premium, Moderador, Administrador). Cada nível pode ter cotas, ser comprável, etc.
*   **`sys_acl_actions`**: Lista todas as ações possíveis no sistema que podem ser controladas por permissões (ex: \"postar artigo\", \"ver perfil privado\", \"criar grupo\").
*   **`sys_acl_matrix`**: O coração do sistema, ligando `IDLevel` com `IDAction` para definir se um nível tem permissão para uma ação, e com quais limites (contagem, período).
*   **`sys_acl_levels_members`**: Associa usuários (via `IDMember`, que no UNA é um ID de perfil, mas para \"Deeper\" pode ser `profile_id` ou `account_id`) a um ou mais níveis, com datas de início e expiração.
*   **`sys_acl_actions_track`**: Rastreia o uso de ações contáveis por membros.

A API de administração \"Deeper\" permitirá o gerenciamento desses componentes.

## Endpoints para Níveis de ACL (`sys_acl_levels`)

### 1. Listar Todos os Níveis de ACL

*   **`GET /admin/acl/levels`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `active` (boolean, para filtrar por níveis ativos/inativos).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"Convidado\",
          \"icon_url\": \"/path/to/guest_icon.png\",
          \"description\": \"Usuários não logados.\",
          \"active\": true,
          \"purchasable\": false,
          \"removable\": false,
          \"quota_size_bytes\": 0,
          \"quota_number_files\": 0,
          \"quota_max_file_size_bytes\": 0,
          \"order_index\": 0,
          \"password_expired_days\": 0, // 0 = nunca expira
          \"password_expired_notify_days\": 0
        },
        {
          \"id\": 2,
          \"name\": \"Membro Padrão\",
          // ... outros campos ...
        }
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"module_name\": \"deeper_articles\", // Módulo que define a ação
          \"action_name\": \"create_article\", // Nome programático da ação
          \"title\": \"Criar Artigo\",
          \"description\": \"Permite ao usuário criar um novo artigo.\",
          \"is_countable\": false, // 'Countable' no UNA
          \"disabled_for_levels_mask\": 3 // Bitmask dos níveis para os quais está desabilitado por padrão (ex: convidado)
        }
        // ...
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"action_id\": 101,
          \"action_name\": \"create_article\", // Nome da ação para facilitar a UI
          \"action_title\": \"Criar Artigo\",
          \"is_allowed\": true, // Derivado da existência na matriz
          \"allowed_count\": null, // Ou número, se for contável
          \"period_length_days\": null, // Ou número
          \"additional_param_value\": null // Se a ação tiver um parâmetro adicional
        },
        {
          \"action_id\": 102,
          \"action_name\": \"delete_own_article\",
          \"action_title\": \"Deletar Próprio Artigo\",
          \"is_allowed\": true
        },
        {
          \"action_id\": 103,
          \"action_name\": \"delete_any_article\",
          \"action_title\": \"Deletar Qualquer Artigo\",
          \"is_allowed\": false // Não há entrada na matriz para este nível/ação
        }
        // ...
      ]
    }
```

```json
    {
      \"permissions\": [
        {
          \"action_id\": 101, // create_article
          \"allow\": true, // Se true, cria/atualiza entrada. Se false, remove entrada da matriz.
          \"allowed_count\": 10, // Opcional
          \"period_length_days\": 30, // Opcional
          \"additional_param_value\": null
        },
        {
          \"action_id\": 103, // delete_any_article
          \"allow\": true // Concedendo permissão
        },
        {
          \"action_id\": 105, // view_premium_content
          \"allow\": false // Revogando/garantindo que não há permissão
        }
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 201, // Ou account_id, dependendo do que IDMember representa
          \"level_id\": 3,
          \"profile_details\": { \"name\": \"Membro Premium 1\", \"email\": \"premium1@example.com\" },
          \"date_starts\": \"2023-01-01T00:00:00Z\",
          \"date_expires\": \"2024-01-01T00:00:00Z\", // Pode ser null
          \"state\": \"active\", // Ex: 'active', 'expired', 'pending_payment'
          \"transaction_id\": \"txn_123abc\" // Opcional
        }
      ]
    }
```

```json
    {
      \"profile_id\": 205,
      \"date_starts\": \"2023-11-01T00:00:00Z\", // Opcional, default now
      \"date_expires\": null, // Opcional, sem expiração
      \"state\": \"active\",
      \"transaction_id\": \"manual_grant_admin\"
    }
```

```json
    {
      \"data\": [
        {
          \"action_id\": 50,
          \"action_name\": \"upload_photo\",
          \"actions_left\": 7,
          \"valid_since\": \"2023-11-01T00:00:00Z\" // Início do período da cota
        }
        // ...
      ]
    }
```

```json
    {
      \"actions_left\": 10, // Novo valor para actions_left
      \"valid_since\": \"2023-11-15T00:00:00Z\" // Novo início de período
    }
```

### 2. Criar Novo Nível de ACL

*   **`POST /admin/acl/levels`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Campos de `sys_acl_levels`.
*   **Resposta de Sucesso (201 Created):** Objeto do nível criado.
*   **Respostas de Erro:** `400` (validação), `401`, `403`.

### 3. Obter Detalhes de um Nível de ACL Específico

*   **`GET /admin/acl/levels/{level_id}`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):** Objeto do nível.
*   **Respostas de Erro:** `404`.

### 4. Atualizar um Nível de ACL

*   **`PUT /admin/acl/levels/{level_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Campos a atualizar.
*   **Resposta de Sucesso (200 OK):** Objeto do nível atualizado.

### 5. Excluir um Nível de ACL
    (Cuidado: o que acontece com usuários nesse nível? E com as entradas na matriz de permissão?)
*   **`DELETE /admin/acl/levels/{level_id}`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:**
    *   Remove o nível de `sys_acl_levels`.
    *   Pode exigir lógica para reatribuir usuários em `sys_acl_levels_members` para um nível padrão ou marcá-los.
    *   Remove entradas associadas em `sys_acl_matrix`.
*   **Resposta de Sucesso (200 OK / 204 No Content):**

## Endpoints para Ações de ACL (`sys_acl_actions`)

### 1. Listar Todas as Ações de ACL

*   **`GET /admin/acl/actions`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `module_name` (para filtrar ações por módulo do UNA, ex: `bx_persons`).
*   **Resposta de Sucesso (200 OK):**

### 2. (Opcional) Criar/Atualizar/Excluir Ações de ACL
    (Ações são geralmente definidas pelo código dos módulos na instalação. Gerenciar via API é menos comum, mas pode ser para customizações.)
*   `POST /admin/acl/actions`
*   `PUT /admin/acl/actions/{action_id}`
*   `DELETE /admin/acl/actions/{action_id}`

## Endpoints para Matriz de Permissões (`sys_acl_matrix`)

### 1. Obter Permissões para um Nível de ACL Específico

*   **`GET /admin/acl/levels/{level_id}/permissions`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):** Lista de ações e suas configurações de permissão para o nível.

    *   A resposta pode listar todas as ações do sistema, indicando `is_allowed` e os detalhes da permissão se houver uma entrada em `sys_acl_matrix` para o `level_id` e `action_id`.

### 2. Atualizar Permissões para um Nível de ACL (Salvar Matriz)

*   **`PUT /admin/acl/levels/{level_id}/permissions`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Uma lista de configurações de permissão para ações.

*   **Ação do Backend:** Itera sobre a lista.
    *   Se `allow: true`, cria ou atualiza a entrada em `sys_acl_matrix` para o `level_id` e `action_id`.
    *   Se `allow: false`, remove a entrada de `sys_acl_matrix` para o `level_id` e `action_id`.
*   **Resposta de Sucesso (200 OK):** `{ \"message\": \"Permissões para o nível atualizadas.\" }`
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

## Endpoints para Membros de Níveis de ACL (`sys_acl_levels_members`)
(Gerenciar quais usuários pertencem a quais níveis)

### 1. Listar Membros de um Nível de ACL

*   **`GET /admin/acl/levels/{level_id}/members`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `page`, `per_page`, `q` (buscar por nome/email do membro), `include=profile_details`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de membros.

### 2. Adicionar um Perfil a um Nível de ACL

*   **`POST /admin/acl/levels/{level_id}/members`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Ação do Backend:** Cria uma entrada em `sys_acl_levels_members`. Pode precisar de lógica para lidar com múltiplas membresias de nível para um usuário (o UNA geralmente permite uma membresia ativa por vez, a de maior \"prioridade\" ou a última definida).
*   **Resposta de Sucesso (201 Created):** Detalhes da nova membresia.

### 3. Atualizar Detalhes da Membresia de Nível de um Perfil

*   **`PUT /admin/acl/levels/{level_id}/members/{profile_id}`** (ou usar um ID da tabela `sys_acl_levels_members` se houver)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Campos a atualizar (ex: `date_expires`, `state`).
*   **Resposta de Sucesso (200 OK):** Detalhes da membresia atualizada.

### 4. Remover um Perfil de um Nível de ACL

*   **`DELETE /admin/acl/levels/{level_id}/members/{profile_id}`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:** Remove a entrada de `sys_acl_levels_members`. Pode precisar reatribuir o usuário a um nível padrão.
*   **Resposta de Sucesso (200 OK / 204 No Content):**

## Endpoints para Rastreamento de Ações (`sys_acl_actions_track`)
(Para gerenciar cotas de ações contáveis)

### 1. Ver Cotas de Ação para um Membro

*   **`GET /admin/acl/members/{profile_id}/action-quotas`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):**

### 2. Resetar/Ajustar Cotas de Ação para um Membro

*   **`PUT /admin/acl/members/{profile_id}/action-quotas/{action_id}`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Cota atualizada.

## Considerações para Repositórios e Contextos:

*   **`Deeper.SystemCore.AclRepo`:**
    *   CRUD para `sys_acl_levels`, `sys_acl_actions`, `sys_acl_matrix`, `sys_acl_levels_members`, `sys_acl_actions_track`.
    *   Funções para buscar permissões da matriz por `level_id`.
    *   Função para aplicar um conjunto de permissões à matriz (inserir/deletar entradas).
*   **`Deeper.SystemCore.Acl` (Contexto/Serviço):**
    *   Verificará permissões de admin.
    *   Orquestrará operações complexas (ex: ao deletar um nível, o que fazer com membros e entradas da matriz).
    *   Lógica para determinar a \"permissão efetiva\" de um usuário para uma ação, considerando todos os seus níveis ativos e a matriz. (Esta lógica é mais para o `Auth` plug e os Contextos de recursos, mas o admin API pode precisar expor essa visão).
*   **Impacto no Sistema:** Mudanças no ACL, especialmente na matriz, têm impacto imediato nas permissões de todos os usuários. O sistema de verificação de permissões (usado pelos controllers para proteger endpoints) precisará ler esses dados atualizados. Pode ser necessário um cache para a matriz de permissões que é invalidado quando ela muda.

Esta API de administração de ACL é fundamental para a segurança e flexibilidade da plataforma \"Deeper\".