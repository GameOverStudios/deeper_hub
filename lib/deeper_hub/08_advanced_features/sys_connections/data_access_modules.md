# Documentação Deeper: Módulos de Acesso a Dados para Conexões de Perfil (`sys_connections`)

Este documento descreve o módulo Elixir (Repositório) `Deeper.AdvancedFeatures.ConnectionsRepo`, que encapsula a lógica de acesso ao banco de dados e as queries SQL diretas para as funcionalidades de Conexões de Perfil (amizades, seguir, bloqueios).

## Módulo: `Deeper.AdvancedFeatures.ConnectionsRepo`

Este módulo fornecerá funções para realizar operações CRUD e consultas customizadas nas tabelas `deeper_conn_friends`, `deeper_conn_subscriptions`, e `deeper_conn_bans`.

**Localização do Código:** `lib/deeper/advanced_features/connections_repo.ex`

### Estrutura de Dados Retornada (Structs ou Mapas)

Poderíamos definir structs simples para cada tipo de conexão ou retornar mapas. Para clareza, vamos assumir mapas ou structs simples como:

```sql
    -- Garante que initiator_id < content_id para evitar duplicatas invertidas para solicitações
    -- Esta lógica de ordenação de IDs é mais para a tabela de amizade mútua.
    -- Para solicitações, a direção importa: requester -> target
    INSERT INTO deeper_conn_friends (initiator_id, content_id, mutual, added)
    VALUES (?, ?, 0, UNIXEPOCH())
    RETURNING *;
```

```sql
    UPDATE deeper_conn_friends
    SET mutual = 1, added = UNIXEPOCH() -- 'added' pode ser atualizado para data de aceitação
    WHERE initiator_id = ? AND content_id = ? AND mutual = 0 -- requester_profile_id, accepter_profile_id
    RETURNING *;
```

```sql
    DELETE FROM deeper_conn_friends
    WHERE initiator_id = ? AND content_id = ? AND mutual = 0; -- requester_profile_id, rejecter_profile_id
```

```sql
        DELETE FROM deeper_conn_friends
        WHERE ((initiator_id = ? AND content_id = ?) OR (initiator_id = ? AND content_id = ?)) AND mutual = 1;
        -- params: [profile1_id, profile2_id, profile2_id, profile1_id]
```

```sql
    -- Para contagem
    SELECT COUNT(*)
    FROM deeper_conn_friends f
    WHERE (f.initiator_id = ? OR f.content_id = ?) AND f.mutual = 1;

    -- Para dados
    SELECT
        f.*,
        -- Selecionar o ID do amigo (o que não é o profile_id fornecido)
        CASE WHEN f.initiator_id = ? THEN f.content_id ELSE f.initiator_id END as friend_profile_id,
        -- Fazer JOIN com sys_profiles e bx_persons_data/bx_organizations_data para obter nome/avatar do amigo
        p_friend.type as friend_profile_type,
        COALESCE(pd_friend.fullname, od_friend.org_name) as friend_display_name,
        COALESCE(pd_friend.picture, od_friend.org_logo) as friend_avatar_file_id
    FROM deeper_conn_friends f
    JOIN sys_profiles p_friend ON p_friend.id = (CASE WHEN f.initiator_id = ? THEN f.content_id ELSE f.initiator_id END)
    LEFT JOIN bx_persons_data pd_friend ON p_friend.type = 'bx_persons' AND p_friend.content_id = pd_friend.id
    LEFT JOIN bx_organizations_data od_friend ON p_friend.type = 'bx_organizations' AND p_friend.content_id = od_friend.id
    WHERE (f.initiator_id = ? OR f.content_id = ?) AND f.mutual = 1
    ORDER BY -- (ex: friend_display_name ASC)
    LIMIT ? OFFSET ?;
    -- params: [profile_id, profile_id, profile_id, profile_id, profile_id, profile_id, limit, offset]
```

```sql
    SELECT f.* -- , (JOINs para dados do solicitante)
    FROM deeper_conn_friends f
    WHERE f.content_id = ? AND f.mutual = 0
    ORDER BY f.added DESC LIMIT ? OFFSET ?;
```

```sql
    SELECT f.* -- , (JOINs para dados do alvo)
    FROM deeper_conn_friends f
    WHERE f.initiator_id = ? AND f.mutual = 0
    ORDER BY f.added DESC LIMIT ? OFFSET ?;
```

```sql
    INSERT INTO deeper_conn_subscriptions (initiator_id, content_id, added)
    VALUES (?, ?, UNIXEPOCH())
    RETURNING *;
```

