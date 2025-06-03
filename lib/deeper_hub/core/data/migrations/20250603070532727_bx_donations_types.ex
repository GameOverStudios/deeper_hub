defmodule DeeperHub.Core.Data.Migrations.BxDonationsTypes do
  @moduledoc """
  Migration para criar e remover a tabela bx_donations_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_donations_types.
  """
  def up do
    Logger.info("Criando tabela de bx_donations_types...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_donations_types (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    period INTEGER NOT NULL DEFAULT 0,
    period_unit TEXT NOT NULL,
    amount REAL NOT NULL DEFAULT 0,
    custom INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_donations_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_donations_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_donations_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_donations_types.
  """
  def down do
    Logger.info("Removendo tabela de bx_donations_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_donations_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_donations_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_donations_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_donations_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
