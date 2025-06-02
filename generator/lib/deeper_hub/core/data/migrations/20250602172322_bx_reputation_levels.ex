defmodule DeeperHub.Core.Data.Migrations.BxReputationLevels do
  @moduledoc """
  Migration para criar e remover a tabela bx_reputation_levels.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reputation_levels.
  """
  def up do
    Logger.info("Criando tabela de bx_reputation_levels...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_reputation_levels (
id int(11) NOT NULL  auto_increment,
name varchar(32) NOT NULL DEFAULT,
title varchar(64) NOT NULL DEFAULT,
icon text NOT NULL,
points_in int(11) NOT NULL DEFAULT 0,
points_out int(11) NOT NULL DEFAULT 0,
date int(11) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_levels criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reputation_levels: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reputation_levels.
  """
  def down do
    Logger.info("Removendo tabela de bx_reputation_levels...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reputation_levels
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_levels removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reputation_levels: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
