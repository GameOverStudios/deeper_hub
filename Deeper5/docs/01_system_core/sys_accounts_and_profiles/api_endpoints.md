# Documentação Deeper: Endpoints da API para Contas e Perfis

Este documento especifica os endpoints RESTful para o gerenciamento de Contas de Usuário (`sys_accounts`) e Perfis (`sys_profiles` e `bx_persons_data`) no sistema \"Deeper\".

**Convenções Gerais:**
*   Todos os endpoints estão sob o prefixo `/api/v1`.
*   Respostas e corpos de requisição são em JSON.
*   A autenticação é feita via JWT no header `Authorization: Bearer <token>`.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../00_core_concepts/api_design_conventions.md).

---

## 1. Autenticação (`/auth`)

Estes endpoints são públicos e não requerem autenticação JWT prévia.

### 1.1. Registrar Nova Conta

*   **Endpoint:** `POST /auth/register`
*   **Descrição:** Cria uma nova conta de usuário e, opcionalmente, um perfil básico de pessoa associado.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"name\": \"novousuario\", // sys_accounts.name (pode ser usado para login ou ser o fullname inicial)
      \"email\": \"usuario@example.com\",
      \"password\": \"senhaSegura123\",
      \"profile_data\": { // Opcional, para criar um perfil de pessoa junto com a conta
        \"fullname\": \"Nome Completo do Usuário\", // bx_persons_data.fullname
        \"type\": \"bx_persons\" // Tipo do perfil a ser criado (default para 'bx_persons' se não especificado)
        // ... outros campos opcionais de bx_persons_data como description, gender, etc.
      }
    }
```

```json
    {
      \"data\": {
        \"account\": {
          \"id\": 123, // sys_accounts.id
          \"name\": \"novousuario\",
          \"email\": \"usuario@example.com\",
          \"active\": 0, // Ou 1, dependendo da política de ativação
          \"role\": 1,
          \"added\": 1678886400
        },
        \"profile\": { // Se profile_data foi fornecido
          \"id\": 456, // sys_profiles.id
          \"type\": \"bx_persons\",
          \"content_id\": 789, // bx_persons_data.id
          \"status\": \"active\"
        },
        \"person_data\": { // Se profile_data foi fornecido
          \"id\": 789,
          \"fullname\": \"Nome Completo do Usuário\",
          // ... outros campos de bx_persons_data retornados
        },
        \"token\": \"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...\" // JWT para login automático
      }
    }
```

```json
    {
      \"email\": \"usuario@example.com\", // ou \"username\": \"novousuario\"
      \"password\": \"senhaSegura123\"
    }
```

```json
    {
      \"data\": {
        \"token\": \"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...\",
        \"user\": { // Informações básicas do usuário logado
          \"account_id\": 123,
          \"profile_id\": 456, // ID do perfil principal em sys_accounts
          \"name\": \"novousuario\",
          \"email\": \"usuario@example.com\",
          \"role\": 1
        }
      }
    }
```

```json
    {
      \"data\": {
        \"id\": 123,
        \"profile_id\": 456,
        \"name\": \"novousuario\",
        \"email\": \"usuario@example.com\",
        \"email_confirmed\": true, // Booleano
        \"phone\": \"123456789\",
        \"phone_confirmed\": false,
        \"receive_updates\": true,
        \"receive_news\": false,
        \"role\": 1,
        \"lang_id\": 2,
        \"added\": 1678886400,
        \"changed\": 1678887000,
        \"active\": true
      }
    }
```

```json
    {
      \"name\": \"novousuario_atualizado\", // Campos permitidos para atualização
      \"phone\": \"987654321\",
      \"receive_updates\": false,
      \"lang_id\": 1
      // Não permitir atualização de email ou status de confirmação por aqui (endpoints dedicados)
      // Não permitir atualização de role ou active por aqui (admin)
    }
```

```json
    {
      \"current_password\": \"senhaAntiga123\",
      \"new_password\": \"novaSenhaSuperSegura456\"
    }
```

```json
    {
      \"data\": {
        \"profile_id\": 456, // sys_profiles.id
        \"account_id\": 123,
        \"type\": \"bx_persons\",
        \"content_id\": 789, // bx_persons_data.id
        \"status\": \"active\", // profile_status
        \"account_name\": \"novousuario\",
        \"account_email\": \"usuario@example.com\",
        \"account_active\": true,
        // Campos de bx_persons_data
        \"person_data_id\": 789, // bx_persons_data.id (pode ser redundante se content_id já está ali)
        \"fullname\": \"Nome Completo do Usuário\",
        \"description\": \"Bio do usuário.\",
        \"gender\": \"other\",
        \"birthday\": \"1990-01-01\",
        \"picture_url\": \"/path/to/picture.jpg\", // URL para a imagem (precisa de lógica de arquivos)
        \"cover_url\": \"/path/to/cover.jpg\",
        // ...outros campos de bx_persons_data e contadores...
        \"allow_view_to\": \"3\"
      }
    }
