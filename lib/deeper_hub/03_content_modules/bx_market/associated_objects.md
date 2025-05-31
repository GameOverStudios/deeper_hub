# Documentação Deeper: Objetos Associados e Interações para Marketplace (`bx_market`)

Este documento descreve como os sistemas de interação genéricos do \"Deeper\" (baseados nas funcionalidades do UNA) se associam e interagem com as listagens de produtos/serviços do módulo Marketplace (`bx_market`).

As listagens do marketplace (`bx_market_entries`) são entidades com as quais os usuários podem interagir de diversas formas, como comentar, votar (avaliar), favoritar e denunciar.

## Identificação do Objeto

Para que os sistemas de interação genéricos saibam a qual entidade do marketplace uma interação se refere, usaremos:

*   **`object_type` (ou `module_name`):** Um identificador textual para o tipo de conteúdo. Para o marketplace, este será consistentemente algo como `\"bx_market_entry\"` ou `\"deeper_market_listing\"`.
*   **`object_id`:** O ID da listagem específica em `bx_market_entries.id`.

## 1. Comentários (`04_interaction_systems/sys_comments_system/`)

*   **Funcionalidade:** Usuários podem postar comentários em listagens de produtos.
*   **Tabelas Envolvidas (do sistema de comentários):**
    *   `sys_cmts_objects` (ou similar, para registrar que \"bx_market_entry\" é um objeto comentável).
    *   `sys_cmts_entries` (ou similar, para armazenar os comentários).
    *   `sys_cmts_votes`, `sys_cmts_reactions` (para votos/reações nos próprios comentários).
*   **Integração com `bx_market_entries`:**
    *   A tabela `bx_market_entries` possui uma coluna `allow_comments` (INTEGER, 0 ou 1) para controlar se os comentários são permitidos para uma listagem específica.
    *   A tabela `bx_market_entries` possui uma coluna `comments_count` (INTEGER) para armazenar o número total de comentários ativos para a listagem.
*   **API Endpoints (do sistema de comentários, aplicados ao marketplace):**
    *   `GET /api/v1/market/entries/{entry_id}/comments?page=1&per_page=10&sort_by=added_desc`
        *   Busca comentários para a listagem com `entry_id`.
        *   O backend usará `object_type = \"bx_market_entry\"` e `object_id = {entry_id}` para consultar o `CommentsRepo`.
    *   `POST /api/v1/market/entries/{entry_id}/comments`
        *   Cria um novo comentário para a listagem.
        *   O `CommentsRepo.create_comment/1` também deve:
            1.  Verificar se `bx_market_entries.allow_comments` é `1` para o `entry_id`.
            2.  Incrementar `bx_market_entries.comments_count` para o `entry_id` correspondente (idealmente em uma transação).
*   **Atualização de `comments_count`:**
    *   Quando um comentário é criado: incrementar.
    *   Quando um comentário é deletado (ou seu status muda para oculto): decrementar.
    *   Esta lógica pode residir no `CommentsRepo` ou em um módulo de serviço que coordena a criação/deleção de comentários e a atualização do contador no objeto pai.

## 2. Votos/Avaliações (`04_interaction_systems/sys_voting_system/`)

*   **Funcionalidade:** Usuários podem votar (ex: avaliação de 1 a 5 estrelas) em listagens de produtos.
*   **Tabelas Envolvidas (do sistema de votos):**
    *   `sys_voting_objects` (para registrar \"bx_market_entry\" como votável).
    *   `sys_voting_track` (para armazenar os votos individuais).
    *   `sys_voting_data` (para armazenar a contagem de votos e a soma/média para cada `object_id`).
*   **Integração com `bx_market_entries`:**
    *   A tabela `bx_market_entries` possui `allow_votes` (INTEGER, 0 ou 1).
    *   A tabela `bx_market_entries` possui `votes_count` (INTEGER) e `score` (REAL, para a média da avaliação).
*   **API Endpoints (do sistema de votos):**
    *   `POST /api/v1/market/entries/{entry_id}/votes`
        *   Corpo da requisição: `{\"value\": 5}` (ex: nota de 1 a 5).
        *   O `VotingRepo.cast_vote/1` também deve:
            1.  Verificar `bx_market_entries.allow_votes`.
            2.  Após registrar o voto, recalcular e atualizar `bx_market_entries.votes_count` e `bx_market_entries.score` para o `entry_id`. Isso pode ser feito buscando todos os votos para o item e recalculando, ou atualizando incrementalmente se `sys_voting_data` já mantiver a soma e contagem.
    *   `GET /api/v1/market/entries/{entry_id}/votes/summary`
        *   Retorna a contagem de votos e a pontuação média para a listagem. Pode ler diretamente de `bx_market_entries.votes_count` e `bx_market_entries.score`, ou do `sys_voting_data`.
    *   `GET /api/v1/market/entries/{entry_id}/votes/my_vote`
        *   Retorna o voto do usuário autenticado para esta listagem, se houver.
*   **Atualização de `votes_count` e `score`:**
    *   Idealmente, o `VotingRepo` ou um serviço associado é responsável por manter esses campos na `bx_market_entries` sincronizados após cada voto.

## 3. Favoritos (`04_interaction_systems/sys_favorites_system/`)

*   **Funcionalidade:** Usuários podem marcar listagens como favoritas.
*   **Tabelas Envolvidas (do sistema de favoritos):**
    *   `sys_favorites_objects` (para registrar \"bx_market_entry\" como favoritável).
    *   `sys_favorites_track` (para armazenar quem favoritou qual `object_id`).
*   **Integração com `bx_market_entries`:**
    *   A tabela `bx_market_entries` possui uma coluna `favorites` (INTEGER) para armazenar o número total de vezes que a listagem foi favoritada.
*   **API Endpoints (do sistema de favoritos):**
    *   `POST /api/v1/market/entries/{entry_id}/favorite`
        *   Adiciona a listagem aos favoritos do usuário autenticado.
        *   O `FavoritesRepo.add_favorite/1` também deve incrementar `bx_market_entries.favorites` para o `entry_id`.
    *   `DELETE /api/v1/market/entries/{entry_id}/favorite`
        *   Remove a listagem dos favoritos do usuário.
        *   O `FavoritesRepo.remove_favorite/1` também deve decrementar `bx_market_entries.favorites`.
    *   `GET /api/v1/market/entries/{entry_id}/favorite/status`
        *   Verifica se o usuário autenticado favoritou esta listagem.
*   **Atualização de `favorites` (contador):**
    *   Atualizado pelo `FavoritesRepo` a cada adição/remoção.

## 4. Denúncias (`04_interaction_systems/sys_reporting_system/`)

*   **Funcionalidade:** Usuários podem denunciar listagens por conteúdo inadequado ou outros motivos.
*   **Tabelas Envolvidas (do sistema de denúncias):**
    *   `sys_reporting_objects` (para registrar \"bx_market_entry\" como denunciável).
    *   `sys_reporting_track` (para armazenar as denúncias, com tipo, texto, autor da denúncia, etc.).
*   **Integração com `bx_market_entries`:**
    *   A tabela `bx_market_entries` possui `allow_reports` (INTEGER, 0 ou 1).
    *   A tabela `bx_market_entries` possui `reports_count` (INTEGER) para o número de denúncias ativas/pendentes.
*   **API Endpoints (do sistema de denúncias):**
    *   `POST /api/v1/market/entries/{entry_id}/reports`
        *   Corpo da requisição: `{\"type\": \"spam\", \"text\": \"This is a spam listing.\"}`.
        *   O `ReportingRepo.submit_report/1` também deve:
            1.  Verificar `bx_market_entries.allow_reports`.
            2.  Incrementar `bx_market_entries.reports_count`.
            3.  Possivelmente notificar administradores.
*   **Atualização de `reports_count`:**
    *   Incrementado quando uma nova denúncia é feita.
    *   Decrementado (ou gerenciado por status na tabela de denúncias) quando uma denúncia é resolvida por um administrador.

## 5. Visualizações (`sys_views_track` - pode ser parte do `04_interaction_systems` ou um sistema mais genérico)

*   **Funcionalidade:** Rastrear o número de visualizações de uma listagem.
*   **Tabelas Envolvidas:**
    *   `sys_views_track` (ou similar): armazena `object_id`, `object_type`, `viewer_id` (se logado), `viewer_nip` (IP), `date`.
*   **Integração com `bx_market_entries`:**
    *   A tabela `bx_market_entries` possui uma coluna `views` (INTEGER).
*   **API Endpoint (exemplo, pode ser implícito na visualização):**
    *   `POST /api/v1/market/entries/{entry_id}/view` (como definido em `api_endpoints.md` do `bx_market`).
*   **Lógica de Atualização de `views`:**
    *   Quando o endpoint de visualização da listagem (`GET /api/v1/market/entries/{id_or_name}`) é acessado, ou quando o endpoint `/view` é chamado:
        1.  Registrar a visualização em `sys_views_track` (evitando duplicatas do mesmo usuário/IP em um curto período).
        2.  Chamar `Deeper.Content.MarketRepo.increment_view_count(entry_id)`.

## Considerações Gerais de Implementação:

*   **Consistência dos Contadores:** Manter os contadores na tabela `bx_market_entries` sincronizados com os dados nas tabelas de interação (`sys_cmts_entries`, `sys_voting_track`, etc.) é crucial. Isso pode ser feito:
    *   Na lógica dos Repositórios de interação (ex: `CommentsRepo` atualiza `bx_market_entries.comments_count`).
    *   Através de módulos de \"Serviço\" Elixir que orquestram a interação e a atualização do contador em uma transação.
    *   (Menos ideal para SQLite sem triggers complexos) Triggers de banco de dados, se o sistema de BD suportasse de forma robusta e se fosse a preferência.
*   **Performance:** Para listagens com muitas interações, recalcular contadores a partir das tabelas de rastreamento a cada vez pode ser lento. Manter contadores denormalizados na tabela principal (`bx_market_entries`) é geralmente uma boa otimização de leitura, com o custo de garantir a consistência na escrita.
*   **ACL para Interações:** A permissão para comentar, votar, etc., também será verificada usando o sistema ACL (`01_system_core/sys_acl/`). Por exemplo, um usuário pode precisar de um certo nível de membresia para poder votar.

Este documento fornece o framework para integrar as listagens do marketplace com os sistemas de interação da plataforma \"Deeper\", garantindo uma experiência de usuário rica e engajadora.