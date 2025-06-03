defmodule DeeperHub.Core.Data.Migrations.BxPhotosMetaKeywordsCamera do
  @moduledoc """
  Migration para criar e remover a tabela bx_photos_meta_keywords_camera.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_photos_meta_keywords_camera.
  """
  def up do
    Logger.info("Criando tabela de bx_photos_meta_keywords_camera...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_photos_meta_keywords_camera (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL,
    keyword TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_meta_keywords_camera criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_photos_meta_keywords_camera: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_photos_meta_keywords_camera: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_photos_meta_keywords_camera.
  """
  def down do
    Logger.info("Removendo tabela de bx_photos_meta_keywords_camera...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_photos_meta_keywords_camera
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_meta_keywords_camera removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_photos_meta_keywords_camera: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_photos_meta_keywords_camera: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
