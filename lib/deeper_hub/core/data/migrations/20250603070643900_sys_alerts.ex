defmodule DeeperHub.Core.Data.Migrations.SysAlerts do
  @moduledoc """
  Migration para criar e remover a tabela sys_alerts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_alerts.
  """
  def up do
    Logger.info("Criando tabela de sys_alerts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_alerts (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    unit TEXT NOT NULL,
    "action" TEXT NOT NULL DEFAULT 'none',
    handler_id INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_alerts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_alerts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_alerts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_alerts.
  """
  def down do
    Logger.info("Removendo tabela de sys_alerts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_alerts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_alerts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_alerts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_alerts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
