# Migração Elixir: Criar Tabela `sys_form_inputs`

Este módulo de migração Elixir cria a tabela `sys_form_inputs` no SQLite, que define cada campo de entrada individual para os formulários definidos em `sys_objects_form`.

## Código da Migração (`lib/deeper/core/data/migrations/forms_engine/create_sys_form_inputs_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.FormsEngine.CreateSysFormInputsTable do
  @moduledoc \"Migração para criar a tabela sys_form_inputs.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_form_inputs...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_inputs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- Nome do sys_objects_form ao qual este input pertence
      module TEXT NOT NULL,
      name TEXT NOT NULL,
      value TEXT NOT NULL DEFAULT '',
      values_list TEXT,
      checked INTEGER NOT NULL DEFAULT 0,
      type TEXT NOT NULL CHECK(type IN (
        'text', 'textarea', 'password', 'number', 'range', 'date', 'datetime_local', 'time', 'email', 'url', 'tel',
        'checkbox', 'radio', 'select', 'select_multiple', 'file', 'hidden', 'submit', 'button', 'reset',
        'block_header', 'block_end', 'fieldset_start', 'fieldset_end', 'div_start', 'div_end',
        'input_set', 'custom', 'captcha', 'value', 'slider', 'doublerange',
        'button_group', 'location', 'recurring', 'checkbox_set'
      )),
      caption_system TEXT,
      caption TEXT,
      info TEXT,
      help TEXT,
      icon TEXT,
      required INTEGER NOT NULL DEFAULT 0,
      unique_input INTEGER NOT NULL DEFAULT 0,
      collapsed INTEGER NOT NULL DEFAULT 0,
      html INTEGER NOT NULL DEFAULT 0,
      privacy INTEGER NOT NULL DEFAULT 0,
      rateable TEXT,
      attrs TEXT,
      attrs_tr TEXT,
      attrs_wrapper TEXT,
      checker_func TEXT,
      checker_params TEXT,
      checker_error TEXT,
      db_pass TEXT,
      db_params TEXT,
      editable INTEGER NOT NULL DEFAULT 1,
      deletable INTEGER NOT NULL DEFAULT 1
    );
    -- Um índice UNIQUE em (object, name) seria ideal se name for único por form object.
    CREATE INDEX IF NOT EXISTS idx_sfi_object_name ON sys_form_inputs(object, name);
    CREATE INDEX IF NOT EXISTS idx_sfi_module ON sys_form_inputs(module);
    -- No UNA, a constraint UNIQUE é (object, name(127))
    -- Para SQLite, um índice UNIQUE pode ser criado:
    -- CREATE UNIQUE INDEX IF NOT EXISTS uidx_sfi_object_name ON sys_form_inputs(object, name);
    -- Adicionando o UNIQUE index:
    -- (Este statement precisa ser separado ou a tabela recriada se já existia sem ele)
    -- Para simplificar a migração inicial, deixamos como INDEX normal.
    -- A lógica da aplicação ou uma migração posterior pode impor a unicidade.
    \"\"\"
    # Para adicionar UNIQUE index se a tabela já foi criada sem:
    # sql_unique_index = \"CREATE UNIQUE INDEX IF NOT EXISTS uidx_sfi_object_name ON sys_form_inputs(object, name);\"
    # Repo.execute(sql_unique_index) após criar a tabela.

    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_inputs criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_form_inputs: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_form_inputs...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_inputs;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_inputs removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_form_inputs: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```