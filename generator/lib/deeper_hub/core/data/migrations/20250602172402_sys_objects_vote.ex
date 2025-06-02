defmodule DeeperHub.Core.Data.Migrations.SysObjectsVote do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_vote.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_vote.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_vote...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_vote (
ID int(11) unsigned NOT NULL  auto_increment,
Name varchar(50) NOT NULL DEFAULT,
Module varchar(32) NOT NULL DEFAULT,
TableMain varchar(50) NOT NULL DEFAULT,
TableTrack varchar(50) NOT NULL DEFAULT,
PostTimeout int(11) NOT NULL DEFAULT 0,
MinValue tinyint(4) NOT NULL DEFAULT 1,
MaxValue tinyint(4) NOT NULL DEFAULT 5,
Pruning int(11) NOT NULL DEFAULT 31536000,
IsUndo tinyint(1) NOT NULL DEFAULT 0,
IsOn tinyint(1) NOT NULL DEFAULT 1,
TriggerTable varchar(32) NOT NULL DEFAULT,
TriggerFieldId varchar(32) NOT NULL DEFAULT,
TriggerFieldAuthor varchar(32) NOT NULL DEFAULT,
TriggerFieldRate varchar(32) NOT NULL DEFAULT,
TriggerFieldRateCount varchar(32) NOT NULL DEFAULT,
ClassName varchar(32) NOT NULL DEFAULT,
ClassFile varchar(256) NOT NULL DEFAULT,
  PRIMARY KEY (ID)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_vote criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_vote: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_vote.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_vote...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_vote
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_vote removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_vote: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
