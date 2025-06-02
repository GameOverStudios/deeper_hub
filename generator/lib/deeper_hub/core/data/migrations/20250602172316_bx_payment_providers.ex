defmodule DeeperHub.Core.Data.Migrations.BxPaymentProviders do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_providers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_providers.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_providers...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_payment_providers (
id int(11) NOT NULL  auto_increment,
name varchar(64) NOT NULL DEFAULT,
caption varchar(128) NOT NULL DEFAULT,
description varchar(128) NOT NULL DEFAULT,
option_prefix varchar(32) NOT NULL DEFAULT,
for_visitor tinyint(4) NOT NULL DEFAULT 0,
for_owner_only tinyint(4) NOT NULL DEFAULT 0,
for_single tinyint(4) NOT NULL DEFAULT 0,
for_recurring tinyint(4) NOT NULL DEFAULT 0,
single_seller tinyint(4) NOT NULL DEFAULT 0,
time_tracker tinyint(4) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 0,
order tinyint(4) NOT NULL DEFAULT 0,
class_name varchar(128) NOT NULL DEFAULT,
class_file varchar(255) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_providers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_providers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_providers.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_providers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_providers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_providers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_providers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
