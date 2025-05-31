# Migração Elixir: Criar Tabela `sys_options`

Este módulo de migração Elixir é responsável por criar a tabela `sys_options` no banco de dados SQLite. Esta é a tabela principal que armazena cada configuração individual do sistema, seu valor, tipo e outros metadados. Ela está ligada a `sys_options_categories`.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_options_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysOptionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_options.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_options.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_options...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_options (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL,
      name TEXT NOT NULL UNIQUE,
      caption TEXT NOT NULL,
      info TEXT,
      value TEXT, -- Armazena o valor da opção como texto
      type TEXT NOT NULL DEFAULT 'text' CHECK(type IN (
        'value', 'digit', 'text', 'code', 'checkbox', 'select', 'combobox',
        'file', 'image', 'list', 'rlist', 'rgb', 'rgba', 'datetime'
      )),
      extra TEXT, -- Para 'select', 'list', etc. (ex: nomes de sys_form_pre_lists)
      \"check\" TEXT, -- Nome de função de validação
      check_params TEXT,
      check_error TEXT,
      \"order\" INTEGER DEFAULT 0,
      FOREIGN KEY (category_id) REFERENCES sys_options_categories(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_options_category_id ON sys_options(category_id);
    CREATE INDEX IF NOT EXISTS idx_sys_options_name ON sys_options(name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_options: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_options.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_options...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_options;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_options: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `category_id`: `INT(11) UNSIGNED` (MySQL) -> `INTEGER` (SQLite). Chave estrangeira para `sys_options_categories.id`.
*   `name`, `caption`, `info`, `value`, `extra`, `check`, `check_params`, `check_error`: `VARCHAR` ou `TEXT`/`MEDIUMTEXT` (MySQL) -> `TEXT` (SQLite). `name` é `UNIQUE`.
*   `type`: `ENUM(...)` (MySQL) -> `TEXT CHECK(type IN (...))` (SQLite).
*   `order`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). Colocado entre aspas (`\"order\"`).
*   **Chave Estrangeira:** Definida para `category_id`.