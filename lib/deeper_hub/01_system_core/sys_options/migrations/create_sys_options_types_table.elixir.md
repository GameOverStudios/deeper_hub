# Migração Elixir: Criar Tabela `sys_options_types`

Este módulo de migração Elixir é responsável por criar a tabela `sys_options_types` no banco de dados SQLite. Esta tabela define os agrupamentos de alto nível para as configurações do sistema.

## Código da Migração (`lib/deeper/core/data/migrations/options/create_sys_options_types_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.Options.CreateSysOptionsTypesTable do
  @moduledoc \"Migração para criar a tabela sys_options_types.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_options_types...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_options_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      \"group\" TEXT NOT NULL,
      name TEXT NOT NULL UNIQUE,
      caption TEXT NOT NULL,
      icon TEXT,
      \"order\" INTEGER DEFAULT 0
    );
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok; {:error, reason} -> {:error, reason}
    end
    |> tap(fn
      :ok -> Logger.info(\"Tabela sys_options_types criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_options_types: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_options_types...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_options_types;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok; {:error, reason} -> {:error, reason}
    end
    |> tap(fn
      :ok -> Logger.info(\"Tabela sys_options_types removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_options_types: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```