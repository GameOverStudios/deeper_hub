# Migração Elixir: Criar Tabela `deeper_group_members`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_group_members` no banco de dados SQLite. Esta tabela gerencia a associação de perfis de usuários aos grupos, incluindo seus papéis e status de membresia.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_group_members_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperGroupMembersTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_group_members.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_group_members.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_group_members...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_group_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL,
      role TEXT NOT NULL DEFAULT 'member' CHECK(role IN ('member', 'moderator', 'admin', 'owner')),
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'invited', 'banned', 'left')),
      joined_at INTEGER NOT NULL,
      approved_by_profile_id INTEGER,
      invited_by_profile_id INTEGER,
      banned_by_profile_id INTEGER,
      ban_reason TEXT,
      notifications_level TEXT NOT NULL DEFAULT 'all' CHECK(notifications_level IN ('all', 'highlights', 'none')),
      UNIQUE (group_id, profile_id),
      FOREIGN KEY (group_id) REFERENCES deeper_groups(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (approved_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
      FOREIGN KEY (invited_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
      FOREIGN KEY (banned_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_dgm_group_id_role ON deeper_group_members(group_id, role);
    CREATE INDEX IF NOT EXISTS idx_dgm_group_id_status ON deeper_group_members(group_id, status);
    CREATE INDEX IF NOT EXISTS idx_dgm_profile_id_status ON deeper_group_members(profile_id, status);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_group_members criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_group_members: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_group_members.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_group_members...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_group_members;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_group_members removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_group_members: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela depende da existência de `deeper_groups` e `sys_profiles`.
*   A constraint `UNIQUE (group_id, profile_id)` é fundamental para garantir que um perfil não possa ser membro do mesmo grupo múltiplas vezes com diferentes status ou papéis (se o papel for parte da unicidade, ele deveria estar na chave `UNIQUE`). Aqui, um perfil é membro ou não, e seu papel/status é um atributo dessa membresia.
*   `ON DELETE CASCADE` para `group_id` e `profile_id` significa que se um grupo ou um perfil for excluído, as entradas de membresia correspondentes são automaticamente removidas.
*   As colunas `approved_by_profile_id`, `invited_by_profile_id`, e `banned_by_profile_id` rastreiam quem realizou essas ações, com `ON DELETE SET NULL` para que a informação da ação não seja perdida se o perfil do \"ator\" for excluído, mas a entrada de membresia em si permaneça.