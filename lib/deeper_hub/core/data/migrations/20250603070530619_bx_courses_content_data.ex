defmodule DeeperHub.Core.Data.Migrations.BxCoursesContentData do
  @moduledoc """
  Migration para criar e remover a tabela bx_courses_content_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_courses_content_data.
  """
  def up do
    Logger.info("Criando tabela de bx_courses_content_data...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_courses_content_data (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL DEFAULT 0,
    node_id INTEGER NOT NULL DEFAULT 0,
    content_type TEXT NOT NULL,
    content_id INTEGER NOT NULL DEFAULT 0,
    usage INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_data criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_courses_content_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_courses_content_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_courses_content_data.
  """
  def down do
    Logger.info("Removendo tabela de bx_courses_content_data...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_courses_content_data
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_data removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_courses_content_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_courses_content_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
