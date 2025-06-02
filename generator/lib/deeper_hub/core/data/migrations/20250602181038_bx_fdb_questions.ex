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
id int(11) unsigned NOT NULL  auto_increment,
author int(11) unsigned NOT NULL,
added int(11) NOT NULL DEFAULT 0,
changed int(11) NOT NULL DEFAULT 0,
text text NOT NULL,
lifetime int(11) NOT NULL DEFAULT 0,
allow_view_to varchar(16) NOT NULL DEFAULT 3,
status_admin enum('active','hidden') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_fdb_questions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_fdb_questions: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_fdb_questions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
