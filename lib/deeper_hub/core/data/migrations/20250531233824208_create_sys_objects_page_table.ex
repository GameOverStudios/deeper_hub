# Migração gerada com ID único: V1748745504208 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysObjectsPageTable do
  # Migração gerada com ID único: V1748745504208 em 2025-05-31 23:38:24
  @moduledoc "Migração para criar a tabela sys_objects_page."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela sys_objects_page...", module: __MODULE__)
    # Repo.execute("PRAGMA foreign_keys = ON;")
    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_page (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author INTEGER NOT NULL DEFAULT 0,
      added INTEGER NOT NULL DEFAULT 0,
      object TEXT NOT NULL UNIQUE,
      uri TEXT NOT NULL UNIQUE,
      title_system TEXT,
      title TEXT NOT NULL,
      module TEXT NOT NULL,
      cover INTEGER NOT NULL DEFAULT 1,
      cover_image INTEGER DEFAULT 0,
      cover_title TEXT,
      type_id INTEGER NOT NULL DEFAULT 1,
      layout_id INTEGER NOT NULL,
      sticky_columns INTEGER NOT NULL DEFAULT 0,
      submenu TEXT,
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
      visible_for_levels_editable INTEGER NOT NULL DEFAULT 1,
      url TEXT,
      content_info TEXT,
      meta_title TEXT,
      meta_description TEXT,
      meta_keywords TEXT,
      meta_robots TEXT,
      cache_lifetime INTEGER NOT NULL DEFAULT 0,
      cache_editable INTEGER NOT NULL DEFAULT 1,
      inj_head TEXT,
      inj_footer TEXT,
      deletable INTEGER NOT NULL DEFAULT 1,
      override_class_name TEXT,
      override_class_file TEXT,
      FOREIGN KEY (type_id) REFERENCES sys_pages_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
      FOREIGN KEY (layout_id) REFERENCES sys_pages_layouts(id) ON DELETE RESTRICT ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_page_module ON sys_objects_page(module);
    -- Índices em 'object' e 'uri' são criados pela constraint UNIQUE.
    """

    Repo.execute(sql)
    |> tap(fn
      {:ok, _} ->
        Logger.info("Tabela sys_objects_page criada com sucesso.", module: __MODULE__)

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_objects_page: #{inspect(reason)}",
          module: __MODULE__
        )
    end)
  end

  def down do
    Logger.info("Removendo tabela sys_objects_page...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_objects_page;"

    Repo.execute(sql)
    |> tap(fn
      {:ok, _} ->
        Logger.info("Tabela sys_objects_page removida com sucesso.", module: __MODULE__)

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_objects_page: #{inspect(reason)}",
          module: __MODULE__
        )
    end)
  end
end
