defmodule DeeperHub.Core.Data.Migrations.BxForumLinks2content do
  @moduledoc """
  Migration para criar e remover a tabela bx_forum_links2content.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_forum_links2content.
  """
  def up do
    Logger.info("Criando tabela de bx_forum_links2content...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_forum_links2content (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL DEFAULT 0,
    link_id INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_links2content criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_forum_links2content: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_forum_links2content: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_forum_links2content.
  """
  def down do
    Logger.info("Removendo tabela de bx_forum_links2content...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_forum_links2content
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_links2content removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_forum_links2content: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_forum_links2content: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
