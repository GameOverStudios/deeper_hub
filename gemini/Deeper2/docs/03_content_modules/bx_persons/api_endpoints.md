# Documentação Deeper: Endpoints da API para Pessoas (`bx_persons`)

Este documento especifica os endpoints RESTful da API \"Deeper\" para interagir com perfis de pessoas, gerenciados pelo módulo `bx_persons` do UNA.

## Convenções Gerais:

*   **Base URL:** `/api/v1/persons` (ou `/api/v1/profiles` se \"persons\" for tratado como um tipo de perfil genérico, mas vamos usar `/persons` para especificidade do módulo `bx_persons`).
*   **Autenticação:** Muitos endpoints requerem autenticação (JWT). A visibilidade e permissões são controladas por ACL.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme `docs/00_core_concepts/api_design_conventions.md`.
*   **Identificador de Perfil:** `{profile_id}` nos caminhos refere-se ao `id` da tabela `sys_profiles`. `{person_content_id}` refere-se ao `id` da tabela `bx_persons_data`. Muitas vezes, a API pode aceitar um `profile_id` e resolver internamente o `content_id` ou vice-versa, ou aceitar um `uri_slug`.

## Endpoints Principais de Perfis de Pessoas

### 1. Listar Perfis de Pessoas

*   **Endpoint:** `GET /persons`
*   **Status:** Público (com filtros de privacidade aplicados implicitamente)
*   **Descrição:** Retorna uma lista paginada de perfis de pessoas.
*   **Query Parameters:**
    *   `page=1`, `per_page=20` (para paginação)
    *   `sort_by=added_desc|fullname_asc|views_desc|...`
    *   `fullname_like=<search_term>`
    *   `gender=<male|female|other>`
    *   `location_like=<city_or_country>`
    *   `has_picture=true|false`
    *   `min_age=<age>`, `max_age=<age>` (requer cálculo a partir de `birthday`)
    *   `skill=<skill_name>` (requer JOIN com `bx_persons_skills`)
    *   `keyword=<keyword>` (requer JOIN com `bx_persons_meta_keywords`)
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"profile_id\": 456, // sys_profiles.id
          \"content_id\": 789, // bx_persons_data.id
          \"uri_slug\": \"john-doe\", // bx_persons_data.uri (se existir)
          \"fullname\": \"John Doe\",
          \"description_snippet\": \"Loves Elixir and hiking...\", // Um breve resumo
          \"main_picture_url\": \"/path/to/avatar.jpg\", // URL da foto principal
          \"location_text\": \"New York, USA\", // bx_persons_data.location
          \"added_timestamp\": 1678886400
        }
        // ... outros perfis
      ],
      \"pagination\": {
        \"total_items\": 1200,
        \"total_pages\": 60,
        \"current_page\": 1,
        \"per_page\": 20
      }
    }
```

```json
    {
      \"data\": {
        \"profile_id\": 456,
        \"content_id\": 789,
        \"account_id\": 123,
        \"uri_slug\": \"john-doe\",
        \"fullname\": \"John Doe\",
        \"description\": \"Loves Elixir and hiking. Enjoys long walks on the beach...\",
        \"gender\": \"male\",
        \"birthday\": \"1990-01-15\",
        \"location_text\": \"New York, USA\",
        \"location_meta\": { // de bx_persons_meta_locations
          \"lat\": 40.7128, \"lng\": -74.0060, \"country\": \"US\", \"city\": \"New York\"
        },
        \"main_picture_url\": \"/path/to/avatar.jpg\",
        \"cover_picture_url\": \"/path/to/cover.jpg\",
        \"views\": 1050,
        \"rate_avg\": 4.5,
        \"rate_count\": 20,
        \"score\": 85,
        \"favorites_count\": 30,
        \"comments_count\": 15,
        \"added_timestamp\": 1678886400,
        \"changed_timestamp\": 1679886400,
        \"profile_status\": \"active\", // sys_profiles.status
        \"account_status\": \"active\", // sys_accounts.active
        \"privacy_settings\": { // Informações sobre quem pode ver o quê
            \"allow_view_to\": \"3\", // ID do grupo de privacidade
            \"allow_post_to\": \"5\",
            \"allow_contact_to\": \"3\"
        },
        \"skills\": [\"Elixir\", \"Phoenix\", \"SQL\"], // de bx_persons_skills
        \"keywords\": [\"developer\", \"tech\", \"hiking\"] // de bx_persons_meta_keywords
        // Outros campos de bx_persons_data e sys_profiles
      }
    }
```

```json
    {
      \"account_id\": 123, // ID da conta existente à qual associar
      // OU dados para criar uma nova conta se não for parte do /auth/register
      // \"account_data\": { \"email\": \"new@user.com\", \"password\": \"...\", \"name\": \"...\" }
      \"person_data\": {
        \"fullname\": \"Jane Doe\",
        \"description\": \"New member\",
        // ... outros campos de bx_persons_data
      }
    }
