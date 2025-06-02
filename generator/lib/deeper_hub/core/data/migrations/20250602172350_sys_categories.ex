defmodule DeeperHub.Core.Data.Migrations.SysCategories do
  @moduledoc """
  Migration para criar e remover a tabela sys_categories.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_categories.
  """
  def up do
    Logger.info("Criando tabela de sys_categories...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_categories (
id int(11) NOT NULL  auto_increment,
author int(11) NOT NULL,
added int(11) NOT NULL,
module varchar(32) NOT NULL,
value varchar(100) NOT NULL,
status enum('active','hidden') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_categories criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_categories: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_categories.
  """
  def down do
    Logger.info("Removendo tabela de sys_categories...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_categories
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_categories removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_categories: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
