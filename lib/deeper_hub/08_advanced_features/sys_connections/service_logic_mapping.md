# Documentação Deeper: Mapeamento da Lógica de Serviço para Conexões de Perfil (`sys_connections`)

Este documento descreve como as funcionalidades e a lógica de \"serviço\" relacionadas às conexões de perfil no UNA (geralmente manipuladas pela classe `BxDolConnection` e seus objetos especializados) serão mapeadas para o backend Elixir \"Deeper\" e sua API RESTful.

A lógica de conexões envolve não apenas a criação/remoção de registros no banco de dados, mas também a verificação de permissões, o disparo de notificações, a atualização de contadores e a aplicação de regras de negócio (ex: o que acontece quando um usuário bloqueia outro que era amigo).

## Mapeamento de Funcionalidades Chave e Lógica de Serviço:

### 1. Enviar Solicitação de Amizade

*   **Funcionalidade UNA Original (via `BxDolConnection` - 'friend' type):**
    *   Verifica se os perfis são diferentes.
    *   Verifica se já não são amigos ou se já existe uma solicitação.
    *   Verifica se há bloqueios mútuos.
    *   Cria um registro de solicitação (pode ser na mesma tabela de amigos com um status \"pendente\" ou em uma tabela separada de solicitações).
    *   Dispara um alerta/notificação para o perfil alvo.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `POST /api/v1/profiles/{user_profile_id}/friendships/request/{target_profile_id}`
    *   **Controller Elixir:**
        1.  Autentica o `{user_profile_id}`.
        2.  Valida que `{user_profile_id}` != `{target_profile_id}`.
        3.  Chama `Deeper.AdvancedFeatures.ConnectionsRepo.request_friendship(user_profile_id, target_profile_id)`.
    *   **`Deeper.AdvancedFeatures.ConnectionsRepo.request_friendship/2`:**
        1.  Verifica se `{target_profile_id}` bloqueou `{user_profile_id}` (consultando `deeper_conn_bans`). Se sim, retorna erro.
        2.  Verifica se já existe uma amizade mútua (`mutual=1`) ou uma solicitação pendente (`mutual=0`) em qualquer direção entre os dois perfis na `deeper_conn_friends`. Se sim, retorna erro.
        3.  Insere o registro na `deeper_conn_friends` com `initiator_id = user_profile_id`, `content_id = target_profile_id`, `mutual = 0`.
        4.  **Ação Pós-DB (Idealmente em um Módulo de Serviço/Contexto ou via Eventos):** Disparar uma notificação para `{target_profile_id}`.

### 2. Aceitar Solicitação de Amizade

*   **Funcionalidade UNA Original:**
    *   Verifica se a solicitação existe.
    *   Muda o status da conexão para \"amigos\" (mútua).
    *   Remove a solicitação se estiver em tabela separada.
    *   Atualiza contadores de amigos para ambos os perfis.
    *   Dispara notificações.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `POST /api/v1/profiles/{user_profile_id}/friendships/accept/{requester_profile_id}`
    *   **Controller Elixir:**
        1.  Autentica o `{user_profile_id}` (o aceitante).
        2.  Chama `Deeper.AdvancedFeatures.ConnectionsRepo.accept_friendship_request(user_profile_id, requester_profile_id)`.
    *   **`Deeper.AdvancedFeatures.ConnectionsRepo.accept_friendship_request/2` (em transação):**
        1.  Verifica se existe uma solicitação pendente de `{requester_profile_id}` para `{user_profile_id}` (ex: `initiator_id = requester`, `content_id = user`, `mutual = 0` em `deeper_conn_friends`). Se não, retorna erro.
        2.  Atualiza a entrada existente para `mutual = 1` e atualiza `added` para o timestamp atual. (Ou, se a política for ter uma entrada normalizada `id1 < id2`, deleta a solicitação e insere a nova entrada mútua).
        3.  **Atualizar Contadores:** Chama funções para incrementar `friends_count` em `bx_persons_data`/`bx_organizations_data` para ambos os perfis. (Ex: `PersonsRepo.increment_friends_count(profile_id)`).
        4.  **Ação Pós-DB:** Disparar uma notificação para `{requester_profile_id}` sobre a aceitação.

### 3. Rejeitar/Cancelar Solicitação de Amizade / Remover Amizade

*   **Funcionalidade UNA Original:**
    *   Remove o registro da solicitação ou da amizade.
    *   Atualiza contadores de amigos (se removendo amizade).
    *   Dispara notificações (para cancelamento de solicitação pelo remetente).
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoints:**
        *   `POST /api/v1/profiles/{user_profile_id}/friendships/reject/{requester_profile_id}`
        *   `DELETE /api/v1/profiles/{user_profile_id}/friendships/{friend_profile_id}` (também usado para cancelar solicitação enviada)
    *   **`Deeper.AdvancedFeatures.ConnectionsRepo.reject_friendship_request/2`:**
        1.  Deleta a entrada de solicitação (`mutual=0`).
    *   **`Deeper.AdvancedFeatures.ConnectionsRepo.remove_friendship/2` (em transação):**
        1.  Deleta a entrada de amizade (`mutual=1`).
        2.  **Atualizar Contadores:** Chama funções para decrementar `friends_count` para ambos os perfis.
        3.  **Ação Pós-DB (para cancelamento de solicitação):** Se `user_profile_id` cancelou uma solicitação *enviada* para `friend_profile_id`, notificar `friend_profile_id`.

### 4. Seguir um Perfil

*   **Funcionalidade UNA Original (tipo 'subscription' ou 'fan'):**
    *   Verifica se já não está seguindo.
    *   Verifica bloqueios.
    *   Cria o registro de assinatura.
    *   Atualiza contadores de \"seguidores\" (fãs) do perfil alvo e \"seguindo\" do perfil iniciador.
    *   Dispara notificação.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `POST /api/v1/profiles/{user_profile_id}/follow/{target_profile_id}`
    *   **Controller Elixir:**
        1.  Autentica `{user_profile_id}`.
        2.  Valida que `{user_profile_id}` != `{target_profile_id}`.
        3.  Chama `Deeper.AdvancedFeatures.ConnectionsRepo.follow_profile(user_profile_id, target_profile_id)`.
    *   **`Deeper.AdvancedFeatures.ConnectionsRepo.follow_profile/2` (em transação):**
        1.  Verifica se `{target_profile_id}` bloqueou `{user_profile_id}`. Se sim, erro.
        2.  Verifica se já existe a assinatura. Se sim, erro ou sucesso idempotente.
        3.  Insere na `deeper_conn_subscriptions`.
        4.  **Atualizar Contadores:**
            *   Incrementar `fans_count` do `{target_profile_id}` (em `bx_persons_data` ou `bx_organizations_data`).
            *   Incrementar `following_count` do `{user_profile_id}` (em `bx_persons_data`).
        5.  **Ação Pós-DB:** Disparar notificação para `{target_profile_id}`.

### 5. Deixar de Seguir um Perfil

*   **Funcionalidade UNA Original:**
    *   Remove o registro de assinatura.
    *   Atualiza contadores.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `DELETE /api/v1/profiles/{user_profile_id}/unfollow/{target_profile_id}`
    *   **`Deeper.AdvancedFeatures.ConnectionsRepo.unfollow_profile/2` (em transação):**
        1.  Deleta da `deeper_conn_subscriptions`.
        2.  **Atualizar Contadores:**
            *   Decrementar `fans_count` do `{target_profile_id}`.
            *   Decrementar `following_count` do `{user_profile_id}`.

### 6. Bloquear um Perfil

*   **Funcionalidade UNA Original:**
    *   Cria um registro de bloqueio.
    *   **Crucial:** Remove quaisquer conexões existentes entre os dois perfis (amizades, A seguindo B, B seguindo A).
    *   Impede futuras solicitações de amizade ou seguir.
    *   Pode afetar a visibilidade de conteúdo.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `POST /api/v1/profiles/{user_profile_id}/block/{target_profile_id}`
    *   **Controller Elixir:**
        1.  Autentica `{user_profile_id}`.
        2.  Valida que `{user_profile_id}` != `{target_profile_id}`.
        3.  Chama `Deeper.AdvancedFeatures.ConnectionsRepo.block_profile(user_profile_id, target_profile_id)`.
    *   **`Deeper.AdvancedFeatures.ConnectionsRepo.block_profile/2` (em transação):**
        1.  Verifica se já está bloqueado.
        2.  **Remover Conexões Existentes:**
            *   Chamar `remove_friendship(user_profile_id, target_profile_id)` (se eram amigos).
            *   Chamar `unfollow_profile(user_profile_id, target_profile_id)` (se user seguia target).
            *   Chamar `unfollow_profile(target_profile_id, user_profile_id)` (se target seguia user).
        3.  Insere na `deeper_conn_bans`.

### 7. Desbloquear um Perfil

*   **Funcionalidade UNA Original:**
    *   Remove o registro de bloqueio.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `DELETE /api/v1/profiles/{user_profile_id}/unblock/{target_profile_id}`
    *   **`Deeper.AdvancedFeatures.ConnectionsRepo.unblock_profile/2`:**
        1.  Deleta da `deeper_conn_bans`.

### 8. Listagem de Conexões (Amigos, Seguidores, Seguindo, Bloqueados)

*   **Funcionalidade UNA Original:**
    *   Serviços para buscar e formatar listas de perfis conectados, geralmente com paginação e informações resumidas do perfil (nome, avatar).
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoints:** `GET /api/v1/profiles/{profile_id}/friends`, `/followers`, `/following`, `/blocked`
    *   **`Deeper.AdvancedFeatures.ConnectionsRepo`:**
        *   As funções `list_friends/2`, `list_followers/2`, `list_following/2`, `list_blocked_profiles/2` conterão o SQL principal para buscar os IDs dos perfis conectados.
        *   **Pré-carregamento de Dados do Perfil:** Para incluir nome, avatar, etc., na resposta da API, essas funções do Repo:
            1.  Primeiro, obtêm os IDs dos perfis conectados.
            2.  Depois, fazem uma chamada batch para `Deeper.SystemCore.ProfilesRepo.get_profile_summaries_by_ids(list_of_ids)` (uma nova função a ser definida no `ProfilesRepo`) para buscar os resumos de todos os perfis necessários de uma vez.
            3.  Combinam os dados da conexão com os resumos dos perfis antes de retornar.
        *   Implementam paginação (`LIMIT`/`OFFSET`) e contagem total.

### 9. Verificação de Status de Conexão

*   **Funcionalidade UNA Original:**
    *   Métodos para verificar rapidamente se A é amigo de B, se A segue B, se A bloqueou B.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/profiles/{profile1_id}/connection-status/{profile2_id}`
    *   **Controller Elixir:** Chama múltiplas funções do `ConnectionsRepo`:
        *   `ConnectionsRepo.get_friendship_status_internal(profile1_id, profile2_id)`
        *   `ConnectionsRepo.is_following(profile1_id, profile2_id)`
        *   `ConnectionsRepo.is_following(profile2_id, profile1_id)`
        *   `ConnectionsRepo.is_blocked_internal(profile1_id, profile2_id)` (verifica ambas as direções)
    *   Agrega os resultados em uma única resposta JSON.

## Considerações sobre Lógica de Serviço Adicional:

*   **Notificações:** Como mencionado, o disparo de notificações (para novas solicitações de amizade, aceitações, novos seguidores) é uma responsabilidade separada, mas que será acionada por essas operações de conexão. Isso pode ser feito através de um sistema de eventos PubSub no Elixir ou chamadas diretas a um `NotificationsService`.
*   **Atualização de Contadores em Perfis (`friends_count`, `fans_count`, `following_count`):**
    *   A atualização desses contadores (nas tabelas `bx_persons_data`, `bx_organizations_data`) deve ocorrer de forma atômica com a modificação da conexão.
    *   O `ConnectionsRepo` pode chamar diretamente funções de atualização de contagem nos Repos correspondentes (ex: `PersonsRepo.adjust_friends_count(profile_id, delta)`), idealmente tudo dentro da mesma transação iniciada pelo controller ou um módulo de serviço.

Este mapeamento visa garantir que a API \"Deeper\" não apenas gerencie os dados de conexão, mas também incorpore a lógica de negócios essencial associada a esses relacionamentos.