defmodule DeeperHub.Core.Data.Migrations.SysStorageTokens do
  @moduledoc """
  Migration para criar e remover a tabela sys_storage_tokens.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_storage_tokens.
  """
  def up do
    Logger.info("Criando tabela de sys_storage_tokens...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_storage_tokens (
iid int(11) NOT NULL  auto_increment,
id int(11) NOT NULL,
object varchar(64) NOT NULL,
hash varchar(32) NOT NULL,
created int(10) unsigned NOT NULL,
  PRIMARY KEY (iid)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_storage_tokens criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_storage_tokens: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_storage_tokens.
  """
  def down do
    Logger.info("Removendo tabela de sys_storage_tokens...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_storage_tokens
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_storage_tokens removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_storage_tokens: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
