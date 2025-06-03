defmodule DeeperHub.Core.Data.Migrations.BxTasksLists do
  @moduledoc """
  Migration para criar e remover a tabela bx_tasks_lists.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_tasks_lists.
  """
  def up do
    Logger.info("Criando tabela de bx_tasks_lists...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_tasks_lists (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    context_id INTEGER NOT NULL,
    title TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_tasks_lists criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_tasks_lists: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_tasks_lists: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_tasks_lists.
  """
  def down do
    Logger.info("Removendo tabela de bx_tasks_lists...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_tasks_lists
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_tasks_lists removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_tasks_lists: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_tasks_lists: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
