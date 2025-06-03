defmodule DeeperHub.Core.Data.Migrations.SysAgentsAutomatorsHelpers do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_automators_helpers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_automators_helpers.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_automators_helpers...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_automators_helpers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    automator_id INTEGER NOT NULL DEFAULT 0,
    helper_id INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_automators_helpers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_automators_helpers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_automators_helpers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_automators_helpers.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_automators_helpers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_automators_helpers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_automators_helpers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_automators_helpers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_automators_helpers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
