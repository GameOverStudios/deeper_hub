defmodule DeeperHub.Core.Data.Migrations.BxAlbumsFiles2albums do
  @moduledoc """
  Migration para criar e remover a tabela bx_albums_files2albums.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_albums_files2albums.
  """
  def up do
    Logger.info("Criando tabela de bx_albums_files2albums...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_albums_files2albums (
id int(10) unsigned NOT NULL  auto_increment,
content_id int(10) unsigned NOT NULL,
file_id int(11) NOT NULL,
author int(10) unsigned NOT NULL,
title varchar(255) NOT NULL,
views int(11) NOT NULL,
rate float NOT NULL,
votes int(11) NOT NULL,
score int(11) NOT NULL DEFAULT 0,
sc_up int(11) NOT NULL DEFAULT 0,
sc_down int(11) NOT NULL DEFAULT 0,
favorites int(11) NOT NULL DEFAULT 0,
comments int(11) NOT NULL,
reports int(11) NOT NULL DEFAULT 0,
featured int(11) NOT NULL DEFAULT 0,
cf int(11) NOT NULL DEFAULT 1,
data text NOT NULL,
exif text NOT NULL,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_albums_files2albums criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_albums_files2albums: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_albums_files2albums.
  """
  def down do
    Logger.info("Removendo tabela de bx_albums_files2albums...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_albums_files2albums
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_albums_files2albums removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_albums_files2albums: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
