# Documentação Deeper Studio API: Gerenciamento de Usuários e Perfis

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento completo de contas de usuário (`sys_accounts`), perfis associados (`sys_profiles`), e os dados específicos de perfis (ex: `bx_persons_data`).

**Objetivo Principal:** Permitir que administradores criem, visualizem, atualizem e deletem contas e perfis de usuários, além de realizar ações administrativas como banir, confirmar email, alterar papéis, etc.

## Tabelas Relevantes (já definidas e migradas):

*   `sys_accounts`
*   `sys_profiles`
*   `bx_persons_data` (e outras tabelas de dados de tipo de perfil, ex: `bx_organizations_data`)
*   Tabelas relacionadas a ACL (`sys_acl_levels_members`) para associação de níveis.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.SystemCore.AccountsRepo`
*   `Deeper.SystemCore.ProfilesRepo`
*   `Deeper.Content.PersonsRepo` (e repositórios para outros tipos de perfil)
*   `Deeper.SystemCore.AclRepo` (para gerenciar `sys_acl_levels_members`)

Estes repositórios precisarão de funções que permitam operações administrativas, como buscar qualquer usuário (não apenas o próprio) e modificar campos que normalmente não são alteráveis pelo usuário final (ex: `active`, `role`, `locked` em `sys_accounts`).

## Endpoints da API de Administração para Usuários e Perfis (`/api/v1/admin/users` e `/api/v1/admin/profiles`):

*(Nota: A nomenclatura pode variar, ex: `/admin/accounts` em vez de `/admin/users` se \"user\" se referir mais ao conceito de perfil)*. Vamos usar `/admin/users` para se referir a `sys_accounts` e `/admin/profiles` para `sys_profiles` e seus dados de conteúdo.

---
### Gerenciamento de Contas (`sys_accounts`) - Endpoints sob `/api/v1/admin/users`

#### 1. Listar Todas as Contas de Usuário

*   **Endpoint:** `GET /api/v1/admin/users`
*   **Descrição:** Retorna uma lista paginada de todas as contas de usuário, com filtros.
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `page`, `per_page`, `sort_by` (ex: `email_asc`, `added_desc`), `filter_email_like`, `filter_name_like`, `filter_active` (0/1), `filter_locked` (0/1), `filter_role`.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"account_id\": 123, // sys_accounts.id
          \"name\": \"John Doe Account\",
          \"email\": \"john.doe@example.com\",
          \"role\": 1,
          \"is_active\": true,
          \"is_locked\": false,
          \"is_email_confirmed\": true,
          \"date_added_timestamp\": 1678886400,
          \"last_login_timestamp\": 1679886400,
          \"profiles_summary\": [ // Resumo dos perfis associados
            {\"profile_id\": 456, \"type\": \"bx_persons\", \"status\": \"active\", \"content_link_admin\": \"/admin/profiles/bx_persons/789\"}
          ]
        }
        // ... outras contas ...
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"name\": \"New User Admin\",
      \"email\": \"newadminuser@example.com\",
      \"password\": \"AdminSetPassword123\", // Senha a ser hasheada
      \"role\": 2, // ID do papel/nível ACL
      \"is_active\": true,
      \"is_email_confirmed\": true, // Admin pode confirmar diretamente
      // Opcional: dados para criar um perfil padrão junto
      \"default_profile\": {
        \"type\": \"bx_persons\",
        \"data\": { \"fullname\": \"New User Admin Profile\", \"gender\": \"other\" }
      }
    }
```

```json
    {
      \"email\": \"updated.email@example.com\",
      \"is_active\": false,
      \"new_password\": \"OptionalNewPassword\" // Se fornecido, atualiza a senha
    }
```

```json
    {
      \"type\": \"bx_persons\", // Tipo de perfil a ser criado
      \"status\": \"active\",
      \"content_data\": { // Dados para a tabela específica do tipo (ex: bx_persons_data)
        \"fullname\": \"Secondary Profile Name\",
        \"description\": \"This is a secondary profile.\"
        // ... outros campos específicos do tipo ...
      }
    }
```

```json
    {
      \"fullname\": \"Updated Profile Name\",
      \"description\": \"Updated description.\",
      \"allow_view_to\": \"1\" // Exemplo de atualização de privacidade
    }
```

#### 2. Criar Nova Conta de Usuário (Administrativo)

*   **Endpoint:** `POST /api/v1/admin/users`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Retorna os dados da conta criada.
*   **Lógica do Backend:** Similar ao registro público, mas com mais controle sobre os campos.

#### 3. Obter Detalhes de uma Conta de Usuário Específica

