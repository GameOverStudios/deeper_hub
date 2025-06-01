# Documentação Deeper: Objetos Associados ao Módulo de Artigos/Posts

Este documento descreve como o módulo de Artigos/Posts (`deeper_articles`) se integra com outros sistemas e objetos genéricos do \"Deeper\" (e, por extensão, do UNA), como comentários, votos, favoritos, gerenciamento de arquivos, etc.

A filosofia é que o módulo `deeper_articles` foca no conteúdo principal do artigo, enquanto as interações e mídias associadas são gerenciadas por sistemas mais genéricos, referenciando o artigo através de um `object_name` (ex: \"deeper_articles\") e um `object_id` (o `id` do artigo).

## 1. Comentários

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_comments_system/`
*   **Tabelas Envolvidas (do sistema de comentários):**
    *   `sys_objects_cmts`: Deverá ter uma entrada para o objeto \"deeper_articles\".
        *   `Name`: \"deeper_articles\"
        *   `Module`: \"deeper_articles\" (ou um módulo \"core\" se for genérico)
        *   `Table`: (Nome da tabela onde os comentários específicos para artigos seriam armazenados, ex: `deeper_article_comments`)
        *   `TriggerTable`: \"deeper_articles\"
        *   `TriggerFieldId`: \"id\"
        *   `TriggerFieldComments`: (Nome de uma coluna em `deeper_articles` para armazenar a contagem de comentários, se essa abordagem for usada. Alternativamente, a contagem é dinâmica.)
    *   `deeper_article_comments` (ou uma tabela genérica de comentários como `sys_cmts_content`): Armazena os comentários.
        *   `cmt_object_id`: Conterá o `id` do artigo da tabela `deeper_articles`.
        *   `cmt_system_id`: Conterá o `ID` da entrada \"deeper_articles\" em `sys_objects_cmts`.
    *   `sys_cmts_ids`: Tabela de metadados/sumário para comentários, referenciando `cmt_system_id` e `cmt_id`.

*   **Endpoints da API (Exemplos, gerenciados pelo módulo de comentários):**
    *   `GET /api/v1/comments?system_object=deeper_articles&object_id={article_id}`: Listar comentários para um artigo.
    *   `POST /api/v1/comments`: Postar um novo comentário.

```json
        {
          \"system_object\": \"deeper_articles\",
          \"object_id\": 123, // article_id
          \"parent_id\": 0, // ou ID do comentário pai para respostas
          \"text\": \"Ótimo artigo!\"
          // profile_id do autor do comentário viria do JWT
        }
```

```json
        {
          \"object_name\": \"deeper_articles_votes\",
          \"object_id\": 123, // article_id
          \"value\": 5 // ex: de 1 a 5 estrelas
        }
```

```json
        {
          \"object_name\": \"deeper_articles_favorites\",
          \"object_id\": 123 // article_id
          // A ação (favoritar/desfavoritar) pode ser implícita ou um parâmetro
        }
```

```json
        // Parte da resposta do artigo
        \"featured_image_details\": {
          \"id\": 789,
          \"file_name\": \"imagem_destaque.jpg\",
          \"mime_type\": \"image/jpeg\",
          \"access_url\": \"/api/v1/files/view/deeper_local_files/path/imagem_destaque.jpg\"
          // Outros metadados relevantes do arquivo
        }
