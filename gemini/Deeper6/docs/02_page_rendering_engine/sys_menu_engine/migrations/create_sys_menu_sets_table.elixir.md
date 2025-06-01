# Migração Elixir: Criar Tabela `sys_menu_sets`

Este módulo de migração Elixir é responsável por criar a tabela `sys_menu_sets` no banco de dados SQLite. Esta tabela armazena definições de conjuntos de itens de menu.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_menu_sets_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysMenuSetsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_menu_sets.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_menu_sets...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_menu_sets (
      set_name TEXT PRIMARY KEY,
      module TEXT NOT NULL,
      title TEXT NOT NULL,
      deletable INTEGER NOT NULL DEFAULT 1
    );
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_menu_sets criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_menu_sets: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

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