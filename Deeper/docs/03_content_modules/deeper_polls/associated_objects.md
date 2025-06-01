# Documentação Deeper: Objetos Associados ao Módulo de Enquetes

Este documento descreve como o módulo de Enquetes (`deeper_polls`) se integra com outros sistemas e objetos genéricos do \"Deeper\", principalmente perfis de usuário e o sistema de comentários.

O módulo `deeper_polls` gerencia a enquete, suas opções e os votos. As interações adicionais, como discussões sobre a enquete, são tratadas por sistemas genéricos.

## 1. Perfis de Usuário (Criador e Votantes)

*   **Sistema de Referência:** `📂 01_system_core/sys_accounts_and_profiles/`
*   **Tabelas Envolvidas:**
    *   `deeper_polls`: Contém `profile_id` (criador da enquete).
    *   `deeper_poll_votes`: Contém `profile_id` (quem votou em uma opção).
*   **Integração:**
    *   Ao criar uma enquete, o `profile_id` do usuário autenticado (via JWT) é associado como criador.
    *   Ao registrar um voto, o `profile_id` do usuário autenticado é associado ao voto.
    *   Ao listar ou visualizar enquetes, a API frequentemente fará `JOIN` com `sys_profiles` (e `sys_accounts`) para incluir detalhes do criador se solicitado pelo parâmetro `include`.
    *   A API pode precisar verificar se um usuário já votou em uma enquete (usando `deeper_poll_votes.profile_id`) para controlar a lógica de `results_visibility` ou para impedir votos duplicados em enquetes de voto único.

## 2. Comentários (sobre a Enquete)

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_comments_system/`
*   **Uso:** Usuários podem comentar sobre a enquete em si (para discutir a pergunta, as opções, ou os resultados).
*   **Tabelas Envolvidas (do sistema de comentários):**
    *   `sys_objects_cmts`: Deverá ter uma entrada para o objeto \"deeper_polls_comments\".
        *   `Name`: \"deeper_polls\" (ou \"deeper_polls_comments\")
        *   `Module`: \"deeper_polls\"
        *   `TriggerTable`: \"deeper_polls\"
        *   `TriggerFieldId`: \"id\"
        *   `TriggerFieldComments`: (Coluna opcional em `deeper_polls` para contagem de comentários, ou contagem dinâmica).
    *   Tabela de conteúdo de comentários: Armazena os comentários com `cmt_object_id` = `poll_id`.
    *   `sys_cmts_ids`: Metadados/sumário para comentários.

*   **Endpoints da API (Gerenciados pelo módulo de comentários):**
    *   `GET /api/v1/comments?system_object=deeper_polls&object_id={poll_id}`: Listar comentários para uma enquete.
    *   `POST /api/v1/comments`: Postar um novo comentário para uma enquete.

```json
        {
          \"system_object\": \"deeper_polls\",
          \"object_id\": 789, // poll_id
          \"text\": \"Interessante esta enquete! Minha opinião é...\"
        }
```

*   **Integração na API de Enquetes:**
    *   `GET /polls/{id_or_slug}?include=comments_summary` poderia adicionar `{\"comments_count\": 12}` ao objeto da enquete.

## 3. Votos (o sistema de votos da enquete é intrínseco ao módulo)

*   O sistema de votação (`deeper_poll_votes` e a lógica em `PollsRepo.cast_vote/3`) é uma parte central do módulo `deeper_polls` e não depende de um sistema de \"votos genérico\" externo para sua funcionalidade principal de registrar escolhas de opções.
*   No entanto, se houvesse um desejo de \"avaliar a enquete em si\" (ex: dar estrelas para a qualidade da pergunta da enquete, diferente de votar nas opções), aí sim o `sys_voting_system` genérico poderia ser usado, configurando um `object_name` como \"deeper_polls_ratings\". Isso geralmente não é uma funcionalidade padrão para enquetes.

## 4. Favoritos (Marcar uma Enquete como Favorita)

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_favorites_system/`
*   **Uso:** Usuários podem querer \"salvar\" ou \"favoritar\" enquetes para fácil acesso posterior.
*   **Configuração:** `sys_objects_favorite` teria uma entrada para \"deeper_polls_favorites\".
*   **Endpoints da API:**
    *   `GET /api/v1/favorites/status?object_name=deeper_polls_favorites&object_id={poll_id}`
    *   `POST /api/v1/favorites` (com `object_name=\"deeper_polls_favorites\"`, `object_id={poll_id}`)
*   **Integração:** `GET /polls/{id_or_slug}?include=favorites_summary` poderia adicionar contagem e status de favorito do usuário atual.

## 5. Visualizações (Views - para a Enquete)

*   **Sistema de Referência:** Pode ser um sistema de visualizações genérico (`sys_objects_view` do UNA) ou um contador simples na tabela `deeper_polls`.
*   **Tabelas Envolvidas (se contador simples):**
    *   `deeper_polls`: Contém `views_count`.
*   **Registro de Visualização:**
    *   `POST /api/v1/polls/{id_or_slug}/view`: Incrementaria `deeper_polls.views_count` através de uma função no `PollsRepo`.
*   **Recuperação:**
    *   O contador `views_count` da tabela `deeper_polls` pode ser retornado pela API.

## 6. Denúncias (Reporting - para a Enquete)

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_reporting_system/`
*   **Uso:** Usuários podem denunciar enquetes por conteúdo inadequado, etc.
*   **Configuração:** `sys_objects_report` teria uma entrada para \"deeper_polls_reports\".
*   **Endpoints da API:** `POST /api/v1/reports` com `object_name=\"deeper_polls_reports\"` e `object_id={poll_id}`.

## 7. Notificações

*   **Sistema de Referência:** Um sistema de notificações genérico (`deeper_notifications` ou integração com `sys_alerts`).
*   **Eventos que Geram Notificações (Exemplos):**
    *   Enquete criada por um perfil que o usuário segue.
    *   Enquete que o usuário votou foi fechada (e os resultados agora estão visíveis, se aplicável).
    *   Comentário em uma enquete que o usuário criou ou está participando da discussão.
*   **Lógica:** A Camada de Contexto/Serviço do `Deeper.Content.Polls` dispararia eventos/alertas.

A integração principal do módulo de enquetes é com os perfis de usuário (para autoria e votação) e com o sistema de comentários para discussões sobre a enquete. As outras interações (favoritos, denúncias) seguem o padrão dos sistemas genéricos.