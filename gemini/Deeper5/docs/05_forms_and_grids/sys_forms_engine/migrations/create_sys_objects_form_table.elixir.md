# Migração Elixir: Criar Tabela `sys_objects_form`

Este módulo de migração Elixir cria a tabela `sys_objects_form` no SQLite, que define as propriedades de cada objeto de formulário no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/forms_engine/create_sys_objects_form_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.FormsEngine.CreateSysObjectsFormTable do
  @moduledoc \"Migração para criar a tabela sys_objects_form.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

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
      table_name TEXT NOT NULL,
      key_column TEXT NOT NULL,
      uri_column TEXT,
      uri_title_column TEXT,
      params TEXT,
      deletable INTEGER NOT NULL DEFAULT 1,
      active INTEGER NOT NULL DEFAULT 1,
      parent_form TEXT,
      override_class_name TEXT,
      override_class_file TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_sof_module ON sys_objects_form(module);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_objects_form criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_objects_form: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_objects_form...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_form;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_objects_form removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_objects_form: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```