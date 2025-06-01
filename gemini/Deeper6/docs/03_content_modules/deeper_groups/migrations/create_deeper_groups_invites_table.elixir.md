# Migração Elixir: Criar Tabela `deeper_groups_invites`

Cria a tabela para convites de grupos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_groups_invites_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperGroupsInvitesTable do
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_groups_invites...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_groups_invites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL,
      inviter_profile_id INTEGER NOT NULL,
      invited_profile_id INTEGER,
      invited_email TEXT,
      invite_code TEXT UNIQUE,
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
    \"\"\"
    Repo.execute(sql)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_groups_invites...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_groups_invites;\"
    Repo.execute(sql)
  end
end
```