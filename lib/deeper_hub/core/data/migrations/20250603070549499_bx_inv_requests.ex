defmodule DeeperHub.Core.Data.Migrations.BxInvRequests do
  @moduledoc """
  Migration para criar e remover a tabela bx_inv_requests.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_inv_requests.
  """
  def up do
    Logger.info("Criando tabela de bx_inv_requests...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_inv_requests (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    text TEXT NOT NULL,
    nip INTEGER NOT NULL DEFAULT 0,
    date INTEGER NOT NULL DEFAULT 0,
    status INTEGER NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_inv_requests criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_inv_requests: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_inv_requests: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_inv_requests.
  """
  def down do
    Logger.info("Removendo tabela de bx_inv_requests...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_inv_requests
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_inv_requests removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_inv_requests: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_inv_requests: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
