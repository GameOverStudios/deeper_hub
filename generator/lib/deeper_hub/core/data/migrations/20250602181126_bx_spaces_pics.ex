defmodule DeeperHub.Core.Data.Migrations.BxSpacesPics do
  @moduledoc """
  Migration para criar e remover a tabela bx_spaces_pics.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_spaces_pics.
  """
  def up do
    Logger.info("Criando tabela de bx_spaces_pics...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_spaces_pics (
id int(11) NOT NULL  auto_increment,
profile_id int(10) unsigned NOT NULL,
remote_id varchar(128) NOT NULL,
path varchar(255) NOT NULL,
file_name varchar(255) NOT NULL,
mime_type varchar(128) NOT NULL,
ext varchar(32) NOT NULL,
size bigint(20) NOT NULL,
dimensions varchar(12) NOT NULL,
added int(11) NOT NULL,
modified int(11) NOT NULL,
private int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_spaces_pics criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_spaces_pics: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_spaces_pics.
  """
  def down do
    Logger.info("Removendo tabela de bx_spaces_pics...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_spaces_pics
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_spaces_pics removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_spaces_pics: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
