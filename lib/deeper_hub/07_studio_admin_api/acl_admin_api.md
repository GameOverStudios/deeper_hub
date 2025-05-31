# API de Administração: Gerenciamento de Controle de Acesso (ACL)

Esta seção da API de Administração \"Deeper\" fornece endpoints para que administradores gerenciem o sistema de Controle de Acesso por Níveis (ACL), baseado nas tabelas `sys_acl_levels`, `sys_acl_actions`, `sys_acl_matrix`, e `sys_acl_levels_members` do UNA.

**Autenticação:** Requerida (nível de superadministrador ou permissões específicas para gerenciar ACL).

## Objetivos da API de Gerenciamento de ACL:

*   Permitir o CRUD para Níveis de Membresia (`sys_acl_levels`).
*   Listar Ações de ACL disponíveis no sistema (`sys_acl_actions`) - geralmente definidas por módulos.
*   Permitir a configuração da Matriz de Permissões (`sys_acl_matrix`), definindo quais níveis podem executar quais ações, com que limites.
*   Gerenciar a associação de membros a níveis de ACL (`sys_acl_levels_members`), incluindo datas de expiração.

## Considerações Importantes:

*   **Impacto das Mudanças:** Alterações no ACL têm impacto direto e imediato nas permissões dos usuários em toda a plataforma.
*   **Cache de ACL:** O backend Elixir \"Deeper\" pode cachear informações de ACL para performance. Atualizações via esta API devem invalidar/atualizar esses caches.
*   **Ações de ACL (`sys_acl_actions`):** No UNA, as ações são geralmente registradas pelos módulos durante sua instalação. A API de admin pode listar essas ações, mas a criação de novas ações via API é menos comum (mais uma tarefa de desenvolvimento de módulo).

## 1. Níveis de Membresia (`/api/v1/admin/acl/levels`)

Interage com `sys_acl_levels`.

### `POST /api/v1/admin/acl/levels`
*   **Descrição:** Cria um novo nível de membresia.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"name\": \"Premium Plus\", // Obrigatório, único
      \"icon\": \"fas fa-star-plus\", // Opcional (caminho ou classe do ícone)
      \"description\": \"Enhanced access and features.\", // Opcional
      \"active\": true, // Obrigatório (yes/no no UNA)
      \"purchasable\": true, // Obrigatório
      \"removable\": true, // Obrigatório
      \"quota_size\": 10737418240, // Em bytes (ex: 10GB)
      \"quota_number\": 1000, // Número de arquivos
      \"quota_max_file_size\": 1073741824, // Em bytes (ex: 1GB)
      \"order_index\": 20, // Ordem de exibição
      \"password_expired_days\": 90, // Dias para expiração da senha (0 = nunca)
      \"password_expired_notify_days\": 7 // Dias antes para notificar
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_acl_levels.ID
          \"name\": \"Standard\",
          \"description\": \"Basic access level\",
          \"active\": true,
          \"purchasable\": false,
          \"order_index\": 10,
          // ... todos os campos de sys_acl_levels
        }
      ],
      \"pagination\": { ... } // Se houver muitos níveis
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101, // sys_acl_actions.ID
          \"module\": \"bx_persons\",
          \"name\": \"view_profile\", // sys_acl_actions.Name
          \"title\": \"View Person Profile\", // sys_acl_actions.Title
          \"countable\": false, // Mapeado de sys_acl_actions.Countable
          \"disabled_for_levels\": 3 // Máscara de bits (ou lista de IDs) dos níveis para os quais esta ação é inerentemente desabilitada
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": {
        \"level_id\": 1,
        \"level_name\": \"Standard\",
        \"permissions\": [
          {
            \"action_id\": 101, // sys_acl_actions.ID
            \"action_name\": \"view_profile\", // Nome da ação para referência
            \"action_module\": \"bx_persons\",
            \"allowed_count\": null, // ou número se for contável
            \"allowed_period_len_days\": null, // ou número de dias
            // \"allowed_period_start\": \"YYYY-MM-DD HH:MM:SS\", // Opcional
            // \"allowed_period_end\": \"YYYY-MM-DD HH:MM:SS\", // Opcional
            \"additional_param_value\": null // Se a ação tiver um parâmetro adicional
          }
          // ... mais permissões para este nível
        ]
      }
    }
