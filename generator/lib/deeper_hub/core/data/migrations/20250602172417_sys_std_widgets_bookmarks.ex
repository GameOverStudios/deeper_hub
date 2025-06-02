defmodule DeeperHub.Core.Data.Migrations.SysStdWidgetsBookmarks do
  @moduledoc """
  Migration para criar e remover a tabela sys_std_widgets_bookmarks.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_std_widgets_bookmarks.
  """
  def up do
    Logger.info("Criando tabela de sys_std_widgets_bookmarks...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_std_widgets_bookmarks (
id int(11) NOT NULL  auto_increment,
widget_id int(11) unsigned NOT NULL DEFAULT 0,
profile_id int(11) unsigned NOT NULL DEFAULT 0,
bookmark tinyint(4) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_widgets_bookmarks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_std_widgets_bookmarks: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_std_widgets_bookmarks.
  """
  def down do
    Logger.info("Removendo tabela de sys_std_widgets_bookmarks...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_std_widgets_bookmarks
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_widgets_bookmarks removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_std_widgets_bookmarks: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
