# Migração gerada com ID único: V1748745504242 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysAclActionsTrackTable do
  # Migração gerada com ID único: V1748745504242 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_acl_actions_track.
  Depende da existência das tabelas `sys_acl_actions` e `sys_accounts`.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_acl_actions_track.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_acl_actions_track...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_acl_actions_track (
      IDAction INTEGER NOT NULL,
      IDMember INTEGER NOT NULL,
      ActionsLeft INTEGER NOT NULL,
      ValidSince INTEGER, -- Unix Timestamp: quando o período de contagem/ActionsLeft foi (re)iniciado
      PRIMARY KEY (IDAction, IDMember),
      FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDMember) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE
    );
    """
    # Repo.execute("PRAGMA foreign_keys = ON;")

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_acl_actions_track criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_acl_actions_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_acl_actions_track.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_acl_actions_track...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_acl_actions_track;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_acl_actions_track removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_acl_actions_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end