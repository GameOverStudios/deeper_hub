defmodule DeeperHub.Core.Data.Migrations.SysObjectsTranscoder do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_transcoder.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_transcoder.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_transcoder...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_transcoder (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    storage_object TEXT NOT NULL,
    source_type TEXT NOT NULL,
    source_params TEXT NOT NULL,
    private TEXT NOT NULL,
    atime_tracking INTEGER NOT NULL,
    atime_pruning INTEGER NOT NULL,
    ts INTEGER NOT NULL DEFAULT 0,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_transcoder criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_transcoder: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_transcoder: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_transcoder.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_transcoder...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_transcoder
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_transcoder removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_transcoder: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_transcoder: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
