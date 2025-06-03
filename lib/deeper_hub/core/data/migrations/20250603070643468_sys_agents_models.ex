defmodule DeeperHub.Core.Data.Migrations.SysAgentsModels do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_models.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_models.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_models...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_models (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    "key" TEXT NOT NULL,
    params TEXT NOT NULL,
    for_asst INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1,
    hidden INTEGER NOT NULL DEFAULT 0,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_models criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_models: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_models: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_models.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_models...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_models
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_models removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_models: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_models: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
