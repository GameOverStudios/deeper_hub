defmodule DeeperHub.Core.Data.Migrations.BxHelpToursItems do
  @moduledoc """
  Migration para criar e remover a tabela bx_help_tours_items.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_help_tours_items.
  """
  def up do
    Logger.info("Criando tabela de bx_help_tours_items...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_help_tours_items (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    tour INTEGER NOT NULL,
    name TEXT NOT NULL,
    element TEXT NOT NULL,
    arrow TEXT NULL,
    title TEXT NOT NULL,
    text TEXT NOT NULL,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_help_tours_items criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_help_tours_items: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_help_tours_items: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_help_tours_items.
  """
  def down do
    Logger.info("Removendo tabela de bx_help_tours_items...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_help_tours_items
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_help_tours_items removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_help_tours_items: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_help_tours_items: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
