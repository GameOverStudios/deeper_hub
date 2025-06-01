# Migração Elixir: Criar Tabela `deeper_groups_content_feed`

Cria a tabela para o feed de conteúdo dentro dos grupos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_groups_content_feed_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperGroupsContentFeedTable do
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_groups_content_feed...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_groups_content_feed (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL,
      author_profile_id INTEGER NOT NULL,
      content_text TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      comments_count INTEGER DEFAULT 0,
      likes_count INTEGER DEFAULT 0,
      FOREIGN KEY (group_id) REFERENCES deeper_groups_entries(id) ON DELETE CASCADE,
      FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_content_feed_group_id_created_at ON deeper_groups_content_feed(group_id, created_at DESC);
    \"\"\"
    Repo.execute(sql)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_groups_content_feed...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_groups_content_feed;\"
    Repo.execute(sql)
  end
end
```