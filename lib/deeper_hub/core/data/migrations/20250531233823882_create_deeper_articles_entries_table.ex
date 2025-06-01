# Migração gerada com ID único: V1748745503882 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperArticlesEntriesTable do
  # Migração gerada com ID único: V1748745503882 em 2025-05-31 23:38:23
  @moduledoc "Migração para criar a tabela deeper_articles_entries."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela deeper_articles_entries...", module: __MODULE__)
    # Repo.execute("PRAGMA foreign_keys = ON;") # Garantir que FKs estão ativas
    sql = """
    CREATE TABLE IF NOT EXISTS deeper_articles_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author_profile_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      slug TEXT NOT NULL UNIQUE,
      summary TEXT,
      body TEXT NOT NULL,
      body_type TEXT NOT NULL DEFAULT 'markdown' CHECK(body_type IN ('markdown', 'html', 'text')),
      featured_image_id INTEGER,
      category_id INTEGER,
      status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft', 'published', 'pending', 'archived')),
      published_at INTEGER,
      views INTEGER NOT NULL DEFAULT 0,
      allow_view_to TEXT NOT NULL DEFAULT '3',
      meta_title TEXT,
      meta_description TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE,
      FOREIGN KEY (category_id) REFERENCES deeper_articles_categories(id) ON DELETE SET NULL ON UPDATE CASCADE
      -- FOREIGN KEY (featured_image_id) REFERENCES deeper_files(id) ON DELETE SET NULL ON UPDATE CASCADE
      -- (Assumindo que deeper_files será criada em 06_file_management)
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_articles_author_id ON deeper_articles_entries(author_profile_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_articles_category_id ON deeper_articles_entries(category_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_articles_status_published_at ON deeper_articles_entries(status, published_at);
    """
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela deeper_articles_entries criada com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao criar tabela deeper_articles_entries: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela deeper_articles_entries...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_articles_entries;"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela deeper_articles_entries removida com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao remover tabela deeper_articles_entries: #{inspect(reason)}", module: __MODULE__)
    end)
  end
end