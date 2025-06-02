defmodule DeeperHub.Core.Data.Migrations.SysEmailTemplates do
  @moduledoc """
  Migration para criar e remover a tabela sys_email_templates.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_email_templates.
  """
  def up do
    Logger.info("Criando tabela de sys_email_templates...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_email_templates (
ID int(11) unsigned NOT NULL  auto_increment,
Module varchar(32) NOT NULL,
NameSystem varchar(255) NOT NULL,
Name varchar(255) NOT NULL,
Subject varchar(255) NOT NULL,
Body varchar(255) NOT NULL,
  PRIMARY KEY (ID)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_email_templates criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_email_templates: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_email_templates.
  """
  def down do
    Logger.info("Removendo tabela de sys_email_templates...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_email_templates
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_email_templates removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_email_templates: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
