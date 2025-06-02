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
id int(11) NOT NULL  auto_increment,
object_id int(11) NOT NULL DEFAULT 0,
name varchar(64) NOT NULL DEFAULT,
source_type enum('sql','service') NOT NULL,
source text NOT NULL,
params text NOT NULL,
weight float NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_recommendation_criteria criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_recommendation_criteria: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_recommendation_criteria: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
