defmodule DeeperHub.Core.Data.Migrations.BxForumPolls do
  @moduledoc """
  Migration para criar e remover a tabela bx_forum_polls.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_forum_polls.
  """
  def up do
    Logger.info("Criando tabela de bx_forum_polls...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_forum_polls (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author_id INTEGER NOT NULL DEFAULT 0,
    content_id INTEGER NOT NULL DEFAULT 0,
    text TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_polls criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_forum_polls: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_forum_polls: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_forum_polls.
  """
  def down do
    Logger.info("Removendo tabela de bx_forum_polls...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_forum_polls
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_polls removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_forum_polls: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_forum_polls: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
