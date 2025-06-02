defmodule DeeperHub.Core.Data.Migrations.BxClassesLinks2content do
  @moduledoc """
  Migration para criar e remover a tabela bx_classes_links2content.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_classes_links2content.
  """
  def up do
    Logger.info("Criando tabela de bx_classes_links2content...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_classes_links2content (
id int(11) NOT NULL  auto_increment,
content_id int(11) NOT NULL DEFAULT 0,
link_id int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_links2content criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_classes_links2content: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_classes_links2content.
  """
  def down do
    Logger.info("Removendo tabela de bx_classes_links2content...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_classes_links2content
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_links2content removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_classes_links2content: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
