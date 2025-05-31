# Documentação Deeper: Objetos Associados ao Módulo de Grupos

Este documento descreve como o módulo de Grupos (`deeper_groups`) se integra com outros sistemas e objetos genéricos do \"Deeper\", como comentários, votos, gerenciamento de arquivos (para avatares/capas), e o sistema de posts internos do grupo.

A abordagem é que o módulo `deeper_groups` gerencia a entidade principal do grupo e sua membresia, enquanto interações e mídias são frequentemente tratadas por sistemas genéricos ou sub-componentes.

## 1. Comentários

Comentários podem existir em dois níveis para grupos:

*   **A. Comentários na Página Principal do Grupo:**
    *   **Sistema de Referência:** `📂 04_interaction_systems/sys_comments_system/`
    *   **Configuração:** `sys_objects_cmts` teria uma entrada para \"deeper_groups_profile_comments\" (ou similar).
        *   `Name`: \"deeper_groups_profile\"
        *   `TriggerTable`: \"deeper_groups\"
        *   `TriggerFieldId`: \"id\"
    *   **Uso:** Comentários sobre o grupo em si, em sua página de perfil.
    *   **Endpoints da API (Gerenciados pelo módulo de comentários):**
        *   `GET /api/v1/comments?system_object=deeper_groups_profile&object_id={group_id}`
        *   `POST /api/v1/comments` (com `system_object=\"deeper_groups_profile\"`, `object_id={group_id}`)

*   **B. Comentários em Posts Dentro do Grupo (se `deeper_group_content_posts` for usado):**
    *   **Sistema de Referência:** `📂 04_interaction_systems/sys_comments_system/`
    *   **Configuração:** `sys_objects_cmts` teria uma entrada para \"deeper_group_posts_comments\".
        *   `Name`: \"deeper_group_posts\"
        *   `TriggerTable`: \"deeper_group_content_posts\"
        *   `TriggerFieldId`: \"id\"
    *   **Uso:** Comentários em posts específicos feitos dentro de um grupo.
    *   **Endpoints da API:**
        *   `GET /api/v1/comments?system_object=deeper_group_posts&object_id={group_post_id}`
        *   `POST /api/v1/comments` (com `system_object=\"deeper_group_posts\"`, `object_id={group_post_id}`)

## 2. Votos / Avaliações

Votos podem ser aplicados ao grupo em si ou a posts dentro do grupo.

*   **A. Votos no Grupo:**
    *   **Sistema de Referência:** `📂 04_interaction_systems/sys_voting_system/`
    *   **Configuração:** `sys_objects_vote` teria uma entrada para \"deeper_groups_votes\".
    *   **Endpoints da API:**
        *   `GET /api/v1/votes/summary?object_name=deeper_groups_votes&object_id={group_id}`
        *   `POST /api/v1/votes` (com `object_name=\"deeper_groups_votes\"`, `object_id={group_id}`)

*   **B. Votos em Posts do Grupo:**
    *   **Sistema de Referência:** `📂 04_interaction_systems/sys_voting_system/`
    *   **Configuração:** `sys_objects_vote` teria uma entrada para \"deeper_group_posts_votes\".
    *   **Endpoints da API:**
        *   `GET /api/v1/votes/summary?object_name=deeper_group_posts_votes&object_id={group_post_id}`
        *   `POST /api/v1/votes` (com `object_name=\"deeper_group_posts_votes\"`, `object_id={group_post_id}`)

## 3. Favoritos (Seguir/Favoritar um Grupo)

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_favorites_system/`
*   **Configuração:** `sys_objects_favorite` teria uma entrada para \"deeper_groups_favorites\".
*   **Endpoints da API:**
    *   `GET /api/v1/favorites/status?object_name=deeper_groups_favorites&object_id={group_id}`
    *   `POST /api/v1/favorites` (com `object_name=\"deeper_groups_favorites\"`, `object_id={group_id}`)
*   **Integração:** `GET /groups/{id_or_slug}?include=favorites_summary` poderia adicionar contagem e status de favorito do usuário atual.

## 4. Avatar e Imagem de Capa do Grupo