```

```json
    {
      \"level_id\": 1,
      \"permissions_to_set\": [ // Lista de permissões para este nível
        {
          \"action_id\": 101,
          \"allowed_count\": null, // null para ilimitado, ou um número
          \"allowed_period_len_days\": null // null para sempre, ou número de dias
        },
        {
          \"action_id\": 105, // Ex: 'create_market_entry'
          \"allowed_count\": 5,
          \"allowed_period_len_days\": 30 // 5 entradas a cada 30 dias
        }
      ],
      \"permissions_to_remove\": [ // Lista de action_ids a serem removidas deste nível
        102
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"level_id\": 1,
          \"level_name\": \"Standard\",
          \"date_starts\": \"2023-01-01 00:00:00\",
          \"date_expires\": null, // ou \"YYYY-MM-DD HH:MM:SS\"
          \"is_active\": true // Calculado com base nas datas
        }
      ]
    }
```

```json
    {
      \"profile_id\": 15,
      \"level_id\": 2, // Ex: \"Premium\"
      \"date_starts\": \"2023-11-01 00:00:00\", // Opcional, default agora
      \"date_expires\": \"2024-11-01 00:00:00\" // Opcional, null para sem expiração
    }
```

```json
    {
      \"data\": {
        \"action_id\": 105,
        \"profile_id\": 15,
        \"actions_left\": 3,
        \"valid_since\": \"2023-10-28 00:00:00\" // Início do período atual
      }
    }
```

*   **Resposta de Sucesso (201 Created):** Detalhes do nível criado.
*   **Respostas de Erro:** `400`, `422` (ex: nome já existe).

### `GET /api/v1/admin/acl/levels`
*   **Descrição:** Lista todos os níveis de membresia.
*   **Query Parameters:** `active` (boolean), `purchasable` (boolean), `sort_by` (ex: `\"order_index_asc\"`).
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/admin/acl/levels/{level_id}`
*   **Descrição:** Obtém detalhes de um nível de membresia específico.
*   **Resposta de Sucesso (200 OK):** Detalhes do nível.
*   **Respostas de Erro:** `404 Not Found`.

### `PUT /api/v1/admin/acl/levels/{level_id}`
*   **Descrição:** Atualiza um nível de membresia existente.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Resposta de Sucesso (200 OK):** Detalhes do nível atualizado.
*   **Respostas de Erro:** `400`, `404`, `422`.

### `DELETE /api/v1/admin/acl/levels/{level_id}`
*   **Descrição:** Deleta um nível de membresia. **Cuidado:** O que acontece com membros nesse nível? Eles devem ser movidos para um nível padrão ou a exclusão deve ser impedida se houver membros? A API deve ter uma política clara (ex: parâmetro `force=true` ou mover para um nível `default_level_id`).
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**
*   **Respostas de Erro:** `404`, `409 Conflict` (se não puder ser deletado devido a membros).

## 2. Ações de ACL (`/api/v1/admin/acl/actions`)

Interage com `sys_acl_actions`. Geralmente, estas são mais para visualização e referência no contexto da matriz de permissões.

### `GET /api/v1/admin/acl/actions`
*   **Descrição:** Lista todas as ações de ACL definidas no sistema.
*   **Query Parameters:**
    *   `module_name` (string): Filtra ações por módulo do UNA (ex: `\"bx_persons\"`).
    *   `search_term` (string): Busca no nome ou título da ação.
    *   `page`, `per_page`.
*   **Resposta de Sucesso (200 OK):**

*(Endpoints para criar/editar/deletar Ações de ACL geralmente não são expostos, pois são definidos pelo código dos módulos).*

## 3. Matriz de Permissões (`/api/v1/admin/acl/matrix`)

Interage com `sys_acl_matrix`. Esta é a interface principal para definir \"quem pode fazer o quê\".

