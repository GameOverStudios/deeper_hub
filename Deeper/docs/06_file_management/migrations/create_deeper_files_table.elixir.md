# Migração Elixir: Criar Tabela `deeper_files`

Este módulo de migração Elixir cria a tabela `deeper_files` no SQLite. Esta tabela unificada armazena os metadados para todos os arquivos carregados no sistema \"Deeper\".

## Código da Migração (`lib/deeper/core/data/migrations/file_management/create_deeper_files_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.FileManagement.CreateDeeperFilesTable do
  @moduledoc \"Migração para criar a tabela deeper_files.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_files...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_files (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uploader_profile_id INTEGER NOT NULL,
      storage_backend_name TEXT NOT NULL,
      original_filename TEXT NOT NULL,
      stored_filename TEXT NOT NULL UNIQUE,
      stored_path TEXT,
      mime_type TEXT NOT NULL,
      size_bytes INTEGER NOT NULL,
      extension TEXT,
      meta_data TEXT, -- JSON
      is_private INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (uploader_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE
      -- FK lógica para storage_backend_name -> deeper_storage_backends.storage_name
    );

    CREATE INDEX IF NOT EXISTS idx_df_uploader_id ON deeper_files(uploader_profile_id);
    CREATE INDEX IF NOT EXISTS idx_df_storage_path_filename ON deeper_files(storage_backend_name, stored_path, stored_filename);
    -- O índice em stored_filename é criado pela constraint UNIQUE.
    \"\"\"
    # Nota: Uma FK para storage_backend_name -> deeper_storage_backends.storage_name seria ideal,
    # mas storage_name não é a PK de deeper_storage_backends. SQLite permite FK para colunas UNIQUE.
    # Se storage_name for UNIQUE, pode ser usada. Caso contrário, a integridade é lógica.

    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_files criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_files: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_files...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_files;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_files removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_files: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```