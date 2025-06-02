defmodule DeeperHub.Core.Data.Migrations.BxCoursesContentData do
  @moduledoc """
  Migration para criar e remover a tabela bx_courses_content_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_courses_content_data.
  """
  def up do
    Logger.info("Criando tabela de bx_courses_content_data...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_courses_content_data (
id int(11) NOT NULL  auto_increment,
entry_id int(11) NOT NULL DEFAULT 0,
node_id int(11) NOT NULL DEFAULT 0,
content_type varchar(32) NOT NULL DEFAULT,
content_id int(11) NOT NULL DEFAULT 0,
usage tinyint(4) NOT NULL DEFAULT 0,
added int(11) NOT NULL DEFAULT 0,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_data criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_courses_content_data: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_courses_content_data.
  """
  def down do
    Logger.info("Removendo tabela de bx_courses_content_data...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_courses_content_data
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_content_data removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_courses_content_data: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
