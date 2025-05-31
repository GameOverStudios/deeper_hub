# API de Administração: Gerenciamento de Usuários e Perfis

Endpoints da API para administradores gerenciarem contas de usuário (`sys_accounts`) e os perfis associados (`sys_profiles`, `bx_persons_data`, etc.).

**Permissões:** Todos os endpoints aqui requerem um papel de administrador do site com plenos poderes sobre o gerenciamento de usuários.

## Endpoints para Contas de Usuário (`sys_accounts`)

### 1. Listar Todas as Contas de Usuário (Visão Administrativa)

*   **`GET /admin/accounts`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:**
    *   `email` (string): Buscar por email (parcial ou exato).
    *   `name` (string): Buscar por nome de conta/usuário.
    *   `status` (string, ex: `active`, `pending`, `locked`, `suspended` - o campo `active` na tabela `sys_accounts` pode precisar ser expandido ou combinado com `locked` para representar esses estados).
    *   `role` (integer): Filtrar por ID de papel.
    *   `ip` (string): Buscar por último IP de login.
    *   `page`, `per_page`.
    *   `sort_by` (ex: `created_at_desc`, `last_login_desc`, `email_asc`).
    *   `include` (ex: `main_profile_summary` - para incluir um resumo do perfil principal associado).
*   **Resposta de Sucesso (200 OK):** Lista paginada de contas de usuário.

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"name\": \"AdminUser\",
          \"email\": \"admin@example.com\",
          \"email_confirmed\": 1,
          \"phone\": \"123456789\",
          \"phone_confirmed\": 1,
          \"role\": 4, // Ex: ID do papel de Admin
          \"status\": \"active\", // Campo derivado ou direto
          \"locked\": 0,
          \"created_at\": 1670000000,
          \"last_login_at\": 1699980000, // 'logged' da tabela
          \"last_login_ip\": \"192.168.1.100\",
          \"main_profile_summary\": { \"profile_id\": 201, \"type\": \"bx_persons\", \"display_name\": \"Admin User FullName\" },
          \"admin_notes\": \"Conta de administrador principal.\"
        }
        // ...
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"name\": \"NewUserByAdmin\",
      \"email\": \"newuser@example.com\",
      \"password\": \"SecurePassword123!\", // Admin define uma senha inicial
      \"role\": 1, // Papel padrão
      \"status\": \"active\", // Pode criar como ativo diretamente
      \"email_confirmed\": true, // Pode confirmar email diretamente
      \"send_welcome_email\": true, // Opcional
      \"profile_data\": { // Opcional, para criar um perfil principal junto
        \"type\": \"bx_persons\",
        \"full_name\": \"New User FullName\",
        \"description\": \"Perfil criado por admin.\"
      }
    }
```

```json
    {
      \"name\": \"UpdatedUserName\",
      \"email\": \"updated_email@example.com\", // Pode exigir re-confirmação
      \"role\": 2,
      \"status\": \"suspended\", // Suspender conta
      \"locked\": 1, // Bloquear conta
      \"email_confirmed\": true,
      \"admin_notes\": \"Conta suspensa devido a violação X.\"
      // \"new_password\": \"NewPasswordForUser\" // Para resetar senha
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 201,
          \"account_id\": 101,
          \"type\": \"bx_persons\",
          \"content_id\": 301,
          \"status\": \"active\",
          \"profile_content_summary\": { // Dados da tabela específica do tipo (ex: bx_persons_data)
            \"full_name\": \"Admin User FullName\",
            \"description\": \"...\"
          }
        }
        // ... outros perfis se a conta tiver múltiplos ...
      ]
    }
```

```json
    {
      \"status\": \"suspended\", // Status do sys_profiles
      \"content_updates\": { // Campos da tabela específica do tipo de perfil (ex: bx_persons_data)
        \"full_name\": \"Nome Completo Editado por Admin\",
        \"description\": \"Descrição atualizada.\",
        \"allow_view_to\": \"1\" // Mudar privacidade do perfil
      }
    }
```

*   **Respostas de Erro:** `401`, `403`.

### 2. Obter Detalhes de Qualquer Conta de Usuário (Visão Administrativa)

*   **`GET /admin/accounts/{account_id}`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include` (ex: `all_profiles`, `login_history`, `acl_level_details`, `audit_logs_for_user`).
*   **Resposta de Sucesso (200 OK):** Objeto completo da conta com informações detalhadas.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Criar Nova Conta de Usuário (Ação Administrativa)
    (Menos comum, geralmente usuários se registram, mas pode ser útil)

