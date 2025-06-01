# Migração gerada com ID único: V1748745503842 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsFavoritesTrackTable do
  # Migração gerada com ID único: V1748745503842 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_persons_favorites_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_favorites_track.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_favorites_track...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
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
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_favorites_track criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_favorites_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_favorites_track.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_favorites_track...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_favorites_track;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_favorites_track removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_favorites_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end