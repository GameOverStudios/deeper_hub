defmodule DeeperHub.Core.Data.Migrations.SysObjectsScore do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_score.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_score.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_score...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_score (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    module TEXT NOT NULL,
    table_main TEXT NOT NULL,
    table_track TEXT NOT NULL,
    post_timeout INTEGER NOT NULL DEFAULT 0,
    pruning INTEGER NOT NULL DEFAULT 31536000,
    is_undo INTEGER NOT NULL DEFAULT 0,
    is_on INTEGER NOT NULL DEFAULT 1,
    trigger_table TEXT NOT NULL,
    trigger_field_id TEXT NOT NULL,
    trigger_field_author TEXT NOT NULL,
    trigger_field_score TEXT NOT NULL,
    trigger_field_cup TEXT NOT NULL,
    trigger_field_cdown TEXT NOT NULL,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_score criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_score: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_score: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_score.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_score...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_score
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_score removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_score: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_score: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
