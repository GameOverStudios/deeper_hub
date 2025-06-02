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
id int(11) NOT NULL  auto_increment,
name varchar(128) NOT NULL DEFAULT,
model_id int(11) NOT NULL DEFAULT 0,
profile_id int(11) NOT NULL DEFAULT 0,
type enum('event','scheduler','webhook') NOT NULL DEFAULT event,
params text NOT NULL,
alert_unit varchar(128) NOT NULL DEFAULT,
alert_action varchar(128) NOT NULL DEFAULT,
message_id int(11) NOT NULL DEFAULT 0,
code text NOT NULL,
added int(11) unsigned NOT NULL DEFAULT 0,
messages int(11) NOT NULL DEFAULT 0,
status enum('auto','manual','ready') NOT NULL DEFAULT auto,
active tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_automators criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_automators: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_automators: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
