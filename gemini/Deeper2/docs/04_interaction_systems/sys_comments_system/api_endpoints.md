# Documentação Deeper: Endpoints da API para Sistema de Comentários Genérico

Este documento especifica os endpoints RESTful da API \"Deeper\" para interagir com o sistema de comentários genérico. Estes endpoints permitem listar, criar, atualizar e deletar comentários associados a diferentes tipos de conteúdo.

## Convenções Gerais:

*   **Base URL:** `/api/v1/comments`
*   **Identificadores:**
    *   `{object_cmt_name}`: O nome do \"objeto de comentários\" (de `sys_objects_cmts.Name`, ex: `bx_persons_profile_cmts`, `bx_posts_item_cmts`). Identifica qual sistema de comentários está sendo usado.
    *   `{item_id}`: O ID do item de conteúdo principal que está sendo comentado (ex: `sys_profiles.id`, `bx_posts.id`).
    *   `{comment_id}`: O ID do comentário específico (de `sys_cmts_ids.id` ou o `cmt_id` da tabela de conteúdo do comentário, dependendo da implementação. Usaremos o ID da tabela de conteúdo do comentário para consistência com `cmt_parent_id`).
*   **Autenticação:** Ações de escrita (POST, PUT, DELETE) são protegidas. A listagem é pública, mas a visibilidade de comentários individuais pode ser afetada por `status_admin` e permissões do visualizador.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Listar Comentários de um Item

*   **Endpoint:** `GET /comments/object/{object_cmt_name}/item/{item_id}`
*   **Status:** Público (com filtragem de visibilidade)
*   **Descrição:** Retorna uma lista paginada de comentários (e suas respostas diretas, ou uma estrutura aninhada limitada) para um item de conteúdo específico.
*   **Parâmetros de URL:**
    *   `{object_cmt_name}`: Nome do objeto de comentários.
    *   `{item_id}`: ID do item de conteúdo.
*   **Query Parameters:**
    *   `page=1`, `per_page=10` (para comentários de nível superior)
    *   `parent_id=0` (default, para buscar comentários de nível superior. Pode ser usado para buscar respostas de um comentário específico).
    *   `sort_by=time_desc|time_asc|votes_desc|...` (ex: `cmt_time DESC`)
    *   `replies_per_comment=3` (opcional, para controlar quantas respostas diretas são incluídas por comentário de nível superior, se o backend for fazer essa junção. Caso contrário, o cliente busca respostas separadamente).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"cmt_id\": 101, // ID do comentário na sua tabela de conteúdo
          \"sys_cmts_ids_id\": 501, // ID da entrada em sys_cmts_ids (opcional de expor)
          \"parent_id\": 0,
          \"object_id\": \"{item_id}\", // ID do item principal comentado
          \"text\": \"Este é um ótimo comentário!\",
          \"time_ago\": \"2 horas atrás\", // ou timestamp
          \"timestamp\": 1679999999,
          \"replies_count\": 2, // bx_..._cmts.cmt_replies
          \"pinned\": false,
          \"author\": {
            \"profile_id\": 123,
            \"fullname\": \"Autor do Comentário\",
            \"avatar_url\": \"/path/to/autor_avatar.jpg\"
          },
          \"metadata\": { // de sys_cmts_ids
            \"rate\": 4.5,
            \"votes\": 10,
            \"score\": 8,
            \"status_admin\": \"active\"
          },
          \"replies_preview\": [ // Opcional, se `replies_per_comment` for usado
            {
              \"cmt_id\": 105, \"text\": \"Concordo!\", \"author\": { ... }, ...
            }
          ],
          \"can_edit\": false, // Se o usuário logado pode editar
          \"can_delete\": false // Se o usuário logado pode deletar
        }
        // ... outros comentários de nível superior
      ],
      \"pagination\": {
        \"total_items\": 50, // Total de comentários de nível superior
        \"total_pages\": 5,
        \"current_page\": 1,
        \"per_page\": 10
      },
      \"config\": { // Configurações do objeto de comentários (de sys_objects_cmts)
        \"name\": \"{object_cmt_name}\",
        \"chars_post_max\": 2048,
        \"number_of_levels\": 0, // 0 para ilimitado
        \"is_ratable\": true
        // ... outras configs relevantes para a UI
      }
    }
```

```json
    {
      \"text\": \"Meu novo comentário aqui!\",
      \"parent_id\": null // ou o ID do comentário pai se for uma resposta
      // \"mood\": 0 (opcional)
    }
```

```json
    {
      \"text\": \"Texto do comentário atualizado.\"
    }
```

```json
    {
      \"value\": 1 // ou -1 para score; ou 1-5 para rating
    }
```

```json
    {
      \"data\": {
        \"cmt_id\": \"{comment_id}\",
        \"new_rate\": 4.6,
        \"new_votes_count\": 11,
        \"user_vote\": 1 // o voto do usuário atual
      }
    }
