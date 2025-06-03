defmodule DeeperHub.Core.Data.Migrations.BxVideosMetaMentions do
  @moduledoc """
  Migration para criar e remover a tabela bx_videos_meta_mentions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_videos_meta_mentions.
  """
  def up do
    Logger.info("Criando tabela de bx_videos_meta_mentions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_videos_meta_mentions (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL,
    profile_id INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_videos_meta_mentions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_videos_meta_mentions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_videos_meta_mentions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_videos_meta_mentions.
  """
  def down do
    Logger.info("Removendo tabela de bx_videos_meta_mentions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_videos_meta_mentions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_videos_meta_mentions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_videos_meta_mentions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_videos_meta_mentions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
