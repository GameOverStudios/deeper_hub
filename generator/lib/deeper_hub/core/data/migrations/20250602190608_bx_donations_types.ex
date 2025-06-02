defmodule DeeperHub.Core.Data.Migrations.BxDonationsTypes do
  @moduledoc """
  Migration para criar e remover a tabela bx_donations_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_donations_types.
  """
  def up do
    Logger.info("Criando tabela de bx_donations_types...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_donations_types (
id int(11) unsigned NOT NULL  auto_increment,
name varchar(128) NOT NULL DEFAULT,
title varchar(128) NOT NULL DEFAULT,
period int(11) unsigned NOT NULL DEFAULT 0,
period_unit varchar(32) NOT NULL DEFAULT,
amount float unsigned NOT NULL DEFAULT 0,
custom tinyint(4) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_donations_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_donations_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_donations_types.
  """
  def down do
    Logger.info("Removendo tabela de bx_donations_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_donations_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_donations_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_donations_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
