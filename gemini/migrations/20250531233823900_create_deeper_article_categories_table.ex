# Migração gerada com ID único: V1748745503900 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperArticleCategoriesTable do
  # Migração gerada com ID único: V1748745503900 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_article_categories.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_article_categories.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_article_categories...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_article_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      slug TEXT NOT NULL UNIQUE,
      description TEXT,
      parent_id INTEGER,
      FOREIGN KEY (parent_id) REFERENCES deeper_article_categories(id) ON DELETE SET NULL -- ou ON DELETE CASCADE se subcategorias devem ser removidas
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_article_categories_slug ON deeper_article_categories(slug);
    CREATE INDEX IF NOT EXISTS idx_deeper_article_categories_parent_id ON deeper_article_categories(parent_id);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_article_categories criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_article_categories: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_article_categories.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_article_categories...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_article_categories;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_article_categories removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_article_categories: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
