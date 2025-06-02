defmodule DeeperHub.Core.Data.Migrations.SysPagesContentPlaceholders do
  @moduledoc """
  Migration para criar e remover a tabela sys_pages_content_placeholders.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_pages_content_placeholders.
  """
  def up do
    Logger.info("Criando tabela de sys_pages_content_placeholders...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_pages_content_placeholders (
id int(11) NOT NULL  auto_increment,
module varchar(32) NOT NULL,
title varchar(255) NOT NULL,
template varchar(255) NOT NULL,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_content_placeholders criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_pages_content_placeholders: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_pages_content_placeholders.
  """
  def down do
    Logger.info("Removendo tabela de sys_pages_content_placeholders...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_pages_content_placeholders
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_content_placeholders removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_pages_content_placeholders: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
