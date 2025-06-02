defmodule DeeperHub.Core.Data.Migrations.BxCreditsBundles do
  @moduledoc """
  Migration para criar e remover a tabela bx_credits_bundles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_credits_bundles.
  """
  def up do
    Logger.info("Criando tabela de bx_credits_bundles...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_credits_bundles (
id int(11) unsigned NOT NULL  auto_increment,
added int(11) NOT NULL,
name varchar(255) NOT NULL,
title varchar(255) NOT NULL,
description varchar(255) NOT NULL,
amount int(11) NOT NULL DEFAULT 0,
bonus int(11) NOT NULL DEFAULT 0,
price float NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 0,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_bundles criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_credits_bundles: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_credits_bundles.
  """
  def down do
    Logger.info("Removendo tabela de bx_credits_bundles...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_credits_bundles
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_bundles removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_credits_bundles: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
