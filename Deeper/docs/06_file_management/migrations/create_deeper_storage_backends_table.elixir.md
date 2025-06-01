# Migração Elixir: Criar Tabela `deeper_storage_backends`

Este módulo de migração Elixir cria a tabela `deeper_storage_backends` no SQLite. Esta tabela armazena as configurações para diferentes \"motores\" ou locais de armazenamento que o sistema \"Deeper\" pode utilizar.

## Código da Migração (`lib/deeper/core/data/migrations/file_management/create_deeper_storage_backends_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.FileManagement.CreateDeeperStorageBackendsTable do
  @moduledoc \"Migração para criar a tabela deeper_storage_backends.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_storage_backends...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_storage_backends (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      storage_name TEXT NOT NULL UNIQUE,
      engine TEXT NOT NULL CHECK(engine IN ('Local', 'S3', 'Other')),
      params TEXT, -- JSON com configurações específicas do engine
      base_url TEXT,
      is_default INTEGER NOT NULL DEFAULT 0,
      active INTEGER NOT NULL DEFAULT 1
    );
    \"\"\"
    # O índice em storage_name é criado pela constraint UNIQUE.
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_storage_backends criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_storage_backends: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_storage_backends...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_storage_backends;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_storage_backends removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_storage_backends: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```