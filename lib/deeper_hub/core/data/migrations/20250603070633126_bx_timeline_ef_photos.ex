defmodule DeeperHub.Core.Data.Migrations.BxTimelineEfPhotos do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_ef_photos.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_ef_photos.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_ef_photos...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_timeline_ef_photos (
    event_id INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (event_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_ef_photos criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_timeline_ef_photos: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_ef_photos: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_ef_photos.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_ef_photos...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_ef_photos
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_ef_photos removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_timeline_ef_photos: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_ef_photos: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