```

*   **Integração no `ArticlesRepo` / Respostas da API de Artigos:**
    *   Ao buscar um artigo (`GET /articles/{id_or_slug}`), a API pode opcionalmente incluir um resumo dos comentários ou uma contagem.
        *   Ex: `?include=comments_summary` poderia adicionar `{\"comments_count\": 15}` ao objeto do artigo.
        *   Isto exigiria que `ArticlesRepo.get_article` fizesse uma subquery ou JOIN para obter essa contagem da tabela de comentários ou `sys_cmts_ids`.

## 2. Votos / Avaliações

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_voting_system/`
*   **Tabelas Envolvidas (do sistema de votos):**
    *   `sys_objects_vote`: Deverá ter uma entrada para \"deeper_articles\".
        *   `Name`: \"deeper_articles_votes\"
        *   `Module`: \"deeper_articles\"
        *   `TableMain`: (Tabela de sumário, ex: `deeper_article_votes_summary`)
        *   `TableTrack`: (Tabela de rastreamento de votos individuais, ex: `deeper_article_votes_track`)
        *   `TriggerTable`: \"deeper_articles\"
        *   `TriggerFieldId`: \"id\"
        *   `TriggerFieldRate`, `TriggerFieldRateCount`: (Colunas em `deeper_articles` para armazenar a média e contagem, se usadas.)
    *   `deeper_article_votes_summary` (ou genérica): Armazena `object_id` (article_id), `count`, `sum`.
    *   `deeper_article_votes_track` (ou genérica): Armazena `object_id`, `author_id`, `value`, `date`.

*   **Endpoints da API (Exemplos, gerenciados pelo módulo de votos):**
    *   `GET /api/v1/votes/summary?object_name=deeper_articles_votes&object_id={article_id}`: Obter o sumário de votos para um artigo.
    *   `POST /api/v1/votes`: Registrar um voto.

*   **Integração no `ArticlesRepo` / Respostas da API de Artigos:**
    *   `GET /articles/{id_or_slug}?include=votes_summary` poderia adicionar `{\"votes_average\": 4.5, \"votes_count\": 100}`.

## 3. Favoritos

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_favorites_system/`
*   **Tabelas Envolvidas (do sistema de favoritos):**
    *   `sys_objects_favorite`: Entrada para \"deeper_articles_favorites\".
    *   `deeper_article_favorites_track` (ou genérica): `object_id` (article_id), `author_id`, `date`.
*   **Endpoints da API (Exemplos, gerenciados pelo módulo de favoritos):**
    *   `GET /api/v1/favorites/status?object_name=deeper_articles_favorites&object_id={article_id}`: Verificar se o usuário logado favoritou o artigo.
    *   `POST /api/v1/favorites`: Favoritar/Desfavoritar um artigo.

*   **Integração no `ArticlesRepo` / Respostas da API de Artigos:**
    *   `GET /articles/{id_or_slug}?include=favorites_summary` poderia adicionar `{\"favorites_count\": 50, \"is_favorited_by_current_user\": true}`.

## 4. Imagem de Destaque (Featured Image)

*   **Sistema de Referência:** `📂 06_file_management/`
*   **Tabelas Envolvidas:**
    *   `deeper_articles`: Contém a coluna `featured_image_file_id INTEGER`, que é uma chave estrangeira para `deeper_files.id`.
    *   `deeper_files`: Armazena os metadados da imagem.
*   **Upload/Associação:**
    1.  O cliente primeiro faz upload da imagem usando o endpoint `POST /api/v1/files/upload`.
    2.  A API de arquivos retorna o `id` do arquivo recém-criado (da tabela `deeper_files`).
    3.  Ao criar (`POST /articles`) ou atualizar (`PUT/PATCH /articles/{id}`) um artigo, o cliente envia este `featured_image_file_id` no corpo da requisição.
*   **Recuperação:**
    *   Ao obter um artigo (`GET /articles/{id_or_slug}`), se `include=featured_image` for solicitado, o `ArticlesRepo.get_article` fará um `JOIN` com a tabela `deeper_files` para incluir os detalhes da imagem de destaque na resposta.

## 5. Categorias

*   **Sistema de Referência:** Tabelas `deeper_article_categories` e `deeper_articles_to_categories` definidas dentro deste módulo.
*   **Associação:**
    *   Ao criar/atualizar um artigo, uma lista de `category_ids` pode ser fornecida.
    *   O `ArticlesRepo.associate_categories_to_article/2` lida com a atualização da tabela de junção `deeper_articles_to_categories`.
*   **Recuperação:**
    *   Ao obter um artigo, se `include=categories` for solicitado, o `ArticlesRepo.fetch_article_categories/1` é chamado para buscar e incluir a lista de categorias associadas.
    *   A listagem de artigos (`GET /articles`) pode ser filtrada por `category_id` ou `category_slug`.

## 6. Visualizações (Views)

*   **Sistema de Referência:** Pode ser um sistema de visualizações genérico (como `sys_objects_view` do UNA) ou uma lógica simples no `ArticlesRepo`.
*   **Tabelas Envolvidas (se sistema genérico):**
    *   `sys_objects_view`: Entrada para \"deeper_articles_views\".
    *   `deeper_article_views_track` (ou genérica): `object_id` (article_id), `viewer_id` (opcional), `viewer_nip` (IP), `date`.
*   **Registro de Visualização:**
    *   Conforme discutido em `service_logic_mapping.md`, um endpoint `POST /api/v1/articles/{id_or_slug}/view` pode ser usado.
    *   Este endpoint chamaria uma função no `ArticlesRepo` (ou um `ViewsRepo` genérico) para:
        1.  Incrementar um contador `views` na tabela `deeper_articles` (abordagem simples).
        2.  OU, registrar a visualização na tabela de rastreamento de visualizações (abordagem mais detalhada, permite análises como \"visualizações únicas\").
*   **Recuperação:**
    *   O contador `views` da tabela `deeper_articles` é retornado por padrão.
    *   Estatísticas mais detalhadas viriam de queries na tabela de rastreamento.

## Considerações:

*   **Nomes de Objetos para Sistemas de Interação:** É importante padronizar os nomes dos objetos (ex: \"deeper_articles_comments\", \"deeper_articles_votes\") que serão usados para configurar `sys_objects_cmts`, `sys_objects_vote`, etc., e que a API usará para identificar o \"sistema\" ao qual uma interação pertence.
*   **Parâmetro `include`:** O uso extensivo do parâmetro `include` na API de artigos permitirá que os clientes solicitem dados relacionados de forma eficiente, evitando múltiplas chamadas de API. Isso requer que os métodos do `ArticlesRepo` construam `JOIN`s ou façam queries adicionais otimizadas.
*   **Desnormalização vs. Normalização:** Para contadores (views, comments, votes), há um trade-off.
    *   **Armazenar na tabela principal (`deeper_articles`):** Rápido para leitura, mas requer atualização (e potencial contenção de escrita) sempre que uma interação ocorre.
    *   **Calcular dinamicamente (ou de uma tabela de sumário):** Mais complexo para leitura, mas as tabelas de interação são atualizadas de forma mais isolada.
    A abordagem do UNA muitas vezes envolve ter colunas de contagem na tabela de conteúdo principal, atualizadas por triggers ou pela aplicação. Para \"Deeper\", podemos começar calculando dinamicamente para `GET`s de item único com `include`, e para listagens, as contagens podem ser mais desafiadoras de obter performaticamente sem colunas de sumário.

Este documento fornece um framework para como o módulo `deeper_articles` interage com outros sistemas. A implementação exata dependerá do design detalhado desses sistemas de interação genéricos.