# Migração Elixir: Criar Tabela `sys_localization_keys`

Este módulo de migração Elixir cria a tabela `sys_localization_keys` no SQLite, que armazena as chaves de string únicas para tradução.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_localization_keys_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysLocalizationKeysTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_localization_keys.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_localization_keys...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_keys (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      IDCategory INTEGER NOT NULL, -- FK para sys_localization_categories.ID
      \"Key\" TEXT NOT NULL UNIQUE, -- A chave de tradução, ex: '_sys_txt_welcome'. Aspas para \"Key\".
      FOREIGN KEY (IDCategory) REFERENCES sys_localization_categories(ID) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_sys_loc_keys_key ON sys_localization_keys(\"Key\");
    CREATE INDEX IF NOT EXISTS idx_sys_loc_keys_idcategory ON sys_localization_keys(IDCategory);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_localization_keys...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_localization_keys;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```