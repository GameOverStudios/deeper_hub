defmodule DeeperHub.Core.Data.Migrations.SysPrivacyGroups do
  @moduledoc """
  Migration para criar e remover a tabela sys_privacy_groups.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_privacy_groups.
  """
  def up do
    Logger.info("Criando tabela de sys_privacy_groups...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_privacy_groups (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    "check" TEXT NOT NULL DEFAULT '''',
    active INTEGER NOT NULL DEFAULT 1,
    visible INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_groups criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_privacy_groups: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_privacy_groups: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_privacy_groups.
  """
  def down do
    Logger.info("Removendo tabela de sys_privacy_groups...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_privacy_groups
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_groups removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_privacy_groups: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_privacy_groups: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
