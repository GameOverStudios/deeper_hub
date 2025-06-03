defmodule DeeperHub.Core.Data.Migrations.BxCreditsHistory do
  @moduledoc """
  Migration para criar e remover a tabela bx_credits_history.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_credits_history.
  """
  def up do
    Logger.info("Criando tabela de bx_credits_history...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_credits_history (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    first_pid INTEGER NOT NULL DEFAULT 0,
    second_pid INTEGER NOT NULL DEFAULT 0,
    amount REAL NOT NULL DEFAULT 0,
    "type" TEXT NOT NULL,
    direction TEXT NOT NULL DEFAULT 'in',
    "order" TEXT NOT NULL,
    data TEXT NOT NULL DEFAULT '''',
    info TEXT NOT NULL,
    date INTEGER NOT NULL DEFAULT 0,
    cleared INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_history criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_credits_history: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_credits_history: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_credits_history.
  """
  def down do
    Logger.info("Removendo tabela de bx_credits_history...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_credits_history
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_history removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_credits_history: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_credits_history: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
