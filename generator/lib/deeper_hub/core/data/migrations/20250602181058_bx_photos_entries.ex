defmodule DeeperHub.Core.Data.Migrations.BxPhotosEntries do
  @moduledoc """
  Migration para criar e remover a tabela bx_photos_entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_photos_entries.
  """
  def up do
    Logger.info("Criando tabela de bx_photos_entries...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_photos_entries (
id int(10) unsigned NOT NULL  auto_increment,
author int(10) unsigned NOT NULL DEFAULT 0,
added int(11) NOT NULL DEFAULT 0,
changed int(11) NOT NULL DEFAULT 0,
thumb int(11) NOT NULL DEFAULT 0,
title varchar(255) NOT NULL,
cat int(11) NOT NULL,
text text NOT NULL,
labels text NOT NULL,
location text NOT NULL,
views int(11) NOT NULL DEFAULT 0,
rate float NOT NULL DEFAULT 0,
votes int(11) NOT NULL DEFAULT 0,
srate float NOT NULL DEFAULT 0,
svotes int(11) NOT NULL DEFAULT 0,
rrate float NOT NULL DEFAULT 0,
rvotes int(11) NOT NULL DEFAULT 0,
score int(11) NOT NULL DEFAULT 0,
sc_up int(11) NOT NULL DEFAULT 0,
sc_down int(11) NOT NULL DEFAULT 0,
favorites int(11) NOT NULL DEFAULT 0,
comments int(11) NOT NULL DEFAULT 0,
reports int(11) NOT NULL DEFAULT 0,
featured int(11) NOT NULL DEFAULT 0,
allow_view_to varchar(16) NOT NULL DEFAULT 3,
cf int(11) NOT NULL DEFAULT 1,
status enum('active','hidden') NOT NULL DEFAULT active,
status_admin enum('active','hidden','pending') NOT NULL DEFAULT active,
exif text NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_photos_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_photos_entries.
  """
  def down do
    Logger.info("Removendo tabela de bx_photos_entries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_photos_entries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_photos_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
