defmodule DeeperHub.Core.Data.Migrations.SysAccountsPassword do
  @moduledoc """
  Migration para criar e remover a tabela sys_accounts_password.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_accounts_password.
  """
  def up do
    Logger.info("Criando tabela de sys_accounts_password...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_accounts_password (
id int(10) unsigned NOT NULL  auto_increment,
account_id int(10) NOT NULL,
password varchar(40) NOT NULL,
password_changed int(11) NOT NULL DEFAULT 0,
salt varchar(10) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_accounts_password criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_accounts_password: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_accounts_password.
  """
  def down do
    Logger.info("Removendo tabela de sys_accounts_password...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_accounts_password
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_accounts_password removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_accounts_password: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
