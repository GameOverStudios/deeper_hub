defmodule DeeperHub.Core.Data.Migrations.SysSearchExtendedSortingFields do
  @moduledoc """
  Migration para criar e remover a tabela sys_search_extended_sorting_fields.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_search_extended_sorting_fields.
  """
  def up do
    Logger.info("Criando tabela de sys_search_extended_sorting_fields...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_search_extended_sorting_fields (
id int(10) unsigned NOT NULL  auto_increment,
object varchar(64) NOT NULL DEFAULT,
name varchar(255) NOT NULL DEFAULT,
direction varchar(32) NOT NULL DEFAULT,
caption varchar(255) NOT NULL DEFAULT,
active tinyint(4) NOT NULL DEFAULT 0,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_search_extended_sorting_fields criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_search_extended_sorting_fields: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_search_extended_sorting_fields.
  """
  def down do
    Logger.info("Removendo tabela de sys_search_extended_sorting_fields...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_search_extended_sorting_fields
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_search_extended_sorting_fields removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_search_extended_sorting_fields: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
