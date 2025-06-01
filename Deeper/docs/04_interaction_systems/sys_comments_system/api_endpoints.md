# Documentação Deeper: Endpoints da API para o Sistema de Comentários

Este documento especifica os endpoints RESTful para interagir com o sistema de comentários \"Deeper\". Os comentários são geralmente aninhados sob o recurso principal ao qual pertencem (ex: artigos, perfis).

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas e corpos de requisição em JSON.
*   Autenticação JWT para criar/editar/deletar comentários ou interagir com eles.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).
*   ACL será aplicado (quem pode comentar, quem pode moderar).

**Parâmetros de Path Genéricos para Recursos Comentáveis:**

*   `{resource_type}`: Identifica o tipo de recurso principal (ex: `articles`, `profiles`, `photos`).
*   `{resource_id}`: O ID do recurso principal específico.
*   `{comment_id}`: O ID do comentário.

---

## 1. Comentários em um Recurso (`/{resource_type}/{resource_id}/comments`)

### 1.1. Listar Comentários de um Recurso

*   **Endpoint:** `GET /{resource_type}/{resource_id}/comments`
*   **Autenticação:** Opcional (para ver comentários públicos).
*   **Descrição:** Retorna uma lista paginada de comentários (geralmente os de nível raiz) para um recurso específico.
*   **Query Parameters:**
    *   `page={integer}` (default: 1)
    *   `per_page={integer}` (default: 20)
    *   `sort_by={string}` (default: `created_at_asc`. Opções: `created_at_desc`, `score_desc`)
    *   `parent_id={integer}` (default: 0 - para buscar comentários raiz. Forneça um `comment_id` para buscar suas respostas diretas).
    *   `include_author_details={boolean}` (default: `true`)
    *   `include_user_vote={boolean}` (default: `true` - se autenticado, inclui o voto/reação do usuário atual em cada comentário)
    *   `lang={lang_code}` (para traduções de UI, se aplicável a alguma parte da resposta)
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"system_name\": \"deeper_articles\", // Exemplo
          \"object_id\": \"{resource_id}\", // ID do artigo
          \"author\": { // Detalhes do autor (se include_author_details=true)
            \"profile_id\": 12,
            \"name\": \"Nome do Autor do Comentário\",
            \"avatar_url\": \"/path/to/avatar.jpg\"
          },
          \"parent_id\": 0,
          \"level\": 0,
          \"text\": \"Este é um comentário raiz.\",
          \"status\": \"active\",
          \"votes\": 15,
          \"score\": 12,
          \"reactions_up\": 10, // Exemplo
          \"replies_count\": 3, // Número de respostas diretas
          \"created_at\": 1678880000,
          \"updated_at\": 1678880500,
          \"current_user_interaction\": { // Se include_user_vote=true e usuário autenticado
            \"score_vote\": 1, // Ex: 1 para upvote, -1 para downvote, 0 ou null se não votou
            \"reaction_value\": \"like_id\" // Exemplo
          }
        }
        // ... mais comentários ...
      ],
      \"pagination\": {
        \"total_items\": 50,
        \"current_page\": 1,
        \"per_page\": 20,
        \"total_pages\": 3
      }
    }
```

```json
    {
      \"text\": \"Ótimo artigo!\",
      \"parent_id\": 0 // ID do comentário pai se for uma resposta, ou 0 (ou omitido) para um comentário raiz
    }
```

```json
    {
      \"text\": \"Texto do comentário atualizado.\"
      // \"status\": \"active\" // Moderadores podem mudar o status
    }
```

```json
    // Para um sistema de score (upvote/downvote)
    {
      \"vote_type\": \"score\", // Obrigatório
      \"value\": 1 // 1 para upvote, -1 para downvote
    }

    // Para um sistema de reações (ex: like, love)
    {
      \"vote_type\": \"reaction\", // Obrigatório
      \"value\": \"like_id\" // ID ou nome da reação específica
    }
```

```json
    {
      \"data\": {
        \"comment_id\": \"{comment_id}\",
        \"new_score\": 13, // Score atualizado do comentário
        \"new_votes_count\": 16, // Contagem total de votos/scores
        \"user_vote\": { \"vote_type\": \"score\", \"value\": 1 } // O voto/reação do usuário
      }
    }
```

```json
    {
      \"vote_type\": \"score\" // O tipo de voto/reação a ser removido
    }
```

```json
    {
      \"data\": {
        \"comment_id\": \"{comment_id}\",
        \"new_score\": 12,
        \"new_votes_count\": 15,
        \"user_vote\": null // Voto/reação do usuário foi removido
      }
    }
