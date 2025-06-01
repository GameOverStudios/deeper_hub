# Documentação Deeper: Mapeamento da Lógica de \"Serviço\" para API (Módulo `deeper_forums`)

O módulo de fóruns no UNA PHP, como outros, usaria \"serviços\" para gerar blocos de UI (listas de fóruns, tópicos recentes, etc.) e para encapsular lógica de apresentação. Na API RESTful \"Deeper\", transformamos isso em endpoints que retornam dados JSON, com o cliente frontend assumindo a responsabilidade pela renderização.

## 1. Serviço: \"Listar Categorias de Fóruns\" (se aplicável)

*   **Funcionalidade UNA PHP (Exemplo Hipotético):**
    *   `BxForumModule->service_list_forum_categories()`
    *   Retornaria HTML de uma lista de categorias de fóruns.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/forum-categories`
    *   **Query Parameters:** `sort_by=order_index_asc`
    *   **Lógica no `Deeper.Content.ForumsRepo`:** Função `list_forum_categories/1`.
    *   **Responsabilidade do Cliente:** Buscar os dados e renderizar a lista de categorias.

## 2. Serviço: \"Listar Fóruns\" (Página principal de fóruns, possivelmente agrupada por categorias)

*   **Funcionalidade UNA PHP:**
    *   `BxForumModule->service_list_forums(int $category_id = null)`
    *   Retornaria HTML da lista de fóruns, mostrando título, descrição, contagens e último post.

*   **Mapeamento para API \"Deeper\":**
    *   **Para obter todas as categorias e depois os fóruns de cada uma (se agrupados):**
        1.  Cliente faz `GET /api/v1/forum-categories`.
        2.  Para cada categoria, ou para obter todos os fóruns: `GET /api/v1/forums?category_id={cat_id}&include=last_post_details&sort_by=order_index_asc`.
    *   **Alternativa (se a API puder retornar fóruns agrupados por categoria):**
        *   `GET /api/v1/forums/structured` (endpoint customizado) ou `GET /api/v1/forum-categories?include=forums,forums.last_post_details`. Este último é mais complexo para a API.
        *   Uma abordagem mais simples é o cliente fazer as duas chamadas e montar a estrutura.
    *   **Lógica no `Deeper.Content.ForumsRepo`:** Função `list_forums/2` (com filtro de categoria) e `get_forum/2` (com `include` para detalhes do último post).
    *   **Responsabilidade do Cliente:** Buscar os dados e renderizar a estrutura de fóruns, possivelmente agrupada.

## 3. Serviço: \"Listar Tópicos em um Fórum\"

*   **Funcionalidade UNA PHP:**
    *   `BxForumModule->service_list_topics(int $forum_id, int $page = 1, int $per_page = 20)`
    *   Retornaria HTML paginado da lista de tópicos.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/forums/{forum_id_or_slug}/topics`
    *   **Query Parameters:** `page`, `per_page`, `sort_by=is_sticky_desc,last_post_at_desc`, `include=author_profile,last_post_profile`.
    *   **Lógica no `Deeper.Content.ForumsRepo`:** Função `list_topics_in_forum/2`.
    *   **Responsabilidade do Cliente:** Renderizar a lista de tópicos e a paginação.

## 4. Serviço: \"Exibir Posts de um Tópico\"

*   **Funcionalidade UNA PHP:**
    *   `BxForumModule->service_view_topic_posts(int $topic_id, int $page = 1, int $per_page = 15)`
    *   Retornaria HTML paginado dos posts do tópico.

*   **Mapeamento para API \"Deeper\":**
    *   **Passo 1 (Obter detalhes do tópico, incluindo o primeiro post):**
        *   `GET /api/v1/topics/{topic_id}?include=author_profile,first_post_body`
    *   **Passo 2 (Obter posts/respostas paginados):**
        *   `GET /api/v1/topics/{topic_id}/posts?page={page_num}&per_page={count}&include=author_profile&sort_by=created_at_asc` (excluindo o primeiro post, que já pode ter sido obtido).
    *   **Lógica no `Deeper.Content.ForumsRepo`:** Funções `get_topic/2` e `list_posts_in_topic/2`.
    *   **Responsabilidade do Cliente:** Montar a visualização do tópico, exibindo o primeiro post e depois a lista paginada de respostas.

## 5. Serviço: \"Formulário para Novo Tópico\"

*   **Funcionalidade UNA PHP:**
    *   `BxForumModule->service_new_topic_form(int $forum_id)`
    *   Retornaria HTML do formulário.

*   **Mapeamento para API \"Deeper\":**
    *   **Não um endpoint que retorna UI.** O formulário é construído pelo cliente.
    *   O cliente precisa saber o `forum_id` (ou slug) para onde o tópico será postado.
    *   Ao submeter, o cliente envia para: `POST /api/v1/forums/{forum_id_or_slug}/topics`.
    *   Validações (título obrigatório, etc.) são tratadas pelo backend.

