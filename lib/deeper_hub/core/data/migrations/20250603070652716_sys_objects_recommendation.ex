defmodule DeeperHub.Core.Data.Migrations.SysObjectsRecommendation do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_recommendation.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_recommendation.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_recommendation...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_recommendation (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    module TEXT NOT NULL,
    connection TEXT NOT NULL,
    content_info TEXT NOT NULL,
    countable INTEGER NOT NULL DEFAULT 1,
    active INTEGER NOT NULL DEFAULT 1,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_recommendation criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_recommendation: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_recommendation: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_recommendation.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_recommendation...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_recommendation
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_recommendation removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_recommendation: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_recommendation: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
