defmodule DeeperHub.Core.Data.Migrations.BxFilesMain do
  @moduledoc """
  Migration para criar e remover a tabela bx_files_main.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_files_main.
  """
  def up do
    Logger.info("Criando tabela de bx_files_main...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_files_main (
id int(10) unsigned NOT NULL  auto_increment,
author int(10) unsigned NOT NULL,
added int(11) NOT NULL,
changed int(11) NOT NULL,
file_id int(11) NOT NULL,
title varchar(255) NOT NULL,
cat int(11) NOT NULL,
desc text NOT NULL,
data text NOT NULL,
data_processed tinyint(4) NOT NULL DEFAULT 0,
labels text NOT NULL,
location text NOT NULL,
views int(11) NOT NULL DEFAULT 0,
rate float NOT NULL DEFAULT 0,
votes int(11) NOT NULL DEFAULT 0,
rrate float NOT NULL DEFAULT 0,
rvotes int(11) NOT NULL DEFAULT 0,
score int(11) NOT NULL DEFAULT 0,
sc_up int(11) NOT NULL DEFAULT 0,
sc_down int(11) NOT NULL DEFAULT 0,
favorites int(11) NOT NULL DEFAULT 0,
comments int(11) NOT NULL DEFAULT 0,
reports int(11) NOT NULL DEFAULT 0,
featured int(11) NOT NULL DEFAULT 0,
cf int(11) NOT NULL DEFAULT 1,
allow_view_to varchar(16) NOT NULL DEFAULT 3,
status enum('active','hidden') NOT NULL DEFAULT active,
status_admin enum('active','hidden','pending') NOT NULL DEFAULT active,
type enum('file','folder') NOT NULL DEFAULT file,
parent_folder_id int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_files_main criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_files_main: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_files_main.
  """
  def down do
    Logger.info("Removendo tabela de bx_files_main...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_files_main
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_files_main removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_files_main: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
