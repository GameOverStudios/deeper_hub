# Documentação Deeper: Sistemas de Interação da API

Este diretório detalha a implementação da API \"Deeper\" para os sistemas de interação genéricos do UNA. Estas são funcionalidades comuns como comentários, votos, favoritos, denúncias, pontuações, etc., que podem ser aplicadas a diferentes tipos de conteúdo na plataforma (ex: perfis de pessoas, posts, fotos, eventos).

**Objetivo Principal:** Fornecer endpoints RESTful genéricos e reutilizáveis para essas interações. Esses endpoints serão normalmente contextualizados por um `object_identifier` (que pode ser o nome do objeto do UNA, como \"bx_persons\") e um `content_id` (o ID específico do item sendo comentado, votado, etc.).

## Abordagem Geral para Sistemas de Interação:

Para cada sistema de interação:

1.  [**Visão Geral do Sistema (`system_name/README.md`)**](./system_name/README.md):
    *   Descreve o propósito do sistema de interação no UNA.
    *   Lista as tabelas UNA primárias envolvidas (ex: `sys_cmts_ids`, `sys_module_target_cmts` ou tabelas específicas de módulo como `bx_persons_cmts`).
    *   Explica como o sistema é configurado no UNA (ex: através de `sys_objects_cmts`, `sys_objects_vote`).

2.  [**Esquema do Banco de Dados (`system_name/database_schema.md`)**](./system_name/database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas genéricas do sistema de interação, se houver (ex: `sys_cmts_ids`), ou reitera as tabelas específicas do módulo se a abordagem for descentralizada.

3.  [**Migrações Elixir (`system_name/migrations/`)**](./system_name/migrations/README.md):
    *   Documentação e código para as migrações das tabelas do sistema.

4.  [**Módulo de Acesso a Dados (Repositório Genérico) (`system_name/data_access_module.md`)**](./system_name/data_access_module.md):
    *   Descreve o módulo Elixir genérico (ex: `Deeper.Interactions.CommentsRepo`) que encapsula as queries SQL. Este repositório precisará ser parametrizável para funcionar com diferentes tabelas de comentários ou objetos do UNA.

5.  [**Endpoints da API Genéricos (`system_name/api_endpoints.md`)**](./system_name/api_endpoints/README.md):
    *   Especifica os endpoints RESTful genéricos. A rota geralmente incluirá um parâmetro para o \"sistema de objeto UNA\" (ex: `bx_persons_profile_comments`) ou para o \"módulo alvo\" e o `content_id`.

## Lista de Sistemas de Interação a Serem Documentados:

1.  [**Sistema de Comentários (`sys_comments_system/`)**](./sys_comments_system/README.md): Para adicionar e visualizar comentários em vários tipos de conteúdo.
2.  [**Sistema de Votos/Avaliações (`sys_voting_system/`)**](./sys_voting_system/README.md): Para permitir que usuários votem (ex: 1-5 estrelas) em conteúdo.
3.  [**Sistema de Favoritos (`sys_favorites_system/`)**](./sys_favorites_system/README.md): Para permitir que usuários marquem conteúdo como favorito.
4.  [**Sistema de Denúncias (`sys_reporting_system/`)**](./sys_reporting_system/README.md): Para usuários denunciarem conteúdo inapropriado.
5.  [**Sistema de Pontuações (Scores) (`sys_scoring_system/`)**](./sys_scoring_system/README.md): Para sistemas de votação tipo up/down que resultam em uma pontuação.
6.  [**Sistema de Reações** (`sys_reactions_system/`)](./sys_reactions_system/README.md): Para permitir reações diversas (like, love, haha, etc.) em conteúdo (se o UNA suportar isso de forma genérica ou se for uma adição \"Deeper\").

A implementação de cada sistema de interação focará na reutilização de código através de repositórios e controllers parametrizáveis, garantindo que a lógica de ACL e as permissões específicas do contexto sejam aplicadas.