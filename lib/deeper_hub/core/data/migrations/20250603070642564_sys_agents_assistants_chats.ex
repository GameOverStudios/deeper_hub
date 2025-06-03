defmodule DeeperHub.Core.Data.Migrations.SysAgentsAssistantsChats do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_assistants_chats.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_assistants_chats.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_assistants_chats...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_assistants_chats (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    "type" INTEGER NOT NULL DEFAULT 1,
    assistant_id INTEGER NOT NULL DEFAULT 0,
    description TEXT NOT NULL,
    message_id INTEGER NOT NULL DEFAULT 0,
    messages INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL DEFAULT 0,
    ai_thread_id TEXT NOT NULL,
    ai_file_id TEXT NOT NULL,
    stored INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_assistants_chats criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_assistants_chats: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_assistants_chats: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_assistants_chats.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_assistants_chats...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_assistants_chats
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_assistants_chats removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_assistants_chats: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_assistants_chats: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
