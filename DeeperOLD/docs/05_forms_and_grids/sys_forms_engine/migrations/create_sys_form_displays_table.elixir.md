# Migração Elixir: Criar Tabela `sys_form_displays`

Este módulo de migração Elixir cria a tabela `sys_form_displays` no SQLite, que define diferentes \"exibições\" ou agrupamentos de campos para um formulário.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_form_displays_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysFormDisplaysTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_form_displays.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_form_displays...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_displays (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      display_name TEXT NOT NULL,
      module TEXT NOT NULL,
      object TEXT NOT NULL, -- FK para sys_objects_form.object
      title TEXT NOT NULL, -- Chave de tradução
      view_mode INTEGER NOT NULL DEFAULT 0, -- Não usado extensivamente no UNA core, pode ser omitido
      UNIQUE(object, display_name)
    );
    CREATE INDEX IF NOT EXISTS idx_sys_form_displays_obj_disp ON sys_form_displays(object, display_name);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_form_displays...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_displays;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```