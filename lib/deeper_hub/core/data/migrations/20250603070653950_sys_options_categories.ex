defmodule DeeperHub.Core.Data.Migrations.SysOptionsCategories do
  @moduledoc """
  Migration para criar e remover a tabela sys_options_categories.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_options_categories.
  """
  def up do
    Logger.info("Criando tabela de sys_options_categories...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_options_categories (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    type_id INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    caption TEXT NOT NULL,
    hidden INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_categories criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_options_categories: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_options_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_options_categories.
  """
  def down do
    Logger.info("Removendo tabela de sys_options_categories...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_options_categories
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_categories removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_options_categories: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_options_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
