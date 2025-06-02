defmodule DeeperHub.Core.Data.Migrations.SysObjectsPage do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_page.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_page.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_page...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_page (
id int(11) NOT NULL  auto_increment,
author int(11) NOT NULL DEFAULT 0,
added int(11) NOT NULL DEFAULT 0,
object varchar(64) NOT NULL,
uri varchar(255) NOT NULL,
title_system varchar(255) NOT NULL,
title varchar(255) NOT NULL,
module varchar(32) NOT NULL,
cover tinyint(4) NOT NULL DEFAULT 1,
cover_image int(11) NOT NULL DEFAULT 0,
cover_title varchar(255) NOT NULL DEFAULT,
type_id int(11) NOT NULL DEFAULT 1,
layout_id int(11) NOT NULL,
sticky_columns tinyint(4) NOT NULL DEFAULT 0,
submenu varchar(64) NOT NULL DEFAULT,
visible_for_levels int(11) NOT NULL DEFAULT 2147483647,
visible_for_levels_editable tinyint(4) NOT NULL DEFAULT 1,
url varchar(255) NOT NULL,
content_info varchar(64) NOT NULL,
meta_title varchar(255) NOT NULL,
meta_description text NOT NULL,
meta_keywords text NOT NULL,
meta_robots varchar(255) NOT NULL,
cache_lifetime int(11) NOT NULL DEFAULT 0,
cache_editable tinyint(4) NOT NULL DEFAULT 1,
inj_head text NOT NULL,
inj_footer text NOT NULL,
config_api text NOT NULL,
deletable tinyint(1) NOT NULL,
override_class_name varchar(255) NOT NULL,
override_class_file varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_page criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_page: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_page.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_page...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_page
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_page removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_page: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
