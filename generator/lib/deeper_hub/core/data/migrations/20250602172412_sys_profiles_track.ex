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
id int(11) unsigned NOT NULL  auto_increment,
profile_id int(11) unsigned NOT NULL DEFAULT 0,
action varchar(32) NOT NULL DEFAULT,
date int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles_track criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_profiles_track: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_profiles_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
