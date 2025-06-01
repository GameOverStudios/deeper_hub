# Migração Elixir: Criar Tabela `bx_persons_favorites_track`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_favorites_track` no banco de dados SQLite. Esta tabela rastreia quais perfis de usuários (`author_id`) favoritaram quais outros perfis de pessoas (`object_id`).

**Dependências:** `sys_profiles`

## Código da Migração (`lib/deeper/content/persons/migrations/create_bx_persons_favorites_track_table.ex`)

```elixir
defmodule Deeper.Content.Persons.Migrations.CreateBxPersonsFavoritesTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_favorites_track.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_favorites_track.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_favorites_track...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_favorites_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil favoritado)
      author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem favoritou)
      date INTEGER NOT NULL, -- Unix Timestamp
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    -- O índice `id (object_id,author_id)` do UNA original é coberto pela PK e/ou um UNIQUE.
    -- Para garantir que um autor não favorite o mesmo objeto múltiplas vezes:
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_fav_track_object_author ON bx_persons_favorites_track(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_fav_track_author_id ON bx_persons_favorites_track(author_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_favorites_track criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_favorites_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_favorites_track.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_favorites_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_favorites_track;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_favorites_track removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_favorites_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `object_id`, `author_id`, `date`: `INT` (MySQL) -> `INTEGER` (SQLite). `date` é um Timestamp Unix.
*   **Índice Único:** Um índice `UNIQUE` em `(object_id, author_id)` é adicionado para garantir a integridade (um usuário não pode favoritar o mesmo perfil múltiplas vezes).
*   **Chaves Estrangeiras:** Definidas para `object_id` e `author_id`, ambas referenciando `sys_profiles.id`.