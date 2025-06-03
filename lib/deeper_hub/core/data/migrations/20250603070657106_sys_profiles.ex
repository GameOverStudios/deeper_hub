defmodule DeeperHub.Core.Data.Migrations.SysProfiles do
  @moduledoc """
  Migration para criar e remover a tabela sys_profiles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_profiles.
  """
  def up do
    Logger.info("Criando tabela de sys_profiles...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_profiles (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL,
    "type" TEXT NOT NULL,
    content_id INTEGER NOT NULL,
    cfw_value INTEGER NOT NULL DEFAULT 2147483647,
    cfw_items INTEGER NOT NULL DEFAULT 2147483647,
    cfu_items INTEGER NOT NULL DEFAULT 2147483647,
    cfu_locked INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_profiles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_profiles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_profiles.
  """
  def down do
    Logger.info("Removendo tabela de sys_profiles...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_profiles
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_profiles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_profiles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
