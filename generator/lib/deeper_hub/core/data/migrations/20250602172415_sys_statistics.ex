defmodule DeeperHub.Core.Data.Migrations.SysStatistics do
  @moduledoc """
  Migration para criar e remover a tabela sys_statistics.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_statistics.
  """
  def up do
    Logger.info("Criando tabela de sys_statistics...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_statistics (
id int(11) unsigned NOT NULL  auto_increment,
module varchar(32) NOT NULL DEFAULT,
name varchar(64) NOT NULL DEFAULT,
title varchar(255) NOT NULL DEFAULT,
link varchar(255) NOT NULL DEFAULT,
icon varchar(32) NOT NULL DEFAULT,
query text NOT NULL DEFAULT '',
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_statistics criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_statistics: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_statistics.
  """
  def down do
    Logger.info("Removendo tabela de sys_statistics...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_statistics
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_statistics removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_statistics: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
