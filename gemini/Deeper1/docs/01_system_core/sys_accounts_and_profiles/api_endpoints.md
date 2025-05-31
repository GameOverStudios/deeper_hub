# Documentação Deeper: Endpoints da API para Contas e Perfis

Este documento especifica os endpoints da API RESTful \"Deeper\" para o gerenciamento de contas de usuário e seus perfis associados. Todos os endpoints estarão sob o prefixo `/api/v1/`.

## Autenticação (Endpoints sob `/auth`)

Estes endpoints lidam com o processo de autenticação e registro.

### 1. Registrar Nova Conta

*   **Endpoint:** `POST /api/v1/auth/register`
*   **Descrição:** Cria uma nova conta de usuário e, opcionalmente, um perfil básico associado.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"name\": \"John Doe\", // Ou username, dependendo da lógica de sys_accounts.name
      \"email\": \"john.doe@example.com\",
      \"password\": \"SecurePassword123\",
      \"profile_type\": \"bx_persons\" // Opcional: tipo de perfil a ser criado (ex: 'bx_persons')
      // Outros campos opcionais para o perfil podem ser incluídos aqui se profile_type for fornecido
      // \"profile_data\": { \"fullname\": \"John Doe\", \"gender\": \"male\" } // se profile_type = 'bx_persons'
    }
```

```json
    {
      \"data\": {
        \"account_id\": 123,
        \"email\": \"john.doe@example.com\",
        \"profile_id\": 456, // ID do perfil criado em sys_profiles
        \"message\": \"Account created successfully. Please check your email for verification.\"
        // Opcionalmente, pode retornar um JWT para login automático
        // \"token\": \"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...\"
      }
    }
```

```json
    {
      \"email\": \"john.doe@example.com\",
      \"password\": \"SecurePassword123\"
    }
```

```json
    {
      \"data\": {
        \"token\": \"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...\", // JWT
        \"expires_in\": 3600, // Segundos até a expiração
        \"user\": { // Informações básicas do usuário logado
          \"account_id\": 123,
          \"profile_id\": 456, // ID do perfil padrão/ativo
          \"name\": \"John Doe\",
          \"email\": \"john.doe@example.com\",
          \"role\": 1 // ID do role
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
        \"phone\": \"1234567890\",
        \"phone_confirmed\": false,
        \"role\": 1,
        \"lang_id\": 1,
        \"active\": true,
        \"locked\": false,
        \"added\": 1678886400, // Unix timestamp
        \"changed\": 1678886400
      }
    }
```

```json
    {
      \"name\": \"Jonathan Doe\",
      \"phone\": \"0987654321\"
      // Outros campos atualizáveis
    }
```

```json
    {
      \"data\": [
        // ... lista de objetos de conta (formato similar ao GET /accounts/{account_id})
      ],
      \"pagination\": {
        \"total_items\": 100,
        \"total_pages\": 5,
        \"current_page\": 1,
        \"per_page\": 20
      }
    }
```

```json
    // O formato exato dependerá do 'type' do perfil, ex: 'bx_persons'
    {
      \"data\": {
        \"profile_id\": 456, // sys_profiles.id
        \"account_id\": 123,
        \"type\": \"bx_persons\",
        \"content_id\": 789, // bx_persons_data.id
        \"status\": \"active\",
        \"account_email\": \"john.doe@example.com\", // Vindo do JOIN com sys_accounts
        // Dados específicos do tipo de perfil (ex: bx_persons_data)
        \"fullname\": \"John Doe\",
        \"description\": \"Software Developer.\",
        \"gender\": \"male\",
        \"birthday\": \"1990-01-01\",
        \"picture_url\": \"/path/to/image.jpg\", // URL para a imagem, se houver
        \"cover_url\": \"/path/to/cover.jpg\",
        // ... outros campos de bx_persons_data ...
        \"views\": 1500,
        \"rate\": 4.5,
        \"allow_view_to\": \"3\" // Nível de privacidade
      }
    }
