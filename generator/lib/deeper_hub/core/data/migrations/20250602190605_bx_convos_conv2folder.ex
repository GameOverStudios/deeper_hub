defmodule DeeperHub.Core.Data.Migrations.BxConvosConv2folder do
  @moduledoc """
  Migration para criar e remover a tabela bx_convos_conv2folder.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_convos_conv2folder.
  """
  def up do
    Logger.info("Criando tabela de bx_convos_conv2folder...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_convos_conv2folder (
id int(10) unsigned NOT NULL  auto_increment,
conv_id int(10) unsigned NOT NULL,
folder_id int(10) unsigned NOT NULL,
collaborator int(10) unsigned NOT NULL,
read_comments int(11) NOT NULL DEFAULT -1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_convos_conv2folder criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_convos_conv2folder: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_convos_conv2folder.
  """
  def down do
    Logger.info("Removendo tabela de bx_convos_conv2folder...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_convos_conv2folder
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_convos_conv2folder removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_convos_conv2folder: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
