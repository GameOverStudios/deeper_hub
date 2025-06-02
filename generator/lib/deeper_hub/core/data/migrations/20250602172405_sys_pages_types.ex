defmodule DeeperHub.Core.Data.Migrations.SysPagesTypes do
  @moduledoc """
  Migration para criar e remover a tabela sys_pages_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_pages_types.
  """
  def up do
    Logger.info("Criando tabela de sys_pages_types...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_pages_types (
id int(11) NOT NULL  auto_increment,
title varchar(255) NOT NULL,
template varchar(255) NOT NULL,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_pages_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_pages_types.
  """
  def down do
    Logger.info("Removendo tabela de sys_pages_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_pages_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_pages_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
