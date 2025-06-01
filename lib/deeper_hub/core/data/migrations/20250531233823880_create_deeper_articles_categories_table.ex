# Migração gerada com ID único: V1748745503880 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperArticlesCategoriesTable do
  # Migração gerada com ID único: V1748745503880 em 2025-05-31 23:38:23
  @moduledoc "Migração para criar a tabela deeper_articles_categories."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela deeper_articles_categories...", module: __MODULE__)
    sql = """
    CREATE TABLE IF NOT EXISTS deeper_articles_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER DEFAULT 0,
      name TEXT NOT NULL,
      slug TEXT NOT NULL UNIQUE,
      description TEXT,
      item_count INTEGER NOT NULL DEFAULT 0,
      "order" INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
      -- No SQLite, a FK para parent_id (auto-referência) é melhor gerenciada
      -- pela aplicação ou com triggers se a lógica de cascata for complexa.
      -- FOREIGN KEY (parent_id) REFERENCES deeper_articles_categories(id) ON DELETE SET DEFAULT DEFAULT 0 ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_articles_categories_parent_id ON deeper_articles_categories(parent_id);
    -- O índice em slug é criado pela constraint UNIQUE.
    """
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela deeper_articles_categories criada com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao criar tabela deeper_articles_categories: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela deeper_articles_categories...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_articles_categories;"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela deeper_articles_categories removida com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao remover tabela deeper_articles_categories: #{inspect(reason)}", module: __MODULE__)
    end)
  end
end