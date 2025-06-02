defmodule DeeperHub.Core.Data.Migrations.BxForumCovers do
  @moduledoc """
  Migration para criar e remover a tabela bx_forum_covers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_forum_covers.
  """
  def up do
    Logger.info("Criando tabela de bx_forum_covers...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_forum_covers (
id int(11) NOT NULL  auto_increment,
profile_id int(10) unsigned NOT NULL,
remote_id varchar(128) NOT NULL,
path varchar(255) NOT NULL,
file_name varchar(255) NOT NULL,
mime_type varchar(128) NOT NULL,
ext varchar(32) NOT NULL,
size bigint(20) NOT NULL,
dimensions varchar(24) NOT NULL,
added int(11) NOT NULL,
modified int(11) NOT NULL,
private int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_covers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_forum_covers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_forum_covers.
  """
  def down do
    Logger.info("Removendo tabela de bx_forum_covers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_forum_covers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_covers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_forum_covers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