```

```json
    {
      \"fullname\": \"Johnathan Doe\",
      \"description\": \"Updated bio.\",
      \"location_text\": \"San Francisco, CA\",
      \"settings\": {\"theme\": \"dark\"} // Exemplo de settings JSON
      // ...
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101, // bx_persons_pictures.id
          \"remote_id\": \"uuid-abc-123\",
          \"file_name\": \"photo1.jpg\",
          \"url\": \"/storage/uuid-abc-123/photo1.jpg\", // URL para a imagem original
          \"thumbnail_url\": \"/storage/resized/uuid-abc-123_thumb/photo1.jpg\", // Exemplo
          \"dimensions\": \"1200x800\",
          \"added_timestamp\": 1679999999
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"keywords\": [\"elixir\", \"developer\", \"phoenix framework\"]
    }
```

```json
    {
      \"data\": {
        \"profile_id\": 456,
        \"keywords\": [\"elixir\", \"developer\", \"phoenix framework\"]
      }
    }
```

```json
    {
      \"data\": {
        \"keywords\": [\"elixir\", \"developer\"]
      }
    }
```

*   **Lógica do Backend:**
    1.  Chamar `PersonsRepo.list_persons_data/1` com os parâmetros de filtro, ordenação e paginação.
    2.  O Repo deve lidar com os JOINs necessários (ex: `sys_profiles` para obter `profile_id`).
    3.  A lógica de privacidade (`allow_view_to`) deve ser aplicada na query SQL ou ao filtrar os resultados, considerando o `user_level_id` do solicitante (se autenticado).

### 2. Obter Detalhes de um Perfil de Pessoa

*   **Endpoint:** `GET /persons/{profile_id_or_uri}`
    *   Alternativa: `GET /persons/id/{profile_id}` e `GET /persons/uri/{uri_slug}` para desambiguação. Vamos usar a forma combinada por enquanto.
*   **Status:** Público (com filtros de privacidade)
*   **Descrição:** Retorna detalhes completos de um perfil de pessoa.
*   **Parâmetros de URL:**
    *   `{profile_id_or_uri}`: O `id` de `sys_profiles` ou o `uri` (slug) do perfil de `bx_persons_data`.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    1.  Determinar se `profile_id_or_uri` é um ID ou URI.
    2.  Chamar `PersonsRepo.get_person_details_by_profile_id/1` ou `PersonsRepo.get_person_details_by_uri/1`.
    3.  O Repo busca dados de `bx_persons_data`, `sys_profiles`, `sys_accounts`, e opcionalmente faz JOINs ou chamadas separadas para `_meta_locations`, `_skills`, `_keywords`.
    4.  Verificar permissões de visualização (ACL, `allow_view_to`).
    5.  **Importante:** Registrar uma visualização chamando `PersonsRepo.track_profile_view/3` (se o solicitante for diferente do dono do perfil).

### 3. Criar um Perfil de Pessoa (Geralmente parte do Registro de Conta)

*   *Este endpoint pode ser coberto por `POST /auth/register` se a criação de perfil for integrada.*
*   **Endpoint (Admin ou caso especial):** `POST /persons`
*   **Status:** Protegido (Admin ou permissão específica)
*   **Descrição:** Cria um novo perfil de pessoa associado a uma conta existente (ou cria a conta também).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Retorna os detalhes do perfil criado.
*   **Lógica do Backend:**
    1.  (Se `account_data` presente) Criar conta via `AccountsRepo`.
    2.  Criar entrada em `bx_persons_data` via `PersonsRepo.create_person_data/1`.
    3.  Criar entrada em `sys_profiles` via `ProfilesRepo.create_profile/1`.
    4.  Atualizar `sys_accounts.profile_id` se aplicável. (Tudo em transação).

### 4. Atualizar Perfil de Pessoa (Usuário Logado)

*   **Endpoint:** `PUT /persons/me`
*   **Status:** Protegido
*   **Descrição:** Permite que o usuário autenticado atualize seu próprio perfil de pessoa.
*   **Corpo da Requisição (JSON):** Campos de `bx_persons_data` que podem ser atualizados.

*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do perfil atualizado.
*   **Lógica do Backend:**
    1.  Extrair `profile_id` (principal) do JWT.
    2.  Obter `content_id` de `sys_profiles` para este `profile_id`.
    3.  Chamar `PersonsRepo.update_person_data/2` com o `content_id` e os parâmetros.

### 5. Atualizar Perfil de Pessoa (Admin)

*   **Endpoint:** `PUT /persons/{profile_id}`
*   **Status:** Protegido (Admin)
*   **Descrição:** Permite que um administrador atualize qualquer perfil de pessoa.
*   **Corpo da Requisição:** Similar ao `PUT /persons/me`.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do perfil atualizado.
*   **Lógica do Backend:** Similar ao `PUT /persons/me`, mas usa o `{profile_id}` da URL e verifica permissões de admin.

### 6. Deletar Perfil de Pessoa (Admin ou Dono da Conta)

*   **Endpoint:** `DELETE /persons/{profile_id}`
*   **Status:** Protegido (Admin ou Dono da Conta com permissão)
*   **Descrição:** Deleta um perfil de pessoa e a conta associada (ou apenas o perfil, dependendo da política).
*   **Resposta de Sucesso (204 No Content).**
*   **Lógica do Backend:**
    1.  Verificar permissões.
    2.  Obter `account_id` e `content_id` a partir do `profile_id`.
    3.  Deletar dados relacionados em cascata (fotos, comentários, votos, etc.) ou usar `ON DELETE CASCADE` nas FKs.
    4.  Deletar de `bx_persons_data`.
    5.  Deletar de `sys_profiles`.
    6.  Deletar de `sys_accounts`. (Tudo em transação).

## Endpoints para Galeria de Fotos do Perfil

### 7. Listar Fotos de um Perfil

*   **Endpoint:** `GET /persons/{profile_id}/pictures`
*   **Status:** Público (respeitando privacidade da foto individual, se houver)
*   **Descrição:** Lista as fotos da galeria de um perfil.
*   **Query Parameters:** `page=1`, `per_page=10`.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Chama `PersonsRepo.list_pictures_for_profile/2`. A geração de `url` e `thumbnail_url` dependerá da implementação do sistema de arquivos (`06_file_management/`).

### 8. Adicionar Foto à Galeria do Usuário Logado

*   **Endpoint:** `POST /persons/me/pictures`
*   **Status:** Protegido
*   **Descrição:** Faz upload de uma nova foto para a galeria do usuário logado. Requer `multipart/form-data`.
*   **Corpo da Requisição:** Campo de arquivo (ex: `picture_file`), e campos opcionais como `caption`, `private`.
*   **Resposta de Sucesso (201 Created):** Detalhes da foto adicionada.
*   **Lógica do Backend:**
    1.  Extrair `profile_id` do JWT.
    2.  Lidar com o upload do arquivo (salvar no storage - lógica de `06_file_management/`).
    3.  Obter `remote_id`, `path`, `file_name`, etc., do arquivo salvo.
    4.  Chamar `PersonsRepo.add_picture_to_profile/2`.
    5.  (Opcional) Iniciar transcodificação para criar versões redimensionadas.

### 9. Deletar Foto da Galeria do Usuário Logado

*   **Endpoint:** `DELETE /persons/me/pictures/{picture_id}`
*   **Status:** Protegido
*   **Descrição:** Deleta uma foto da galeria do usuário logado.
*   **Parâmetros de URL:** `{picture_id}` (ID de `bx_persons_pictures`).
*   **Resposta de Sucesso (204 No Content).**
*   **Lógica do Backend:**
    1.  Extrair `profile_id` do JWT.
    2.  Chamar `PersonsRepo.delete_picture/2` passando o `profile_id` para verificação de propriedade.
    3.  Lidar com a exclusão do arquivo físico no storage e versões redimensionadas.

## Endpoints para Interações (Comentários, Favoritos, Votos, etc.)

*Estes endpoints geralmente seguirão um padrão, utilizando os sistemas de interação genéricos (a serem definidos em `04_interaction_systems/`) mas contextualizados para `bx_persons`.*

**Exemplo para Comentários (assumindo sistema genérico):**
*   `GET /persons/{profile_id}/comments?page=1&per_page=10`
*   `POST /persons/{profile_id}/comments` (Protegido)
    *   Corpo: `{\"text\": \"Ótimo perfil!\", \"parent_comment_id\": null}`
*   `PUT /persons/{profile_id}/comments/{comment_id}` (Protegido, dono ou mod)
*   `DELETE /persons/{profile_id}/comments/{comment_id}` (Protegido, dono ou mod)

**Exemplo para Favoritos (assumindo sistema genérico):**
*   `GET /persons/{profile_id}/favorites` (Quem favoritou este perfil)
*   `POST /persons/{profile_id}/favorite` (Protegido - para favoritar/desfavoritar por quem está logado)
    *   Pode ser um toggle ou métodos separados `POST /favorite` e `DELETE /favorite`.

*Padrões similares para Votos/Scores, Reports.*

## Endpoints para Metadados e Habilidades

### 10. Gerenciar Keywords do Perfil do Usuário Logado

*   **Endpoint:** `PUT /persons/me/keywords`
*   **Status:** Protegido
*   **Descrição:** Define/sobrescreve as palavras-chave para o perfil do usuário logado.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Extrair `profile_id` do JWT, chamar `PersonsRepo.set_profile_keywords/2`.

### 11. Obter Keywords de um Perfil

*   **Endpoint:** `GET /persons/{profile_id}/keywords`
*   **Status:** Público
*   **Resposta de Sucesso (200 OK):**