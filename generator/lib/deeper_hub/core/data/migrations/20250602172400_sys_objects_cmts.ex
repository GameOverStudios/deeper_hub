defmodule DeeperHub.Core.Data.Migrations.SysObjectsCmts do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_cmts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_cmts.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_cmts...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_cmts (
ID int(10) unsigned NOT NULL  auto_increment,
Name varchar(64) NOT NULL,
Module varchar(32) NOT NULL,
Table varchar(50) NOT NULL,
CharsPostMin int(10) NOT NULL,
CharsPostMax int(10) NOT NULL,
CharsDisplayMax int(10) NOT NULL,
Html smallint(1) NOT NULL,
PerView smallint(6) NOT NULL,
PerViewReplies smallint(6) NOT NULL,
BrowseType varchar(50) NOT NULL,
IsBrowseSwitch smallint(1) NOT NULL,
PostFormPosition varchar(50) NOT NULL,
NumberOfLevels smallint(6) NOT NULL,
IsDisplaySwitch smallint(1) NOT NULL,
IsRatable smallint(1) NOT NULL,
ViewingThreshold smallint(6) NOT NULL,
IsOn smallint(1) NOT NULL,
RootStylePrefix varchar(16) NOT NULL DEFAULT cmt,
BaseUrl varchar(256) NOT NULL,
ObjectVote varchar(64) NOT NULL DEFAULT,
ObjectReaction varchar(64) NOT NULL DEFAULT,
ObjectScore varchar(64) NOT NULL DEFAULT,
ObjectReport varchar(64) NOT NULL DEFAULT,
TriggerTable varchar(32) NOT NULL,
TriggerFieldId varchar(32) NOT NULL,
TriggerFieldAuthor varchar(32) NOT NULL,
TriggerFieldTitle varchar(32) NOT NULL,
TriggerFieldComments varchar(32) NOT NULL,
ClassName varchar(32) NOT NULL,
ClassFile varchar(256) NOT NULL,
  PRIMARY KEY (ID)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_cmts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_cmts: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_cmts.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_cmts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_cmts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_cmts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_cmts: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
