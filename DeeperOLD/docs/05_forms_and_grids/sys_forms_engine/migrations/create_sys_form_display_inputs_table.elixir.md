# Migração Elixir: Criar Tabela `sys_form_display_inputs`

Este módulo de migração Elixir cria a tabela `sys_form_display_inputs` no SQLite. Esta tabela crucial liga campos de formulário (`sys_form_inputs`) a uma exibição específica (`sys_form_displays`) e controla a visibilidade do campo com base nos níveis de ACL.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_form_display_inputs_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysFormDisplayInputsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_form_display_inputs.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_form_display_inputs...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_display_inputs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      display_name TEXT NOT NULL, -- Referencia sys_form_displays.display_name (e implicitamente o form object)
      input_name TEXT NOT NULL, -- Referencia sys_form_inputs.name
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Máscara de bits ACL
      active INTEGER NOT NULL DEFAULT 0, -- No schema UNA é 0, mas 1 para 'parte da exibição' faz sentido
      \"order\" INTEGER NOT NULL DEFAULT 0,
      UNIQUE(display_name, input_name)
      -- FKs para display_name (composto com o form_object de sys_form_displays) e input_name (composto com form_object)
      -- seriam complexas. A lógica da aplicação garante a integridade.
    );
    CREATE INDEX IF NOT EXISTS idx_sys_form_display_inputs_disp_input ON sys_form_display_inputs(display_name, input_name);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_form_display_inputs...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_display_inputs;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```