defmodule DeeperHub.Core.Data.Migrations.SysAgentsAssistantsFiles do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_assistants_files.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_assistants_files.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_assistants_files...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_assistants_files (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    assistant_id INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    ai_file_id TEXT NOT NULL,
    ai_file_size INTEGER NOT NULL DEFAULT 0,
    ai_file_status TEXT NOT NULL DEFAULT 'in_progress',
    locked INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_assistants_files criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_assistants_files: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_assistants_files: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_assistants_files.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_assistants_files...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_assistants_files
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_assistants_files removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_assistants_files: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_assistants_files: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
