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
id int(11) NOT NULL  auto_increment,
automator_id int(11) NOT NULL DEFAULT 0,
assistant_id int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_automators_assistants criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_automators_assistants: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_automators_assistants: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
