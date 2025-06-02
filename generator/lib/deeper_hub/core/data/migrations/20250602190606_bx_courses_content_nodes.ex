defmodule DeeperHub.Core.Data.Migrations.BxCoursesContentNodes do
  @moduledoc """
  Migration para criar e remover a tabela bx_courses_content_nodes.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_courses_content_nodes.
  """
  def up do
    Logger.info("Criando tabela de bx_courses_content_nodes...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_courses_content_nodes (
id int(11) NOT NULL  auto_increment,
entry_id int(11) NOT NULL DEFAULT 0,
title varchar(255) NOT NULL DEFAULT,
text text NOT NULL,
passing tinyint(4) NOT NULL DEFAULT 0,
counters text NOT NULL,
added int(11) NOT NULL,
status enum('active','hidden') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_nodes criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_courses_content_nodes: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_courses_content_nodes.
  """
  def down do
    Logger.info("Removendo tabela de bx_courses_content_nodes...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_courses_content_nodes
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_nodes removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_courses_content_nodes: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
