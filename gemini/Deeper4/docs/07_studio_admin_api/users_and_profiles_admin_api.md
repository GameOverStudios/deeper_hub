# API de Administração: Gerenciamento de Usuários e Perfis

Esta seção da API de Administração \"Deeper\" fornece endpoints para gerenciar contas de usuário (`sys_accounts`) e os perfis associados (`sys_profiles`, `bx_persons_data`, `bx_organizations_data`, etc.).

**Autenticação:** Requerida (nível de administrador do sistema).

## 1. Contas de Usuário (`/api/v1/admin/accounts`)

Estes endpoints interagem principalmente com a tabela `sys_accounts`.

### `GET /api/v1/admin/accounts`
*   **Descrição:** Lista todas as contas de usuário com filtros, ordenação e paginação.
*   **Query Parameters:**
    *   `search_term` (string): Busca por `email`, `name`.
    *   `status` (string, ex: `\"active\"`, `\"pending\"`, `\"locked\"`).
    *   `role` (integer): ID do papel.
    *   `page` (integer, default 1).
    *   `per_page` (integer, default 20).
    *   `sort_by` (string, ex: `\"email_asc\"`, `\"added_desc\"`).
    *   `preload` (string, ex: `\"main_profile_summary\"`)
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_accounts.id
          \"name\": \"John Doe\",
          \"email\": \"john.doe@example.com\",
          \"status\": \"active\", // Mapeado de sys_accounts.active e sys_accounts.locked
          \"role\": 1,
          \"added\": 1678886400,
          \"last_login\": 1678890000, // Mapeado de sys_accounts.logged
          \"main_profile_summary\": { // Se preload
            \"profile_id\": 15, // sys_profiles.id
            \"type\": \"bx_persons\",
            \"display_name\": \"John Doe\"
          }
        }
        // ... mais contas
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"name\": \"John Doe\",
        \"email\": \"john.doe@example.com\",
        \"email_confirmed\": true,
        \"phone\": \"123-456-7890\",
        \"phone_confirmed\": false,
        \"role\": 1,
        \"lang_id\": 2,
        \"status\": \"active\", // \"active\", \"pending\", \"locked\", \"suspended\" (combinando sys_accounts.active, locked, e status do perfil principal)
        \"added\": 1678886400,
        \"changed\": 1678886500,
        \"last_login\": 1678890000,
        \"last_ip\": \"192.168.1.100\",
        \"login_attempts\": 0,
        \"referred_by\": \"some_campaign\",
        \"profiles\": [ // Se preload=\"profiles\"
          {
            \"profile_id\": 15, // sys_profiles.id
            \"type\": \"bx_persons\",
            \"content_id\": 101, // bx_persons_data.id
            \"status\": \"active\", // sys_profiles.status
            \"display_name\": \"John Doe\" // bx_persons_data.fullname
          },
          {
            \"profile_id\": 75, // sys_profiles.id
            \"type\": \"bx_organizations\",
            \"content_id\": 201, // bx_organizations_data.id
            \"status\": \"active\",
            \"display_name\": \"My New Company Inc.\" // bx_organizations_data.org_name
          }
        ]
      }
    }
```

```json
    {
      \"name\": \"Jane Admin\",
      \"email\": \"jane.admin@example.com\",
      \"password\": \"SecurePassword123!\", // Senha em texto plano, backend fará o hash
      \"role\": 2, // Papel de admin, por exemplo
      \"status\": \"active\", // \"active\" ou \"pending\" (para envio de confirmação)
      \"send_confirmation_email\": true // Opcional
    }
```

```json
    {
      \"action\": \"confirm_email\" // \"lock\", \"unlock\", \"suspend_main_profile\", \"activate_main_profile\"
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 15, // sys_profiles.id
          \"account_id\": 1,
          \"type\": \"bx_persons\",
          \"content_id\": 101,
          \"status\": \"active\",
          \"display_name\": \"John Doe\", // Da tabela de dados (bx_persons_data.fullname)
          \"account_email\": \"john.doe@example.com\" // Se preload=\"account_info\"
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": { // Dados de sys_profiles
        \"profile_id\": 15,
        \"account_id\": 1,
        \"type\": \"bx_persons\",
        \"content_id\": 101,
        \"status\": \"active\",
        \"content_data\": { // Dados da tabela específica do tipo, ex: bx_persons_data
          \"id\": 101,
          \"author_id\": 15,
          \"fullname\": \"John Doe\",
          \"description\": \"...\",
          // ... todos os campos de bx_persons_data
        },
        \"account_details\": { // Se preload
            \"id\": 1,
            \"email\": \"john.doe@example.com\",
            \"status\": \"active\"
        }
      }
    }
