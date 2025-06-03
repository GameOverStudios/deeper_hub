defmodule DeeperHub.Core.Data.Migrations.BxInvInvites do
  @moduledoc """
  Migration para criar e remover a tabela bx_inv_invites.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_inv_invites.
  """
  def up do
    Logger.info("Criando tabela de bx_inv_invites...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_inv_invites (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL,
    profile_id INTEGER NOT NULL,
    "key" TEXT NOT NULL,
    redirect TEXT NOT NULL,
    email TEXT NOT NULL,
    date INTEGER NOT NULL DEFAULT 0,
    date_seen INTEGER NULL,
    date_joined INTEGER NULL,
    joined_account_id INTEGER NULL,
    request_id INTEGER NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_inv_invites criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_inv_invites: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_inv_invites: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_inv_invites.
  """
  def down do
    Logger.info("Removendo tabela de bx_inv_invites...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_inv_invites
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_inv_invites removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_inv_invites: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_inv_invites: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
