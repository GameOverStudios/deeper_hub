defmodule DeeperHub.Core.Data.Migrations.SysMenuSets do
  @moduledoc """
  Migration para criar e remover a tabela sys_menu_sets.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_menu_sets.
  """
  def up do
    Logger.info("Criando tabela de sys_menu_sets...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_menu_sets (
set_name varchar(64) NOT NULL,
module varchar(32) NOT NULL,
title varchar(255) NOT NULL,
deletable tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (set_name)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_sets criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_menu_sets: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_menu_sets.
  """
  def down do
    Logger.info("Removendo tabela de sys_menu_sets...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_menu_sets
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_sets removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_menu_sets: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
