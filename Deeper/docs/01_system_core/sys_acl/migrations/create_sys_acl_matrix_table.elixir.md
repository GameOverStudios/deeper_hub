# Migração Elixir: Criar Tabela `sys_acl_matrix`

Este módulo de migração Elixir cria a tabela `sys_acl_matrix` no SQLite, que é a matriz de permissões principal, ligando níveis de ACL a ações e definindo as condições da permissão.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_matrix_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclMatrixTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_matrix.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_matrix...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_matrix (
      IDLevel INTEGER NOT NULL, -- FK para sys_acl_levels.ID
      IDAction INTEGER NOT NULL, -- FK para sys_acl_actions.ID
      AllowedCount INTEGER, -- Pode ser NULL (ilimitado) ou 0 (nenhum) ou >0 (contagem)
      AllowedPeriodLen INTEGER, -- Em dias, pode ser NULL
      AllowedPeriodStart TEXT, -- DATETIME como TEXT, pode ser NULL
      AllowedPeriodEnd TEXT, -- DATETIME como TEXT, pode ser NULL
      AdditionalParamValue TEXT, -- Pode ser NULL
      PRIMARY KEY (IDLevel, IDAction)
      -- FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE,
      -- FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE
    );
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_matrix...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_acl_matrix;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```