defmodule DeeperHub.Core.Data.Migrations.SysObjectsGrid do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_grid.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_grid.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_grid...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_grid (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
source_type enum('Array','Sql') NOT NULL,
source text NOT NULL,
table varchar(255) NOT NULL,
field_id varchar(255) NOT NULL,
field_order varchar(255) NOT NULL,
field_active varchar(255) NOT NULL,
order_get_field varchar(255) NOT NULL DEFAULT order_field,
order_get_dir varchar(255) NOT NULL DEFAULT order_dir,
paginate_url varchar(255) NOT NULL,
paginate_per_page int(11) NOT NULL DEFAULT 10,
paginate_simple varchar(255) NULL,
paginate_get_start varchar(255) NOT NULL,
paginate_get_per_page varchar(255) NOT NULL,
filter_fields text NOT NULL,
filter_fields_translatable text NOT NULL,
filter_mode enum('like','fulltext','auto') NOT NULL DEFAULT auto,
filter_get varchar(255) NOT NULL DEFAULT filter,
sorting_fields text NOT NULL,
sorting_fields_translatable text NOT NULL,
visible_for_levels int(11) NOT NULL DEFAULT 2147483647,
responsive tinyint(4) NOT NULL DEFAULT 1,
show_total_count tinyint(4) NOT NULL DEFAULT 0,
override_class_name varchar(255) NOT NULL,
override_class_file varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_grid criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_grid: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_grid.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_grid...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_grid
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_grid removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_grid: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
