defmodule DeeperHub.Core.Data.Migrations.SysAgentsAutomators do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_automators.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_automators.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_automators...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_automators (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    model_id INTEGER NOT NULL DEFAULT 0,
    profile_id INTEGER NOT NULL DEFAULT 0,
    "type" TEXT NOT NULL DEFAULT 'event',
    params TEXT NOT NULL,
    alert_unit TEXT NOT NULL,
    alert_action TEXT NOT NULL,
    message_id INTEGER NOT NULL DEFAULT 0,
    code TEXT NOT NULL,
    added INTEGER NOT NULL DEFAULT 0,
    messages INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'auto',
    active INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_automators criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_automators: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_automators: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_automators.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_automators...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_automators
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_automators removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_automators: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_automators: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
