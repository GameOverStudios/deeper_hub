defmodule DeeperHub.Core.Data.Migrations.BxCreditsWithdrawals do
  @moduledoc """
  Migration para criar e remover a tabela bx_credits_withdrawals.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_credits_withdrawals.
  """
  def up do
    Logger.info("Criando tabela de bx_credits_withdrawals...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_credits_withdrawals (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    performer_id INTEGER NOT NULL DEFAULT 0,
    profile_id INTEGER NOT NULL DEFAULT 0,
    amount REAL NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    message TEXT NOT NULL DEFAULT '''',
    "order" TEXT NOT NULL,
    added INTEGER NOT NULL DEFAULT 0,
    confirmed INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'requested'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_withdrawals criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_credits_withdrawals: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_credits_withdrawals: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_credits_withdrawals.
  """
  def down do
    Logger.info("Removendo tabela de bx_credits_withdrawals...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_credits_withdrawals
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_withdrawals removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_credits_withdrawals: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_credits_withdrawals: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