*   **`POST /admin/accounts`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Objeto da conta (e perfil) criado.
*   **Respostas de Erro:** `400` (validação, email duplicado), `401`, `403`.

### 4. Atualizar Qualquer Conta de Usuário (Ação Administrativa)

*   **`PUT /admin/accounts/{account_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.

*   **Resposta de Sucesso (200 OK):** Objeto da conta atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 5. Excluir Qualquer Conta de Usuário (Ação Administrativa)

*   **`DELETE /admin/accounts/{account_id}`**
*   **Autenticação:** Admin Requerida.
*   **Opções (Query Param ou Corpo):**
    *   `reason` (string): Motivo da exclusão.
    *   `delete_content` (boolean, default: false): Se o conteúdo do usuário (perfis, posts, etc.) deve ser excluído ou anonimizado/reatribuído. Operação complexa e destrutiva.
    *   `hard_delete` (boolean, default: false): Se a exclusão é física do DB ou apenas marcação (soft delete).
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Exclui a conta e, dependendo das opções, seus perfis e conteúdo associado (via `ON DELETE CASCADE` ou lógica customizada).
*   **Respostas de Erro:** `401`, `403`, `404`.

### 6. Ações Específicas na Conta

*   **`POST /admin/accounts/{account_id}/confirm-email`**: Força a confirmação do email.
*   **`POST /admin/accounts/{account_id}/unlock`**: Desbloqueia uma conta.
*   **`POST /admin/accounts/{account_id}/set-password`**: Define uma nova senha.
    *   Corpo: `{ \"new_password\": \"...\", \"notify_user\": true }`
*   **Autenticação:** Admin Requerida.
*   **Resposta (200 OK):** Mensagem de sucesso.

## Endpoints para Perfis de Usuário (`sys_profiles` e tabelas de conteúdo de perfil como `bx_persons_data`)

A administração de perfis pode ser aninhada sob contas ou ter seus próprios endpoints de admin, dependendo da granularidade.

### 1. Listar Perfis de uma Conta Específica (Admin)

*   **`GET /admin/accounts/{account_id}/profiles`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):**

### 2. Obter Detalhes de Qualquer Perfil (Admin)

*   **`GET /admin/profiles/{profile_id}`** (Rota não aninhada, usando o ID global do perfil)
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include=account_details,content_details` (para buscar da tabela específica como `bx_persons_data`).
*   **Resposta de Sucesso (200 OK):** Objeto completo do perfil e seu conteúdo.

### 3. Atualizar Qualquer Perfil e Seu Conteúdo (Admin)

*   **`PUT /admin/profiles/{profile_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Ação do Backend:** Atualiza `sys_profiles` e a tabela de conteúdo correspondente (ex: `bx_persons_data`).
*   **Resposta de Sucesso (200 OK):** Objeto do perfil atualizado.

### 4. Excluir Qualquer Perfil (Admin)
    (Geralmente, excluir uma conta exclui perfis via CASCADE. Este endpoint seria para excluir um perfil específico sem excluir a conta, se permitido.)

*   **`DELETE /admin/profiles/{profile_id}`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**

## Considerações para Repositórios e Contextos:

*   **`Deeper.SystemCore.AccountsRepo` e `Deeper.SystemCore.ProfilesRepo` (e Repos de conteúdo de perfil como `Deeper.Content.PersonsRepo`):**
    *   Precisarão de funções que aceitem um parâmetro `as_admin: true` ou variantes de função para bypassar verificações de propriedade e filtros de status/privacidade.
    *   Funções para buscar por múltiplos critérios (email, IP, status, etc.) serão necessárias.
    *   Lógica para lidar com `delete_content` e `hard_delete` na exclusão de contas.
*   **`Deeper.Accounts` e `Deeper.Profiles` (Contextos/Serviços):**
    *   Conterão a lógica de negócios para todas as operações administrativas.
    *   Farão a verificação de permissão de administrador no `current_user_profile`.
    *   Orquestrarão operações que afetam múltiplas tabelas (ex: criar conta e perfil principal, excluir conta e todo o seu conteúdo).
    *   Lidarão com o envio de notificações (ex: quando senha é resetada por admin).
*   **Log de Auditoria:** Todas as ações administrativas (mudança de status, reset de senha, exclusão de conta/perfil, mudança de papel) são críticas e devem ser logadas extensivamente.

Estes endpoints fornecem uma base sólida para o gerenciamento administrativo de usuários e perfis, que é uma parte essencial de qualquer plataforma.