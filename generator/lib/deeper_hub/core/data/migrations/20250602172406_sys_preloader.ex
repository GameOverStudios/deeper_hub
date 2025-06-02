defmodule DeeperHub.Core.Data.Migrations.SysPreloader do
  @moduledoc """
  Migration para criar e remover a tabela sys_preloader.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_preloader.
  """
  def up do
    Logger.info("Criando tabela de sys_preloader...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_preloader (
id int(11) NOT NULL  auto_increment,
module varchar(32) NOT NULL,
type varchar(16) NOT NULL,
content varchar(255) NOT NULL,
active tinyint(4) NOT NULL DEFAULT 1,
order int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_preloader criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_preloader: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_preloader.
  """
  def down do
    Logger.info("Removendo tabela de sys_preloader...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_preloader
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_preloader removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_preloader: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
