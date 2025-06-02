defmodule DeeperHub.Core.Data.Migrations.SysCmtsScores do
  @moduledoc """
  Migration para criar e remover a tabela sys_cmts_scores.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_cmts_scores.
  """
  def up do
    Logger.info("Criando tabela de sys_cmts_scores...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_cmts_scores (
id int(11) NOT NULL  auto_increment,
object_id int(11) NOT NULL DEFAULT 0,
count_up int(11) NOT NULL DEFAULT 0,
count_down int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_scores criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_cmts_scores: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_cmts_scores.
  """
  def down do
    Logger.info("Removendo tabela de sys_cmts_scores...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_cmts_scores
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_scores removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_cmts_scores: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
