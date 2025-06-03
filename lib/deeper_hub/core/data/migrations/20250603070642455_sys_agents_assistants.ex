defmodule DeeperHub.Core.Data.Migrations.SysAgentsAssistants do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_assistants.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_assistants.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_assistants...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_assistants (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    model_id INTEGER NOT NULL DEFAULT 0,
    profile_id INTEGER NOT NULL DEFAULT 0,
    description TEXT NOT NULL,
    prompt TEXT NOT NULL,
    ai_vs_id TEXT NOT NULL,
    ai_asst_id TEXT NOT NULL,
    added INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 0,
    hidden INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_assistants criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_assistants: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_assistants: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_assistants.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_assistants...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_assistants
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_assistants removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_assistants: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_assistants: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
