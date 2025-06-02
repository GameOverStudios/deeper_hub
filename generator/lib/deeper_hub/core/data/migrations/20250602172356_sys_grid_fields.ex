defmodule DeeperHub.Core.Data.Migrations.SysGridFields do
  @moduledoc """
  Migration para criar e remover a tabela sys_grid_fields.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_grid_fields.
  """
  def up do
    Logger.info("Criando tabela de sys_grid_fields...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_grid_fields (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
name varchar(255) NOT NULL,
title varchar(255) NOT NULL,
width varchar(16) NOT NULL,
translatable tinyint(4) NOT NULL DEFAULT 0,
chars_limit int(11) NOT NULL DEFAULT 0,
params text NOT NULL,
hidden_on varchar(255) NOT NULL DEFAULT,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_grid_fields criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_grid_fields: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_grid_fields.
  """
  def down do
    Logger.info("Removendo tabela de sys_grid_fields...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_grid_fields
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_grid_fields removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_grid_fields: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
