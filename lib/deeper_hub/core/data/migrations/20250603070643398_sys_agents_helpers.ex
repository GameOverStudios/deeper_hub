defmodule DeeperHub.Core.Data.Migrations.SysAgentsHelpers do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_helpers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_helpers.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_helpers...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_helpers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NULL,
    model_id INTEGER NOT NULL DEFAULT 0,
    profile_id INTEGER NOT NULL DEFAULT 0,
    description TEXT NOT NULL,
    prompt TEXT NULL,
    added INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_helpers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_helpers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_helpers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_helpers.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_helpers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_helpers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_helpers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_helpers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_helpers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
