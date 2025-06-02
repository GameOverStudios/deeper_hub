defmodule DeeperHub.Core.Data.Migrations.SysObjectsAuths do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_auths.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_auths.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_auths...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_objects_auths (
ID int(10) unsigned NOT NULL  auto_increment,
Name varchar(64) NOT NULL,
Title varchar(128) NOT NULL,
Link varchar(255) NOT NULL,
OnClick varchar(255) NOT NULL,
Icon varchar(64) NOT NULL,
Style varchar(255) NOT NULL,
  PRIMARY KEY (ID)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_auths criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_auths: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_auths.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_auths...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_auths
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_auths removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_auths: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
