# Documentação Deeper: Endpoints da API (Pública/Admin) para Controle de Acesso (ACL)

Este documento especifica os endpoints da API RESTful \"Deeper\" relacionados à consulta da estrutura de Controle de Acesso (ACL). A *aplicação* das regras de ACL é uma responsabilidade transversal embutida na maioria dos endpoints da API. Os endpoints listados aqui são primariamente para visualização da configuração do ACL, útil para administração e depuração.

**Atenção:** A maioria destes endpoints deve ser restrita a administradores. Expor a estrutura completa do ACL publicamente pode revelar informações sobre a lógica de permissões do sistema.

## Objetivos:

*   Permitir que administradores visualizem os Níveis de ACL, Ações de ACL e a Matriz de Permissões.
*   (Potencialmente) Permitir que o cliente (especialmente um cliente de admin) verifique se o usuário atual tem permissão para uma ação específica (embora isso seja geralmente tratado no backend antes de executar a ação).

## Tabelas Relevantes (Já Definidas em `docs/01_system_core/sys_acl/`):

*   `sys_acl_levels`
*   `sys_acl_actions`
*   `sys_acl_levels_members`
*   `sys_acl_matrix`
*   `sys_acl_actions_track`

## Módulo de Acesso a Dados (Já Definido em `docs/01_system_core/sys_acl/data_access_module.md`):

*   `Deeper.SystemCore.ACLRepo` será utilizado.

## Endpoints da API (Principalmente para Administração)

### 1. Listar Níveis de ACL

*   **Endpoint:** `GET /api/v1/admin/acl/levels`
*   **Propósito:** Retorna uma lista de todos os níveis de ACL definidos em `sys_acl_levels`.
*   **Autenticação:** Administrador.
*   **Query Parameters:**
    *   `lang` (String, Opcional): Para tradução de `Name` (se for uma chave) e `Description`.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_acl_levels.ID
          \"name\": \"Standard Member\", // Título traduzido
          \"icon_url\": \"/path/to/icon_standard.png\", // Resolvido de sys_acl_levels.Icon
          \"description\": \"Standard membership level with basic access.\", // Descrição traduzida
          \"order\": 10
          // Outros campos relevantes de sys_acl_levels como QuotaSize, Purchasable etc.
        }
        // ... mais níveis ...
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101, // sys_acl_actions.ID
          \"module\": \"bx_persons\",
          \"name\": \"create_profile\",
          \"title\": \"Create Person Profile\", // Título traduzido
          \"description\": \"Allows user to create a new person profile.\", // Descrição traduzida
          \"countable\": 1 // 0 ou 1
        }
        // ... mais ações ...
      ]
    }
```

```json
    {
      \"level_id\": 1,
      \"level_name\": \"Standard Member\",
      \"permissions\": [
        {
          \"action_id\": 101,
          \"action_name\": \"bx_persons_create_profile\", // Obtido com JOIN em sys_acl_actions
          \"action_title\": \"Create Person Profile\",
          \"allowed_count\": null, // ou um número
          \"period_len_seconds\": null, // ou um número de segundos
          \"period_start\": null, // \"YYYY-MM-DD HH:MM:SS\"
          \"period_end\": null
        }
        // ... mais permissões para este nível ...
      ]
    }
```

```json
    {
      \"action_name\": \"bx_persons_create_profile\",
      \"allowed\": true, // ou false
      \"reason\": \"User level does not have this permission.\" // Opcional, se allowed: false
      // Pode incluir informações sobre contagem restante se a ação for contável e permitida.
      // \"actions_left\": 5 
    }
```

### 2. Listar Ações de ACL

*   **Endpoint:** `GET /api/v1/admin/acl/actions`
*   **Propósito:** Retorna uma lista de todas as ações de ACL definidas em `sys_acl_actions`.
*   **Autenticação:** Administrador.
*   **Query Parameters:**
    *   `module_filter` (String, Opcional): Filtrar ações por `sys_acl_actions.Module`.
    *   `lang` (String, Opcional): Para tradução de `Title` e `Desc`.
*   **Resposta de Sucesso (200 OK):**

### 3. Obter Matriz de Permissões para um Nível (Admin)

*   **Endpoint:** `GET /api/v1/admin/acl/levels/{levelId}/matrix`
*   **Propósito:** Retorna todas as permissões (da `sys_acl_matrix`) para um nível de ACL específico.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{levelId}` (Integer, Obrigatório).
*   **Resposta de Sucesso (200 OK):**

### 4. Verificar Permissão para uma Ação Específica (Potencialmente Público com Cautela)

Este endpoint é mais controverso para ser público. Geralmente, a verificação de permissão é feita no backend *antes* de uma ação ser tentada. Expor isso diretamente pode permitir que usuários \"pesquisem\" permissões. Se implementado publicamente, deve ser apenas para o *usuário autenticado atual*.

*   **Endpoint:** `GET /api/v1/acl/check-permission`
*   **Propósito:** Verifica se o usuário autenticado atualmente tem permissão para uma ação específica.
*   **Autenticação:** Obrigatória.
*   **Query Parameters:**
    *   `action_name` (String, Obrigatório): O nome da ação de `sys_acl_actions.Name`.
    *   `module_name` (String, Opcional): O módulo da ação (para desambiguação se `action_name` não for único globalmente).
*   **Lógica do Backend:**
    1.  Obter `IDLevel` do usuário a partir do JWT.
    2.  Encontrar `IDAction` a partir de `action_name` (e `module_name`).
    3.  Chamar `Deeper.SystemCore.ACLRepo.check_permission(user_level_id, action_id)`.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: Se `action_name` não for fornecido.
    *   `404 Not Found`: Se a ação especificada não existir.

### Endpoints para Gerenciamento de ACL (CRUD - Estritamente Admin)

Estes seriam parte da API de Administração mais completa (`07_studio_admin_api/acl_admin_api.md`):

*   `POST /api/v1/admin/acl/levels` (Criar nível)
*   `PUT /api/v1/admin/acl/levels/{levelId}` (Atualizar nível)
*   `DELETE /api/v1/admin/acl/levels/{levelId}` (Deletar nível)
*   Endpoints similares para `sys_acl_actions` (embora ações sejam geralmente definidas por módulos).
*   `POST /api/v1/admin/acl/matrix` (Adicionar/atualizar entrada na matriz)
*   `DELETE /api/v1/admin/acl/matrix_entries/{levelId}/{actionId}` (Remover entrada da matriz)
*   `POST /api/v1/admin/users/{accountId}/acl-memberships` (Adicionar usuário a um nível)
*   `DELETE /api/v1/admin/users/{accountId}/acl-memberships/{membershipId}` (Remover usuário de um nível)

### Considerações:

*   **Performance:** A função `ACLRepo.check_permission` pode ser chamada frequentemente. Cachear os resultados (com base no `IDLevel` e `IDAction`) pode ser benéfico, invalidando o cache quando a `sys_acl_matrix` ou `sys_acl_levels_members` mudam.
*   **Exposição de Dados:** Tenha muito cuidado com quais informações do ACL são expostas publicamente. A estrutura de permissões é uma parte sensível do sistema. A maioria dos endpoints de consulta de ACL deve ser restrita a administradores.

Estes endpoints fornecem a capacidade de inspecionar (e para administradores, gerenciar) o sistema de controle de acesso. A principal funcionalidade do ACL, no entanto, é sua aplicação *implícita* em todos os outros endpoints da API para proteger recursos e ações.