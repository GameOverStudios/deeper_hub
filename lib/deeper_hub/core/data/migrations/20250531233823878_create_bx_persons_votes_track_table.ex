# Migração gerada com ID único: V1748745503877 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsVotesTrackTable do
  # Migração gerada com ID único: V1748745503877 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_persons_votes_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_votes_track.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_votes_track...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_votes_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil votado)
      author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem votou)
      author_nip INTEGER NOT NULL, -- IP do autor como inteiro (no UNA é INT UNSIGNED)
      value INTEGER NOT NULL, -- O valor do voto, ex: 1 a 5. No UNA é TINYINT(4)
      date INTEGER NOT NULL, -- Unix Timestamp
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    -- O índice `vote (object_id,author_nip)` do UNA.
    -- Um índice UNIQUE em (object_id, author_id) é comum para que um usuário só vote uma vez.
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_vote_track_object_author ON bx_persons_votes_track(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_vote_track_author_id ON bx_persons_votes_track(author_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_votes_track criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_votes_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_votes_track.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_votes_track...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_votes_track;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_votes_track removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_votes_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end