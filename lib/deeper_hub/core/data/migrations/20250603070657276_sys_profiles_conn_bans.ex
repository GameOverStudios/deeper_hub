defmodule DeeperHub.Core.Data.Migrations.SysProfilesConnBans do
  @moduledoc """
  Migration para criar e remover a tabela sys_profiles_conn_bans.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_profiles_conn_bans.
  """
  def up do
    Logger.info("Criando tabela de sys_profiles_conn_bans...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_profiles_conn_bans (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    module TEXT NOT NULL,
    initiator INTEGER NOT NULL,
    content INTEGER NOT NULL,
    added INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles_conn_bans criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_profiles_conn_bans: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_profiles_conn_bans: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_profiles_conn_bans.
  """
  def down do
    Logger.info("Removendo tabela de sys_profiles_conn_bans...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_profiles_conn_bans
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles_conn_bans removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_profiles_conn_bans: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_profiles_conn_bans: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
