defmodule DeeperHub.Core.Data.Migrations.SysObjectsPrivacy do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_privacy.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_privacy.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_privacy...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_privacy (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    module TEXT NOT NULL,
    "action" TEXT NOT NULL,
    title TEXT NOT NULL,
    default_group TEXT NOT NULL DEFAULT 1,
    spaces TEXT NOT NULL DEFAULT 'all',
    "table" TEXT NOT NULL,
    table_field_id TEXT NOT NULL,
    table_field_author TEXT NOT NULL,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_privacy criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_privacy: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_privacy: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_privacy.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_privacy...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_privacy
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_privacy removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_privacy: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_privacy: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
