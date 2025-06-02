defmodule DeeperHub.Core.Data.Migrations.BxStoriesEntriesMedia do
  @moduledoc """
  Migration para criar e remover a tabela bx_stories_entries_media.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_stories_entries_media.
  """
  def up do
    Logger.info("Criando tabela de bx_stories_entries_media...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_stories_entries_media (
id int(11) unsigned NOT NULL  auto_increment,
content_id int(11) unsigned NOT NULL,
file_id int(11) NOT NULL,
author int(10) unsigned NOT NULL,
title varchar(255) NOT NULL,
cf int(11) NOT NULL DEFAULT 1,
data text NOT NULL,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_stories_entries_media criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_stories_entries_media: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_stories_entries_media.
  """
  def down do
    Logger.info("Removendo tabela de bx_stories_entries_media...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_stories_entries_media
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_stories_entries_media removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_stories_entries_media: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
