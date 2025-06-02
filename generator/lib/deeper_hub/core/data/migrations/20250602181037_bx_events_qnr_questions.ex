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
id int(10) unsigned NOT NULL  auto_increment,
content_id int(10) unsigned NOT NULL DEFAULT 0,
added int(10) NOT NULL DEFAULT 0,
action varchar(16) NOT NULL DEFAULT add,
question varchar(255) NOT NULL DEFAULT,
answer varchar(16) NOT NULL DEFAULT text,
extra text NOT NULL,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_qnr_questions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_events_qnr_questions: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_events_qnr_questions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