```

```json
    {
      \"status\": \"suspended\", // Para sys_profiles.status
      \"content_data\": { // Campos para a tabela de dados do tipo de perfil
        \"fullname\": \"Johnathan Doe\", // Exemplo para bx_persons_data
        \"description\": \"Updated description.\"
      }
    }
```

### `GET /api/v1/admin/accounts/{account_id}`
*   **Descrição:** Obtém detalhes completos de uma conta de usuário específica.
*   **Query Parameters:**
    *   `preload` (string, ex: `\"profiles\"`)
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

### `POST /api/v1/admin/accounts`
*   **Descrição:** Cria uma nova conta de usuário (geralmente um admin criando para outro usuário).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Corpo da conta criada (sem a senha).
*   **Respostas de Erro:** `400`, `422` (ex: email já existe).

### `PUT /api/v1/admin/accounts/{account_id}`
*   **Descrição:** Atualiza dados de uma conta de usuário.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (ex: `name`, `email`, `role`, `status`).
    *   Para `status`: pode aceitar \"active\", \"pending\", \"locked\", \"unlocked\", \"suspend\", \"unsuspend\". O backend traduzirá isso para as colunas `active` e `locked` de `sys_accounts` e `status` de `sys_profiles`.
    *   Para `password`: pode aceitar um novo password para reset.
*   **Resposta de Sucesso (200 OK):** Corpo da conta atualizada.
*   **Respostas de Erro:** `400`, `404`, `422`.

### `POST /api/v1/admin/accounts/{account_id}/action`
*   **Descrição:** Executa ações específicas na conta, como confirmar email, bloquear/desbloquear, suspender/ativar.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Corpo da conta atualizada.
*   **Respostas de Erro:** `400`, `404`, `422`.

### `DELETE /api/v1/admin/accounts/{account_id}`
*   **Descrição:** Deleta uma conta de usuário e todos os seus perfis e conteúdos associados (devido a `ON DELETE CASCADE` nas FKs). Ação drástica, requer confirmação.
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**
*   **Respostas de Erro:** `404`.

## 2. Perfis do Sistema (`/api/v1/admin/profiles`)

Estes endpoints interagem com `sys_profiles` e as tabelas de dados de perfil associadas (ex: `bx_persons_data`, `bx_organizations_data`).

### `GET /api/v1/admin/profiles`
*   **Descrição:** Lista todos os perfis do sistema com filtros, ordenação e paginação.
*   **Query Parameters:**
    *   `account_id` (integer)
    *   `type` (string, ex: `\"bx_persons\"`, `\"bx_organizations\"`)
    *   `status` (string, ex: `\"active\"`, `\"pending\"`, `\"suspended\"`)
    *   `search_term` (string, busca no nome do perfil - requer JOIN com tabelas de dados)
    *   `page`, `per_page`, `sort_by` (ex: `\"display_name_asc\"`, `\"added_desc\"` onde `added` seria de `sys_profiles` ou da tabela de dados).
    *   `preload` (string, ex: `\"account_info\"`)
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/admin/profiles/{profile_id}`
*   **Descrição:** Obtém detalhes completos de um perfil específico do sistema e seus dados de conteúdo.
*   **Query Parameters:** `preload` (ex: `\"account_details\"`)
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

### `PUT /api/v1/admin/profiles/{profile_id}`
*   **Descrição:** Atualiza dados de um perfil específico. Isso pode envolver atualizar `sys_profiles.status` e/ou campos na tabela de dados de conteúdo (ex: `bx_persons_data.fullname`).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Corpo do perfil atualizado.
*   **Respostas de Erro:** `400`, `404`, `422`.

### `DELETE /api/v1/admin/profiles/{profile_id}`
*   **Descrição:** Deleta um perfil específico e seus dados de conteúdo. **Cuidado:** Se este for o único perfil de uma conta, a conta pode ficar \"órfã\" ou pode haver lógica para deletar a conta se todos os seus perfis forem removidos. Geralmente, deletar a conta (`/api/v1/admin/accounts/{account_id}`) é a ação mais abrangente.
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**
*   **Respostas de Erro:** `404`.

## Considerações para API de Admin de Usuários/Perfis:

*   **Status Compostos:** O \"status\" de um usuário pode ser uma combinação de `sys_accounts.active`, `sys_accounts.locked`, e `sys_profiles.status` (do perfil principal). A API de admin deve simplificar isso para o administrador (ex: \"Ativo\", \"Pendente\", \"Bloqueado\", \"Suspenso\").
*   **Operações em Lote:** Considerar endpoints para ações em lote (ex: banir múltiplos usuários, mudar status de múltiplos perfis).
*   **Logs de Auditoria:** Todas as ações administrativas devem ser registradas em `sys_audit`.
*   **Segurança:** Validação rigorosa de permissões é crucial para cada endpoint.

Esta API fornecerá aos administradores as ferramentas necessárias para gerenciar a base de usuários e seus diversos perfis na plataforma \"Deeper\".