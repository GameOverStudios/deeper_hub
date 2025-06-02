defmodule DeeperHub.Core.Data.Migrations.SysMenuTemplates do
  @moduledoc """
  Migration para criar e remover a tabela sys_menu_templates.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_menu_templates.
  """
  def up do
    Logger.info("Criando tabela de sys_menu_templates...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_menu_templates (
id int(11) NOT NULL  auto_increment,
template varchar(255) NOT NULL,
title varchar(255) NOT NULL,
visible tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_templates criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_menu_templates: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_menu_templates.
  """
  def down do
    Logger.info("Removendo tabela de sys_menu_templates...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_menu_templates
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_menu_templates removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_menu_templates: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
