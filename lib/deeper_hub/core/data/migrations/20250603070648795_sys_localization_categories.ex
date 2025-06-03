defmodule DeeperHub.Core.Data.Migrations.SysLocalizationCategories do
  @moduledoc """
  Migration para criar e remover a tabela sys_localization_categories.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_localization_categories.
  """
  def up do
    Logger.info("Criando tabela de sys_localization_categories...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_localization_categories (
    ID INTEGER NOT NULL,
    Name TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_localization_categories criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_localization_categories: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_localization_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_localization_categories.
  """
  def down do
    Logger.info("Removendo tabela de sys_localization_categories...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_localization_categories
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_localization_categories removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_localization_categories: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_localization_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
