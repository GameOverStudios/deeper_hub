defmodule DeeperHub.Core.Data.Migrations.SysFormPreLists do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_pre_lists.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_pre_lists.
  """
  def up do
    Logger.info("Criando tabela de sys_form_pre_lists...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_form_pre_lists (
id int(11) NOT NULL  auto_increment,
module varchar(32) NOT NULL DEFAULT,
key varchar(255) NOT NULL DEFAULT,
title varchar(255) NOT NULL DEFAULT,
use_for_sets tinyint(4) unsigned NOT NULL DEFAULT 1,
extendable tinyint(4) unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_pre_lists criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_pre_lists: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_pre_lists.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_pre_lists...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_pre_lists
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_pre_lists removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_pre_lists: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
