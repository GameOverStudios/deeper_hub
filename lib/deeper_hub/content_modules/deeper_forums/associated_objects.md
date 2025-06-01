# Documentação Deeper: Objetos Associados ao Módulo de Fóruns

Este documento descreve como o módulo de Fóruns (`deeper_forums`) se integra com outros sistemas e objetos genéricos do \"Deeper\", como perfis de usuário, gerenciamento de arquivos (para anexos, se implementado), e os sistemas de interação (votos, favoritos, denúncias).

O módulo `deeper_forums` gerencia a estrutura hierárquica de fóruns, tópicos e posts. As interações com esses elementos são frequentemente tratadas por sistemas mais genéricos.

## 1. Perfis de Usuário (Autores e Interações)

*   **Sistema de Referência:** `📂 01_system_core/sys_accounts_and_profiles/`
*   **Tabelas Envolvidas:**
    *   `deeper_forums`: Contém `last_post_profile_id`.
    *   `deeper_forum_topics`: Contém `profile_id` (autor do tópico), `last_post_profile_id`.
    *   `deeper_forum_posts`: Contém `profile_id` (autor do post), `edited_by_profile_id`.
    *   `deeper_forum_read_topics`: Contém `profile_id`.
    *   `deeper_forum_subscriptions`: Contém `profile_id`.
*   **Integração:**
    *   Ao criar tópicos ou posts, o `profile_id` do usuário autenticado (via JWT) é associado como autor.
    *   Ao listar tópicos ou posts, a API frequentemente fará `JOIN` com `sys_profiles` (e `sys_accounts`) para incluir detalhes do autor (nome, avatar, etc.) se solicitado pelo parâmetro `include`.
    *   As tabelas de `read_topics` e `subscriptions` são específicas do usuário.

## 2. Comentários (se os posts do fórum tiverem seu próprio sistema de comentários aninhados, além das respostas diretas)

*   **Cenário:** Geralmente, em um fórum, as \"respostas\" a um tópico são os próprios posts. No entanto, se cada post individual pudesse ter *seus próprios comentários* (como em um blog), então o sistema de comentários genérico seria usado.
*   **Sistema de Referência (se aplicável):** `📂 04_interaction_systems/sys_comments_system/`
*   **Configuração (se aplicável):** `sys_objects_cmts` teria uma entrada para \"deeper_forum_posts_comments\".
    *   `Name`: \"deeper_forum_posts\"
    *   `TriggerTable`: \"deeper_forum_posts\"
    *   `TriggerFieldId`: \"id\"
*   **Endpoints da API (se aplicável):**
    *   `GET /api/v1/comments?system_object=deeper_forum_posts&object_id={forum_post_id}`
    *   `POST /api/v1/comments` (com `system_object=\"deeper_forum_posts\"`, `object_id={forum_post_id}`)
*   **Nota:** Para a maioria dos fóruns, a estrutura Tópico -> Post (resposta) já serve como o sistema de \"comentários\". Esta seção é mais para casos de uso onde posts individuais são mais ricos e podem ter suas próprias threads de discussão.

## 3. Votos / Reações (para Tópicos e/ou Posts)

