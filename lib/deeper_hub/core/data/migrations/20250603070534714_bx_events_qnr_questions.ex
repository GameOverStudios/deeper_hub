defmodule DeeperHub.Core.Data.Migrations.BxEventsQnrQuestions do
  @moduledoc """
  Migration para criar e remover a tabela bx_events_qnr_questions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_events_qnr_questions.
  """
  def up do
    Logger.info("Criando tabela de bx_events_qnr_questions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_events_qnr_questions (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    "action" TEXT NOT NULL DEFAULT 'add',
    question TEXT NOT NULL,
    answer TEXT NOT NULL DEFAULT 'text',
    extra TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_qnr_questions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_events_qnr_questions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_events_qnr_questions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_events_qnr_questions.
  """
  def down do
    Logger.info("Removendo tabela de bx_events_qnr_questions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_events_qnr_questions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_qnr_questions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_events_qnr_questions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_events_qnr_questions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
