defmodule DeeperHub.Core.Data.Migrations.BxClassesStatuses do
  @moduledoc """
  Migration para criar e remover a tabela bx_classes_statuses.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_classes_statuses.
  """
  def up do
    Logger.info("Criando tabela de bx_classes_statuses...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_classes_statuses (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    class_id INTEGER NOT NULL,
    student_profile_id INTEGER NOT NULL,
    viewed INTEGER NOT NULL,
    replied INTEGER NOT NULL,
    completed INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_statuses criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_classes_statuses: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_classes_statuses: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_classes_statuses.
  """
  def down do
    Logger.info("Removendo tabela de bx_classes_statuses...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_classes_statuses
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_statuses removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_classes_statuses: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_classes_statuses: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
