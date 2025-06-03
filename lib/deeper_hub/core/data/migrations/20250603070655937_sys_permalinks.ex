defmodule DeeperHub.Core.Data.Migrations.SysPermalinks do
  @moduledoc """
  Migration para criar e remover a tabela sys_permalinks.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_permalinks.
  """
  def up do
    Logger.info("Criando tabela de sys_permalinks...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_permalinks (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    standard TEXT NOT NULL,
    permalink TEXT NOT NULL,
    "check" TEXT NOT NULL,
    compare_by_prefix INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_permalinks criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_permalinks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_permalinks: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_permalinks.
  """
  def down do
    Logger.info("Removendo tabela de sys_permalinks...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_permalinks
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_permalinks removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_permalinks: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_permalinks: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
