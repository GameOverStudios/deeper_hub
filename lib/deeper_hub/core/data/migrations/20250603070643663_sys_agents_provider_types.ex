defmodule DeeperHub.Core.Data.Migrations.SysAgentsProviderTypes do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_provider_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_provider_types.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_provider_types...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_provider_types (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    option_prefix TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_provider_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_provider_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_provider_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_provider_types.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_provider_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_provider_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_provider_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_provider_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_provider_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