```sql
    DELETE FROM deeper_conn_subscriptions
    WHERE initiator_id = ? AND content_id = ?;
```

```sql
    -- Para contagem
    SELECT COUNT(*) FROM deeper_conn_subscriptions WHERE content_id = ?;
    -- Para dados
    SELECT sub.*, p.type as follower_profile_type, COALESCE(pd.fullname, od.org_name) as follower_display_name -- , pd.picture as follower_avatar_file_id
    FROM deeper_conn_subscriptions sub
    JOIN sys_profiles p ON sub.initiator_id = p.id
    LEFT JOIN bx_persons_data pd ON p.type = 'bx_persons' AND p.content_id = pd.id
    LEFT JOIN bx_organizations_data od ON p.type = 'bx_organizations' AND p.content_id = od.id
    WHERE sub.content_id = ?
    ORDER BY sub.added DESC LIMIT ? OFFSET ?;
```

```sql
    -- Para contagem
    SELECT COUNT(*) FROM deeper_conn_subscriptions WHERE initiator_id = ?;
    -- Para dados
    SELECT sub.*, p.type as followed_profile_type, COALESCE(pd.fullname, od.org_name) as followed_display_name -- , pd.picture as followed_avatar_file_id
    FROM deeper_conn_subscriptions sub
    JOIN sys_profiles p ON sub.content_id = p.id
    LEFT JOIN bx_persons_data pd ON p.type = 'bx_persons' AND p.content_id = pd.id
    LEFT JOIN bx_organizations_data od ON p.type = 'bx_organizations' AND p.content_id = od.id
    WHERE sub.initiator_id = ?
    ORDER BY sub.added DESC LIMIT ? OFFSET ?;
```

```sql
    INSERT INTO deeper_conn_bans (initiator_id, content_id, added)
    VALUES (?, ?, UNIXEPOCH())
    RETURNING *;
```

```sql
    DELETE FROM deeper_conn_bans
    WHERE initiator_id = ? AND content_id = ?;
```

```sql
    -- Para contagem
    SELECT COUNT(*) FROM deeper_conn_bans WHERE initiator_id = ?;
    -- Para dados (com JOINs para info do perfil bloqueado)
    SELECT ban.*, p.type as blocked_profile_type, COALESCE(pd.fullname, od.org_name) as blocked_display_name -- , pd.picture as blocked_avatar_file_id
    FROM deeper_conn_bans ban
    JOIN sys_profiles p ON ban.content_id = p.id
    LEFT JOIN bx_persons_data pd ON p.type = 'bx_persons' AND p.content_id = pd.id
    LEFT JOIN bx_organizations_data od ON p.type = 'bx_organizations' AND p.content_id = od.id
    WHERE ban.initiator_id = ?
    ORDER BY ban.added DESC LIMIT ? OFFSET ?;
```

```elixir
# Para amizades (pode incluir o perfil do amigo)
defmodule Deeper.AdvancedFeatures.Connections.Friendship do
  defstruct [:id, :initiator_id, :content_id, :mutual, :added, :friend_profile_summary]
end

# Para assinaturas (pode incluir o perfil seguido/seguidor)
defmodule Deeper.AdvancedFeatures.Connections.Subscription do
  defstruct [:id, :initiator_id, :content_id, :added, :profile_summary] # profile_summary do content_id ou initiator_id dependendo da query
end

# Para bloqueios
defmodule Deeper.AdvancedFeatures.Connections.Ban do
  defstruct [:id, :initiator_id, :content_id, :added, :banned_profile_summary]
end
```

```elixir
        # Em transação:
        # 1. DELETE FROM deeper_conn_friends WHERE initiator_id = requester AND content_id = accepter AND mutual = 0;
        # 2. {id1, id2} = Enum.sort([requester_profile_id, accepter_profile_id])
        # 3. INSERT INTO deeper_conn_friends (initiator_id, content_id, mutual, added)
        #    VALUES (id1, id2, 1, UNIXEPOCH()) ON CONFLICT DO NOTHING RETURNING *;
```

```elixir
    # {id1, id2} = Enum.sort([profile1_id, profile2_id])
    # DELETE FROM deeper_conn_friends WHERE initiator_id = id1 AND content_id = id2 AND mutual = 1;
```

---

### Funções para Amizades (`deeper_conn_friends`)

