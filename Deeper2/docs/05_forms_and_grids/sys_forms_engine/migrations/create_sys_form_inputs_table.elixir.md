# Migração Elixir: Criar Tabela `sys_form_inputs`

Este módulo de migração Elixir é responsável por criar a tabela `sys_form_inputs` no banco de dados SQLite. Esta tabela define cada campo de entrada individual (input, textarea, select, etc.) que pertence a um formulário definido em `sys_objects_form`.

**Dependências:** `sys_objects_form`

## Código da Migração (`lib/deeper/forms/migrations/create_sys_form_inputs_table.ex`)

```elixir
defmodule Deeper.Forms.Migrations.CreateSysFormInputsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_form_inputs.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_form_inputs.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_form_inputs...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_inputs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- FK para sys_objects_form.object
      module TEXT NOT NULL,
      name TEXT NOT NULL,
      value TEXT,
      \"values\" TEXT,
      checked INTEGER NOT NULL DEFAULT 0,
      type TEXT NOT NULL DEFAULT 'text' CHECK(type IN (
        'text', 'textarea', 'password', 'select', 'select_multiple', 'checkbox', 'radio_set',
        'checkbox_set', 'hidden', 'file', 'button', 'reset', 'submit', 'image', 'button_group',
        'datepicker', 'datetime', 'number', 'email', 'url', 'slider', 'doublerange',
        'location', 'input_set', 'textarea_html', 'captcha', 'value', 'block_header', 'fieldset_start', 'fieldset_end', 'alert'
      )),
      caption_system TEXT,
      caption TEXT,
      info TEXT,
      help TEXT,
      icon TEXT,
      required INTEGER NOT NULL DEFAULT 0,
      \"unique\" INTEGER NOT NULL DEFAULT 0,
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
      deletable INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (object) REFERENCES sys_objects_form(object) ON DELETE CASCADE ON UPDATE CASCADE
      -- FK para module (sys_modules.name)
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_form_inputs_object_name ON sys_form_inputs(object, name);
    CREATE INDEX IF NOT EXISTS idx_sys_form_inputs_module ON sys_form_inputs(module);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_form_inputs criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_form_inputs: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_form_inputs.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_form_inputs...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_inputs;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_form_inputs removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_form_inputs: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT`.
*   `\"values\"` e `\"unique\"` estão entre aspas.
*   `type`: `ENUM` implícito no UNA, aqui com `CHECK` constraint.
*   **Índice Único:** `uidx_sys_form_inputs_object_name` garante que um nome de campo seja único dentro de um formulário.
*   **Chave Estrangeira:** `object` para `sys_objects_form.object`.