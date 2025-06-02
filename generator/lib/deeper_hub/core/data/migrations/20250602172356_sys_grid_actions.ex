defmodule DeeperHub.Core.Data.Migrations.SysGridActions do
  @moduledoc """
  Migration para criar e remover a tabela sys_grid_actions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_grid_actions.
  """
  def up do
    Logger.info("Criando tabela de sys_grid_actions...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_grid_actions (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
type enum('bulk','single','independent') NOT NULL,
name varchar(255) NOT NULL,
title varchar(255) NOT NULL,
icon text NOT NULL,
icon_only tinyint(4) NOT NULL DEFAULT 0,
confirm tinyint(4) NOT NULL DEFAULT 1,
active tinyint(4) NOT NULL DEFAULT 1,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_grid_actions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_grid_actions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_grid_actions.
  """
  def down do
    Logger.info("Removendo tabela de sys_grid_actions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_grid_actions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_grid_actions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_grid_actions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
