defmodule DeeperHub.Core.Data.Migrations.BxForumCategories do
  @moduledoc """
  Migration para criar e remover a tabela bx_forum_categories.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_forum_categories.
  """
  def up do
    Logger.info("Criando tabela de bx_forum_categories...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_forum_categories (
    category INTEGER NOT NULL DEFAULT 0,
    visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
    icon TEXT NOT NULL,
      PRIMARY KEY (category)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_categories criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_forum_categories: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_forum_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_forum_categories.
  """
  def down do
    Logger.info("Removendo tabela de bx_forum_categories...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_forum_categories
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_categories removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_forum_categories: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_forum_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
