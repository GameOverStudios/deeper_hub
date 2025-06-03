defmodule DeeperHub.Core.Data.Migrations.BxCoursesScores do
  @moduledoc """
  Migration para criar e remover a tabela bx_courses_scores.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_courses_scores.
  """
  def up do
    Logger.info("Criando tabela de bx_courses_scores...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_courses_scores (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL DEFAULT 0,
    count_up INTEGER NOT NULL DEFAULT 0,
    count_down INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_scores criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_courses_scores: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_courses_scores: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_courses_scores.
  """
  def down do
    Logger.info("Removendo tabela de bx_courses_scores...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_courses_scores
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_scores removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_courses_scores: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_courses_scores: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
