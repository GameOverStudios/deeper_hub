defmodule DeeperHub.Core.Data.Migrations.BxHelpToursItems do
  @moduledoc """
  Migration para criar e remover a tabela bx_help_tours_items.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_help_tours_items.
  """
  def up do
    Logger.info("Criando tabela de bx_help_tours_items...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_help_tours_items (
id int(11) NOT NULL  auto_increment,
tour int(11) NOT NULL,
name varchar(255) NOT NULL,
element varchar(255) NOT NULL,
arrow enum('auto','auto-start','auto-end','top','top-start','top-end','bottom','bottom-start','bottom-end','right','right-start','right-end','left','left-start','left-end') NULL,
title varchar(128) NOT NULL,
text varchar(128) NOT NULL,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_help_tours_items criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_help_tours_items: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_help_tours_items.
  """
  def down do
    Logger.info("Removendo tabela de bx_help_tours_items...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_help_tours_items
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_help_tours_items removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_help_tours_items: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
