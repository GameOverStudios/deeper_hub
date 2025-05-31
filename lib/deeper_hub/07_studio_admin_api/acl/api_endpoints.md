# Endpoints da API de Admin para Gerenciamento de ACL

Endpoints para administrar Níveis de ACL, Ações ACL, e a Matriz de Permissões. Todos os endpoints aqui requerem autenticação de Administrador.

## Base Path: `/api/v1/admin/acl`

---
### Gerenciamento de Níveis de ACL (`/levels`)

#### 1. Listar Níveis de ACL
*   **Endpoint:** `GET /api/v1/admin/acl/levels`
*   **Query Params:** `sort_by`, `sort_order`, `lang`.
*   **Resposta:** Lista de todos os níveis de ACL (habilitados ou não).

#### 2. Criar Nível de ACL
*   **Endpoint:** `POST /api/v1/admin/acl/levels`
*   **Corpo (JSON):** Detalhes do nível (Name, Icon, Description, Active, Purchasable, Removable, Quotas, Order, PasswordExpiry).
*   **Resposta (201 Created):** O nível criado.

#### 3. Obter Detalhes de um Nível de ACL
*   **Endpoint:** `GET /api/v1/admin/acl/levels/{level_id}`
*   **Path Param:** `level_id`.
*   **Resposta (200 OK):** Detalhes do nível.

#### 4. Atualizar Nível de ACL
*   **Endpoint:** `PUT /api/v1/admin/acl/levels/{level_id}`
*   **Path Param:** `level_id`.
*   **Corpo (JSON):** Campos a serem atualizados.
*   **Resposta (200 OK):** O nível atualizado.

#### 5. Deletar Nível de ACL
*   **Endpoint:** `DELETE /api/v1/admin/acl/levels/{level_id}`
*   **Path Param:** `level_id`.
*   **Resposta (204 No Content).**
*   **Erro (409 Conflict):** Se o nível estiver em uso (em `sys_acl_levels_members` ou `sys_acl_matrix`) e não puder ser deletado.

---
### Gerenciamento de Ações ACL (`/actions`)

#### 6. Listar Ações ACL
*   **Endpoint:** `GET /api/v1/admin/acl/actions`
*   **Query Params:** `filter_module`, `filter_name_like`, `sort_by`, `sort_order`, `lang`.
*   **Resposta:** Lista de todas as ações ACL.

#### 7. Criar Ação ACL
*   **Endpoint:** `POST /api/v1/admin/acl/actions`
*   **Corpo (JSON):** Detalhes da ação (Module, Name, Title, Desc, Countable, DisabledForLevels, AdditionalParamName).
*   **Resposta (201 Created):** A ação criada.

#### 8. Obter Detalhes de uma Ação ACL
*   **Endpoint:** `GET /api/v1/admin/acl/actions/{action_id}`
*   **Path Param:** `action_id`.
*   **Resposta (200 OK):** Detalhes da ação.

#### 9. Atualizar Ação ACL
*   **Endpoint:** `PUT /api/v1/admin/acl/actions/{action_id}`
*   **Path Param:** `action_id`.
*   **Corpo (JSON):** Campos a serem atualizados (geralmente Title, Desc, Countable, DisabledForLevels, AdditionalParamName).
*   **Resposta (200 OK):** A ação atualizada.

#### 10. Deletar Ação ACL
*   **Endpoint:** `DELETE /api/v1/admin/acl/actions/{action_id}`
*   **Path Param:** `action_id`.
*   **Resposta (204 No Content).**
*   **Erro (409 Conflict):** Se a ação estiver em uso (em `sys_acl_matrix` ou `sys_acl_actions_track`).

---
### Gerenciamento da Matriz de Permissões (`/matrix`)

#### 11. Listar Entradas da Matriz de Permissões
*   **Endpoint:** `GET /api/v1/admin/acl/matrix`
*   **Query Params:** `level_id`, `action_id`, `module_name` (para filtrar ações por módulo), `lang`.
*   **Resposta:** Lista de entradas da matriz, incluindo nomes/títulos traduzidos para níveis e ações.

#### 12. Obter uma Permissão Específica da Matriz
*   **Endpoint:** `GET /api/v1/admin/acl/matrix/level/{level_id}/action/{action_id}`
*   **Path Params:** `level_id`, `action_id`.
*   **Resposta (200 OK):** Detalhes da entrada da matriz, ou 404 se não existir.

#### 13. Definir/Atualizar Permissão na Matriz
*   **Endpoint:** `PUT /api/v1/admin/acl/matrix/level/{level_id}/action/{action_id}`
*   **Path Params:** `level_id`, `action_id`.
*   **Corpo (JSON):**

```json
    {
      // null significa que o campo não é usado ou é ilimitado/sem restrição de período
      \"allowed_count\": null, // ou um inteiro
      \"allowed_period_len_days\": null, // ou um inteiro (dias)
      \"allowed_period_start_iso\": null, // \"YYYY-MM-DDTHH:MM:SSZ\" ou null
      \"allowed_period_end_iso\": null,   // \"YYYY-MM-DDTHH:MM:SSZ\" ou null
      \"additional_param_value\": null // ou uma string
    }
```

*   **Lógica:** Se a entrada não existe, cria. Se existe, atualiza.
*   **Resposta (200 OK):** A entrada da matriz criada/atualizada.

#### 14. Deletar Permissão da Matriz
*   **Endpoint:** `DELETE /api/v1/admin/acl/matrix/level/{level_id}/action/{action_id}`
*   **Path Params:** `level_id`, `action_id`.
*   **Resposta (204 No Content).**

## Considerações de UI de Admin:

*   A interface para gerenciar a matriz de ACL é tipicamente uma tabela grande com Níveis nas linhas e Ações (agrupadas por Módulo) nas colunas. Clicar em uma célula permitiria configurar os detalhes (`AllowedCount`, etc.).
*   A API deve suportar a busca de dados de forma eficiente para popular tal interface.
*   A UI deve fornecer seletores/listas para `IDLevel` e `IDAction` ao criar/editar entradas na matriz.

Esta API de gerenciamento de ACL é crítica para a configuração de segurança e permissões da plataforma \"Deeper\".