```

*   **Lógica do Backend:**
    1.  Chamar `CommentsRepo.list_comments/3` com `object_cmt_name`, `item_id`, e opções de paginação/ordenação.
    2.  O Repo lida com a obtenção da configuração, consulta à tabela de comentários correta, JOINs para autor e metadados.
    3.  Determinar `can_edit` e `can_delete` com base no autor do comentário e nas permissões do usuário logado.

### 2. Postar um Novo Comentário

*   **Endpoint:** `POST /comments/object/{object_cmt_name}/item/{item_id}`
*   **Status:** Protegido
*   **Descrição:** Adiciona um novo comentário a um item de conteúdo.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Retorna o comentário recém-criado, formatado como na listagem.
*   **Erros Comuns:**
    *   `400 Bad Request`: Texto do comentário faltando ou inválido (ex: excede `CharsPostMax`).
    *   `401 Unauthorized`/`403 Forbidden`: Usuário não tem permissão para comentar.
    *   `404 Not Found`: Item `{item_id}` ou `{object_cmt_name}` não encontrado.
*   **Lógica do Backend:**
    1.  Extrair `author_profile_id` do JWT.
    2.  Validar permissões de postagem (ACL).
    3.  Chamar `CommentsRepo.add_comment/4` com os dados.
    4.  Retornar o comentário formatado.

### 3. Obter um Comentário Específico

*   **Endpoint:** `GET /comments/object/{object_cmt_name}/comment/{comment_id}`
*   **Status:** Público (com filtragem de visibilidade)
*   **Descrição:** Retorna os detalhes de um comentário específico.
*   **Resposta de Sucesso (200 OK):** Formato similar a um item da lista de `GET /comments/object/.../item/...`.
*   **Lógica do Backend:** Chama `CommentsRepo.get_comment/2`.

### 4. Atualizar um Comentário

*   **Endpoint:** `PUT /comments/object/{object_cmt_name}/comment/{comment_id}`
*   **Status:** Protegido (Dono do comentário ou Moderador com permissão)
*   **Descrição:** Atualiza o texto de um comentário existente.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna o comentário atualizado.
*   **Erros Comuns:**
    *   `403 Forbidden`: Usuário não é o autor ou não tem permissão de moderação.
    *   `404 Not Found`: Comentário não encontrado.
*   **Lógica do Backend:**
    1.  Extrair `author_profile_id` do JWT.
    2.  Chamar `CommentsRepo.update_comment/4`, que internamente verifica a propriedade/permissão.

### 5. Deletar um Comentário

*   **Endpoint:** `DELETE /comments/object/{object_cmt_name}/comment/{comment_id}`
*   **Status:** Protegido (Dono do comentário ou Moderador com permissão)
*   **Descrição:** Deleta um comentário.
*   **Resposta de Sucesso (204 No Content).**
*   **Erros Comuns:**
    *   `403 Forbidden`: Usuário não é o autor ou não tem permissão de moderação.
    *   `404 Not Found`: Comentário não encontrado.
*   **Lógica do Backend:**
    1.  Extrair `profile_id` do JWT e determinar se é moderador.
    2.  Chamar `CommentsRepo.delete_comment/4`.

## Endpoints para Interações *nos* Comentários (Exemplo: Votos)

*Se os comentários em si puderem ser votados (conforme `sys_objects_cmts.ObjectVote`):*

### 6. Votar em um Comentário

*   **Endpoint:** `POST /comments/object/{object_cmt_name}/comment/{comment_id}/vote`
*   **Status:** Protegido
*   **Descrição:** Permite que um usuário vote em um comentário específico.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna o novo estado de votos/score do comentário.

*   **Lógica do Backend:**
    1.  Extrair `voter_profile_id` do JWT.
    2.  Chamar `CommentsRepo.vote_on_comment/4` (que internamente usaria `VotingRepo` ou `ScoringRepo` com o `ObjectVote` ou `ObjectScore` configurado para o sistema de comentários, e o `sys_cmts_ids.id` do comentário como `item_id` para o sistema de votos/scores).

*Endpoints similares para Reports, Reactions nos comentários seguiriam este padrão, usando o `sys_cmts_ids.id` do comentário como o `item_id` para os respectivos sistemas de interação genéricos.*

### Considerações:

*   **Nomes de Tabela Dinâmicos:** O `{object_cmt_name}` na URL é crucial para que o backend saiba qual configuração de `sys_objects_cmts` usar e, consequentemente, qual tabela de conteúdo de comentários consultar.
*   **Aninhamento de Respostas:** A listagem de comentários (`GET /comments/object/.../item/...`) pode:
    *   Retornar apenas o nível superior (`parent_id=0`) e o cliente faz chamadas separadas para `parent_id={cmt_id_pai}` para buscar respostas.
    *   Retornar alguns níveis de respostas embutidas (ex: `replies_preview`). A primeira é mais RESTful e flexível.
*   **Atualização de Contadores:** O `CommentsRepo` é responsável por garantir que os contadores (`TriggerFieldComments` em `TriggerTable`, `cmt_replies` no comentário pai) sejam atualizados.