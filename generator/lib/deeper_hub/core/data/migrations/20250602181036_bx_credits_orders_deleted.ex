defmodule DeeperHub.Core.Data.Migrations.BxCreditsOrdersDeleted do
  @moduledoc """
  Migration para criar e remover a tabela bx_credits_orders_deleted.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_credits_orders_deleted.
  """
  def up do
    Logger.info("Criando tabela de bx_credits_orders_deleted...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_credits_orders_deleted (
id int(11) unsigned NOT NULL  auto_increment,
profile_id int(11) unsigned NOT NULL DEFAULT 0,
bundle_id int(11) unsigned NOT NULL DEFAULT 0,
count int(11) unsigned NOT NULL DEFAULT 0,
order varchar(32) NOT NULL DEFAULT,
license varchar(32) NOT NULL DEFAULT,
type varchar(16) NOT NULL DEFAULT,
added int(11) unsigned NOT NULL DEFAULT 0,
expired int(11) unsigned NOT NULL DEFAULT 0,
new tinyint(1) NOT NULL DEFAULT 1,
reason varchar(16) NOT NULL DEFAULT,
deleted int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_orders_deleted criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_credits_orders_deleted: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_credits_orders_deleted.
  """
  def down do
    Logger.info("Removendo tabela de bx_credits_orders_deleted...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_credits_orders_deleted
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_orders_deleted removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_credits_orders_deleted: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
