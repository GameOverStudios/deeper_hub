# Documentação Deeper: Endpoints da API para Contas e Perfis

Este documento especifica os endpoints RESTful da API \"Deeper\" para o gerenciamento de contas de usuário e perfis. Estes endpoints utilizarão os módulos de acesso a dados (`AccountsRepo`, `ProfilesRepo`, `PersonsRepo`) definidos anteriormente.

## Convenções Gerais:

*   **Base URL:** `/api/v1`
*   **Autenticação:** Endpoints marcados como \"Protegido\" requerem um JWT válido no cabeçalho `Authorization: Bearer <token>`.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme definido em `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints de Autenticação (`/auth`)

### 1. Registrar Nova Conta

*   **Endpoint:** `POST /auth/register`
*   **Descrição:** Cria uma nova conta de usuário e, opcionalmente, um perfil de pessoa associado.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"name\": \"John Doe\", // Usado para sys_accounts.name e bx_persons_data.fullname
      \"email\": \"john.doe@example.com\",
      \"password\": \"securePassword123\",
      \"profile_data\": { // Opcional, para criar dados em bx_persons_data
        \"description\": \"Loves Elixir!\",
        \"gender\": \"male\",
        \"birthday\": \"1990-01-15\"
        // Outros campos de bx_persons_data
      }
    }
```

```json
    {
      \"data\": {
        \"account_id\": 123, // sys_accounts.id
        \"profile_id\": 456, // sys_profiles.id (se perfil foi criado)
        \"email\": \"john.doe@example.com\",
        \"name\": \"John Doe\",
        \"message\": \"Conta criada com sucesso. Verifique seu email para ativação.\" // Exemplo
        // NÃO retornar JWT aqui, a menos que o login seja automático após registro e email confirmado.
      }
    }
```

```json
    {
      \"email\": \"john.doe@example.com\",
      \"password\": \"securePassword123\"
    }
```

```json
    {
      \"data\": {
        \"token\": \"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...\", // JWT
        \"expires_in\": 3600, // Tempo de expiração em segundos
        \"user\": { // Informações básicas do usuário/perfil logado
          \"account_id\": 123,
          \"profile_id\": 456,
          \"name\": \"John Doe\",
          \"email\": \"john.doe@example.com\",
          \"role\": 1 // sys_accounts.role
          // Adicionar level_id do ACL aqui se disponível no login
        }
      }
    }
```

```json
    {
      \"data\": {
        \"id\": 123,
        \"profile_id\": 456,
        \"name\": \"John Doe\",
        \"email\": \"john.doe@example.com\",
        \"email_confirmed\": true,
        \"phone\": \"123-456-7890\",
        \"phone_confirmed\": false,
        \"receive_updates\": true,
        \"receive_news\": false,
        \"role\": 1,
        \"lang_id\": 2,
        \"added\": 1678886400, // Unix timestamp
        \"changed\": 1678886500,
        \"active\": true
        // Não incluir password_hash ou login_attempts
      }
    }
```

```json
    {
      \"name\": \"Johnny Doe\",
      \"phone\": \"987-654-3210\",
      \"receive_updates\": false,
      \"current_password\": \"securePassword123\", // Necessário se a senha for alterada
      \"new_password\": \"newSecurePassword456\" // Opcional
    }
```

```json
    {
      \"data\": { // Dados combinados de sys_profiles e bx_persons_data (ou outro tipo de perfil)
        \"profile_id\": 456, // sys_profiles.id
        \"account_id\": 123, // sys_accounts.id
        \"type\": \"bx_persons\",
        \"content_id\": 789, // bx_persons_data.id
        \"status\": \"active\", // sys_profiles.status
        \"fullname\": \"John Doe\", // bx_persons_data.fullname
        \"description\": \"Loves Elixir!\",
        \"gender\": \"male\",
        \"birthday\": \"1990-01-15\",
        \"picture_url\": \"/path/to/picture.jpg\", // URL da imagem, ou ID do arquivo
        \"cover_url\": \"/path/to/cover.jpg\",
        \"views\": 105,
        // ... outros campos de bx_persons_data ...
        \"allow_view_to\": \"3\" // Representação da configuração de privacidade
      }
    }
