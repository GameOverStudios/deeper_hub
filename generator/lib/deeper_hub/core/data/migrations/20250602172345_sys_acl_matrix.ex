defmodule DeeperHub.Core.Data.Migrations.SysAclMatrix do
  @moduledoc """
  Migration para criar e remover a tabela sys_acl_matrix.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_acl_matrix.
  """
  def up do
    Logger.info("Criando tabela de sys_acl_matrix...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_acl_matrix (
IDLevel int(10) unsigned NOT NULL DEFAULT 0,
IDAction int(10) unsigned NOT NULL DEFAULT 0,
AllowedCount int(10) unsigned NULL,
AllowedPeriodLen int(10) unsigned NULL,
AllowedPeriodStart datetime NULL,
AllowedPeriodEnd datetime NULL,
AdditionalParamValue varchar(255) NULL,
  PRIMARY KEY (IDLevel),
  PRIMARY KEY (IDAction)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_matrix criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_acl_matrix: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_acl_matrix.
  """
  def down do
    Logger.info("Removendo tabela de sys_acl_matrix...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_acl_matrix
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_matrix removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_acl_matrix: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
