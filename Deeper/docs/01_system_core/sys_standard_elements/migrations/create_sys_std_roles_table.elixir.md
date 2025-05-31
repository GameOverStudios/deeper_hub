# Migração Elixir: Criar Tabela `sys_std_roles`

Este módulo de migração Elixir cria a tabela `sys_std_roles` no SQLite, que define papéis padrão do sistema, complementando ou sobrepondo-se aos Níveis de ACL.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_std_roles_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStdRolesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_std_roles.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_std_roles...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_std_roles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE, -- Nome programático do papel, ex: 'admin', 'moderator', 'member'
      title TEXT NOT NULL, -- Chave de tradução para o título do papel
      description TEXT NOT NULL DEFAULT '', -- Chave de tradução para a descrição
      active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      \"order\" INTEGER NOT NULL DEFAULT 0
    );
    -- FULLTEXT KEY searchable (title, description) -- Omitido para SQLite inicial
    CREATE INDEX IF NOT EXISTS idx_sys_std_roles_name ON sys_std_roles(name);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_std_roles...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_std_roles;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```