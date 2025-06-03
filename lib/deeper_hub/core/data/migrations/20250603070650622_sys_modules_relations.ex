defmodule DeeperHub.Core.Data.Migrations.SysModulesRelations do
  @moduledoc """
  Migration para criar e remover a tabela sys_modules_relations.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_modules_relations.
  """
  def up do
    Logger.info("Criando tabela de sys_modules_relations...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_modules_relations (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    module TEXT NOT NULL,
    on_install TEXT NOT NULL,
    on_uninstall TEXT NOT NULL,
    on_enable TEXT NOT NULL,
    on_disable TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_modules_relations criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_modules_relations: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_modules_relations: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_modules_relations.
  """
  def down do
    Logger.info("Removendo tabela de sys_modules_relations...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_modules_relations
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_modules_relations removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_modules_relations: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_modules_relations: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
