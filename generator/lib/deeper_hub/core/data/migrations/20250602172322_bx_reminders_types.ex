defmodule DeeperHub.Core.Data.Migrations.BxRemindersTypes do
  @moduledoc """
  Migration para criar e remover a tabela bx_reminders_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reminders_types.
  """
  def up do
    Logger.info("Criando tabela de bx_reminders_types...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_reminders_types (
id int(11) NOT NULL  auto_increment,
author int(11) NOT NULL DEFAULT 0,
added int(11) NOT NULL,
changed int(11) NOT NULL,
name varchar(128) NOT NULL,
title varchar(255) NOT NULL,
text varchar(255) NOT NULL,
link varchar(255) NOT NULL,
when varchar(32) NOT NULL,
show int(11) NOT NULL DEFAULT 0,
notify varchar(255) NOT NULL,
personal tinyint(4) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 0,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reminders_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reminders_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reminders_types.
  """
  def down do
    Logger.info("Removendo tabela de bx_reminders_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reminders_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reminders_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reminders_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
