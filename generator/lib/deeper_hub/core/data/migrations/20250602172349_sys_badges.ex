defmodule DeeperHub.Core.Data.Migrations.SysBadges do
  @moduledoc """
  Migration para criar e remover a tabela sys_badges.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_badges.
  """
  def up do
    Logger.info("Criando tabela de sys_badges...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_badges (
id int(11) unsigned NOT NULL  auto_increment,
added int(11) NOT NULL,
module varchar(32) NOT NULL DEFAULT,
text varchar(255) NOT NULL DEFAULT,
icon text NOT NULL DEFAULT '',
color varchar(32) NOT NULL DEFAULT,
fontcolor varchar(32) NOT NULL DEFAULT,
is_icon_only tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_badges criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_badges: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_badges.
  """
  def down do
    Logger.info("Removendo tabela de sys_badges...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_badges
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_badges removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_badges: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
