# Migração Elixir: Criar Tabela `sys_objects_form`

Este módulo de migração Elixir cria a tabela `sys_objects_form` no SQLite, que define as propriedades de cada formulário no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_form_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsFormTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_form.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_form...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_form (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      title TEXT NOT NULL,
      action TEXT NOT NULL,
      form_attrs TEXT,
      submit_name TEXT NOT NULL,
      \"table\" TEXT NOT NULL,
      \"key\" TEXT NOT NULL,
      uri TEXT,
      uri_title TEXT,
      params TEXT,
      deletable INTEGER NOT NULL DEFAULT 1,
      active INTEGER NOT NULL DEFAULT 0, -- No schema original é 0, mas 1 faz mais sentido para ativo
      parent_form TEXT DEFAULT '',
      override_class_name TEXT,
      override_class_file TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_sys_objects_form_object ON sys_objects_form(object);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_form...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_form;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```