## 6. Serviço: \"Formulário para Nova Resposta (Post)\"

*   **Funcionalidade UNA PHP:**
    *   `BxForumModule->service_new_post_form(int $topic_id, int $parent_post_id = null)`
    *   Retornaria HTML do formulário de resposta.

*   **Mapeamento para API \"Deeper\":**
    *   **Não um endpoint que retorna UI.** O formulário é construído pelo cliente.
    *   O cliente precisa do `topic_id` e, opcionalmente, `parent_post_id` (para citação/resposta direta).
    *   Ao submeter, o cliente envia para: `POST /api/v1/topics/{topic_id}/posts`.

## 7. Serviço: \"Últimos Tópicos Ativos\" (para um bloco em todo o site)

*   **Funcionalidade UNA PHP:**
    *   `BxForumModule->service_latest_active_topics(int $count = 5)`
    *   Retornaria HTML.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/topics/latest-activity` (Endpoint customizado) OU `GET /api/v1/topics` (se a listagem global de tópicos for suportada).
    *   **Query Parameters (para `/topics`):**
        *   `sort_by=last_post_at_desc`
        *   `per_page={N}`
        *   `include=forum_details,author_profile,last_post_profile`
    *   **Lógica no `Deeper.Content.ForumsRepo`:** Uma função `list_all_topics/2` que pode ordenar globalmente por `last_post_at` e ser paginada.
    *   **Responsabilidade do Cliente:** Renderizar a lista.

## 8. Serviço: \"Marcar Tópico como Lido\" / \"Ir para Próximo Post Não Lido\"

*   **Funcionalidade UNA PHP:** Lógica interna para rastrear leitura e fornecer links.
*   **Mapeamento para API \"Deeper\":**
    *   **Rastrear Leitura:**
        *   `POST /api/v1/topics/{topic_id}/read` com corpo `{ \"last_read_post_id\": ... }`.
    *   **Obter Status de Leitura (para indicar \"novo\" na UI):**
        *   Ao listar tópicos (`GET /forums/{forum_id}/topics`), o cliente pode, para cada tópico, verificar se `topic.last_post_id` é maior que o `last_read_post_id` para aquele tópico (obtido via `GET /me/forum-read-statuses?topic_ids=...`).
    *   **\"Ir para Próximo Post Não Lido\":**
        *   O cliente obtém o `last_read_post_id` para o tópico.
        *   Faz `GET /api/v1/topics/{topic_id}/posts?after_post_id={last_read_post_id}&per_page=1&sort_by=created_at_asc`.
        *   Se houver resultado, esse é o primeiro post não lido. O cliente calcula a página correta para exibir este post ou implementa scroll infinito.

## 9. Serviço: \"Ações de Moderação de Tópico/Post\" (Fixar, Trancar, Esconder, Deletar)

*   **Funcionalidade UNA PHP:** Links/botões de moderação na UI.
*   **Mapeamento para API \"Deeper\":**
    *   **Não serviços que retornam UI.** São endpoints de ação.
    *   **Tópicos:**
        *   `PUT /api/v1/topics/{topic_id}` com corpo `{ \"is_sticky\": true/false }` ou `{ \"is_locked\": true/false }` ou `{ \"status\": \"hidden_by_moderator\" }`.
        *   `DELETE /api/v1/topics/{topic_id}`.
    *   **Posts:**
        *   `PUT /api/v1/posts/{post_id}` com corpo `{ \"status\": \"hidden_by_moderator\" }`.
        *   `DELETE /api/v1/posts/{post_id}`.
    *   **Autenticação e Autorização:** Essas ações requerem que o usuário seja moderador do fórum ou admin do site. A lógica de permissão é verificada no backend.

## Considerações:

*   **Performance de Contadores e \"Último Post\":** As tabelas `deeper_forums` e `deeper_forum_topics` têm campos denormalizados (`topics_count`, `posts_count`, `last_post_id`, etc.). Manter esses campos atualizados de forma consistente e performática é crucial e será responsabilidade das funções do `ForumsRepo` que criam/atualizam/deletam tópicos e posts (dentro de transações).
*   **Navegação e Estado do Usuário:** A API fornecerá os dados. O cliente é responsável por manter o estado da navegação do usuário (ex: qual página de um tópico ele está vendo) e por solicitar os dados corretos para paginação ou para \"carregar mais\".
*   **Busca:** Um serviço \"Buscar nos Fóruns\" seria mapeado para um endpoint `GET /api/v1/search/forums?q=termo` ou filtros `q` nos endpoints de listagem de tópicos/posts. Isso exigiria lógica de busca no `ForumsRepo` (usando `LIKE` ou FTS do SQLite).

Este mapeamento foca em fornecer os blocos de construção de dados para que o cliente possa recriar as funcionalidades interativas de um sistema de fóruns.