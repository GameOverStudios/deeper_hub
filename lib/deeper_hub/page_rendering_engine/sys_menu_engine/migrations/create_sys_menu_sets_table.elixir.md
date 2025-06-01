# Migração Elixir: Criar Tabela `sys_menu_sets`

Este módulo de migração Elixir é responsável por criar a tabela `sys_menu_sets` no banco de dados SQLite. Esta tabela define \"conjuntos\" lógicos de itens de menu, que são então usados por \"objetos de menu\".

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_menu_sets_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysMenuSetsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_menu_sets.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_menu_sets.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_menu_sets...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_menu_sets (
      set_name TEXT PRIMARY KEY NOT NULL,
      module TEXT NOT NULL,
      title TEXT NOT NULL,
      deletable INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
    );

    CREATE INDEX IF NOT EXISTS idx_sys_menu_sets_module ON sys_menu_sets(module);
    \"\"\"
    -- Nota: a FK para sys_modules.name na coluna 'module' será conceitual,
    -- pois a definição estrita de FKs entre todas as tabelas pode ser complexa
    -- de gerenciar na ordem de migração inicial. A lógica da aplicação pode impor isso.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_menu_sets criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_menu_sets: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_menu_sets.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_menu_sets...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_menu_sets;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_menu_sets removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_menu_sets: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `set_name`: `VARCHAR(64)` com `PRIMARY KEY` (MySQL) -> `TEXT PRIMARY KEY NOT NULL` (SQLite).
*   `module`, `title`: `VARCHAR` (MySQL) -> `TEXT` (SQLite).
*   `deletable`: `TINYINT(4)` (MySQL) -> `INTEGER` (SQLite), (0 ou 1).