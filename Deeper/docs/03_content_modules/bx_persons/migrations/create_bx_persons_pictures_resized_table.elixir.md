# Migração Elixir: Criar Tabela `bx_persons_pictures_resized`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_pictures_resized` no banco de dados SQLite. Esta tabela armazena informações sobre as versões redimensionadas (thumbnails, etc.) das imagens de perfil.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_pictures_resized_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsPicturesResizedTable do
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

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_pictures_resized (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL, -- FK para bx_persons_data.id
      remote_id TEXT NOT NULL UNIQUE, -- ID do arquivo redimensionado
      -- original_picture_id INTEGER, -- Opcional: FK para bx_persons_pictures.id
      path TEXT NOT NULL,
      file_name TEXT NOT NULL,
      mime_type TEXT NOT NULL,
      ext TEXT NOT NULL,
      size INTEGER NOT NULL,
      added INTEGER NOT NULL, -- Unix Timestamp
      modified INTEGER NOT NULL, -- Unix Timestamp
      private INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (profile_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE
      -- FOREIGN KEY (original_picture_id) REFERENCES bx_persons_pictures(id) ON DELETE SET NULL -- Opcional
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_pictures_resized_profile_id ON bx_persons_pictures_resized(profile_id);
    -- CREATE INDEX IF NOT EXISTS idx_bx_ppr_original_id ON bx_persons_pictures_resized(original_picture_id); -- Se usar original_picture_id
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

## Notas:

*   Similar a `bx_persons_pictures`, `profile_id` referencia `bx_persons_data(id)`.
*   A coluna `original_picture_id` (comentada) poderia ser usada para ligar a imagem redimensionada à sua original em `bx_persons_pictures`, mas isso adiciona complexidade e pode não ser estritamente necessário se `remote_id` for suficiente para identificar os arquivos. O UNA pode ter uma lógica implícita ou baseada em convenção de nomenclatura para associar originais e redimensionados.
*   Esta tabela deve ser criada após `bx_persons_data`.