*   **Endpoint:** `GET /api/v1/admin/users/{account_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna dados detalhados da conta, incluindo todos os perfis associados com mais detalhes.

#### 4. Atualizar uma Conta de Usuário

*   **Endpoint:** `PUT /api/v1/admin/users/{account_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Permite atualizar campos como `name`, `email`, `role`, `is_active`, `is_locked`, `is_email_confirmed`. Pode incluir opção para resetar senha.

*   **Resposta de Sucesso (200 OK):** Retorna os dados da conta atualizada.

#### 5. Deletar uma Conta de Usuário

*   **Endpoint:** `DELETE /api/v1/admin/users/{account_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (204 No Content).**
*   **Lógica do Backend:** Deleta de `sys_accounts`. `ON DELETE CASCADE` em `sys_profiles` deve lidar com os perfis.

#### 6. Ações Específicas na Conta

*   `PUT /api/v1/admin/users/{account_id}/confirm-email`
*   `PUT /api/v1/admin/users/{account_id}/lock`
*   `PUT /api/v1/admin/users/{account_id}/unlock`
*   `PUT /api/v1/admin/users/{account_id}/activate`
*   `PUT /api/v1/admin/users/{account_id}/deactivate`
*   `POST /api/v1/admin/users/{account_id}/send-password-reset` (dispara email de reset)

---
### Gerenciamento de Perfis (`sys_profiles` e dados de conteúdo) - Endpoints sob `/api/v1/admin/profiles`

O `{profile_type}` aqui seria o valor de `sys_profiles.type` (ex: `bx_persons`, `bx_organizations`).
O `{content_id}` seria o `sys_profiles.content_id` (que é o `id` na tabela de dados do tipo, ex: `bx_persons_data.id`).

#### 7. Listar Todos os Perfis (de um certo tipo ou todos)

*   **Endpoint:** `GET /api/v1/admin/profiles` ou `GET /api/v1/admin/profiles/{profile_type}`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `page`, `per_page`, `sort_by`, filtros (`filter_status`, `filter_account_email_like`, `filter_content_field_like` - este último é complexo).
*   **Resposta de Sucesso (200 OK):** Lista de perfis com dados resumidos do conteúdo e da conta.

#### 8. Criar Novo Perfil para uma Conta Existente

*   **Endpoint:** `POST /api/v1/admin/users/{account_id}/profiles`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Retorna os dados do perfil criado.
*   **Lógica do Backend:**
    1.  Cria a entrada na tabela de conteúdo (ex: `bx_persons_data`) usando o `ContentRepo` apropriado.
    2.  Cria a entrada em `sys_profiles` ligando `account_id` ao novo `content_id`.
    3.  Se este for o novo perfil principal da conta, atualiza `sys_accounts.profile_id`.

#### 9. Obter Detalhes de um Perfil Específico (por `profile_id` de `sys_profiles`)

*   **Endpoint:** `GET /api/v1/admin/profiles/{profile_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna dados combinados de `sys_profiles`, `sys_accounts`, e da tabela de conteúdo do perfil (ex: `bx_persons_data`).

#### 10. Obter Detalhes de um Perfil Específico (por tipo e `content_id`)

*   **Endpoint:** `GET /api/v1/admin/profiles/{profile_type}/{content_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Similar ao anterior.

#### 11. Atualizar Dados de Conteúdo de um Perfil

*   **Endpoint:** `PUT /api/v1/admin/profiles/{profile_type}/{content_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Contém os campos da tabela de conteúdo (ex: `bx_persons_data`) a serem atualizados.

*   **Resposta de Sucesso (200 OK):** Retorna os dados do perfil atualizado.
*   **Lógica do Backend:** Usa o `ContentRepo` apropriado (ex: `PersonsRepo.update_person_data`).

#### 12. Atualizar Status de um Perfil (`sys_profiles.status`)

*   **Endpoint:** `PUT /api/v1/admin/profiles/{profile_id}/status`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `{\"status\": \"suspended\"}` (valores válidos: 'active', 'pending', 'suspended').
*   **Resposta de Sucesso (200 OK).**
*   **Lógica do Backend:** Usa `ProfilesRepo.update_status`.

#### 13. Deletar um Perfil (e seus dados de conteúdo)

*   **Endpoint:** `DELETE /api/v1/admin/profiles/{profile_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (204 No Content).**
*   **Lógica do Backend:**
    1.  Busca o perfil de `sys_profiles` para obter `type` e `content_id`.
    2.  Deleta a entrada da tabela de conteúdo (ex: `bx_persons_data`) usando o `ContentRepo` (ex: `PersonsRepo.delete_person_data(content_id)`).
    3.  Deleta a entrada de `sys_profiles`.
    4.  Verifica se a conta (`sys_accounts`) ficou sem perfis ou se o `profile_id` principal precisa ser alterado/limpo.

#### 14. Gerenciar Níveis de ACL de um Perfil

*   **Endpoint:** `GET /api/v1/admin/profiles/{profile_id}/acl-levels` (Listar níveis atuais do perfil)
*   **Endpoint:** `POST /api/v1/admin/profiles/{profile_id}/acl-levels` (Adicionar perfil a um nível)
    *   Corpo: `{\"level_id\": 5, \"start_date\": \"YYYY-MM-DD HH:MM:SS\", \"expires_date\": \"YYYY-MM-DD HH:MM:SS\"}`
*   **Endpoint:** `PUT /api/v1/admin/profiles/{profile_id}/acl-levels/{level_id}` (Atualizar datas de uma associação)
*   **Endpoint:** `DELETE /api/v1/admin/profiles/{profile_id}/acl-levels/{level_id}` (Remover perfil de um nível)
*   **Lógica do Backend:** Usa `AclRepo` para manipular `sys_acl_levels_members`.

## Considerações:

*   **Autorização Granular para Admins:** Em sistemas maiores, pode haver diferentes papéis de administrador (super admin, moderador de usuários, etc.). A Studio API precisaria de seu próprio sub-sistema de ACL para controlar quais administradores podem acessar quais endpoints de gerenciamento.
*   **Validação:** Todas as entradas devem ser rigorosamente validadas.
*   **Logs de Auditoria:** Ações administrativas críticas (deletar usuário, alterar permissões) devem ser registradas em uma tabela de auditoria (`sys_audit`).
*   **Consistência de Dados:** Operações complexas (como criar conta + perfil + dados de conteúdo) devem ser transacionais.

Esta API de gerenciamento de usuários e perfis é uma parte extensa, mas vital, do Studio API, dando aos administradores controle total sobre a base de usuários da plataforma \"Deeper\".