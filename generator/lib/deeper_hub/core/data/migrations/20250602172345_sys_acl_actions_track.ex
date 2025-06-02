defmodule DeeperHub.Core.Data.Migrations.SysAclActionsTrack do
  @moduledoc """
  Migration para criar e remover a tabela sys_acl_actions_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_acl_actions_track.
  """
  def up do
    Logger.info("Criando tabela de sys_acl_actions_track...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_acl_actions_track (
IDAction int(10) unsigned NOT NULL DEFAULT 0,
IDMember int(10) unsigned NOT NULL DEFAULT 0,
ActionsLeft int(10) unsigned NOT NULL DEFAULT 0,
ValidSince datetime NULL,
  PRIMARY KEY (IDAction),
  PRIMARY KEY (IDMember)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_actions_track criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_acl_actions_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_acl_actions_track.
  """
  def down do
    Logger.info("Removendo tabela de sys_acl_actions_track...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_acl_actions_track
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_actions_track removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_acl_actions_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