```

```json
    // Exemplo para um perfil 'bx_persons'
    {
      \"fullname\": \"Jonathan Doe Updated\",
      \"description\": \"Senior Software Developer.\",
      \"location\": \"New City\"
      // Outros campos de bx_persons_data que podem ser atualizados
      // \"allow_view_to\": \"1\" // Atualizar configurações de privacidade
    }
```

```json
    {
      \"data\": [
        // ... lista de objetos de perfil (formato similar ao GET /profiles/me)
      ],
      \"pagination\": { /* ... */ }
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: Dados inválidos ou faltando (ex: email já existe).
    *   `422 Unprocessable Entity`: Falha de validação (ex: senha fraca).
*   **Lógica do Backend:**
    1.  Valida os dados de entrada.
    2.  Verifica se o email já está em uso (`AccountsRepo.get_by_email`).
    3.  Hasheia a senha.
    4.  Cria a entrada em `sys_accounts` (`AccountsRepo.create`).
    5.  Se `profile_type` for fornecido (ex: 'bx_persons'):
        *   Cria a entrada em `bx_persons_data` (`PersonsRepo.create` com `profile_data`).
        *   Cria a entrada em `sys_profiles` ligando a conta ao novo `content_id` de `bx_persons_data` (`ProfilesRepo.create`).
        *   Atualiza `profile_id` em `sys_accounts` se for o perfil principal.
    6.  (Opcional) Envia email de confirmação.

### 2. Login de Usuário

*   **Endpoint:** `POST /api/v1/auth/login`
*   **Descrição:** Autentica um usuário e retorna um JSON Web Token (JWT).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: Email ou senha não fornecidos.
    *   `401 Unauthorized`: Credenciais inválidas, conta inativa ou bloqueada.
*   **Lógica do Backend:**
    1.  Busca a conta por email (`AccountsRepo.get_by_email`).
    2.  Verifica se a conta existe, está ativa e não está bloqueada.
    3.  Compara o hash da senha fornecida com o `password_hash` armazenado.
    4.  Se válido, gera um JWT (incluindo `account_id`, `profile_id` ativo, `role_id`, `acl_level_id` no payload).
    5.  Atualiza informações de último login (`AccountsRepo.update_login_info`).

### 3. Logout de Usuário (Opcional/Gerenciado pelo Cliente)

*   **Endpoint:** `POST /api/v1/auth/logout` (Opcional)
*   **Descrição:** Invalida o token JWT do usuário.
    *   **Implementação Simples (Cliente):** O cliente simplesmente descarta o JWT. Não há necessidade de endpoint se não houver invalidação do lado do servidor.
    *   **Implementação Servidor (Mais Complexa):** Requer uma blacklist de tokens.
*   **Autenticação:** Requer JWT válido.
*   **Resposta de Sucesso (204 No Content ou 200 OK com mensagem).**

## Contas de Usuário (Endpoints sob `/accounts`)

Gerenciamento direto de contas (geralmente para administradores ou para o próprio usuário).

### 4. Obter Conta de Usuário por ID

*   **Endpoint:** `GET /api/v1/accounts/{account_id}`
*   **Descrição:** Retorna os detalhes de uma conta de usuário específica.
*   **Autenticação:** Requer JWT.
*   **Autorização:**
    *   Usuário só pode obter seus próprios dados de conta.
    *   Administradores podem obter dados de qualquer conta (verificar ACL).
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:**
    *   `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

### 5. Atualizar Conta de Usuário

*   **Endpoint:** `PUT /api/v1/accounts/{account_id}`
    *   Alternativa: `PATCH /api/v1/accounts/{account_id}` para atualizações parciais.
*   **Descrição:** Atualiza os detalhes de uma conta de usuário.
*   **Autenticação:** Requer JWT.
*   **Autorização:** Usuário só pode atualizar sua própria conta (exceto campos sensíveis como `role`, `active`, `locked`, que seriam para admins). Admins podem ter mais permissões.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna a representação atualizada da conta.
*   **Respostas de Erro:**
    *   `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `422 Unprocessable Entity`.

