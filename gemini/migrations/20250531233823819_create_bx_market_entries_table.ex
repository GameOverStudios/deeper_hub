# Migração gerada com ID único: V1748745503819 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxMarketEntriesTable do
  # Migração gerada com ID único: V1748745503819 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_market_entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_market_entries.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_market_entries...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_market_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author_id INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('active', 'pending', 'hidden', 'sold', 'expired')),
      status_admin TEXT NOT NULL DEFAULT 'active' CHECK(status_admin IN ('active', 'hidden', 'pending')),
      category_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      name TEXT NOT NULL, -- Slug/identificador único para a URL do produto
      description TEXT,
      tags TEXT,
      price REAL,
      currency_code TEXT DEFAULT 'USD',
      price_negotiable INTEGER NOT NULL DEFAULT 0 CHECK(price_negotiable IN (0,1)),
      location_text TEXT,
      location_lat REAL,
      location_lng REAL,
      quantity INTEGER DEFAULT 1,
      condition TEXT CHECK(condition IN ('new', 'used_like_new', 'used_good', 'used_fair')),
      allow_comments INTEGER NOT NULL DEFAULT 1 CHECK(allow_comments IN (0,1)),
      allow_votes INTEGER NOT NULL DEFAULT 1 CHECK(allow_votes IN (0,1)),
      allow_reports INTEGER NOT NULL DEFAULT 1 CHECK(allow_reports IN (0,1)),
      views INTEGER NOT NULL DEFAULT 0,
      favorites INTEGER NOT NULL DEFAULT 0,
      comments_count INTEGER NOT NULL DEFAULT 0,
      votes_count INTEGER NOT NULL DEFAULT 0,
      score REAL NOT NULL DEFAULT 0,
      reports_count INTEGER NOT NULL DEFAULT 0,
      featured_until INTEGER,
      added INTEGER NOT NULL,
      changed INTEGER NOT NULL,
      last_bump INTEGER,
      expiration_date INTEGER,

      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES bx_market_categories(id) ON DELETE RESTRICT
    );

    CREATE INDEX IF NOT EXISTS idx_bx_market_entries_author_id ON bx_market_entries(author_id);
    CREATE INDEX IF NOT EXISTS idx_bx_market_entries_category_id ON bx_market_entries(category_id);
    CREATE INDEX IF NOT EXISTS idx_bx_market_entries_status ON bx_market_entries(status);
    CREATE UNIQUE INDEX IF NOT EXISTS idx_bx_market_entries_name ON bx_market_entries(name); -- Name (slug) deve ser único
    CREATE INDEX IF NOT EXISTS idx_bx_market_entries_price ON bx_market_entries(price);
    CREATE INDEX IF NOT EXISTS idx_bx_market_entries_added ON bx_market_entries(added);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_market_entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_market_entries: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_market_entries.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_market_entries...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS bx_market_entries;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_market_entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_market_entries: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
