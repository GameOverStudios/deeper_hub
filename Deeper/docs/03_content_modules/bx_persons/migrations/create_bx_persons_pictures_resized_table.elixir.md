# Migração Elixir: Criar Tabela `bx_persons_pictures_resized`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_pictures_resized` no banco de dados SQLite. Esta tabela armazena informações sobre as versões redimensionadas das imagens da galeria de um perfil de pessoa.

**Dependências:** `sys_profiles`

## Código da Migração (`lib/deeper/content/persons/migrations/create_bx_persons_pictures_resized_table.ex`)

```elixir
defmodule Deeper.Content.Persons.Migrations.CreateBxPersonsPicturesResizedTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_pictures_resized.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_pictures_resized.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_pictures_resized...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_pictures_resized (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL, -- FK para sys_profiles.id
      remote_id TEXT NOT NULL UNIQUE, -- ID do arquivo redimensionado no storage
      path TEXT NOT NULL,
      file_name TEXT NOT NULL,
      mime_type TEXT NOT NULL,
      ext TEXT NOT NULL,
      size INTEGER NOT NULL,
      added INTEGER NOT NULL, -- Unix Timestamp
      modified INTEGER NOT NULL, -- Unix Timestamp
      private INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_pictures_resized_profile_id ON bx_persons_pictures_resized(profile_id);
    -- remote_id já é UNIQUE pela definição da tabela
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_pictures_resized criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_pictures_resized: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_pictures_resized.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_pictures_resized...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_pictures_resized;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_pictures_resized removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_pictures_resized: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   Similar à `bx_persons_pictures`, com `remote_id` sendo `NOT NULL UNIQUE` diretamente na definição da coluna.
*   **Chave Estrangeira:** Definida para `profile_id`.