### 6. Listar Contas de Usuário (Primariamente para Admin)

*   **Endpoint:** `GET /api/v1/accounts`
*   **Descrição:** Retorna uma lista paginada de contas de usuário, com opções de filtro e ordenação.
*   **Autenticação:** Requer JWT.
*   **Autorização:** Geralmente restrito a administradores.
*   **Query Parameters:**
    *   `page` (ou `offset`), `per_page` (ou `limit`) para paginação.
    *   `sort_by` (ex: `name_asc`, `email_desc`, `added_desc`).
    *   Filtros: `email_like`, `name_like`, `active` (true/false), `role`, etc.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `401 Unauthorized`, `403 Forbidden`.

## Perfis (Endpoints sob `/profiles`)

Gerenciamento de perfis associados a contas.

### 7. Obter Perfil Principal do Usuário Logado (\"Meu Perfil\")

*   **Endpoint:** `GET /api/v1/profiles/me`
*   **Descrição:** Retorna os detalhes do perfil principal/ativo do usuário autenticado. Este endpoint é um atalho conveniente.
*   **Autenticação:** Requer JWT.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `401 Unauthorized`, `404 Not Found` (se o usuário não tiver um perfil principal ativo).
*   **Lógica do Backend:**
    1.  Extrai `account_id` (e possivelmente `profile_id` do perfil principal) do JWT.
    2.  Usa `ProfilesRepo.get_profile_details/1` (ou uma função similar) para buscar os dados do perfil, fazendo JOIN com `sys_accounts` e a tabela de dados do tipo de perfil (ex: `bx_persons_data`).

### 8. Obter Perfil Específico por ID

*   **Endpoint:** `GET /api/v1/profiles/{profile_id}`
*   **Descrição:** Retorna os detalhes de um perfil específico.
*   **Autenticação:** Requer JWT (para verificar permissões de visualização).
*   **Autorização:**
    *   Verifica se o usuário logado tem permissão para visualizar este perfil, baseado nas configurações de privacidade do perfil (`allow_view_to` em `bx_persons_data`) e no nível de ACL do solicitante.
*   **Resposta de Sucesso (200 OK):** Formato similar ao `GET /profiles/me`.
*   **Respostas de Erro:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

### 9. Atualizar Perfil Específico

*   **Endpoint:** `PUT /api/v1/profiles/{profile_id}`
    *   Alternativa: `PATCH /api/v1/profiles/{profile_id}`
*   **Descrição:** Atualiza os dados de um perfil específico (ex: dados em `bx_persons_data`).
*   **Autenticação:** Requer JWT.
*   **Autorização:** Usuário só pode atualizar seus próprios perfis, ou administradores com permissão.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna a representação atualizada do perfil.
*   **Respostas de Erro:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `422 Unprocessable Entity`.
*   **Lógica do Backend:**
    1.  Verifica se o usuário logado é o dono do perfil (comparando `account_id` do JWT com `sys_profiles.account_id` do `{profile_id}`) ou se é admin.
    2.  Obtém o `content_id` e `type` de `sys_profiles` para o `{profile_id}`.
    3.  Usa o repositório apropriado (ex: `PersonsRepo.update`) para atualizar os dados na tabela de conteúdo (ex: `bx_persons_data`).

### 10. Listar Perfis (com Filtros e Paginação)

*   **Endpoint:** `GET /api/v1/profiles`
*   **Descrição:** Retorna uma lista paginada de perfis, com opções de filtro e ordenação.
*   **Autenticação:** Requer JWT.
*   **Autorização:** A lista retornada deve respeitar as configurações de privacidade de cada perfil em relação ao usuário solicitante. Isso pode tornar a query complexa.
*   **Query Parameters:**
    *   `page`, `per_page`
    *   `sort_by` (ex: `fullname_asc`, `added_desc`)
    *   Filtros: `type` (ex: 'bx_persons'), `fullname_like` (se type=bx_persons), `location_like`, etc.
*   **Resposta de Sucesso (200 OK):**