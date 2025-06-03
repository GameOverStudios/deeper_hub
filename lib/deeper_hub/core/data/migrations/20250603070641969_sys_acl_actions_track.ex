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
    IDAction INTEGER NOT NULL DEFAULT 0,
    IDMember INTEGER NOT NULL DEFAULT 0,
    ActionsLeft INTEGER NOT NULL DEFAULT 0,
    ValidSince TEXT NULL,
      PRIMARY KEY (IDAction, IDMember)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_acl_actions_track criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_acl_actions_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_acl_actions_track: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_acl_actions_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_acl_actions_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
