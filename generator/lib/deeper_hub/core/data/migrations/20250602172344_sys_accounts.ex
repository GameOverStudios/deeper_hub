defmodule DeeperHub.Core.Data.Migrations.SysAccounts do
  @moduledoc """
  Migration para criar e remover a tabela sys_accounts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_accounts.
  """
  def up do
    Logger.info("Criando tabela de sys_accounts...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_accounts (
id int(10) unsigned NOT NULL  auto_increment,
profile_id int(10) unsigned NOT NULL,
name varchar(255) NOT NULL,
picture int(11) NOT NULL DEFAULT 0,
email varchar(255) NOT NULL,
email_confirmed tinyint(4) NOT NULL DEFAULT 0,
phone varchar(255) NOT NULL,
phone_confirmed tinyint(4) NOT NULL DEFAULT 0,
receive_updates tinyint(4) NOT NULL DEFAULT 1,
receive_news tinyint(4) NOT NULL DEFAULT 1,
password varchar(40) NOT NULL,
password_changed int(11) NOT NULL DEFAULT 0,
salt varchar(10) NOT NULL,
role tinyint(4) NOT NULL DEFAULT 1,
lang_id int(10) unsigned NOT NULL DEFAULT 0,
added int(11) NOT NULL DEFAULT 0,
changed int(11) NOT NULL DEFAULT 0,
logged int(11) NOT NULL DEFAULT 0,
ip varchar(40) NOT NULL DEFAULT,
referred varchar(255) NOT NULL DEFAULT,
login_attempts tinyint(4) NOT NULL DEFAULT 0,
locked tinyint(4) NOT NULL DEFAULT 0,
active int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_accounts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_accounts: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_accounts.
  """
  def down do
    Logger.info("Removendo tabela de sys_accounts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_accounts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_accounts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_accounts: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
