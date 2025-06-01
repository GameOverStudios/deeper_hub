# Documentação Deeper: API de Administração - Gerenciamento de Usuários e Perfis

Este documento descreve os endpoints da API \"Deeper\" para administradores gerenciarem contas de usuário (`sys_accounts`), perfis associados (`sys_profiles`), e dados específicos de perfis (como `bx_persons_data`).

## Escopo e Funcionalidades:

*   Listar todas as contas de usuário com filtros e paginação.
*   Visualizar detalhes de uma conta de usuário específica, incluindo seus perfis associados.
*   Criar novas contas de usuário (como administrador).
*   Atualizar dados de contas de usuário (ex: email, nome, status, papel).
*   Ativar, desativar, bloquear ou suspender contas de usuário.
*   Confirmar email/telefone de usuários.
*   Gerenciar perfis associados a uma conta (listar, visualizar detalhes, potencialmente criar/editar/deletar se não houver uma UI de \"personificação\").
*   Visualizar e editar dados específicos do perfil (ex: `bx_persons_data`).
*   Potencialmente, gerenciar conexões de banimento (`sys_profiles_conn_bans`).

## Tabelas Relevantes (Já Definidas em `docs/01_system_core/sys_accounts_and_profiles/`):

*   `sys_accounts`
*   `sys_profiles`
*   `bx_persons_data` (e outras tabelas de dados de perfil, como `bx_organizations_data`, se implementadas)
*   `sys_acl_levels_members` (para atribuir/ver níveis de ACL)
*   `sys_std_roles_members` (se o sistema de papéis (`sys_std_roles`) for usado além/junto com ACL)

## Módulos de Acesso a Dados (Já Definidos/Esboçados):

*   `Deeper.SystemCore.AccountsRepo`
*   `Deeper.SystemCore.ProfilesRepo`
*   `Deeper.Content.PersonsRepo` (e outros repos de conteúdo de perfil)
*   `Deeper.SystemCore.ACLRepo` (para gerenciar `sys_acl_levels_members`)

## Endpoints da API de Administração para Usuários e Perfis

Todos os endpoints estão sob `/api/v1/admin/...` e requerem autenticação de administrador com as devidas permissões ACL para gerenciamento de usuários.

### Gerenciamento de Contas (`sys_accounts`)

#### 1. Listar Contas de Usuário

*   **Endpoint:** `GET /api/v1/admin/accounts`
*   **Propósito:** Retorna uma lista paginada de todas as contas de usuário no sistema.
*   **Autenticação:** Administrador.
*   **Query Parameters:**
    *   `offset` (Integer, Opcional, Default: 0)
    *   `limit` (Integer, Opcional, Default: 20)
    *   `search_term` (String, Opcional): Buscar por `name`, `email`.
    *   `status` (String, Opcional): Filtrar por `sys_accounts.active` (ex: `0` para inativo/pendente, `1` para ativo), ou `locked` (ex: `0` ou `1`).
    *   `role` (Integer, Opcional): Filtrar por `sys_accounts.role`.
    *   `sort_by` (String, Opcional): Campo para ordenação (ex: `added_desc`, `email_asc`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"John Doe\",
          \"email\": \"john.doe@example.com\",
          \"active\": 1, // 1 = ativo, 0 = pendente/inativo
          \"locked\": 0,
          \"role\": 1, // Role ID
          \"added\": 1678886400, // Timestamp
          \"profile_count\": 1 // Número de perfis associados
        }
        // ... mais contas ...
      ],
      \"pagination\": {
        \"total_items\": 150,
        \"offset\": 0,
        \"limit\": 20
        // ...
      }
    }
```

```json
    {
      \"id\": 1,
      \"name\": \"John Doe\",
      \"email\": \"john.doe@example.com\",
      \"email_confirmed\": 1,
      \"phone\": \"123-456-7890\",
      \"phone_confirmed\": 0,
      \"role\": 1,
      \"lang_id\": 2,
      \"added\": 1678886400,
      \"changed\": 1678886500,
      \"logged\": 1679000000,
      \"ip\": \"192.168.1.100\",
      \"login_attempts\": 0,
      \"locked\": 0,
      \"active\": 1,
      \"profiles\": [ // Lista de sys_profiles associados
        {
          \"id\": 10, // sys_profiles.id
          \"type\": \"bx_persons\",
          \"content_id\": 101, // bx_persons_data.id
          \"status\": \"active\",
          \"profile_name\": \"John D.\" // Obtido de bx_persons_data.fullname
        }
      ],
      \"acl_levels\": [ // Lista de sys_acl_levels_members associados
        {
          \"level_id\": 4, // ID do nível Admin
          \"level_name\": \"Administrator\", // Obtido de sys_acl_levels.Name (traduzido)
          \"date_starts\": \"2023-01-01T00:00:00Z\",
          \"date_expires\": null // ou \"2024-01-01T00:00:00Z\"
        }
      ]
      // Outras informações relevantes, como histórico de IPs, etc.
    }
