defmodule DeeperHub.Core.Data.Migrations.SysAclLevels do
  @moduledoc """
  Migration para criar e remover a tabela sys_acl_levels.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_acl_levels.
  """
  def up do
    Logger.info("Criando tabela de sys_acl_levels...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_acl_levels (
ID int(10) unsigned NOT NULL  auto_increment,
Name varchar(100) NOT NULL DEFAULT,
Icon text NOT NULL DEFAULT '',
Description varchar(255) NOT NULL DEFAULT,
Active enum('yes','no') NOT NULL DEFAULT no,
Purchasable enum('yes','no') NOT NULL DEFAULT yes,
Removable enum('yes','no') NOT NULL DEFAULT yes,
QuotaSize bigint(20) NOT NULL,
QuotaNumber int(11) NOT NULL,
QuotaMaxFileSize bigint(20) NOT NULL,
Order int(11) NOT NULL DEFAULT 0,
PasswordExpired int(11) NOT NULL DEFAULT 0,
PasswordExpiredNotify int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (ID)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_levels criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_acl_levels: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_acl_levels.
  """
  def down do
    Logger.info("Removendo tabela de sys_acl_levels...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_acl_levels
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_levels removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_acl_levels: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
