defmodule DeeperHub.Core.Data.Migrations.SysProfilesConnRelations do
  @moduledoc """
  Migration para criar e remover a tabela sys_profiles_conn_relations.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_profiles_conn_relations.
  """
  def up do
    Logger.info("Criando tabela de sys_profiles_conn_relations...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_profiles_conn_relations (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    initiator INTEGER NOT NULL DEFAULT 0,
    content INTEGER NOT NULL DEFAULT 0,
    relation INTEGER NOT NULL DEFAULT 0,
    mutual INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles_conn_relations criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_profiles_conn_relations: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_profiles_conn_relations: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_profiles_conn_relations.
  """
  def down do
    Logger.info("Removendo tabela de sys_profiles_conn_relations...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_profiles_conn_relations
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles_conn_relations removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_profiles_conn_relations: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_profiles_conn_relations: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
