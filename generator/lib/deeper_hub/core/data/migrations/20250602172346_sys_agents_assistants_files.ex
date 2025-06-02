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
id int(11) NOT NULL  auto_increment,
name varchar(128) NOT NULL DEFAULT,
assistant_id int(11) NOT NULL DEFAULT 0,
added int(11) NOT NULL DEFAULT 0,
ai_file_id varchar(64) NOT NULL DEFAULT,
ai_file_size int(11) NOT NULL DEFAULT 0,
ai_file_status varchar(64) NOT NULL DEFAULT in_progress,
locked tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_assistants_files criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_assistants_files: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_assistants_files: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
