# Migração Elixir: Criar Tabela `sys_form_displays`

Este módulo de migração Elixir cria a tabela `sys_form_displays` no SQLite. Esta tabela permite que um único objeto de formulário (`sys_objects_form`) tenha diferentes \"visualizações\" ou \"modos\" (ex: um display para adicionar, outro para editar, outro para visualização apenas).

## Código da Migração (`lib/deeper/core/data/migrations/forms_engine/create_sys_form_displays_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.FormsEngine.CreateSysFormDisplaysTable do
  @moduledoc \"Migração para criar a tabela sys_form_displays.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_form_displays...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_displays (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      display_name TEXT NOT NULL,
      module TEXT NOT NULL,
      object TEXT NOT NULL, -- FK (lógica) para sys_objects_form.object
      title TEXT NOT NULL,
      view_mode INTEGER NOT NULL DEFAULT 0
    );
    -- A constraint UNIQUE no UNA é em (object, display_name)
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sfd_object_display ON sys_form_displays(object, display_name);
    -- Se display_name for globalmente único, então UNIQUE(display_name)
    -- CREATE UNIQUE INDEX IF NOT EXISTS uidx_sfd_display_name ON sys_form_displays(display_name);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_displays criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_form_displays: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_form_displays...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_displays;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_displays removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_form_displays: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```