# Documentação Deeper: Endpoints da API para Módulo Pessoas (`bx_persons`)

Este documento especifica os endpoints da API RESTful \"Deeper\" dedicados ao módulo \"Pessoas\" (`bx_persons`). Muitos dados de perfil já são acessíveis através dos endpoints genéricos `/api/v1/profiles` (como `GET /profiles/me` e `GET /profiles/{profile_id}`). Os endpoints listados aqui cobrem funcionalidades mais específicas do módulo `bx_persons`, como listagens especializadas, gerenciamento de fotos de perfil, e interações como visualizações e comentários diretamente ligados a perfis de pessoas.

Todos os endpoints estarão sob o prefixo `/api/v1/persons`. O `{person_id}` nos caminhos geralmente se refere ao `id` da tabela `bx_persons_data` (que é o `content_id` em `sys_profiles` quando `type = 'bx_persons'`).

## Endpoints Principais para `bx_persons`

### 1. Listar Perfis de Pessoas

*   **Endpoint:** `GET /api/v1/persons`
*   **Descrição:** Retorna uma lista paginada de perfis de pessoas, com opções avançadas de filtro e ordenação. Este endpoint é a principal forma de buscar/descobrir membros.
*   **Autenticação:** Requer JWT (para aplicar filtros de privacidade e ACL).
*   **Query Parameters:**
    *   **Paginação:** `page` (ou `offset`), `per_page` (ou `limit`).
    *   **Ordenação:** `sort_by` (ex: `fullname_asc`, `added_desc`, `views_desc`, `last_online_desc` - este último requer JOIN com `sys_accounts.logged`). `sort_order` (`asc` ou `desc`).
    *   **Filtros:**
        *   `fullname_like`: Buscar por nome completo (parcial).
        *   `location_like`: Buscar por localização (parcial).
        *   `gender`: Filtrar por gênero.
        *   `age_min`, `age_max`: Filtrar por faixa etária (requer cálculo a partir de `bx_persons_data.birthday`).
        *   `is_online`: (true/false) Filtrar por status online (requer JOIN com `sys_accounts` e verificação de `logged` contra um threshold de atividade recente).
        *   `has_avatar`: (true/false) Filtrar perfis com/sem foto de perfil (`bx_persons_data.picture IS NOT NULL`).
        *   Outros filtros baseados em campos de `bx_persons_data` ou tabelas relacionadas (ex: por `skill`, por `meta_keyword` - requer JOINs adicionais).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"person_id\": 789, // bx_persons_data.id
          \"profile_id\": 456, // sys_profiles.id
          \"account_id\": 123, // sys_accounts.id
          \"fullname\": \"John Doe\",
          \"description_snippet\": \"Software Developer...\", // Snippet da descrição
          \"location\": \"New City\",
          \"avatar_url\": \"/path/to/avatar_thumb.jpg\", // URL para um thumbnail do avatar
          \"is_online\": true,
          \"added_timestamp\": 1678886400
          // Outros campos resumidos relevantes para uma listagem
        }
        // ... outros perfis ...
      ],
      \"pagination\": {
        \"total_items\": 127,
        \"total_pages\": 7,
        \"current_page\": 1,
        \"per_page\": 20
      }
    }
```

```json
    // Formato idêntico à resposta de GET /api/v1/profiles/me ou GET /api/v1/profiles/{profile_id}
    // Contendo todos os campos de bx_persons_data e informações relevantes de sys_accounts e sys_profiles.
    {
      \"data\": {
        \"person_id\": 789,
        \"profile_id\": 456,
        \"account_id\": 123,
        \"fullname\": \"John Doe\",
        \"description\": \"Software Developer.\",
        \"gender\": \"male\",
        // ... todos os outros campos ...
        \"pictures\": [ // Lista de URLs para as fotos do perfil (pode ser um endpoint separado)
            { \"id\": 1, \"url\": \"/path/to/original1.jpg\", \"thumb_url\": \"/path/to/thumb1.jpg\", \"is_main\": true },
            { \"id\": 2, \"url\": \"/path/to/original2.jpg\", \"thumb_url\": \"/path/to/thumb2.jpg\", \"is_main\": false }
        ],
        \"comments_count\": 15,
        \"views_count\": 1502
      }
    }
```

```json
    {
      \"data\": [
        {
          \"picture_id\": 1, // bx_persons_pictures.id
          \"remote_id\": \"abc123xyz\",
          \"url\": \"/storage/persons_pictures/abc123xyz.jpg\", // URL para a imagem original
          \"thumbnails\": { // URLs para versões redimensionadas
            \"small\": \"/storage/persons_pictures_resized/s_abc123xyz.jpg\",
            \"medium\": \"/storage/persons_pictures_resized/m_abc123xyz.jpg\"
          },
          \"dimensions\": \"800x600\",
          \"added_timestamp\": 1678886400,
          \"is_main_avatar\": true // Se esta é a foto principal do perfil (bx_persons_data.picture)
        }
        // ... outras fotos ...
      ],
      \"pagination\": { /* ... */ }
    }
```

*   **Respostas de Erro:** `401 Unauthorized`.
*   **Lógica do Backend:** Utiliza `PersonsRepo.list_persons_with_details` com os filtros e lógica de privacidade complexa.

### 2. Obter Dados Detalhados de um Perfil de Pessoa

*   **Endpoint:** `GET /api/v1/persons/{person_id}`
*   **Descrição:** Retorna os dados detalhados de um perfil de pessoa específico. Similar a `GET /api/v1/profiles/{profile_id}` mas focado no `person_id` de `bx_persons_data`. O cliente pode usar um ou outro dependendo do ID que possui.
*   **Autenticação:** Requer JWT.
*   **Autorização:** Verifica `allow_view_to` do perfil contra o nível de ACL do solicitante.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

---
## Gerenciamento de Fotos do Perfil

### 3. Listar Fotos de um Perfil de Pessoa

*   **Endpoint:** `GET /api/v1/persons/{person_id}/pictures`
*   **Descrição:** Retorna uma lista paginada das fotos (originais e/ou redimensionadas relevantes) de um perfil de pessoa.
*   **Autenticação:** Requer JWT (para verificar permissões de visualização, se as fotos puderem ser privadas).
*   **Query Parameters:** `page`, `per_page`.
*   **Resposta de Sucesso (200 OK):**