```

```json
    {
      \"name\": \"Jane Smith\",
      \"email\": \"jane.smith@example.com\",
      \"password\": \"aVeryStrongPassword123!\", // Senha em texto plano, o backend fará o hash
      \"role\": 1,
      \"active\": 1, // Pode criar como ativo ou pendente
      \"email_confirmed\": 1, // Admin pode confirmar diretamente
      \"send_welcome_email\": true // Opcional: flag para o backend disparar um email
    }
```

```json
    {
      \"name\": \"Johnathan Doe\",
      \"email\": \"john.doe.new@example.com\", // Pode exigir re-confirmação
      \"role\": 2,
      \"active\": 0, // Desativar conta
      \"locked\": 1, // Bloquear conta
      \"email_confirmed\": 1, // Admin pode confirmar
      \"new_password\": \"newSecurePassword456!\" // Opcional, para resetar senha
    }
```

```json
    {
      \"action\": \"activate\", // ou \"deactivate\", \"lock\", \"unlock\", \"delete\"
      \"account_ids\": [1, 5, 12]
    }
```

```json
    {
      \"message\": \"Action 'activate' performed on 3 accounts.\",
      \"results\": [
        {\"account_id\": 1, \"status\": \"success\"},
        {\"account_id\": 5, \"status\": \"success\"},
        {\"account_id\": 12, \"status\": \"failed\", \"reason\": \"Account already active\"}
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 10, // sys_profiles.id
          \"type\": \"bx_persons\",
          \"content_id\": 101, // bx_persons_data.id
          \"status\": \"active\",
          \"profile_name\": \"John D.\" // bx_persons_data.fullname
        },
        {
          \"id\": 11,
          \"type\": \"bx_organizations\", // Se implementado
          \"content_id\": 201,
          \"status\": \"pending\",
          \"profile_name\": \"Acme Corp\"
        }
      ]
    }
```

```json
    {
      \"profile_info\": { // Dados de sys_profiles
        \"id\": 10,
        \"account_id\": 1,
        \"type\": \"bx_persons\",
        \"content_id\": 101,
        \"status\": \"active\"
      },
      \"account_info\": { // Dados resumidos de sys_accounts
        \"id\": 1,
        \"name\": \"John Doe\",
        \"email\": \"john.doe@example.com\"
      },
      \"content_data\": { // Dados de bx_persons_data (ou outra tabela de tipo de perfil)
        \"id\": 101, // bx_persons_data.id
        \"fullname\": \"John D.\",
        \"description\": \"Loves Elixir and UNA.\",
        \"gender\": \"male\",
        // ... todos os campos de bx_persons_data ...
        \"allow_view_to\": \"3\"
      }
    }
```

```json
    {
      \"profile_status\": \"suspended\", // Para sys_profiles.status
      \"content_update\": { // Para bx_persons_data (se profile type for bx_persons)
        \"fullname\": \"Johnathan Public Doe\",
        \"description\": \"Updated bio by admin.\",
        \"allow_view_to\": \"1\" // Alterar privacidade
      }
    }
```

```json
    {
      \"type\": \"bx_organizations\", // Tipo do novo perfil
      \"status\": \"active\",
      \"content_data\": { // Dados para bx_organizations_data
        \"org_name\": \"Deeper Inc.\",
        \"org_description\": \"Building the future.\"
        // ...
      }
    }
```

#### 2. Obter Detalhes de uma Conta de Usuário

*   **Endpoint:** `GET /api/v1/admin/accounts/{accountId}`
*   **Propósito:** Retorna os detalhes completos de uma conta de usuário, incluindo uma lista resumida de seus perfis.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{accountId}` (Integer, Obrigatório).
*   **Resposta de Sucesso (200 OK):**

#### 3. Criar Nova Conta de Usuário (como Admin)

