defmodule DeeperHub.Core.Data.Migrations.BxFdbQuestions do
  @moduledoc """
  Migration para criar e remover a tabela bx_fdb_questions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_fdb_questions.
  """
  def up do
    Logger.info("Criando tabela de bx_fdb_questions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_fdb_questions (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL DEFAULT 0,
    changed INTEGER NOT NULL DEFAULT 0,
    text TEXT NOT NULL,
    lifetime INTEGER NOT NULL DEFAULT 0,
    allow_view_to TEXT NOT NULL DEFAULT 3,
    status_admin TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_fdb_questions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_fdb_questions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_fdb_questions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_fdb_questions.
  """
  def down do
    Logger.info("Removendo tabela de bx_fdb_questions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_fdb_questions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_fdb_questions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_fdb_questions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_fdb_questions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
