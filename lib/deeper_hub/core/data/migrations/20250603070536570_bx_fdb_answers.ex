defmodule DeeperHub.Core.Data.Migrations.BxFdbAnswers do
  @moduledoc """
  Migration para criar e remover a tabela bx_fdb_answers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_fdb_answers.
  """
  def up do
    Logger.info("Criando tabela de bx_fdb_answers...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_fdb_answers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL DEFAULT 0,
    title TEXT NOT NULL,
    important INTEGER NOT NULL DEFAULT 0,
    data TEXT NOT NULL DEFAULT '''',
    votes INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_fdb_answers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_fdb_answers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_fdb_answers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_fdb_answers.
  """
  def down do
    Logger.info("Removendo tabela de bx_fdb_answers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_fdb_answers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_fdb_answers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_fdb_answers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_fdb_answers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
