defmodule DeeperHub.Core.Data.Migrations.BxPollsVotesTrack do
  @moduledoc """
  Migration para criar e remover a tabela bx_polls_votes_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_polls_votes_track.
  """
  def up do
    Logger.info("Criando tabela de bx_polls_votes_track...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_polls_votes_track (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL DEFAULT 0,
    author_id INTEGER NOT NULL DEFAULT 0,
    author_nip INTEGER NOT NULL DEFAULT 0,
    value INTEGER NOT NULL DEFAULT 0,
    date INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_polls_votes_track criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_polls_votes_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_polls_votes_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_polls_votes_track.
  """
  def down do
    Logger.info("Removendo tabela de bx_polls_votes_track...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_polls_votes_track
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_polls_votes_track removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_polls_votes_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_polls_votes_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
