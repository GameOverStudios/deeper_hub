# Migração Elixir: Criar Tabela `sys_form_inputs`

Este módulo de migração Elixir cria a tabela `sys_form_inputs` no SQLite, que define os campos individuais de cada formulário.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_form_inputs_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysFormInputsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_form_inputs.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_form_inputs...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_inputs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- FK para sys_objects_form.object
      module TEXT NOT NULL,
      name TEXT NOT NULL,
      value TEXT NOT NULL DEFAULT '',
      \"values\" TEXT NOT NULL DEFAULT '', -- Aspas para 'values'
      checked INTEGER NOT NULL DEFAULT 0,
      type TEXT NOT NULL,
      caption_system TEXT NOT NULL,
      caption TEXT NOT NULL,
      info TEXT,
      help TEXT,
      icon TEXT,
      required INTEGER NOT NULL DEFAULT 0,
      unique_input INTEGER NOT NULL DEFAULT 0, -- Renomeado de 'unique'
      collapsed INTEGER NOT NULL DEFAULT 0,
      html INTEGER NOT NULL DEFAULT 0,
      privacy INTEGER NOT NULL DEFAULT 0,
      rateable TEXT DEFAULT '',
      attrs TEXT,
      attrs_tr TEXT,
      attrs_wrapper TEXT,
      checker_func TEXT,
      checker_params TEXT,
      checker_error TEXT,
      db_pass TEXT,
      db_params TEXT,
      editable INTEGER NOT NULL DEFAULT 1,
      deletable INTEGER NOT NULL DEFAULT 1,
      UNIQUE(object, name)
      -- FOREIGN KEY (object) REFERENCES sys_objects_form(object) ON DELETE CASCADE -- Opcional, mas recomendado
    );
    CREATE INDEX IF NOT EXISTS idx_sys_form_inputs_object_name ON sys_form_inputs(object, name);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_form_inputs...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_inputs;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```