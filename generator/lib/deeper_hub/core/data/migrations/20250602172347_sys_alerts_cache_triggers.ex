defmodule DeeperHub.Core.Data.Migrations.SysAlertsCacheTriggers do
  @moduledoc """
  Migration para criar e remover a tabela sys_alerts_cache_triggers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_alerts_cache_triggers.
  """
  def up do
    Logger.info("Criando tabela de sys_alerts_cache_triggers...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_alerts_cache_triggers (
id int(11) unsigned NOT NULL  auto_increment,
unit varchar(128) NOT NULL DEFAULT,
action varchar(32) NOT NULL DEFAULT,
cache_key varchar(255) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_alerts_cache_triggers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_alerts_cache_triggers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_alerts_cache_triggers.
  """
  def down do
    Logger.info("Removendo tabela de sys_alerts_cache_triggers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_alerts_cache_triggers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_alerts_cache_triggers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_alerts_cache_triggers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
