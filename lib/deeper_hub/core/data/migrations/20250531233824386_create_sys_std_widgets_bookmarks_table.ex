# Migração gerada com ID único: V1748745504385 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysStdWidgetsBookmarksTable do
  # Migração gerada com ID único: V1748745504385 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_std_widgets_bookmarks.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_std_widgets_bookmarks.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_std_widgets_bookmarks...", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_widgets_bookmarks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      widget_id INTEGER NOT NULL, -- FK para sys_std_widgets.id
      profile_id INTEGER NOT NULL, -- FK para sys_profiles.id
      bookmark INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      FOREIGN KEY (widget_id) REFERENCES sys_std_widgets(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_std_widgets_bookmarks_widget_profile ON sys_std_widgets_bookmarks(widget_id, profile_id);
    CREATE INDEX IF NOT EXISTS idx_sys_std_widgets_bookmarks_profile_id ON sys_std_widgets_bookmarks(profile_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_widgets_bookmarks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_std_widgets_bookmarks: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_std_widgets_bookmarks.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_std_widgets_bookmarks...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_std_widgets_bookmarks;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_widgets_bookmarks removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_std_widgets_bookmarks: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
