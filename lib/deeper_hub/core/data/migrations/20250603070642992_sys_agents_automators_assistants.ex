defmodule DeeperHub.Core.Data.Migrations.SysAgentsAutomatorsAssistants do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_automators_assistants.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_automators_assistants.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_automators_assistants...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_automators_assistants (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    automator_id INTEGER NOT NULL DEFAULT 0,
    assistant_id INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_automators_assistants criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_automators_assistants: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_automators_assistants: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_automators_assistants.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_automators_assistants...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_automators_assistants
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_automators_assistants removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_automators_assistants: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_automators_assistants: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