```

```json
    {
      \"fullname\": \"Johnny Doe\",
      \"description\": \"Elixir enthusiast and developer.\",
      \"gender\": \"male\",
      \"location\": \"New City\",
      \"settings\": { \"theme_color\": \"blue\" } // Exemplo de settings como JSON
      // ... outros campos de bx_persons_data permitidos para atualização
    }
```

```json
    {
      \"data\": [
        {
          \"profile_id\": 456,
          \"type\": \"bx_persons\",
          \"content_id\": 789,
          \"fullname\": \"John Doe\",
          \"description_snippet\": \"Loves Elixir!...\", // Snippet
          \"picture_url\": \"/path/to/picture.jpg\"
          // Somente campos para exibição em lista
        },
        // ... outros perfis ...
      ],
      \"pagination\": {
        \"total_items\": 150,
        \"total_pages\": 8,
        \"current_page\": 1,
        \"per_page\": 20
      }
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Erros Comuns:**
    *   `422 Unprocessable Entity`: Falha na validação (email já existe, senha fraca, campos faltando).
    *   `400 Bad Request`: JSON malformado.
*   **Lógica do Backend:**
    1.  Validar dados de entrada.
    2.  Gerar hash da senha.
    3.  Chamar `AccountsRepo.create_account/1`.
    4.  Se `profile_data` presente e conta criada com sucesso:
        a.  Chamar `PersonsRepo.create_person_data/1` (passando `author` como o `profile_id` que *será* criado para este usuário ou um `account_id` temporário se o `profile_id` ainda não existir).
        b.  Chamar `ProfilesRepo.create_profile/1` (ligando `account_id` e `content_id` de `bx_persons_data`).
        c.  Atualizar `sys_accounts.profile_id` com o `id` do novo perfil em `sys_profiles`. (Idealmente tudo em uma transação).
    5.  (Opcional) Enviar email de confirmação.

### 2. Login de Usuário

*   **Endpoint:** `POST /auth/login`
*   **Descrição:** Autentica um usuário e retorna um JWT.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):**

*   **Erros Comuns:**
    *   `401 Unauthorized`: Credenciais inválidas, conta inativa ou bloqueada.
    *   `422 Unprocessable Entity`: Email ou senha faltando.
*   **Lógica do Backend:**
    1.  Buscar conta por email via `AccountsRepo.get_account_by_email/1`.
    2.  Verificar se a conta existe, está ativa e não está bloqueada.
    3.  Verificar a senha usando `Comeonin` e o `password_hash` armazenado.
    4.  Se válido, gerar JWT (com `account_id`, `profile_id` principal, `level_id` do ACL, `exp`).
    5.  Atualizar `sys_accounts.logged` e `sys_accounts.ip` via `AccountsRepo.update_last_logged/2`.
    6.  Resetar `login_attempts` via `AccountsRepo.reset_login_attempts/1`.

### 3. (Opcional) Logout de Usuário

*   **Endpoint:** `POST /auth/logout`
*   **Status:** Protegido
*   **Descrição:** Invalida o token do lado do cliente (o servidor pode opcionalmente adicionar o token a uma blacklist se tal mecanismo for implementado).
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (204 No Content).**
*   **Lógica do Backend (Opcional para blacklist):**
    1.  Adicionar o JTI (JWT ID) do token a uma lista de tokens invalidados (ex: Redis com TTL).

## Endpoints de Contas (`/accounts`)

### 4. Obter Dados da Conta Logada

*   **Endpoint:** `GET /accounts/me`
*   **Status:** Protegido
*   **Descrição:** Retorna informações detalhadas da conta do usuário autenticado.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    1.  Extrair `account_id` do JWT.
    2.  Chamar `AccountsRepo.get_account/1`.

### 5. Atualizar Dados da Conta Logada

*   **Endpoint:** `PUT /accounts/me`
*   **Status:** Protegido
*   **Descrição:** Permite que o usuário autenticado atualize seus próprios dados da conta.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna os dados da conta atualizada (similar ao `GET /accounts/me`).
*   **Erros Comuns:**
    *   `422 Unprocessable Entity`: Falha na validação (ex: `current_password` inválida se `new_password` fornecido).
*   **Lógica do Backend:**
    1.  Extrair `account_id` do JWT.
    2.  Se `new_password` presente, verificar `current_password`. Se válida, gerar hash da `new_password`.
    3.  Chamar `AccountsRepo.update_account/2` com os campos permitidos.

