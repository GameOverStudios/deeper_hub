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
    ID INTEGER NOT NULL,
    Name TEXT NOT NULL,
    Module TEXT NOT NULL,
    "Table" TEXT NOT NULL,
    CharsPostMin INTEGER NOT NULL,
    CharsPostMax INTEGER NOT NULL,
    CharsDisplayMax INTEGER NOT NULL,
    Html INTEGER NOT NULL,
    PerView INTEGER NOT NULL,
    PerViewReplies INTEGER NOT NULL,
    BrowseType TEXT NOT NULL,
    IsBrowseSwitch INTEGER NOT NULL,
    PostFormPosition TEXT NOT NULL,
    NumberOfLevels INTEGER NOT NULL,
    IsDisplaySwitch INTEGER NOT NULL,
    IsRatable INTEGER NOT NULL,
    ViewingThreshold INTEGER NOT NULL,
    IsOn INTEGER NOT NULL,
    RootStylePrefix TEXT NOT NULL DEFAULT 'cmt',
    BaseUrl TEXT NOT NULL,
    ObjectVote TEXT NOT NULL,
    ObjectReaction TEXT NOT NULL,
    ObjectScore TEXT NOT NULL,
    ObjectReport TEXT NOT NULL,
    TriggerTable TEXT NOT NULL,
    TriggerFieldId TEXT NOT NULL,
    TriggerFieldAuthor TEXT NOT NULL,
    TriggerFieldTitle TEXT NOT NULL,
    TriggerFieldComments TEXT NOT NULL,
    ClassName TEXT NOT NULL,
    ClassFile TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_cmts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_cmts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_cmts: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_cmts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_cmts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
