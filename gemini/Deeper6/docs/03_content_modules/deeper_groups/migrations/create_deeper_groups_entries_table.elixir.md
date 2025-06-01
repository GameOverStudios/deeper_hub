# Migração Elixir: Criar Tabela `deeper_groups_entries`

Cria a tabela principal para os grupos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_groups_entries_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperGroupsEntriesTable do
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_groups_entries...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_groups_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author_profile_id INTEGER NOT NULL,
      category_id INTEGER,
      title TEXT NOT NULL,
      group_name TEXT NOT NULL UNIQUE,
      description TEXT,
      cover_image_file_id INTEGER,
      avatar_image_file_id INTEGER,
      privacy_type TEXT DEFAULT 'public' CHECK(privacy_type IN ('public', 'private', 'secret')),
      allow_join_requests INTEGER DEFAULT 1,
      allow_invites INTEGER DEFAULT 1,
      members_count INTEGER DEFAULT 0,
      posts_count INTEGER DEFAULT 0,
      views_count INTEGER DEFAULT 0,
      favorites_count INTEGER DEFAULT 0,
      status TEXT DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'suspended', 'hidden')),
      featured INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES deeper_groups_categories(id) ON DELETE SET NULL
    );
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_entries_author ON deeper_groups_entries(author_profile_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_entries_category ON deeper_groups_entries(category_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_entries_status ON deeper_groups_entries(status);
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_entries_privacy_type ON deeper_groups_entries(privacy_type);
    \"\"\"
    Repo.execute(sql)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_groups_entries...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_groups_entries;\"
    Repo.execute(sql)
  end
end
```