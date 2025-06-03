defmodule DeeperHub.Core.Data.Migrations.BxCoursesContentNodes do
  @moduledoc """
  Migration para criar e remover a tabela bx_courses_content_nodes.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_courses_content_nodes.
  """
  def up do
    Logger.info("Criando tabela de bx_courses_content_nodes...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_courses_content_nodes (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL DEFAULT 0,
    title TEXT NOT NULL,
    text TEXT NOT NULL,
    passing INTEGER NOT NULL DEFAULT 0,
    counters TEXT NOT NULL,
    added INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_nodes criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_courses_content_nodes: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_courses_content_nodes: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_courses_content_nodes.
  """
  def down do
    Logger.info("Removendo tabela de bx_courses_content_nodes...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_courses_content_nodes
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_nodes removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_courses_content_nodes: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_courses_content_nodes: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
