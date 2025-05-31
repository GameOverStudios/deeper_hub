# Migração Elixir: Criar Tabela `deeper_comments`

Este módulo de migração Elixir cria a tabela principal `deeper_comments` no SQLite. Esta tabela armazena todos os comentários do sistema de forma unificada.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/comments/create_deeper_comments_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Comments.CreateDeeperCommentsTable do
  @moduledoc \"Migração para criar a tabela deeper_comments.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_comments...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      system_name TEXT NOT NULL,
      object_id INTEGER NOT NULL,
      author_profile_id INTEGER NOT NULL,
      parent_id INTEGER DEFAULT 0,
      level INTEGER NOT NULL DEFAULT 0,
      text TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'spam', 'deleted_by_user', 'deleted_by_admin')),
      votes INTEGER NOT NULL DEFAULT 0,
      score INTEGER NOT NULL DEFAULT 0,
      reactions_up INTEGER NOT NULL DEFAULT 0,
      reactions_down INTEGER NOT NULL DEFAULT 0,
      reports INTEGER NOT NULL DEFAULT 0,
      replies_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (parent_id) REFERENCES deeper_comments(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_comments_system_object ON deeper_comments(system_name, object_id, status, created_at);
    CREATE INDEX IF NOT EXISTS idx_deeper_comments_author_id ON deeper_comments(author_profile_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_comments_parent_id ON deeper_comments(parent_id);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_comments criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_comments: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_comments...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_comments;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_comments removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_comments: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```