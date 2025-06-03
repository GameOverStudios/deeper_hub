defmodule DeeperHub.Core.Data.Migrations.SysProfilesConnFriends do
  @moduledoc """
  Migration para criar e remover a tabela sys_profiles_conn_friends.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_profiles_conn_friends.
  """
  def up do
    Logger.info("Criando tabela de sys_profiles_conn_friends...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_profiles_conn_friends (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    initiator INTEGER NOT NULL,
    content INTEGER NOT NULL,
    mutual INTEGER NOT NULL,
    added INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles_conn_friends criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_profiles_conn_friends: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_profiles_conn_friends: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_profiles_conn_friends.
  """
  def down do
    Logger.info("Removendo tabela de sys_profiles_conn_friends...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_profiles_conn_friends
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles_conn_friends removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_profiles_conn_friends: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_profiles_conn_friends: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
