defmodule DeeperHub.Core.Data.Migrations.SysStorageUserQuotas do
  @moduledoc """
  Migration para criar e remover a tabela sys_storage_user_quotas.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_storage_user_quotas.
  """
  def up do
    Logger.info("Criando tabela de sys_storage_user_quotas...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_storage_user_quotas (
    profile_id INTEGER NOT NULL,
    current_size INTEGER NOT NULL,
    current_number INTEGER NOT NULL,
    ts INTEGER NOT NULL,
      PRIMARY KEY (profile_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_storage_user_quotas criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_storage_user_quotas: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_storage_user_quotas: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_storage_user_quotas.
  """
  def down do
    Logger.info("Removendo tabela de sys_storage_user_quotas...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_storage_user_quotas
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_storage_user_quotas removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_storage_user_quotas: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_storage_user_quotas: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
