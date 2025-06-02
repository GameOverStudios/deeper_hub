defmodule DeeperHub.Core.Data.Migrations.BxMapshowAccounts do
  @moduledoc """
  Migration para criar e remover a tabela bx_mapshow_accounts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_mapshow_accounts.
  """
  def up do
    Logger.info("Criando tabela de bx_mapshow_accounts...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_mapshow_accounts (
id int(11) NOT NULL  auto_increment,
account_id int(11) NOT NULL,
lng float NULL,
lat float NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_mapshow_accounts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_mapshow_accounts: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_mapshow_accounts.
  """
  def down do
    Logger.info("Removendo tabela de bx_mapshow_accounts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_mapshow_accounts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_mapshow_accounts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_mapshow_accounts: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
