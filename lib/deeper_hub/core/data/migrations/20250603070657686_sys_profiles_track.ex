defmodule DeeperHub.Core.Data.Migrations.SysProfilesTrack do
  @moduledoc """
  Migration para criar e remover a tabela sys_profiles_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_profiles_track.
  """
  def up do
    Logger.info("Criando tabela de sys_profiles_track...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_profiles_track (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL DEFAULT 0,
    "action" TEXT NOT NULL,
    date INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles_track criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_profiles_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_profiles_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_profiles_track.
  """
  def down do
    Logger.info("Removendo tabela de sys_profiles_track...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_profiles_track
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles_track removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_profiles_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_profiles_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