*   **Sistema de Referência:**
    *   `📂 04_interaction_systems/sys_voting_system/` (para votos simples cima/baixo ou estrelas)
    *   `📂 04_interaction_systems/sys_reactions_system/` (para reações tipo \"like\", \"amei\", etc.)
*   **Configuração:**
    *   **Para Tópicos:** `sys_objects_vote` (ou `_reaction`) teria uma entrada para \"deeper_forum_topics_votes\".
    *   **Para Posts:** `sys_objects_vote` (ou `_reaction`) teria uma entrada para \"deeper_forum_posts_votes\".
*   **Endpoints da API (Exemplos para Posts):**
    *   `GET /api/v1/votes/summary?object_name=deeper_forum_posts_votes&object_id={forum_post_id}`
    *   `POST /api/v1/votes` (com `object_name=\"deeper_forum_posts_votes\"`, `object_id={forum_post_id}`)
*   **Integração:**
    *   Ao listar tópicos ou posts, a API pode incluir contagens de votos/reações se solicitado via `include`.
    *   A UI do cliente mostraria os controles de voto/reação e chamaria os endpoints apropriados.

## 4. Favoritos / Seguir (para Tópicos ou Fóruns)

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_favorites_system/`
*   **Tabela `deeper_forum_subscriptions` já lida com o conceito de \"seguir\" tópicos/fóruns para notificações.**
*   Se uma funcionalidade separada de \"favoritar tópico\" (distinta de seguir para notificações) for desejada:
    *   **Configuração:** `sys_objects_favorite` teria uma entrada para \"deeper_forum_topics_favorites\".
    *   **Endpoints da API:**
        *   `GET /api/v1/favorites/status?object_name=deeper_forum_topics_favorites&object_id={topic_id}`
        *   `POST /api/v1/favorites` (com `object_name=\"deeper_forum_topics_favorites\"`, `object_id={topic_id}`)

## 5. Anexos de Arquivos em Posts

*   **Sistema de Referência:** `📂 06_file_management/`
*   **Implementação:**
    1.  **Tabela de Junção:** Seria necessária uma nova tabela de junção, por exemplo, `deeper_forum_post_attachments`.

```json
        {
          \"object_name\": \"deeper_forum_posts_reports\", // ou _topics_
          \"object_id\": 12345, // ID do post ou tópico
          \"report_type\": \"spam\", // Tipo de denúncia
          \"message\": \"Este post é um anúncio inadequado.\" // Opcional
        }
```

```sql
        CREATE TABLE IF NOT EXISTS deeper_forum_post_attachments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          post_id INTEGER NOT NULL,
          file_id INTEGER NOT NULL,
          added_at INTEGER NOT NULL,
          FOREIGN KEY (post_id) REFERENCES deeper_forum_posts(id) ON DELETE CASCADE,
          FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE,
          UNIQUE (post_id, file_id)
        );
```

        (Uma migração correspondente seria criada.)
    2.  **Upload/Associação:**
        *   Cliente faz upload de arquivos via `POST /api/v1/files/upload`, obtendo os `file_id`s.
        *   Ao criar/editar um post (`POST /topics/{topic_id}/posts` ou `PUT /posts/{post_id}`), o cliente envia uma lista de `attachment_file_ids` no corpo da requisição.
        *   O `ForumsRepo` (ou um Contexto/Serviço) lidaria com a inserção/atualização das associações na tabela `deeper_forum_post_attachments`.
    3.  **Recuperação:**
        *   Ao obter um post (`GET /posts/{post_id}` ou ao listar posts com `include=attachments`), o `ForumsRepo` faria `JOIN` com `deeper_forum_post_attachments` e `deeper_files` para incluir os detalhes dos anexos.

## 6. Denúncias (Reporting - para Tópicos ou Posts)

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_reporting_system/`
*   **Configuração:**
    *   **Para Tópicos:** `sys_objects_report` teria uma entrada para \"deeper_forum_topics_reports\".
    *   **Para Posts:** `sys_objects_report` teria uma entrada para \"deeper_forum_posts_reports\".
*   **Endpoints da API (Gerenciados pelo módulo de denúncias):**
    *   `POST /api/v1/reports`

*   **Integração:** A UI do cliente forneceria uma opção \"Denunciar\" para tópicos/posts, que chamaria este endpoint.

## 7. Notificações (para novas respostas, tópicos seguidos, etc.)

*   **Sistema de Referência:** Um sistema de notificações genérico a ser definido (ex: `deeper_notifications` ou integração com `sys_alerts`).
*   **Eventos que Geram Notificações:**
    *   Nova resposta em um tópico seguido pelo usuário.
    *   Novo tópico em um fórum seguido pelo usuário.
    *   Menção do usuário em um post (`@username`).
    *   Post/Tópico denunciado (para moderadores).
*   **Lógica:** A Camada de Contexto/Serviço do `Deeper.Content.Forums` dispararia eventos/alertas para o sistema de notificações quando essas ações ocorressem.
    *   Ex: Após `ForumsRepo.create_post`, o contexto verifica se há subscritores para o tópico e dispara:
      `Deeper.Alerts.dispatch(\"forum_new_post\", %{post_id: ..., topic_id: ..., author_id: ...})`.
    *   O sistema de notificações então lida com a criação e entrega das notificações (email, push, in-app) aos usuários relevantes.

## Considerações de Visibilidade:

*   O acesso a qualquer objeto associado (votos em um post, anexos, etc.) deve sempre respeitar a visibilidade do objeto pai (o tópico ou post em si, que por sua vez depende da visibilidade do fórum).
*   Os Repos e a Camada de Contexto devem implementar verificações de permissão antes de retornar dados associados ou permitir interações.

A integração com estes sistemas associados é o que torna o módulo de fóruns uma ferramenta de comunidade rica e interativa.