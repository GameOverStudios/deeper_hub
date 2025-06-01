# Migração Elixir: Criar Tabela `bx_organizations_members` (Opcional)

Este módulo de migração Elixir é responsável por criar a tabela `bx_organizations_members` no banco de dados SQLite. Esta tabela gerencia a associação de múltiplos perfis (usuários) a uma organização, com papéis específicos.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_organizations_members_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxOrganizationsMembersTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_organizations_members.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_organizations_members.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_organizations_members...\", module: __MODULE__)

    # Usando a alternativa com UNIQUE constraint para (org_id, profile_id)
    # e um 'id' autoincrementável separado para a tabela de junção.
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_organizations_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      org_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL,
      role TEXT NOT NULL DEFAULT 'member' CHECK(role IN ('admin', 'editor', 'member')),
      added INTEGER NOT NULL, -- Unix Timestamp

      UNIQUE (org_id, profile_id),
      FOREIGN KEY (org_id) REFERENCES bx_organizations_data(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_org_members_org_id ON bx_organizations_members(org_id);
    CREATE INDEX IF NOT EXISTS idx_bx_org_members_profile_id ON bx_organizations_members(profile_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_organizations_members criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_organizations_members: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_organizations_members.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_organizations_members...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS bx_organizations_members;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_organizations_members removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_organizations_members: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```