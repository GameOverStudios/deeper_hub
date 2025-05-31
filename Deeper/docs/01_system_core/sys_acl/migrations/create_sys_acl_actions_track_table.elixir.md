# Migração Elixir: Criar Tabela `sys_acl_actions_track`

Este módulo de migração Elixir cria a tabela `sys_acl_actions_track` no SQLite, que rastreia o uso de ações ACL contáveis por membro.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_actions_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclActionsTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_actions_track.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_actions_track...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_actions_track (
      IDAction INTEGER NOT NULL, -- FK para sys_acl_actions.ID
      IDMember INTEGER NOT NULL, -- FK para sys_profiles.id
      ActionsLeft INTEGER NOT NULL DEFAULT 0,
      ValidSince TEXT, -- DATETIME como TEXT (início do período atual), pode ser NULL
      PRIMARY KEY (IDAction, IDMember)
      -- FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE,
      -- FOREIGN KEY (IDMember) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_actions_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_acl_actions_track;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```