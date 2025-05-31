# Documentação Deeper: Sistemas de Interação

Este diretório detalha as APIs para os sistemas genéricos de interação do UNA, que podem ser aplicados a diversos tipos de conteúdo (artigos, perfis, fotos, etc.). O objetivo é fornecer uma maneira padronizada para os usuários comentarem, votarem, favoritarem, denunciarem e reagirem a diferentes entidades no sistema \"Deeper\".

Cada sistema de interação terá seu próprio conjunto de tabelas (geralmente uma tabela principal para o objeto e uma tabela de \"track\" para registrar a ação do usuário) e um Repositório Elixir dedicado.

## Abordagem Geral para Sistemas de Interação:

1.  **Objetos de Interação no UNA:** O UNA define \"objetos\" para cada tipo de interação (ex: `sys_objects_cmts`, `sys_objects_vote`, `sys_objects_favorite`). Esses objetos no banco de dados UNA especificam qual tabela de \"track\" usar, tabelas de gatilho para atualizar contagens, etc.
2.  **API \"Deeper\":**
    *   A API \"Deeper\" fornecerá endpoints que geralmente são aninhados sob o recurso principal ao qual a interação se aplica (ex: `GET /articles/{article_id}/comments`).
    *   O backend precisará identificar qual \"objeto de interação UNA\" corresponde ao tipo de conteúdo e à ação (ex: comentários para \"artigos\"). Isso pode ser feito por convenção (ex: `comentarios_deeper_articles`) ou consultando as tabelas `sys_objects_*` do UNA.
    *   As permissões ACL serão aplicadas (ex: quem pode postar um comentário, quem pode votar).

## Estrutura dos Submódulos de Interação:

Cada sistema de interação terá seu próprio subdiretório, contendo:
*   `README.md`: Visão geral do sistema de interação e sua API.
*   `database_schema.md`: Definições `CREATE TABLE` para SQLite (para as tabelas de track e, se houver, tabelas agregadas de contagem).
*   `migrations/README.md` e `migrations/*.elixir.md`: Documentação e código das migrações.
*   `data_access_module.md`: Definição do Repositório Elixir e suas funções SQL.
*   `api_endpoints.md`: Especificação dos endpoints da API RESTful.

## Sistemas de Interação Planejados:

*   [**Sistema de Comentários (`sys_comments_system/`)**](./sys_comments_system/README.md) - (A ser detalhado a seguir)
*   [**Sistema de Votos (`sys_voting_system/`)**](./sys_voting_system/README.md) (ex: votos de 1-5 estrelas)
*   [**Sistema de Favoritos (`sys_favorites_system/`)**](./sys_favorites_system/README.md)
*   [**Sistema de Denúncias (`sys_reporting_system/`)**](./sys_reporting_system/README.md)
*   [**Sistema de Pontuações (`sys_scoring_system/`)**](./sys_scoring_system/README.md) (ex: upvotes/downvotes que resultam em um score)
*   [**Sistema de Reações (`sys_reactions_system/`)**](./sys_reactions_system/README.md) (ex: Like, Love, Haha)

## Integração com Módulos de Conteúdo:

Quando um módulo de conteúdo (como `deeper_articles`) precisa de comentários, ele não implementará sua própria lógica de comentários. Em vez disso, os endpoints da API de artigos para comentários (`/articles/{id}/comments`) serão roteados para os controllers do sistema genérico de comentários, passando o `article_id` como o `object_id` e um identificador do \"sistema de comentários\" a ser usado (ex: \"deeper_articles_comments\").

O `object_id` nas tabelas de track (`sys_cmts_track`, `sys_votes_track`, etc.) será o ID da entidade principal (ex: `deeper_articles_entries.id`).