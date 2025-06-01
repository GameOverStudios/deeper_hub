# Migração gerada com ID único: V1748745503891 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperArticlesTagsTable do
  # Migração gerada com ID único: V1748745503891 em 2025-05-31 23:38:23
  @moduledoc "Migração para criar a tabela deeper_articles_tags."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela deeper_articles_tags...", module: __MODULE__)
    sql = """
    CREATE TABLE IF NOT EXISTS deeper_articles_tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      slug TEXT NOT NULL UNIQUE,
      item_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
    """
    # Índices em name e slug são criados pelas constraints UNIQUE.
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela deeper_articles_tags criada com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao criar tabela deeper_articles_tags: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela deeper_articles_tags...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_articles_tags;"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela deeper_articles_tags removida com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao remover tabela deeper_articles_tags: #{inspect(reason)}", module: __MODULE__)
    end)
  end
end