defmodule DeeperHub.Core.Data.Migrations.SysAgentsProvidersValues do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_providers_values.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_providers_values.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_providers_values...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_agents_providers_values (
id int(11) NOT NULL  auto_increment,
provider_id int(11) NOT NULL DEFAULT 0,
option_id int(11) NOT NULL DEFAULT 0,
value varchar(255) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_providers_values criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_providers_values: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_providers_values.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_providers_values...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_providers_values
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_providers_values removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_providers_values: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
