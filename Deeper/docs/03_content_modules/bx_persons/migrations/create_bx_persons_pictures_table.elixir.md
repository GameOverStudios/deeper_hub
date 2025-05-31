# Migração Elixir: Criar Tabela `bx_persons_pictures`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_pictures` no banco de dados SQLite. Esta tabela armazena informações sobre as imagens originais dos avatares e outras fotos associadas aos perfis de pessoas.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_pictures_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsPicturesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_pictures.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_pictures.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_pictures...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_pictures (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL, -- FK para bx_persons_data.id
      remote_id TEXT NOT NULL UNIQUE,
      path TEXT NOT NULL,
      file_name TEXT NOT NULL,
      mime_type TEXT NOT NULL,
      ext TEXT NOT NULL,
      size INTEGER NOT NULL,
      dimensions TEXT, -- Ex: \"800x600\"
      added INTEGER NOT NULL, -- Unix Timestamp
      modified INTEGER NOT NULL, -- Unix Timestamp
      private INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (profile_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_pictures_profile_id ON bx_persons_pictures(profile_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_pictures criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_pictures: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_pictures.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_pictures...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_pictures;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_pictures removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_pictures: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A coluna `profile_id` referencia `bx_persons_data(id)` e utiliza `ON DELETE CASCADE` para que as imagens associadas sejam removidas se o perfil da pessoa for deletado.
*   `remote_id` é um identificador único para o arquivo no sistema de armazenamento.
*   Esta tabela deve ser criada após `bx_persons_data`.