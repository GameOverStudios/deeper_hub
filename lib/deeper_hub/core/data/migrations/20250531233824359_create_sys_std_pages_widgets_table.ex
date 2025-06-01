# Migração gerada com ID único: V1748745504359 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysStdPagesWidgetsTable do
  # Migração gerada com ID único: V1748745504359 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_std_pages_widgets.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_std_pages_widgets.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_std_pages_widgets...", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_pages_widgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      page_id INTEGER NOT NULL, -- FK para sys_std_pages.id
      widget_id INTEGER NOT NULL, -- FK para sys_std_widgets.id
      "order" INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (page_id) REFERENCES sys_std_pages(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (widget_id) REFERENCES sys_std_widgets(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_std_pages_widgets_page_widget ON sys_std_pages_widgets(page_id, widget_id);
    CREATE INDEX IF NOT EXISTS idx_sys_std_pages_widgets_widget_id ON sys_std_pages_widgets(widget_id); -- Para buscas por widget_id
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_pages_widgets criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_std_pages_widgets: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_std_pages_widgets.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_std_pages_widgets...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_std_pages_widgets;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_pages_widgets removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_std_pages_widgets: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end