# Migração Elixir: Criar Tabela `sys_form_display_inputs`

Este módulo de migração Elixir cria a tabela `sys_form_display_inputs` no SQLite. Esta tabela mapeia quais campos (`sys_form_inputs`) são mostrados em um display de formulário específico (`sys_form_displays`), sua ordem e visibilidade ACL.

## Código da Migração (`lib/deeper/core/data/migrations/forms_engine/create_sys_form_display_inputs_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.FormsEngine.CreateSysFormDisplayInputsTable do
  @moduledoc \"Migração para criar a tabela sys_form_display_inputs.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_form_display_inputs...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_display_inputs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      display_name TEXT NOT NULL, -- Refere-se a sys_form_displays.display_name
      input_name TEXT NOT NULL, -- Refere-se a sys_form_inputs.name (do mesmo form object)
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
      active INTEGER NOT NULL DEFAULT 1,
      \"order\" INTEGER NOT NULL DEFAULT 0
    );
    -- A constraint UNIQUE no UNA é em (display_name, input_name)
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sfdi_display_input ON sys_form_display_inputs(display_name, input_name);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_display_inputs criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_form_display_inputs: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_form_display_inputs...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_display_inputs;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_display_inputs removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_form_display_inputs: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```