defmodule DeeperHub.Core.Data.Migrations.SysStdPagesWidgets do
  @moduledoc """
  Migration para criar e remover a tabela sys_std_pages_widgets.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_std_pages_widgets.
  """
  def up do
    Logger.info("Criando tabela de sys_std_pages_widgets...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_pages_widgets (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    page_id INTEGER NOT NULL DEFAULT 0,
    widget_id INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_pages_widgets criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_std_pages_widgets: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_std_pages_widgets: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_std_pages_widgets.
  """
  def down do
    Logger.info("Removendo tabela de sys_std_pages_widgets...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_std_pages_widgets
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_pages_widgets removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_std_pages_widgets: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_std_pages_widgets: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
