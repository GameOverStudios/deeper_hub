# Migração Elixir: Criar Tabela `sys_objects_favorite`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_favorite` no banco de dados SQLite. Esta tabela armazena as configurações para diferentes instâncias de sistemas de \"favoritos\".

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_favorite_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsFavoriteTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_favorite.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_favorite.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_favorite...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_favorite (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      table_track TEXT NOT NULL,
      table_lists TEXT, -- Pode ser NULL se não usado
      pruning INTEGER NOT NULL DEFAULT 0,
      is_on INTEGER NOT NULL DEFAULT 1,
      is_undo INTEGER NOT NULL DEFAULT 1,
      is_public INTEGER NOT NULL DEFAULT 1,
      base_url TEXT,
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_author TEXT, -- Geralmente não usado para favoritos
      trigger_field_count TEXT,
      class_name TEXT, -- Específico do UNA PHP
      class_file TEXT -- Específico do UNA PHP
    );
    CREATE INDEX IF NOT EXISTS idx_sys_objects_favorite_name ON sys_objects_favorite(name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_favorite criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_favorite: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_favorite.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_favorite...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_favorite;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_favorite removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_favorite: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `name`: Identificador único para o sistema de favoritos (ex: `bx_persons`).
*   `table_track`: Nome da tabela SQL que armazena os registros de favoritos (ex: `bx_persons_favorites_track`).
*   `trigger_table`, `trigger_field_id`, `trigger_field_count`: Usados para atualizar o contador de favoritos na tabela do conteúdo pai.