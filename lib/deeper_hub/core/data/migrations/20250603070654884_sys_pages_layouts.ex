defmodule DeeperHub.Core.Data.Migrations.SysPagesLayouts do
  @moduledoc """
  Migration para criar e remover a tabela sys_pages_layouts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_pages_layouts.
  """
  def up do
    Logger.info("Criando tabela de sys_pages_layouts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_pages_layouts (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    title TEXT NOT NULL,
    template TEXT NOT NULL,
    cells_number INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_layouts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_pages_layouts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_pages_layouts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_pages_layouts.
  """
  def down do
    Logger.info("Removendo tabela de sys_pages_layouts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_pages_layouts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_layouts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_pages_layouts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_pages_layouts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
