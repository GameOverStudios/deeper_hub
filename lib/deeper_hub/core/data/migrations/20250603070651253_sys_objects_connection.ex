defmodule DeeperHub.Core.Data.Migrations.SysObjectsConnection do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_connection.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_connection.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_connection...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_connection (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    "table" TEXT NOT NULL,
    profile_initiator INTEGER NOT NULL DEFAULT 1,
    profile_content INTEGER NOT NULL DEFAULT 0,
    "type" TEXT NOT NULL,
    tt_initiator TEXT NOT NULL,
    tf_id_initiator TEXT NOT NULL,
    tf_count_initiator TEXT NOT NULL,
    tt_content TEXT NOT NULL,
    tf_id_content TEXT NOT NULL,
    tf_count_content TEXT NOT NULL,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_connection criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_connection: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_connection: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_connection.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_connection...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_connection
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_connection removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_connection: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_connection: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
