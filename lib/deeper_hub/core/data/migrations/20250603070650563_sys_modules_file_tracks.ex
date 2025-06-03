defmodule DeeperHub.Core.Data.Migrations.SysModulesFileTracks do
  @moduledoc """
  Migration para criar e remover a tabela sys_modules_file_tracks.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_modules_file_tracks.
  """
  def up do
    Logger.info("Criando tabela de sys_modules_file_tracks...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_modules_file_tracks (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    module_id INTEGER NOT NULL DEFAULT 0,
    file TEXT NOT NULL,
    hash TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_modules_file_tracks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_modules_file_tracks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_modules_file_tracks: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_modules_file_tracks.
  """
  def down do
    Logger.info("Removendo tabela de sys_modules_file_tracks...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_modules_file_tracks
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_modules_file_tracks removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_modules_file_tracks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_modules_file_tracks: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
