defmodule DeeperHub.Core.Data.Migrations.SysStdWidgets do
  @moduledoc """
  Migration para criar e remover a tabela sys_std_widgets.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_std_widgets.
  """
  def up do
    Logger.info("Criando tabela de sys_std_widgets...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_std_widgets (
id int(11) unsigned NOT NULL  auto_increment,
page_id varchar(255) NOT NULL DEFAULT,
module varchar(32) NOT NULL DEFAULT,
type varchar(32) NOT NULL DEFAULT,
url varchar(255) NOT NULL DEFAULT,
click text NOT NULL DEFAULT '',
icon varchar(255) NOT NULL DEFAULT,
caption varchar(255) NOT NULL DEFAULT,
cnt_notices text NOT NULL DEFAULT '',
cnt_actions text NOT NULL DEFAULT '',
featured tinyint(4) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_widgets criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_std_widgets: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_std_widgets.
  """
  def down do
    Logger.info("Removendo tabela de sys_std_widgets...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_std_widgets
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_std_widgets removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_std_widgets: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