```

```json
    {
      \"fullname\": \"Novo Nome Completo\",
      \"description\": \"Nova bio.\",
      \"gender\": \"male\",
      \"birthday\": \"1991-02-02\",
      \"location\": \"Nova Cidade\",
      // \"picture_id\": 10, // Se o upload de imagem for separado e retornar um ID
      // \"cover_id\": 11,
      \"settings\": { \"theme\": \"dark\" } // JSON para settings
    }
```

```json
    {
      \"data\": [
        // ... lista de objetos de perfil de pessoa (resumidos) ...
      ],
      \"pagination\": {
        \"total_items\": 100,
        \"current_page\": 1,
        \"per_page\": 20,
        \"total_pages\": 5
      }
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: Dados de entrada ausentes ou inválidos.
    *   `422 Unprocessable Entity`: Email ou nome de usuário já existe, senha fraca.
    *   `500 Internal Server Error`.
*   **Lógica de Backend:**
    1.  Validar dados de entrada.
    2.  Hashear a senha.
    3.  Chamar `Deeper.SystemCore.AccountsRepo.create_account/1`.
    4.  Se `profile_data` presente e conta criada com sucesso:
        *   Chamar `Deeper.Content.PersonsRepo.create_person_data/1` (passando o `sys_profiles.id` do autor, que neste caso pode ser complexo de determinar sem um perfil pré-existente ou pode ser um ID de sistema/admin, ou o `author` em `bx_persons_data` pode ser o `sys_profiles.id` do perfil que está sendo criado).
            *   **Alternativa/Simplificação:** O `author` em `bx_persons_data` pode ser o `account_id` do criador, ou o `sys_profiles.id` do perfil de pessoa recém-criado. Isso precisa ser definido. Por agora, vamos assumir que `create_person_data` pode lidar com isso.
        *   Chamar `Deeper.SystemCore.ProfilesRepo.create_profile/1` (com `account_id`, `type`, e `content_id` do `bx_persons_data` criado).
        *   Opcionalmente, atualizar `sys_accounts.profile_id` com o ID do novo perfil principal.
    5.  Gerar JWT.

### 1.2. Login de Usuário

*   **Endpoint:** `POST /auth/login`
*   **Descrição:** Autentica um usuário existente e retorna um JWT.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: Email/senha ausentes.
    *   `401 Unauthorized`: Credenciais inválidas, conta não ativa ou bloqueada.
    *   `500 Internal Server Error`.
*   **Lógica de Backend:**
    1.  Chamar `Deeper.SystemCore.AccountsRepo.get_account_by_email/1`.
    2.  Verificar se a conta existe, está ativa e não bloqueada.
    3.  Verificar a senha (comparar hash).
    4.  Se sucesso, chamar `Deeper.SystemCore.AccountsRepo.reset_login_attempts/1`.
    5.  Gerar JWT (contendo `account_id`, `profile_id` principal da conta, `level_id` do ACL).
    6.  Retornar token e informações básicas do usuário.
    7.  Se falha na verificação da senha, chamar `Deeper.SystemCore.AccountsRepo.record_login_attempt/1`.


---

## 2. Contas de Usuário (`/accounts`)

Endpoints para gerenciar a própria conta do usuário autenticado.

### 2.1. Obter Dados da Conta Autenticada

*   **Endpoint:** `GET /accounts/me`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Retorna os dados da conta do usuário autenticado.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica de Backend:**
    1.  Extrair `account_id` do JWT.
    2.  Chamar `Deeper.SystemCore.AccountsRepo.get_account/1`.

### 2.2. Atualizar Dados da Conta Autenticada

*   **Endpoint:** `PUT /accounts/me`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Atualiza os dados da conta do usuário autenticado.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):**
    *   Corpo contém os dados da conta atualizada (similar ao `GET /accounts/me`).
*   **Lógica de Backend:**
    1.  Extrair `account_id` do JWT.
    2.  Validar os campos permitidos para atualização.
    3.  Chamar `Deeper.SystemCore.AccountsRepo.update_account/2`.

### 2.3. Atualizar Senha da Conta Autenticada

