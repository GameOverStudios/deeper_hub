defmodule DeeperHub.Core.Data.Migrations.SysRecommendationCriteria do
  @moduledoc """
  Migration para criar e remover a tabela sys_recommendation_criteria.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_recommendation_criteria.
  """
  def up do
    Logger.info("Criando tabela de sys_recommendation_criteria...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_recommendation_criteria (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    source_type TEXT NOT NULL,
    source TEXT NOT NULL,
    params TEXT NOT NULL,
    weight REAL NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_recommendation_criteria criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_recommendation_criteria: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_recommendation_criteria: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_recommendation_criteria.
  """
  def down do
    Logger.info("Removendo tabela de sys_recommendation_criteria...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_recommendation_criteria
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_recommendation_criteria removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_recommendation_criteria: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_recommendation_criteria: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
