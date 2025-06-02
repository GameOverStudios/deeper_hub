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
id int(11) NOT NULL  auto_increment,
name varchar(64) NOT NULL DEFAULT,
module varchar(64) NOT NULL DEFAULT,
connection varchar(64) NOT NULL DEFAULT,
content_info varchar(64) NOT NULL DEFAULT,
countable tinyint(4) NOT NULL DEFAULT 1,
active tinyint(4) NOT NULL DEFAULT 1,
class_name varchar(32) NOT NULL DEFAULT,
class_file varchar(256) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_recommendation criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_recommendation: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_recommendation: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
