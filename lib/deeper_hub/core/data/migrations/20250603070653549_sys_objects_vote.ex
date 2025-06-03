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
    ID INTEGER NOT NULL,
    Name TEXT NOT NULL,
    Module TEXT NOT NULL,
    TableMain TEXT NOT NULL,
    TableTrack TEXT NOT NULL,
    PostTimeout INTEGER NOT NULL DEFAULT 0,
    MinValue INTEGER NOT NULL DEFAULT 1,
    MaxValue INTEGER NOT NULL DEFAULT 5,
    Pruning INTEGER NOT NULL DEFAULT 31536000,
    IsUndo INTEGER NOT NULL DEFAULT 0,
    IsOn INTEGER NOT NULL DEFAULT 1,
    TriggerTable TEXT NOT NULL,
    TriggerFieldId TEXT NOT NULL,
    TriggerFieldAuthor TEXT NOT NULL,
    TriggerFieldRate TEXT NOT NULL,
    TriggerFieldRateCount TEXT NOT NULL,
    ClassName TEXT NOT NULL,
    ClassFile TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_vote criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_vote: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_vote: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_vote: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_vote: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