*   **Endpoint:** `PUT /accounts/me/password`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Atualiza a senha do usuário autenticado.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (204 No Content).**
*   **Respostas de Erro:**
    *   `400 Bad Request`: Senhas ausentes ou nova senha fraca.
    *   `401 Unauthorized` (ou `422`): `current_password` incorreta.
*   **Lógica de Backend:**
    1.  Extrair `account_id` do JWT.
    2.  Chamar `Deeper.SystemCore.AccountsRepo.get_account/1` para obter o hash da senha atual.
    3.  Verificar `current_password`.
    4.  Se válida, hashear `new_password`.
    5.  Chamar `Deeper.SystemCore.AccountsRepo.update_password_hash/2`.


---

## 3. Perfis (`/profiles`)

Endpoints para interagir com perfis, especialmente o perfil de pessoa.

### 3.1. Obter Dados do Perfil Principal do Usuário Autenticado

*   **Endpoint:** `GET /profiles/me`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Retorna os dados completos do perfil principal associado à conta do usuário autenticado (ex: dados de `sys_profiles` e `bx_persons_data`).
*   **Resposta de Sucesso (200 OK):**

*   **Lógica de Backend:**
    1.  Extrair `account_id` do JWT.
    2.  Chamar `Deeper.SystemCore.AccountsRepo.get_account/1` para obter o `profile_id` principal.
    3.  Se `profile_id` existir, chamar `Deeper.SystemCore.ProfilesRepo.get_profile/1` para obter `content_id` e `type`.
    4.  Se `type` for `'bx_persons'`, chamar `Deeper.Content.PersonsRepo.get_full_person_profile_by_person_data_id/1` (ou uma função similar que faça os JOINs necessários) usando o `content_id`.

### 3.2. Atualizar Dados do Perfil Principal (Pessoa) do Usuário Autenticado

*   **Endpoint:** `PUT /profiles/me`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Atualiza os dados do perfil de pessoa (`bx_persons_data`) do usuário autenticado.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):**
    *   Corpo contém os dados do perfil atualizado (similar ao `GET /profiles/me`).
*   **Lógica de Backend:**
    1.  Extrair `account_id` do JWT.
    2.  Obter o `profile_id` principal e subsequentemente o `content_id` do perfil de pessoa (como no `GET /profiles/me`).
    3.  Validar os campos permitidos para atualização.
    4.  Chamar `Deeper.Content.PersonsRepo.update_person_data/2` com o `content_id` e os parâmetros.

### 3.3. Obter Dados de um Perfil de Pessoa Público

*   **Endpoint:** `GET /profiles/persons/{person_id_or_username}`
    *   `person_id_or_username`: Pode ser o `bx_persons_data.id` ou um `sys_accounts.name` (se nomes de usuário forem únicos e mapeáveis para perfis de pessoa). A lógica de resolução precisará ser implementada.
*   **Autenticação:** Opcional (se o perfil for público, não requer JWT; se requer login para ver, sim). A lógica de `allow_view_to` será aplicada.
*   **Descrição:** Retorna os dados públicos de um perfil de pessoa específico.
*   **Resposta de Sucesso (200 OK):**
    *   Similar ao `GET /profiles/me`, mas apenas com campos permitidos pela configuração de privacidade `allow_view_to` e pelo status do perfil.
*   **Respostas de Erro:**
    *   `404 Not Found`: Perfil não encontrado.
    *   `403 Forbidden`: Se o perfil não for público e o usuário não tiver permissão.
*   **Lógica de Backend:**
    1.  Resolver `person_id_or_username` para um `bx_persons_data.id`.
    2.  Chamar `Deeper.Content.PersonsRepo.get_full_person_profile_by_person_data_id/1`.
    3.  Verificar permissões de visualização (`allow_view_to` em `bx_persons_data`) com base no usuário autenticado (se houver) e seu nível de ACL.
    4.  Filtrar os campos retornados com base na privacidade.

### 3.4. Listar Perfis de Pessoa (com Paginação e Filtros)

*   **Endpoint:** `GET /profiles/persons`
*   **Autenticação:** Opcional (para ver perfis públicos).
*   **Descrição:** Lista perfis de pessoa, com suporte a paginação e filtros.
*   **Query Parameters:**
    *   `page=1`
    *   `per_page=20`
    *   `sort_by=added_desc` (ou `fullname_asc`, etc.)
    *   `filter_fullname=Nome` (LIKE)
    *   `filter_location=Cidade` (LIKE)
    *   `filter_gender=male`
    *   ... outros filtros relevantes ...
*   **Resposta de Sucesso (200 OK):**