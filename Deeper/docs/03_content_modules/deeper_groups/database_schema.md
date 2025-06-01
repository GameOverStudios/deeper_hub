# Documentação Deeper: Esquema do Banco de Dados para Grupos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas principais do módulo de Grupos (`deeper_groups`).

## Tabela: `deeper_groups_categories` (Categorias de Grupos)

Opcional, mas útil para organizar grupos.

```sql
CREATE TABLE IF NOT EXISTS deeper_groups_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_id INTEGER DEFAULT 0,
  name TEXT NOT NULL UNIQUE,
  title_lang_key TEXT,
  \"order\" INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_categories_parent_id ON deeper_groups_categories(parent_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_groups_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  author_profile_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do criador do grupo
  category_id INTEGER, -- FK para deeper_groups_categories.id
  title TEXT NOT NULL,
  group_name TEXT NOT NULL UNIQUE, -- Nome curto/identificador único para URL (slug)
  description TEXT,
  cover_image_file_id INTEGER, -- FK para deeper_files.id
  avatar_image_file_id INTEGER, -- FK para deeper_files.id
  
  -- Configurações de Privacidade e Adesão
  privacy_type TEXT DEFAULT 'public' CHECK(privacy_type IN ('public', 'private', 'secret')),
  -- 'public': qualquer um pode ver e entrar.
  -- 'private': qualquer um pode ver (ou apenas o nome/descrição), mas precisa de aprovação para entrar.
  -- 'secret': não listado, entrada apenas por convite.
  allow_join_requests INTEGER DEFAULT 1, -- Se 'private', permite pedidos de adesão?
  allow_invites INTEGER DEFAULT 1, -- Permite que membros convidem outros?

  -- Contadores
  members_count INTEGER DEFAULT 0,
  posts_count INTEGER DEFAULT 0, -- Se houver um feed/posts dentro do grupo
  views_count INTEGER DEFAULT 0,
  favorites_count INTEGER DEFAULT 0,
  
  -- Status e Visibilidade
  status TEXT DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'suspended', 'hidden')),
  featured INTEGER DEFAULT 0,

  created_at INTEGER NOT NULL, -- Unix Timestamp
  updated_at INTEGER NOT NULL, -- Unix Timestamp

  FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES deeper_groups_categories(id) ON DELETE SET NULL
  -- FOREIGN KEY (cover_image_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL
  -- FOREIGN KEY (avatar_image_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_deeper_groups_entries_author ON deeper_groups_entries(author_profile_id);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_entries_category ON deeper_groups_entries(category_id);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_entries_status ON deeper_groups_entries(status);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_entries_privacy_type ON deeper_groups_entries(privacy_type);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_groups_members (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id INTEGER NOT NULL, -- FK para deeper_groups_entries.id
  profile_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem é o membro)
  role TEXT DEFAULT 'member' CHECK(role IN ('admin', 'moderator', 'member')),
  status TEXT DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'invited', 'banned')),
  -- 'active': membro ativo.
  -- 'pending_approval': solicitou adesão e aguarda aprovação.
  -- 'invited': foi convidado e ainda não aceitou.
  -- 'banned': banido do grupo.
  joined_at INTEGER NOT NULL, -- Unix Timestamp de quando se tornou membro ou status mudou
  promoted_by_profile_id INTEGER, -- Quem promoveu/mudou o papel (opcional)

  UNIQUE (group_id, profile_id),
  FOREIGN KEY (group_id) REFERENCES deeper_groups_entries(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (promoted_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_deeper_groups_members_group_id_role_status ON deeper_groups_members(group_id, role, status);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_members_profile_id_group_id ON deeper_groups_members(profile_id, group_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_groups_invites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id INTEGER NOT NULL,
  inviter_profile_id INTEGER NOT NULL, -- Quem convidou
  invited_profile_id INTEGER, -- Quem foi convidado (se usuário existente)
  invited_email TEXT, -- Email do convidado (se não usuário existente)
  invite_code TEXT UNIQUE, -- Código de convite único (opcional)
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'accepted', 'declined', 'expired')),
  created_at INTEGER NOT NULL,
  expires_at INTEGER,

  FOREIGN KEY (group_id) REFERENCES deeper_groups_entries(id) ON DELETE CASCADE,
  FOREIGN KEY (inviter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (invited_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_invites_group_id_status ON deeper_groups_invites(group_id, status);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_invites_invited_profile_id ON deeper_groups_invites(invited_profile_id);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_invites_invited_email ON deeper_groups_invites(invited_email);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_groups_content_feed (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id INTEGER NOT NULL,
  author_profile_id INTEGER NOT NULL,
  content_text TEXT NOT NULL,
  -- attachments_json TEXT, -- Lista de anexos (arquivos, imagens)
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  
  -- Contadores para o post
  comments_count INTEGER DEFAULT 0,
  likes_count INTEGER DEFAULT 0,

  FOREIGN KEY (group_id) REFERENCES deeper_groups_entries(id) ON DELETE CASCADE,
  FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_deeper_groups_content_feed_group_id_created_at ON deeper_groups_content_feed(group_id, created_at DESC);
```

## Tabela: `deeper_groups_entries` (Entradas de Grupos)

Tabela principal para armazenar os detalhes dos grupos.

## Tabela: `deeper_groups_members` (Membros de Grupos)

Registra quais perfis são membros de quais grupos e seus papéis.

## Tabela: `deeper_groups_invites` (Convites para Grupos)

Opcional, para gerenciar convites formais.

## Tabela: `deeper_groups_content_feed` (Conteúdo dentro do Grupo - Exemplo)

Esta é uma tabela de exemplo se os grupos tiverem seu próprio feed de posts. Alternativamente, posts podem ser de um módulo genérico (`deeper_posts`) com uma FK para `group_id`.

**Próximo Passo:** Definir os módulos de migração Elixir para criar estas tabelas.