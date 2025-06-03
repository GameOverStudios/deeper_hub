defmodule DeeperHub.Core.Data.Migrations.BxFilesDownloadingJobs do
  @moduledoc """
  Migration para criar e remover a tabela bx_files_downloading_jobs.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_files_downloading_jobs.
  """
  def up do
    Logger.info("Criando tabela de bx_files_downloading_jobs...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_files_downloading_jobs (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    owner INTEGER NOT NULL,
    files TEXT NOT NULL,
    result TEXT NOT NULL,
    started INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_files_downloading_jobs criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_files_downloading_jobs: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_files_downloading_jobs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_files_downloading_jobs.
  """
  def down do
    Logger.info("Removendo tabela de bx_files_downloading_jobs...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_files_downloading_jobs
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_files_downloading_jobs removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_files_downloading_jobs: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_files_downloading_jobs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
