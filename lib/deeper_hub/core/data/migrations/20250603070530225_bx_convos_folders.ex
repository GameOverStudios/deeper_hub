defmodule DeeperHub.Core.Data.Migrations.BxConvosFolders do
  @moduledoc """
  Migration para criar e remover a tabela bx_convos_folders.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_convos_folders.
  """
  def up do
    Logger.info("Criando tabela de bx_convos_folders...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_convos_folders (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    name TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_convos_folders criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_convos_folders: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_convos_folders: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_convos_folders.
  """
  def down do
    Logger.info("Removendo tabela de bx_convos_folders...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_convos_folders
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_convos_folders removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_convos_folders: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_convos_folders: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
