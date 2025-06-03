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
    iid INTEGER NOT NULL,
    id INTEGER NOT NULL,
    object TEXT NOT NULL,
    hash TEXT NOT NULL,
    created INTEGER NOT NULL,
      PRIMARY KEY (iid)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_storage_tokens criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_storage_tokens: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_storage_tokens: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_storage_tokens: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_storage_tokens: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
