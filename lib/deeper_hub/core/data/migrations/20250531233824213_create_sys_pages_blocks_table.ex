# Migração gerada com ID único: V1748745504213 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysPagesBlocksTable do
  # Migração gerada com ID único: V1748745504213 em 2025-05-31 23:38:24
  @moduledoc "Migração para criar a tabela sys_pages_blocks."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela sys_pages_blocks...", module: __MODULE__)
    # Repo.execute("PRAGMA foreign_keys = ON;")
    sql = """
    CREATE TABLE IF NOT EXISTS sys_pages_blocks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- Refere-se a sys_objects_page.object
      cell_id INTEGER NOT NULL DEFAULT 1,
      module TEXT NOT NULL,
      title_system TEXT,
      title TEXT NOT NULL,
      designbox_id INTEGER NOT NULL DEFAULT 11, -- Default para 'Sem Título' ou 'Padrão'
      class TEXT,
      submenu TEXT,
      tabs INTEGER NOT NULL DEFAULT 0,
      async INTEGER NOT NULL DEFAULT 0,
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
      hidden_on TEXT,
      type TEXT NOT NULL DEFAULT 'raw' CHECK(type IN (
        'raw', 'html', 'creative', 'bento_grid', 'lang', 'image', 'rss', 'menu', 'custom', 'service', 'wiki'
      )),
      content TEXT NOT NULL,
      content_empty TEXT,
      text TEXT,
      text_updated INTEGER,
      help TEXT,
      cache_lifetime INTEGER NOT NULL DEFAULT 0,
      deletable INTEGER NOT NULL DEFAULT 1,
      copyable INTEGER NOT NULL DEFAULT 1,
      active INTEGER NOT NULL DEFAULT 1,
      active_api INTEGER NOT NULL DEFAULT 0,
      "order" INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (designbox_id) REFERENCES sys_pages_design_boxes(id) ON DELETE SET DEFAULT ON UPDATE CASCADE
      -- A FK para sys_objects_page.object é lógica, não uma constraint SQL direta aqui
      -- para evitar complexidade com chaves não primárias como FK no SQLite de forma simples,
      -- mas a aplicação deve garantir a integridade.
    );

    CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_object_cell ON sys_pages_blocks(object, cell_id, "order");
    CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_module ON sys_pages_blocks(module);
    CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_type ON sys_pages_blocks(type);
    """
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_pages_blocks criada com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao criar tabela sys_pages_blocks: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela sys_pages_blocks...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_pages_blocks;"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_pages_blocks removida com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao remover tabela sys_pages_blocks: #{inspect(reason)}", module: __MODULE__)
    end)
  end
end