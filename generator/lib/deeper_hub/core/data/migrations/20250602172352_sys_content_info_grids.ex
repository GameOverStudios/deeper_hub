defmodule DeeperHub.Core.Data.Migrations.SysContentInfoGrids do
  @moduledoc """
  Migration para criar e remover a tabela sys_content_info_grids.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_content_info_grids.
  """
  def up do
    Logger.info("Criando tabela de sys_content_info_grids...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_content_info_grids (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
grid_object varchar(64) NOT NULL,
grid_field_id varchar(64) NOT NULL,
condition text NOT NULL DEFAULT '',
selection varchar(256) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_content_info_grids criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_content_info_grids: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_content_info_grids.
  """
  def down do
    Logger.info("Removendo tabela de sys_content_info_grids...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_content_info_grids
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_content_info_grids removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_content_info_grids: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
