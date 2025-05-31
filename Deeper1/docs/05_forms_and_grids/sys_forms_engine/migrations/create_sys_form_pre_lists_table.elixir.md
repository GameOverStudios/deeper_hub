# Migração Elixir: Criar Tabela `sys_form_pre_lists`

Este módulo de migração Elixir cria a tabela `sys_form_pre_lists` no SQLite, que define chaves para listas de valores pré-definidos usadas em campos de formulário (selects, radios, etc.).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_form_pre_lists_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysFormPreListsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_form_pre_lists.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_form_pre_lists...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_pre_lists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      module TEXT NOT NULL DEFAULT '',
      \"key\" TEXT NOT NULL UNIQUE, -- Aspas para 'key'
      title TEXT NOT NULL, -- Chave de tradução para o título da lista
      use_for_sets INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      extendable INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
    );
    CREATE INDEX IF NOT EXISTS idx_sys_form_pre_lists_key ON sys_form_pre_lists(\"key\");
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_form_pre_lists...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_pre_lists;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```