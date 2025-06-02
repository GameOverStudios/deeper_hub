defmodule DeeperHub.Core.Data.Migrations.SysStdPages do
  @moduledoc """
  Migration para criar e remover a tabela sys_std_pages.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_std_pages.
  """
  def up do
    Logger.info("Criando tabela de sys_std_pages...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_std_pages (
id int(11) unsigned NOT NULL  auto_increment,
index int(11) unsigned NOT NULL DEFAULT 0,
name varchar(64) NOT NULL DEFAULT,
header varchar(255) NOT NULL DEFAULT,
caption varchar(255) NOT NULL DEFAULT,
icon varchar(255) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_pages criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_std_pages: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_std_pages.
  """
  def down do
    Logger.info("Removendo tabela de sys_std_pages...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_std_pages
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_pages removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_std_pages: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