#### `request_friendship(requester_profile_id :: integer(), target_profile_id :: integer()) :: {:ok, Friendship.t()} | {:error, :already_friends | :request_exists | :cannot_request_self | any()}`
*   **Descrição:** Cria uma solicitação de amizade (ou estabelece amizade se a lógica for de aceitação automática mútua, o que é menos comum). Define `mutual = 0`.
*   **Lógica:**
    *   Verificar se `requester_profile_id != target_profile_id`.
    *   Verificar se já não são amigos (`mutual = 1`).
    *   Verificar se já não existe uma solicitação pendente (em qualquer direção).
    *   Verificar se o `target_profile_id` não bloqueou o `requester_profile_id`.
*   **SQL:**

#### `accept_friendship_request(accepter_profile_id :: integer(), requester_profile_id :: integer()) :: {:ok, Friendship.t()} | {:error, :no_request_found | any()}`
*   **Descrição:** Aceita uma solicitação de amizade. Define `mutual = 1` para a relação.
*   **Lógica:**
    *   Verificar se existe uma solicitação de `requester_profile_id` para `accepter_profile_id` com `mutual = 0`.
    *   Atualizar a entrada para `mutual = 1` (ou deletar a solicitação e criar uma nova entrada mútua, dependendo do modelo).
    *   **Atualizar Contadores:** Incrementar `friends_count` para ambos os perfis (em `bx_persons_data` ou similar).
*   **SQL (assumindo que atualiza a solicitação existente):**

    *   **Ou, se for criar uma nova entrada para amizade mútua, normalizando os IDs (menor, maior):**

#### `reject_friendship_request(rejecter_profile_id :: integer(), requester_profile_id :: integer()) :: :ok | {:error, :no_request_found | any()}`
*   **Descrição:** Rejeita/remove uma solicitação de amizade.
*   **SQL:**

#### `remove_friendship(profile1_id :: integer(), profile2_id :: integer()) :: :ok | {:error, :not_friends | any()}`
*   **Descrição:** Remove uma amizade mútua existente.
*   **Lógica:**
    *   Remover a entrada correspondente da amizade.
    *   **Atualizar Contadores:** Decrementar `friends_count` para ambos os perfis.
*   **SQL (assumindo uma única entrada normalizada para amizade mútua):**

    *   **SQL (se a tabela `deeper_conn_friends` puder ter duas entradas por amizade A->B e B->A, ambas `mutual=1`):**

#### `list_friends(profile_id :: integer(), pagination_opts :: map()) :: {:ok, %{data: [Friendship.t()], pagination: map()}} | {:error, any()}`
*   **Descrição:** Lista os amigos de um perfil.
*   **`pagination_opts`:** `:page`, `:per_page`.
*   **SQL (assumindo uma única entrada normalizada com `mutual=1` e IDs ordenados):**

#### `list_friendship_requests(profile_id :: integer(), type :: :received | :sent, pagination_opts :: map()) :: {:ok, %{data: [Friendship.t()], pagination: map()}} | {:error, any()}`
*   **Descrição:** Lista solicitações de amizade recebidas ou enviadas por um perfil.
*   **SQL (para recebidas):**

*   **SQL (para enviadas):**

#### `get_friendship_status(profile1_id :: integer(), profile2_id :: integer()) :: {:ok, :friends | :request_sent | :request_received | :not_connected | :blocked_by_them | :you_blocked_them} | {:error, any()}`
*   **Descrição:** Verifica o status da conexão de amizade entre dois perfis.
*   **Lógica:**
    1.  Verificar bloqueios primeiro.
    2.  Verificar amizade mútua.
    3.  Verificar solicitação pendente em qualquer direção.

---

### Funções para Assinaturas/Seguir (`deeper_conn_subscriptions`)

#### `follow_profile(follower_profile_id :: integer(), followed_profile_id :: integer()) :: {:ok, Subscription.t()} | {:error, :already_following | :cannot_follow_self | :target_blocked_you | any()}`
*   **Descrição:** Um perfil começa a seguir outro.
*   **Lógica:**
    *   Verificar se `follower_profile_id != followed_profile_id`.
    *   Verificar se já não está seguindo.
    *   Verificar se o `followed_profile_id` não bloqueou o `follower_profile_id`.
    *   **Atualizar Contadores:** Incrementar `fans_count` do `followed_profile_id` (em `bx_persons_data` ou `bx_organizations_data`) e `following_count` do `follower_profile_id`.
*   **SQL:**