## Endpoints de Perfis (`/profiles`)

### 6. Obter Dados do Perfil Principal do Usuário Logado

*   **Endpoint:** `GET /profiles/me`
*   **Status:** Protegido
*   **Descrição:** Retorna os dados detalhados do perfil principal (ex: \"bx_persons\") associado à conta do usuário autenticado.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    1.  Extrair `account_id` e `profile_id` (principal) do JWT.
    2.  Chamar `ProfilesRepo.get_profile/1` usando o `profile_id` do JWT.
    3.  Com base no `type` e `content_id` do perfil:
        *   Se `type == \"bx_persons\"`, chamar `PersonsRepo.get_person_data/1` usando `content_id`.
        *   (Implementar para outros tipos de perfil futuramente).
    4.  Combinar os dados e retornar.

### 7. Obter Dados de um Perfil Específico por ID

*   **Endpoint:** `GET /profiles/{profile_id}`
*   **Status:** Público (a visibilidade do conteúdo do perfil é controlada pela lógica de `allow_view_to` e ACL)
*   **Descrição:** Retorna os dados detalhados de um perfil específico.
*   **Resposta de Sucesso (200 OK):** Similar ao `GET /profiles/me`.
*   **Erros Comuns:**
    *   `404 Not Found`: Perfil não existe.
    *   `403 Forbidden`: Se o usuário logado não tiver permissão para ver este perfil (baseado em `allow_view_to` e ACL).
*   **Lógica do Backend:**
    1.  Chamar `ProfilesRepo.get_profile/1` com o `{profile_id}` da URL.
    2.  Verificar permissões de visualização (ACL e `allow_view_to` da tabela de conteúdo).
    3.  Buscar dados específicos do tipo de perfil (ex: `PersonsRepo.get_person_data/1`).
    4.  Combinar e retornar.

### 8. Atualizar Dados do Perfil Principal do Usuário Logado

*   **Endpoint:** `PUT /profiles/me`
*   **Status:** Protegido
*   **Descrição:** Permite que o usuário autenticado atualize os dados do seu perfil principal.
*   **Corpo da Requisição (JSON):** Dependerá do `type` do perfil. Para \"bx_persons\":

*   **Resposta de Sucesso (200 OK):** Retorna os dados do perfil atualizado (similar ao `GET /profiles/me`).
*   **Lógica do Backend:**
    1.  Extrair `profile_id` (principal) do JWT.
    2.  Chamar `ProfilesRepo.get_profile/1` para obter `type` e `content_id`.
    3.  Se `type == \"bx_persons\"`, chamar `PersonsRepo.update_person_data/2` com `content_id` e os parâmetros.
    4.  (Implementar para outros tipos de perfil).

### 9. Listar Perfis (Exemplo: Pessoas)

*   **Endpoint:** `GET /profiles?type=bx_persons`
*   **Status:** Público (com paginação; visibilidade individual controlada por ACL/privacidade)
*   **Descrição:** Lista perfis de um tipo específico, com paginação, filtros e ordenação.
*   **Query Parameters:**
    *   `type=bx_persons` (obrigatório ou com um default)
    *   `page=1` (ou `offset=0`)
    *   `per_page=20` (ou `limit=20`)
    *   `sort_by=added_desc` (ex: `fullname_asc`, `views_desc`)
    *   Filtros específicos do tipo (ex: `fullname_like=John`, `gender=male`)
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    1.  Validar `type`.
    2.  Se `type == \"bx_persons\"`, chamar `PersonsRepo.list_persons_data/1` com as opções de paginação, filtro e ordenação. Esta função precisará fazer `JOIN` com `sys_profiles` para obter `profile_id` e filtrar por `type`, e também implementar a lógica de paginação (queries separadas para dados e contagem total).
    3.  A verificação de `allow_view_to` para cada item da lista pode ser complexa e impactar a performance. Uma abordagem é aplicar filtros genéricos na query SQL e, se necessário, filtrar mais finamente na camada da aplicação (ou o cliente lida com itens \"bloqueados\" na UI).
    4.  Mapear os resultados para o formato de resposta da lista.

*(Outros endpoints, como upload de avatar/capa para perfis, seriam definidos em uma seção de gerenciamento de arquivos e depois referenciados ou integrados aqui).*