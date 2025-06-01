# Migração gerada com ID único: V1748745503874 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsViewsTrackTable do
  # Migração gerada com ID único: V1748745503874 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_persons_views_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_views_track.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_views_track...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_views_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil que foi visto)
      viewer_id INTEGER NOT NULL DEFAULT 0, -- FK (condicional) para sys_profiles.id (o perfil do visualizador, 0 se anônimo)
      viewer_nip INTEGER, -- IP do visualizador como inteiro (convertido de VARCHAR)
      date INTEGER NOT NULL, -- Unix Timestamp
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
      -- A FK para viewer_id não é estrita se viewer_id pode ser 0.
      -- Se viewer_id > 0, FOREIGN KEY (viewer_id) REFERENCES sys_profiles(id) ON DELETE SET DEFAULT ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_object_id ON bx_persons_views_track(object_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_viewer_id_date ON bx_persons_views_track(viewer_id, date) WHERE viewer_id != 0;
    CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_date ON bx_persons_views_track(date);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_views_track criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_views_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_views_track.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_views_track...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_views_track;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_views_track removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_views_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end