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
    IDLevel INTEGER NOT NULL DEFAULT 0,
    IDAction INTEGER NOT NULL DEFAULT 0,
    AllowedCount INTEGER NULL,
    AllowedPeriodLen INTEGER NULL,
    AllowedPeriodStart TEXT NULL,
    AllowedPeriodEnd TEXT NULL,
    AdditionalParamValue TEXT NULL,
      PRIMARY KEY (IDLevel, IDAction)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_matrix criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_acl_matrix: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_acl_matrix: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_acl_matrix: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_acl_matrix: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
