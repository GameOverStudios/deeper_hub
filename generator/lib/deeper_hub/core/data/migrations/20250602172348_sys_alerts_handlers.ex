defmodule DeeperHub.Core.Data.Migrations.SysAlertsHandlers do
  @moduledoc """
  Migration para criar e remover a tabela sys_alerts_handlers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_alerts_handlers.
  """
  def up do
    Logger.info("Criando tabela de sys_alerts_handlers...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_alerts_handlers (
id int(11) unsigned NOT NULL  auto_increment,
name varchar(128) NOT NULL DEFAULT,
class varchar(128) NOT NULL DEFAULT,
file varchar(255) NOT NULL DEFAULT,
service_call text NOT NULL DEFAULT '',
active tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_alerts_handlers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_alerts_handlers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_alerts_handlers.
  """
  def down do
    Logger.info("Removendo tabela de sys_alerts_handlers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_alerts_handlers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_alerts_handlers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_alerts_handlers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
