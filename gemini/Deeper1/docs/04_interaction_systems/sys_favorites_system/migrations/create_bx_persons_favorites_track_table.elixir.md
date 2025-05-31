# Migração Elixir: Criar Tabela `bx_persons_favorites_track` (Rastreamento de Favoritos para Pessoas)

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_favorites_track` no banco de dados SQLite. Esta tabela armazena os registros de quais usuários favoritaram quais perfis de pessoas.

Esta é um exemplo de uma tabela `table_track` referenciada em `sys_objects_favorite`.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_favorites_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsFavoritesTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela de rastreamento de favoritos bx_persons_favorites_track.
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

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_favorites_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para bx_persons_data.id
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) que favoritou
      date INTEGER NOT NULL, -- Unix Timestamp
      -- Adicionando UNIQUE constraint para garantir que um usuário só pode favoritar um item uma vez
      UNIQUE (object_id, author_id)
    );

    -- Índice para buscar favoritos de um usuário
    CREATE INDEX IF NOT EXISTS idx_bx_persons_fav_track_author_object ON bx_persons_favorites_track(author_id, object_id);
    -- Índice para buscar quem favoritou um objeto (se is_public for true)
    CREATE INDEX IF NOT EXISTS idx_bx_persons_fav_track_object_author ON bx_persons_favorites_track(object_id, author_id);
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

## Notas:

*   `object_id`: Corresponde ao `id` da tabela `bx_persons_data` (o perfil que foi favoritado).
*   `author_id`: Corresponde ao `id` da tabela `sys_profiles` do usuário que favoritou.
*   `date`: Timestamp de quando o item foi favoritado.
*   A restrição `UNIQUE (object_id, author_id)` é crucial para a lógica de favoritar/desfavoritar.