defmodule DeeperHub.Core.Data.Migrations.BxPhotosReports do
  @moduledoc """
  Migration para criar e remover a tabela bx_photos_reports.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_photos_reports.
  """
  def up do
    Logger.info("Criando tabela de bx_photos_reports...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_photos_reports (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL DEFAULT 0,
    count INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_reports criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_photos_reports: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_photos_reports: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_photos_reports.
  """
  def down do
    Logger.info("Removendo tabela de bx_photos_reports...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_photos_reports
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_photos_reports removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_photos_reports: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_photos_reports: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
