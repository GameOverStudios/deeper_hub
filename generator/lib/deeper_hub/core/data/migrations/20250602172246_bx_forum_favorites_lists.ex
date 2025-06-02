defmodule DeeperHub.Core.Data.Migrations.BxForumFavoritesLists do
  @moduledoc """
  Migration para criar e remover a tabela bx_forum_favorites_lists.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_forum_favorites_lists.
  """
  def up do
    Logger.info("Criando tabela de bx_forum_favorites_lists...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_forum_favorites_lists (
id int(11) NOT NULL  auto_increment,
title varchar(255) NOT NULL,
author_id int(11) NOT NULL DEFAULT 0,
date int(11) NOT NULL DEFAULT 0,
allow_view_favorite_list_to varchar(16) NOT NULL DEFAULT 3,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_favorites_lists criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_forum_favorites_lists: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_forum_favorites_lists.
  """
  def down do
    Logger.info("Removendo tabela de bx_forum_favorites_lists...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_forum_favorites_lists
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_favorites_lists removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_forum_favorites_lists: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