#### `unfollow_profile(follower_profile_id :: integer(), followed_profile_id :: integer()) :: :ok | {:error, :not_following | any()}`
*   **Descrição:** Um perfil deixa de seguir outro.
*   **Lógica:**
    *   **Atualizar Contadores:** Decrementar `fans_count` e `following_count`.
*   **SQL:**

#### `list_followers(profile_id :: integer(), pagination_opts :: map()) :: {:ok, %{data: [Subscription.t()], pagination: map()}} | {:error, any()}`
*   **Descrição:** Lista os perfis que seguem `profile_id`.
*   **SQL:**

#### `list_following(profile_id :: integer(), pagination_opts :: map()) :: {:ok, %{data: [Subscription.t()], pagination: map()}} | {:error, any()}`
*   **Descrição:** Lista os perfis que `profile_id` está seguindo.
*   **SQL:**

#### `is_following(follower_profile_id :: integer(), followed_profile_id :: integer()) :: {:ok, boolean()} | {:error, any()}`
*   **SQL:** `SELECT COUNT(*) as count FROM deeper_conn_subscriptions WHERE initiator_id = ? AND content_id = ?;` (retorna true se count > 0)

---

### Funções para Bloqueios (`deeper_conn_bans`)

#### `block_profile(blocker_profile_id :: integer(), blocked_profile_id :: integer()) :: {:ok, Ban.t()} | {:error, :already_blocked | :cannot_block_self | any()}`
*   **Descrição:** Um perfil bloqueia outro.
*   **Lógica:**
    *   Verificar se `blocker_profile_id != blocked_profile_id`.
    *   Verificar se já não está bloqueado.
    *   **Importante:** Ao bloquear, quaisquer conexões existentes de amizade ou seguir entre os dois perfis devem ser removidas. (Ex: chamar `remove_friendship` e `unfollow_profile` em ambas as direções). Isso deve ser feito em uma transação.
*   **SQL:**

#### `unblock_profile(blocker_profile_id :: integer(), blocked_profile_id :: integer()) :: :ok | {:error, :not_blocked | any()}`
*   **SQL:**

#### `list_blocked_profiles(blocker_profile_id :: integer(), pagination_opts :: map()) :: {:ok, %{data: [Ban.t()], pagination: map()}} | {:error, any()}`
*   **Descrição:** Lista os perfis que `blocker_profile_id` bloqueou.
*   **SQL:**

#### `is_blocked(profile1_id :: integer(), profile2_id :: integer()) :: {:ok, :profile1_blocked_profile2 | :profile2_blocked_profile1 | :not_blocked} | {:error, any()}`
*   **Descrição:** Verifica se existe um bloqueio mútuo ou unilateral entre dois perfis.
*   **SQL:**
    1.  `SELECT COUNT(*) FROM deeper_conn_bans WHERE initiator_id = ? AND content_id = ?;` (profile1, profile2)
    2.  `SELECT COUNT(*) FROM deeper_conn_bans WHERE initiator_id = ? AND content_id = ?;` (profile2, profile1)

---

## Considerações de Implementação `ConnectionsRepo`:

*   **Atualização de Contadores:** As funções que modificam conexões (criar/remover amizade, seguir/deixar de seguir) precisam de uma estratégia para atualizar os contadores correspondentes nas tabelas `bx_persons_data` e `bx_organizations_data` (ex: `friends_count`, `fans_count`, `following_count`). Isso pode ser feito:
    *   Com chamadas explícitas a outros Repos (ex: `PersonsRepo.update_friend_count(profile_id, delta)`).
    *   Através de um sistema de eventos/notificações interno, se \"Deeper\" implementar um.
    *   Idealmente, dentro da mesma transação da operação de conexão.
*   **Performance de Listagens:** As queries `list_friends`, `list_followers`, `list_following` que fazem JOINs para obter informações do perfil podem se tornar lentas. Estratégias:
    *   Garantir bons índices.
    *   Para pré-carregamento de dados do perfil, em vez de JOINs complexos na query principal, pode ser mais eficiente buscar os IDs dos perfis conectados e depois fazer uma única query batch para buscar os detalhes de todos esses perfis (ex: `SELECT ... FROM sys_profiles WHERE id IN (?, ?, ...)`).
*   **Normalização de Amizades:** Decidir sobre a representação de amizades mútuas (uma linha com IDs ordenados ou duas linhas) afetará as queries. A abordagem de uma linha com IDs ordenados e `mutual=1` é geralmente mais limpa para evitar duplicidade de dados sobre a *existência* da amizade.

Este `ConnectionsRepo` será uma peça central para as interações sociais na plataforma \"Deeper\".