*   **Sistema de Referência:** `📂 06_file_management/`
*   **Tabelas Envolvidas:**
    *   `deeper_groups`: Contém `avatar_file_id` e `cover_file_id` (FKs para `deeper_files.id`).
*   **Upload/Associação:**
    1.  Cliente faz upload das imagens via `POST /api/v1/files/upload`.
    2.  API de arquivos retorna os IDs dos arquivos.
    3.  Ao criar (`POST /groups`) ou atualizar (`PUT/PATCH /groups/{id}`) um grupo, o cliente envia `avatar_file_id` e/ou `cover_file_id`.
*   **Recuperação:**
    *   `GET /groups/{id_or_slug}?include=avatar,cover`: O `GroupsRepo.get_group` fará `JOIN` com `deeper_files` para incluir detalhes das imagens.

## 5. Posts de Conteúdo Dentro do Grupo

*   **Sistema de Referência:** Tabela `deeper_group_content_posts` definida e gerenciada dentro deste módulo de grupos (pelo `GroupsRepo`).
*   **Endpoints da API (Gerenciados pelo módulo de grupos):**
    *   `POST /groups/{group_id}/posts`
    *   `GET /groups/{group_id}/posts`
    *   `GET /groups/{group_id}/posts/{post_id}` (e PUT/DELETE)
*   **Interações com esses posts (comentários, votos):** Seriam gerenciadas pelos sistemas genéricos, como descrito nos pontos 1.B e 2.B acima, usando um `object_name` como \"deeper_group_posts\".

## 6. Membros do Grupo

*   **Sistema de Referência:** Tabela `deeper_group_members` gerenciada pelo `GroupsRepo` dentro deste módulo.
*   **Endpoints da API (Gerenciados pelo módulo de grupos):**
    *   `POST /groups/{group_id}/members` (para juntar-se/solicitar/aceitar convite)
    *   `GET /groups/{group_id}/members`
    *   `GET /groups/{group_id}/members/{member_profile_id}`
    *   `PUT /groups/{group_id}/members/{member_profile_id}` (para mudar papel/status)
    *   `DELETE /groups/{group_id}/members/{member_profile_id}` (ou `/me` para sair)

## 7. Convites e Solicitações de Adesão (se implementados com tabelas dedicadas)

*   **Sistema de Referência:** Tabelas `deeper_group_invites` e `deeper_group_join_requests` gerenciadas pelo `GroupsRepo`.
*   **Endpoints da API (Gerenciados pelo módulo de grupos):**
    *   `POST /groups/{group_id}/invites`
    *   `GET /groups/{group_id}/invites?status=pending`
    *   `GET /groups/{group_id}/join-requests?status=pending`
    *   `PUT /groups/{group_id}/join-requests/{request_id}`

## 8. Notificações

*   Ações dentro do módulo de grupos (novo membro, novo post no grupo, convite, solicitação aprovada) podem disparar notificações.
*   **Sistema de Referência:** Um sistema de notificações genérico (`deeper_notifications` ou integração com `sys_alerts`).
*   **Lógica:** A camada de Contexto/Serviço do `Deeper.Content.Groups` (ou funções específicas no `GroupsRepo` se a camada de contexto for fina) seria responsável por emitir eventos/alertas que o sistema de notificações consumiria para criar e enviar notificações.
    *   Ex: Após `GroupsRepo.approve_group_membership`, o contexto poderia disparar um alerta: `Deeper.Alerts.dispatch(\"group_membership_approved\", %{group_id: ..., profile_id: ..., approver_id: ...})`.

## Considerações de Visibilidade e Permissões:

*   O acesso aos objetos associados (comentários, posts de grupo, lista de membros) deve sempre respeitar a `privacy_level` do grupo e o status de membresia do usuário solicitante.
*   Por exemplo, posts em um grupo `private` só devem ser listados/acessíveis para membros ativos desse grupo. A lógica para isso residiria nos respectivos Repos, que receberiam o `profile_id` do usuário logado como parâmetro para aplicar as verificações de permissão necessárias.

Esta estrutura de objetos associados permite que o módulo de grupos se mantenha focado em sua funcionalidade principal, ao mesmo tempo que se integra de forma poderosa com outros sistemas para oferecer uma experiência rica em recursos.