*   **Endpoint:** `POST /api/v1/admin/accounts`
*   **Propósito:** Cria uma nova conta de usuário. O administrador pode precisar definir uma senha inicial ou um fluxo de definição de senha.
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Corpo da conta criada (similar ao GET de detalhes).
    *   Cabeçalho `Location`: `/api/v1/admin/accounts/{newAccountId}`.

#### 4. Atualizar Conta de Usuário

*   **Endpoint:** `PUT /api/v1/admin/accounts/{accountId}`
*   **Propósito:** Atualiza os dados de uma conta de usuário.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{accountId}` (Integer, Obrigatório).
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.

*   **Resposta de Sucesso (200 OK):** Corpo da conta atualizada.

#### 5. Ações em Massa em Contas (Opcional)

*   **Endpoint:** `POST /api/v1/admin/accounts/bulk-actions`
*   **Propósito:** Realizar ações em múltiplas contas (ex: ativar, desativar, deletar).
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):**

### Gerenciamento de Perfis (`sys_profiles` e dados específicos como `bx_persons_data`)

Os perfis são geralmente gerenciados no contexto de uma conta.

#### 1. Listar Perfis de uma Conta

*   **Endpoint:** `GET /api/v1/admin/accounts/{accountId}/profiles`
*   **Propósito:** Retorna todos os perfis associados a uma conta específica.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{accountId}` (Integer, Obrigatório).
*   **Resposta de Sucesso (200 OK):**

#### 2. Obter Detalhes de um Perfil Específico (Admin)

*   **Endpoint:** `GET /api/v1/admin/profiles/{profileId}`
    *   *(Este endpoint é similar ao público `GET /api/v1/profiles/{profileId}`, mas pode retornar mais dados ou não aplicar todas as regras de privacidade se acessado por um admin).*
*   **Propósito:** Retorna os detalhes completos de um perfil, incluindo seus dados específicos (ex: de `bx_persons_data`).
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{profileId}` (Integer, Obrigatório): ID da tabela `sys_profiles`.
*   **Resposta de Sucesso (200 OK):**

#### 3. Atualizar Dados de um Perfil Específico (Admin)

*   **Endpoint:** `PUT /api/v1/admin/profiles/{profileId}`
*   **Propósito:** Atualiza os dados de um perfil (tanto em `sys_profiles` quanto na tabela de conteúdo específica como `bx_persons_data`).
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{profileId}` (Integer, Obrigatório): ID da tabela `sys_profiles`.
*   **Corpo da Requisição (JSON):**
    Campos de `sys_profiles` (ex: `status`) e/ou campos da tabela de conteúdo (ex: `fullname`, `description` de `bx_persons_data`). O backend precisará saber o `type` do perfil para atualizar a tabela correta.

*   **Resposta de Sucesso (200 OK):** Corpo do perfil atualizado (similar ao GET de detalhes).

#### 4. Criar um Novo Perfil para uma Conta Existente (Admin - Menos Comum)

*   **Endpoint:** `POST /api/v1/admin/accounts/{accountId}/profiles`
*   **Propósito:** Adiciona um novo perfil (ex: um perfil de organização) a uma conta existente. Requer que o admin forneça o `type` e os dados para a tabela de conteúdo correspondente.
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Detalhes do novo perfil criado.

### Gerenciamento de Níveis ACL para Usuários

*   **Endpoint:** `GET /api/v1/admin/accounts/{accountId}/acl-levels`
*   **Endpoint:** `POST /api/v1/admin/accounts/{accountId}/acl-levels` (para atribuir um nível)
    *   Corpo: `{ \"level_id\": 5, \"start_date\": \"...\", \"expires_date\": \"...\" }`
*   **Endpoint:** `DELETE /api/v1/admin/accounts/{accountId}/acl-levels/{levelMembershipId}` (para remover uma atribuição de nível)

Estes endpoints interagiriam com `sys_acl_levels_members` e usariam o `ACLRepo`.

### Considerações Adicionais:

*   **Personificação (Impersonation):** Uma funcionalidade comum de admin é \"logar como\" um usuário. A API precisaria de um endpoint especial para gerar um JWT temporário para o usuário personificado, com alguma indicação de que é uma sessão de personificação.
*   **Auditoria:** Todas as ações de administração devem ser rigorosamente auditadas.
*   **Permissões Granulares de Admin:** Nem todo administrador pode ter permissão para todas essas ações. A lógica de ACL do UNA (usando `sys_acl_actions` para ações de admin) deve ser verificada.

Esta API fornece uma base sólida para um painel de administração gerenciar usuários e seus perfis de forma abrangente.