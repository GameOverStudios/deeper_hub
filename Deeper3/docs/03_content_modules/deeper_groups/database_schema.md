# Documentação Deeper: Esquema do Banco de Dados para Módulo de Grupos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas relacionadas ao módulo de Grupos (`deeper_groups`).

## Tabela Principal: `deeper_groups`

```sql
CREATE TABLE IF NOT EXISTS deeper_groups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL, -- Criador/Proprietário do grupo
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  rules TEXT, -- Regras do grupo
  avatar_file_id INTEGER, -- FK para deeper_files.id
  cover_file_id INTEGER,  -- FK para deeper_files.id
  privacy_level TEXT NOT NULL DEFAULT 'public' CHECK(privacy_level IN ('public', 'private', 'secret')),
  allow_member_invites INTEGER NOT NULL DEFAULT 1, -- 0 = não, 1 = sim (membros podem convidar)
  join_approval_mode TEXT NOT NULL DEFAULT 'open' CHECK(join_approval_mode IN ('open', 'approval', 'invite_only')),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'suspended_by_admin', 'deleted_by_owner')),
  members_count INTEGER NOT NULL DEFAULT 0, -- Contagem denormalizada de membros
  -- Outros contadores podem ser adicionados aqui (ex: posts_count, last_activity_ts)
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE RESTRICT, -- Ou SET NULL se o grupo puder existir sem um proprietário original
  FOREIGN KEY (avatar_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL,
  FOREIGN KEY (cover_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_deeper_groups_profile_id ON deeper_groups(profile_id);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_slug ON deeper_groups(slug);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_privacy_level ON deeper_groups(privacy_level);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_status ON deeper_groups(status);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_group_members (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id INTEGER NOT NULL,
  profile_id INTEGER NOT NULL, -- Perfil do membro
  role TEXT NOT NULL DEFAULT 'member' CHECK(role IN ('member', 'moderator', 'admin', 'owner')), -- Papel do membro no grupo
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'invited', 'banned', 'left')),
  joined_at INTEGER NOT NULL, -- Unix Timestamp de quando entrou ou foi convidado
  approved_by_profile_id INTEGER, -- Quem aprovou a entrada (se aplicável)
  invited_by_profile_id INTEGER, -- Quem convidou (se aplicável)
  banned_by_profile_id INTEGER, -- Quem baniu (se aplicável)
  ban_reason TEXT, -- Opcional
  notifications_level TEXT NOT NULL DEFAULT 'all' CHECK(notifications_level IN ('all', 'highlights', 'none')), -- Preferência de notificação para este grupo
  UNIQUE (group_id, profile_id), -- Um perfil só pode ser membro uma vez de um grupo
  FOREIGN KEY (group_id) REFERENCES deeper_groups(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
  FOREIGN KEY (invited_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
  FOREIGN KEY (banned_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_dgm_group_id_role ON deeper_group_members(group_id, role);
CREATE INDEX IF NOT EXISTS idx_dgm_group_id_status ON deeper_group_members(group_id, status);
CREATE INDEX IF NOT EXISTS idx_dgm_profile_id_status ON deeper_group_members(profile_id, status);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_group_content_posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id INTEGER NOT NULL,
  profile_id INTEGER NOT NULL, -- Autor do post
  parent_post_id INTEGER, -- Para posts aninhados/comentários em posts de grupo
  body TEXT NOT NULL,
  -- Campos adicionais como 'pinned', 'type' (anúncio, discussão), etc.
  -- Pode ter anexos (referenciando deeper_files através de uma tabela de junção)
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (group_id) REFERENCES deeper_groups(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE, -- Ou SET NULL
  FOREIGN KEY (parent_post_id) REFERENCES deeper_group_content_posts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dgcp_group_id_created_at ON deeper_group_content_posts(group_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dgcp_profile_id ON deeper_group_content_posts(profile_id);
CREATE INDEX IF NOT EXISTS idx_dgcp_parent_post_id ON deeper_group_content_posts(parent_post_id);
```

```sql
    CREATE TABLE IF NOT EXISTS deeper_group_invites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL,
      inviter_profile_id INTEGER NOT NULL, -- Quem convidou
      invited_email TEXT, -- Se o convite for para um email não registrado
      invited_profile_id INTEGER, -- Se o convite for para um perfil existente
      token TEXT UNIQUE, -- Token único para aceitar o convite
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'accepted', 'declined', 'expired')),
      created_at INTEGER NOT NULL,
      expires_at INTEGER,
      FOREIGN KEY (group_id) REFERENCES deeper_groups(id) ON DELETE CASCADE,
      FOREIGN KEY (inviter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (invited_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      UNIQUE (group_id, invited_email) WHERE invited_profile_id IS NULL, -- Evitar múltiplos convites para o mesmo email
      UNIQUE (group_id, invited_profile_id) WHERE invited_email IS NULL -- Evitar múltiplos convites para o mesmo perfil
    );
```

```sql
    CREATE TABLE IF NOT EXISTS deeper_group_join_requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL,
      requester_profile_id INTEGER NOT NULL,
      message TEXT, -- Mensagem opcional com a solicitação
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'approved', 'rejected')),
      requested_at INTEGER NOT NULL,
      reviewed_by_profile_id INTEGER, -- Quem aprovou/rejeitou
      reviewed_at INTEGER,
      FOREIGN KEY (group_id) REFERENCES deeper_groups(id) ON DELETE CASCADE,
      FOREIGN KEY (requester_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (reviewed_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
      UNIQUE (group_id, requester_profile_id) -- Um perfil só pode ter uma solicitação pendente por grupo
    );
```

*   **`profile_id`**: O criador original. `ON DELETE RESTRICT` impede a exclusão do perfil do proprietário se ele ainda possuir grupos, a menos que haja uma lógica para transferir a propriedade. `SET NULL` ou atribuir a um \"usuário do sistema\" são alternativas.
*   **`privacy_level`**: Define a visibilidade e como se juntar ao grupo.
*   **`join_approval_mode`**: Como novos membros são aceitos (`open` para público, `approval` para privado, `invite_only` para secreto).
*   **`members_count`**: Contagem desnormalizada para performance.

## Tabela: `deeper_group_members` (Membros do Grupo)

*   Define a relação entre um perfil e um grupo, incluindo seu papel e status.
*   A constraint `UNIQUE (group_id, profile_id)` é crucial.

## Tabela: `deeper_group_content_posts` (Exemplo de conteúdo dentro do grupo)
Se os grupos puderem ter seu próprio feed de posts, diferente dos artigos globais. Poderia também ser uma tabela de junção se os `deeper_articles` forem reutilizados. Para este exemplo, vamos criar uma tabela simples para posts específicos de grupos.

*   Esta é uma tabela simplificada. Um sistema de posts mais robusto dentro de grupos poderia ser mais complexo, possivelmente reutilizando/adaptando a estrutura de `deeper_articles`.
*   Interações como comentários e votos para esses posts de grupo usariam os sistemas genéricos, com `object_name = \"deeper_group_posts\"` e `object_id = post_id`.

## Tabelas Opcionais / Implementação Futura:

*   **`deeper_group_invites`**: Se o fluxo de convite for complexo (ex: convites pendentes com expiração).

*   **`deeper_group_join_requests`**: Para grupos privados que requerem aprovação.

Este conjunto de tabelas fornece a infraestrutura para um módulo de grupos funcional.