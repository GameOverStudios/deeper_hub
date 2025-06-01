# Migração gerada com ID único: V1748745504267 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysAclMatrixTable do
  # Migração gerada com ID único: V1748745504267 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_acl_matrix.
  Depende da existência das tabelas `sys_acl_levels` e `sys_acl_actions`.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_acl_matrix.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_acl_matrix...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_acl_matrix (
      IDLevel INTEGER NOT NULL,
      IDAction INTEGER NOT NULL,
      AllowedCount INTEGER, -- NULL para ilimitado
      AllowedPeriodLen INTEGER, -- Segundos, NULL se não aplicável
      AllowedPeriodStart INTEGER, -- Unix Timestamp
      AllowedPeriodEnd INTEGER, -- Unix Timestamp
      AdditionalParamValue TEXT,
      PRIMARY KEY (IDLevel, IDAction),
      FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );
    """
    # Repo.execute("PRAGMA foreign_keys = ON;")

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_acl_matrix criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_acl_matrix: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_acl_matrix.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_acl_matrix...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_acl_matrix;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_acl_matrix removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_acl_matrix: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end