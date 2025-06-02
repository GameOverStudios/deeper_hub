defmodule DeeperHub.Core.Data.Migrations.BxCoursesContentStructure do
  @moduledoc """
  Migration para criar e remover a tabela bx_courses_content_structure.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_courses_content_structure.
  """
  def up do
    Logger.info("Criando tabela de bx_courses_content_structure...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_courses_content_structure (
id int(11) NOT NULL  auto_increment,
entry_id int(11) NOT NULL DEFAULT 0,
parent_id int(11) NOT NULL DEFAULT 0,
node_id int(11) NOT NULL DEFAULT 0,
level tinyint(4) NOT NULL DEFAULT 0,
order int(11) NOT NULL DEFAULT 0,
cn_l2 int(11) NOT NULL DEFAULT 0,
cn_l3 int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_structure criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_courses_content_structure: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_courses_content_structure.
  """
  def down do
    Logger.info("Removendo tabela de bx_courses_content_structure...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_courses_content_structure
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_structure removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_courses_content_structure: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
