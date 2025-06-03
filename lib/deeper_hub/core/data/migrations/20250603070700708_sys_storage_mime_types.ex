defmodule DeeperHub.Core.Data.Migrations.SysStorageMimeTypes do
  @moduledoc """
  Migration para criar e remover a tabela sys_storage_mime_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_storage_mime_types.
  """
  def up do
    Logger.info("Criando tabela de sys_storage_mime_types...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_storage_mime_types (
    ext TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    icon TEXT NOT NULL,
    icon_font TEXT NOT NULL,
      PRIMARY KEY (ext)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_storage_mime_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_storage_mime_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_storage_mime_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_storage_mime_types.
  """
  def down do
    Logger.info("Removendo tabela de sys_storage_mime_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_storage_mime_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_storage_mime_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_storage_mime_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_storage_mime_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
