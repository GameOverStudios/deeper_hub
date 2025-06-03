defmodule DeeperHub.Core.Data.Migrations.SysAgentsProviders do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_providers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_providers.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_providers...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_providers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type_id INTEGER NOT NULL DEFAULT 0,
    profile_id INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_providers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_providers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_providers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_providers.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_providers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_providers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_providers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_providers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_providers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
