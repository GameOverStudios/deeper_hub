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
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    class TEXT NOT NULL,
    file TEXT NOT NULL,
    service_call TEXT NOT NULL DEFAULT '''',
    active INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_alerts_handlers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_alerts_handlers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_alerts_handlers: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_alerts_handlers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_alerts_handlers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