```

*   **Lógica de Backend (Controller):**
    1.  Identificar o `system_name` apropriado baseado no `{resource_type}` (ex: `articles` -> `deeper_articles_comments`).
    2.  Obter `current_user_profile_id` do JWT (se presente).
    3.  Chamar `Deeper.InteractionSystems.CommentsRepo.list_comments/3` com `system_name`, `{resource_id}`, e os query params processados.
    4.  Se `include_user_vote` e usuário autenticado, buscar os votos/reações do usuário para os comentários listados usando `CommentsRepo.get_user_votes_for_comments/2` e mesclar na resposta.

### 1.2. Criar Novo Comentário em um Recurso

*   **Endpoint:** `POST /{resource_type}/{resource_id}/comments`
*   **Autenticação:** Requerida (JWT). Permissão ACL para \"postar comentário\" no `{resource_type}` será verificada.
*   **Descrição:** Cria um novo comentário (ou uma resposta a um comentário existente) em um recurso.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):**
    *   Corpo contém o comentário recém-criado (similar à estrutura de um item na listagem, com `author` sendo o usuário atual).
    *   Header `Location` apontando para o novo recurso (ex: `/api/v1/{resource_type}/{resource_id}/comments/{new_comment_id}`).
*   **Respostas de Erro:** `400`, `401`, `403` (sem permissão para comentar), `404` (recurso principal não encontrado ou comentário pai não encontrado), `422`.
*   **Lógica de Backend:**
    1.  Extrair `author_profile_id` do JWT.
    2.  Verificar permissão ACL.
    3.  Identificar o `system_name` baseado no `{resource_type}`.
    4.  Chamar `Deeper.InteractionSystems.CommentsRepo.create_comment/1` com os dados.

---

## 2. Gerenciamento de Comentário Específico (`/{resource_type}/{resource_id}/comments/{comment_id}`)

Estes endpoints operam em um comentário já existente.

### 2.1. Obter Comentário Específico

*   **Endpoint:** `GET /{resource_type}/{resource_id}/comments/{comment_id}`
*   **Autenticação:** Opcional.
*   **Descrição:** Retorna os detalhes de um comentário específico.
*   **Query Parameters:**
    *   `include_author_details={boolean}` (default: `true`)
    *   `include_user_vote={boolean}` (default: `true`)
*   **Resposta de Sucesso (200 OK):** (Objeto de comentário similar ao da listagem).
*   **Lógica de Backend:**
    1.  Chamar `Deeper.InteractionSystems.CommentsRepo.get_comment_by_id/2`.
    2.  Verificar se o `system_name` e `object_id` do comentário correspondem ao `{resource_type}` e `{resource_id}` da URL para consistência.
    3.  Aplicar lógica de `include_user_vote`.

### 2.2. Atualizar Comentário

*   **Endpoint:** `PUT /{resource_type}/{resource_id}/comments/{comment_id}`
*   **Autenticação:** Requerida. O usuário deve ser o autor do comentário ou ter permissão de moderador.
*   **Descrição:** Atualiza o texto de um comentário existente.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** (Objeto do comentário atualizado).
*   **Respostas de Erro:** `400`, `401`, `403` (não é autor/moderador), `404`.
*   **Lógica de Backend:**
    1.  Verificar se o usuário autenticado é o autor ou tem permissões de moderação.
    2.  Chamar `Deeper.InteractionSystems.CommentsRepo.update_comment/2`.

### 2.3. Deletar Comentário

*   **Endpoint:** `DELETE /{resource_type}/{resource_id}/comments/{comment_id}`
*   **Autenticação:** Requerida. O usuário deve ser o autor ou ter permissão de moderador.
*   **Descrição:** Deleta um comentário (pode ser soft ou hard delete dependendo da política).
*   **Query Parameters (Opcional):**
    *   `type={string}` (default: `soft`. Opções: `soft`, `hard`) - Se a API permitir ao usuário escolher.
*   **Resposta de Sucesso (204 No Content).**
*   **Respostas de Erro:** `401`, `403`, `404`.
*   **Lógica de Backend:**
    1.  Verificar permissão para deletar.
    2.  Chamar `Deeper.InteractionSystems.CommentsRepo.delete_comment/2`.

---

## 3. Votos/Reações em Comentários (`/{resource_type}/{resource_id}/comments/{comment_id}/interactions`)

Estes endpoints permitem que usuários interajam com comentários (ex: upvote/downvote, like).

### 3.1. Registrar Voto/Reação em um Comentário

*   **Endpoint:** `POST /{resource_type}/{resource_id}/comments/{comment_id}/interactions`
*   **Autenticação:** Requerida.
*   **Descrição:** Permite que um usuário dê um upvote/downvote, ou uma reação específica a um comentário.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Respostas de Erro:** `400`, `401`, `403` (ex: já votou e não pode mudar, ou não pode votar em seus próprios comentários), `404`.
*   **Lógica de Backend:**
    1.  Extrair `voter_profile_id` do JWT.
    2.  Verificar permissão ACL para votar/reagir.
    3.  Chamar `Deeper.InteractionSystems.CommentsRepo.vote_on_comment/4`.
    4.  Retornar o estado atualizado dos contadores do comentário e o voto do usuário.

### 3.2. Remover Voto/Reação de um Comentário

*   **Endpoint:** `DELETE /{resource_type}/{resource_id}/comments/{comment_id}/interactions`
*   **Autenticação:** Requerida.
*   **Descrição:** Remove um voto/reação previamente feito pelo usuário em um comentário.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):**