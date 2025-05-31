# Migração Elixir: Criar Tabela `sys_form_pre_lists`

Este módulo de migração Elixir é responsável por criar a tabela `sys_form_pre_lists` no banco de dados SQLite. Esta tabela define nomes (chaves) para listas de valores pré-definidos que podem ser usados em campos de formulário como `select`, `radio_set`, `checkbox_set`.

## Código da Migração (`lib/deeper/forms/migrations/create_sys_form_pre_lists_table.ex`)

```elixir
defmodule Deeper.Forms.Migrations.CreateSysFormPreListsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_form_pre_lists.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_form_pre_lists.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_form_pre_lists...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_pre_lists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      module TEXT NOT NULL,
      \"key\" TEXT NOT NULL UNIQUE, -- Chave única da lista, ex: 'Country', 'bx_persons_genders'
      title TEXT NOT NULL, -- Título da lista (pode ser chave de linguagem)
      use_for_sets INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      extendable INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
      -- FK para module (sys_modules.name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_form_pre_lists_key ON sys_form_pre_lists(\"key\");
    CREATE INDEX IF NOT EXISTS idx_sys_form_pre_lists_module ON sys_form_pre_lists(module);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_form_pre_lists criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_form_pre_lists: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_form_pre_lists.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_form_pre_lists...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_pre_lists;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_form_pre_lists removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_form_pre_lists: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT`.
*   `module`, `key`, `title`: `VARCHAR` (MySQL) -> `TEXT`. `\"key\"` está entre aspas e é `UNIQUE`.
*   `use_for_sets`, `extendable`: `TINYINT(4) UNSIGNED` (MySQL) -> `INTEGER` (0 ou 1).