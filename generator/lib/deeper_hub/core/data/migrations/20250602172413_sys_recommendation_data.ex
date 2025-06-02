defmodule DeeperHub.Core.Data.Migrations.SysRecommendationData do
  @moduledoc """
  Migration para criar e remover a tabela sys_recommendation_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_recommendation_data.
  """
  def up do
    Logger.info("Criando tabela de sys_recommendation_data...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_recommendation_data (
id int(11) NOT NULL  auto_increment,
profile_id int(11) NOT NULL DEFAULT 0,
object_id int(11) NOT NULL DEFAULT 0,
item_id int(11) NOT NULL DEFAULT 0,
item_type varchar(64) NOT NULL DEFAULT,
item_value int(11) NOT NULL DEFAULT 0,
item_reducer int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_recommendation_data criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_recommendation_data: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_recommendation_data.
  """
  def down do
    Logger.info("Removendo tabela de sys_recommendation_data...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_recommendation_data
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_recommendation_data removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_recommendation_data: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
