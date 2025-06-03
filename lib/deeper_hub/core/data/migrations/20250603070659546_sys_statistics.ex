defmodule DeeperHub.Core.Data.Migrations.SysStatistics do
  @moduledoc """
  Migration para criar e remover a tabela sys_statistics.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_statistics.
  """
  def up do
    Logger.info("Criando tabela de sys_statistics...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_statistics (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    module TEXT NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    link TEXT NOT NULL,
    icon TEXT NOT NULL,
    "query" TEXT NOT NULL DEFAULT '''',
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_statistics criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_statistics: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_statistics: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_statistics.
  """
  def down do
    Logger.info("Removendo tabela de sys_statistics...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_statistics
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_statistics removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_statistics: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_statistics: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
