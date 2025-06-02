defmodule DeeperHub.Core.Data.Migrations.SysOptions do
  @moduledoc """
  Migration para criar e remover a tabela sys_options.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_options.
  """
  def up do
    Logger.info("Criando tabela de sys_options...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_options (
id int(11) unsigned NOT NULL  auto_increment,
category_id int(11) unsigned NOT NULL DEFAULT 0,
name varchar(64) NOT NULL DEFAULT,
caption varchar(255) NOT NULL DEFAULT,
info varchar(255) NOT NULL DEFAULT,
value mediumtext NOT NULL,
type enum('value','digit','text','code','checkbox','select','combobox','file','image','list','rlist','rgb','rgba','datetime') NOT NULL DEFAULT digit,
extra text NOT NULL DEFAULT '',
check varchar(32) NOT NULL,
check_params text NOT NULL,
check_error varchar(255) NOT NULL DEFAULT,
order int(11) NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_options: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_options.
  """
  def down do
    Logger.info("Removendo tabela de sys_options...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_options
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_options: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
