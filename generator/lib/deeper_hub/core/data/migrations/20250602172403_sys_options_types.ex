defmodule DeeperHub.Core.Data.Migrations.SysOptionsTypes do
  @moduledoc """
  Migration para criar e remover a tabela sys_options_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_options_types.
  """
  def up do
    Logger.info("Criando tabela de sys_options_types...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_options_types (
id int(11) unsigned NOT NULL  auto_increment,
group varchar(64) NOT NULL DEFAULT,
name varchar(64) NOT NULL DEFAULT,
caption varchar(64) NOT NULL DEFAULT,
icon varchar(255) NOT NULL DEFAULT,
order int(11) NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_options_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_options_types.
  """
  def down do
    Logger.info("Removendo tabela de sys_options_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_options_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_options_types: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