### `GET /api/v1/admin/acl/matrix?level_id={level_id}`
*   **Descrição:** Obtém todas as permissões definidas para um nível de membresia específico.
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/admin/acl/matrix?action_id={action_id}`
*   **Descrição:** Obtém todas as permissões definidas para uma ação de ACL específica, mostrando quais níveis a possuem.
*   **Resposta de Sucesso (200 OK):** Similar ao anterior, mas agrupado ou focado na ação.

### `PUT /api/v1/admin/acl/matrix`
*   **Descrição:** Define ou atualiza uma ou múltiplas permissões na matriz. Ação complexa.
*   **Corpo da Requisição (JSON):** Pode ser uma lista de objetos de permissão.

*   **Lógica do Backend:**
    *   Para cada item em `permissions_to_set`: Insere ou atualiza a entrada em `sys_acl_matrix` para o `level_id` e `action_id`.
    *   Para cada `action_id` em `permissions_to_remove`: Deleta a entrada de `sys_acl_matrix`.
    *   **Invalidar Cache de ACL.**
*   **Resposta de Sucesso (200 OK):** Status da operação, talvez a lista de permissões atualizada para o nível.
*   **Respostas de Erro:** `400`, `404` (level_id ou action_id inválido).

## 4. Membros e Níveis (`/api/v1/admin/acl/memberships`)

Interage com `sys_acl_levels_members` e `sys_acl_actions_track`.

### `GET /api/v1/admin/acl/memberships?profile_id={profile_id}`
*   **Descrição:** Lista os níveis de ACL aos quais um perfil específico pertence.
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/admin/acl/memberships?level_id={level_id}`
*   **Descrição:** Lista todos os perfis que pertencem a um nível de ACL específico.
*   **Query Parameters:** `page`, `per_page`, `preload` (ex: `\"profile_summary\"`)
*   **Resposta de Sucesso (200 OK):** Lista de perfis com detalhes da membresia.

### `POST /api/v1/admin/acl/memberships`
*   **Descrição:** Adiciona um perfil a um nível de ACL.
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:**
    *   Insere em `sys_acl_levels_members`.
    *   **Invalidar Cache de ACL para este usuário.**
*   **Resposta de Sucesso (201 Created):** Detalhes da nova associação.

### `PUT /api/v1/admin/acl/memberships/{membership_id_or_profile_level_pair}`
*   **Descrição:** Atualiza uma associação de nível existente (ex: estender data de expiração).
    *   Identificar a entrada em `sys_acl_levels_members` (pode precisar de um ID primário para esta tabela, ou usar `profile_id` e `level_id` como chave composta para a API). Se `sys_acl_levels_members` tiver `IDMember` e `IDLevel` como chave, isso pode ser usado.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (ex: `date_expires`).
*   **Resposta de Sucesso (200 OK).**

### `DELETE /api/v1/admin/acl/memberships/{membership_id_or_profile_level_pair}`
*   **Descrição:** Remove um perfil de um nível de ACL.
*   **Resposta de Sucesso (204 No Content).**

### `GET /api/v1/admin/acl/memberships/actions-track?profile_id={profile_id}&action_id={action_id}`
*   **Descrição:** Obtém o status de rastreamento de uma ação contável para um perfil (`sys_acl_actions_track`).
*   **Resposta de Sucesso (200 OK):**

### `PUT /api/v1/admin/acl/memberships/actions-track`
*   **Descrição:** Administrador ajusta manualmente o `actions_left` ou `valid_since` para um usuário/ação.
*   **Corpo da Requisição (JSON):** `{ \"profile_id\": 15, \"action_id\": 105, \"actions_left\": 10 }`
*   **Resposta de Sucesso (200 OK).**

## Considerações Finais:

*   **Complexidade:** A API de ACL é poderosa e, portanto, complexa. As operações devem ser bem testadas.
*   **Interface de Usuário (Admin):** Uma interface de administração para ACL precisará ser muito clara para evitar configurações incorretas. A API deve fornecer dados de forma que facilite a construção dessa UI.
*   **Logs de Auditoria:** Todas as alterações no ACL devem ser meticulosamente registradas em `sys_audit`.

Esta API de administração do ACL é fundamental para controlar as permissões e funcionalidades disponíveis para diferentes grupos de usuários na plataforma \"Deeper\".