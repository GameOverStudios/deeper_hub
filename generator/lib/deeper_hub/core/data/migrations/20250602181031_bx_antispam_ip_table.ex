defmodule DeeperHub.Core.Data.Migrations.BxAntispamIpTable do
  @moduledoc """
  Migration para criar e remover a tabela bx_antispam_ip_table.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_antispam_ip_table.
  """
  def up do
    Logger.info("Criando tabela de bx_antispam_ip_table...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_antispam_ip_table (
ID int(11) NOT NULL  auto_increment,
From int(10) unsigned NOT NULL,
To int(10) unsigned NOT NULL,
Type enum('allow','deny') NOT NULL DEFAULT deny,
LastDT int(11) unsigned NOT NULL,
Desc varchar(128) NOT NULL,
  PRIMARY KEY (ID)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_ip_table criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_antispam_ip_table: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_antispam_ip_table.
  """
  def down do
    Logger.info("Removendo tabela de bx_antispam_ip_table...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_antispam_ip_table
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_ip_table removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_antispam_ip_table: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
