# Migração Elixir: Criar Tabela `deeper_groups_members`

Cria a tabela para os membros dos grupos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_groups_members_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperGroupsMembersTable do
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_groups_members...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_groups_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL,
      role TEXT DEFAULT 'member' CHECK(role IN ('admin', 'moderator', 'member')),
      status TEXT DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'invited', 'banned')),
      joined_at INTEGER NOT NULL,
      promoted_by_profile_id INTEGER,
      UNIQUE (group_id, profile_id),
      FOREIGN KEY (group_id) REFERENCES deeper_groups_entries(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (promoted_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
    );
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_members_group_id_role_status ON deeper_groups_members(group_id, role, status);
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_members_profile_id_group_id ON deeper_groups_members(profile_id, group_id);
    \"\"\"
    Repo.execute(sql)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_groups_members...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_groups_members;\"
    Repo.execute(sql)
  end
end
```