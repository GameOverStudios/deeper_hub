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
id int(11) NOT NULL  auto_increment,
name varchar(128) NOT NULL DEFAULT,
type tinyint(4) NOT NULL DEFAULT 1,
assistant_id int(11) NOT NULL DEFAULT 0,
description text NOT NULL,
message_id int(11) NOT NULL DEFAULT 0,
messages int(11) NOT NULL DEFAULT 0,
added int(11) NOT NULL DEFAULT 0,
ai_thread_id varchar(64) NOT NULL DEFAULT,
ai_file_id varchar(64) NOT NULL DEFAULT,
stored int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_assistants_chats criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_assistants_chats: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_assistants_chats: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
