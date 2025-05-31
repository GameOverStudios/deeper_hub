# Documentação Deeper: APIs para Sistemas de Interação Genéricos

Esta seção da documentação \"Deeper\" detalha as APIs RESTful para os sistemas de interação genéricos do UNA. Estes sistemas são projetados para serem aplicados a diferentes tipos de conteúdo (ex: perfis, posts, fotos, eventos) de forma consistente.

Os principais sistemas de interação incluem:

*   **Comentários:** Permitir que usuários comentem em itens de conteúdo.
*   **Votos/Avaliações:** Permitir que usuários avaliem itens (ex: estrelas, valor numérico).
*   **Favoritos:** Permitir que usuários marquem itens como favoritos.
*   **Denúncias:** Permitir que usuários denunciem itens por conteúdo impróprio.
*   **Pontuações (Scores):** Permitir votos do tipo \"up/down\" ou \"like/dislike\".
*   **Reações:** Permitir que usuários reajam a itens com emojis ou reações predefinidas (ex: \"Gostei\", \"Amei\", \"Haha\").

## Abordagem Geral:

Para cada sistema de interação:

1.  **Tabelas de Configuração do UNA:** O UNA usa tabelas como `sys_objects_cmts`, `sys_objects_vote`, `sys_objects_favorite`, etc., para definir \"objetos de interação\". Cada objeto especifica o módulo ao qual se aplica, as tabelas de dados e de rastreamento usadas, e campos de trigger na tabela de conteúdo principal para atualizar contadores.
2.  **Tabelas de Dados/Rastreamento Genéricas:**
    *   Comentários: `sys_cmts_ids` (metadados do comentário) e uma tabela de conteúdo de comentários específica do objeto (ex: `bx_persons_cmts` se não for totalmente genérico, ou uma tabela central de comentários ligada a `sys_cmts_ids`). O UNA mais recente tende a usar uma tabela de comentários por objeto de comentário configurado em `sys_objects_cmts.Table`.
    *   Outras interações (Votos, Favoritos, etc.): Geralmente usam duas tabelas por objeto: uma de \"sumário\" (ex: `bx_persons_votes` contendo `count` e `sum`) e uma de \"track\" (ex: `bx_persons_votes_track` registrando cada voto individual). A API \"Deeper\" pode optar por simplificar isso, focando nas tabelas de track e calculando sumários dinamicamente ou usando as tabelas de sumário existentes.
3.  **API \"Deeper\":**
    *   Fornecerá endpoints genéricos que aceitam um `object_interaction_name` (o nome do objeto de `sys_objects_cmts.Name`, `sys_objects_vote.Name`, etc.) e um `item_id` (o ID do conteúdo específico sendo interagido).
    *   Os Repos correspondentes (ex: `CommentsRepo`, `VotingRepo`) usarão o `object_interaction_name` para buscar a configuração do objeto de interação e determinar quais tabelas de dados/track consultar.
    *   Os Repos também serão responsáveis por atualizar os contadores na tabela de conteúdo principal (ex: `bx_persons_data.comments`, `bx_persons_data.votes`) conforme definido nos campos `TriggerField*` do objeto de interação.

## Estrutura dos Submódulos:

*   [**Sistema de Comentários (`sys_comments_system/`)**](./sys_comments_system/README.md)
*   [**Sistema de Votos/Avaliações (`sys_voting_system/`)**](./sys_voting_system/README.md)
*   [**Sistema de Favoritos (`sys_favorites_system/`)**](./sys_favorites_system/README.md)
*   [**Sistema de Denúncias (`sys_reporting_system/`)**](./sys_reporting_system/README.md)
*   [**Sistema de Pontuações (Scores) (`sys_scoring_system/`)**](./sys_scoring_system/README.md)
*   [**Sistema de Reações (`sys_reactions_system/`)**](./sys_reactions_system/README.md)

Esta abordagem modular permite que as mesmas APIs de interação sejam usadas para diferentes tipos de conteúdo em toda a aplicação \"Deeper\".