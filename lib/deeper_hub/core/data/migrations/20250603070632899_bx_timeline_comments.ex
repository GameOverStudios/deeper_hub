defmodule DeeperHub.Core.Data.Migrations.BxTimelineComments do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_comments.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_comments.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_comments...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_timeline_comments (
    cmt_id INTEGER NOT NULL,
    cmt_parent_id INTEGER NOT NULL DEFAULT 0,
    cmt_vparent_id INTEGER NOT NULL DEFAULT 0,
    cmt_object_id INTEGER NOT NULL DEFAULT 0,
    cmt_author_id INTEGER NOT NULL DEFAULT 0,
    cmt_level INTEGER NOT NULL DEFAULT 0,
    cmt_text TEXT NOT NULL,
    cmt_time INTEGER NOT NULL DEFAULT 0,
    cmt_replies INTEGER NOT NULL DEFAULT 0,
    cmt_pinned INTEGER NOT NULL DEFAULT 0,
    cmt_cf INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (cmt_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_comments criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_timeline_comments: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_comments: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_comments.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_comments...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_comments
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_comments removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_timeline_comments: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_comments: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
