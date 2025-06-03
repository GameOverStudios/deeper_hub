defmodule DeeperHub.Core.Data.Migrations.BxClassesModules do
  @moduledoc """
  Migration para criar e remover a tabela bx_classes_modules.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_classes_modules.
  """
  def up do
    Logger.info("Criando tabela de bx_classes_modules...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_classes_modules (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL,
    module_title TEXT NOT NULL,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_modules criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_classes_modules: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_classes_modules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_classes_modules.
  """
  def down do
    Logger.info("Removendo tabela de bx_classes_modules...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_classes_modules
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_modules removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_classes_modules: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_classes_modules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
