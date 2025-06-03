defmodule DeeperHub.Core.Data.Migrations.SysCategories do
  @moduledoc """
  Migration para criar e remover a tabela sys_categories.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_categories.
  """
  def up do
    Logger.info("Criando tabela de sys_categories...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_categories (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    module TEXT NOT NULL,
    value TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_categories criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_categories: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_categories.
  """
  def down do
    Logger.info("Removendo tabela de sys_categories...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_categories
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_categories removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_categories: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
