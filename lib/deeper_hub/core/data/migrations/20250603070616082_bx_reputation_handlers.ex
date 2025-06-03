defmodule DeeperHub.Core.Data.Migrations.BxReputationHandlers do
  @moduledoc """
  Migration para criar e remover a tabela bx_reputation_handlers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reputation_handlers.
  """
  def up do
    Logger.info("Criando tabela de bx_reputation_handlers...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_reputation_handlers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "group" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'insert',
    alert_unit TEXT NOT NULL,
    alert_action TEXT NOT NULL,
    points_active INTEGER NOT NULL DEFAULT 0,
    points_passive INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_handlers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_reputation_handlers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reputation_handlers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reputation_handlers.
  """
  def down do
    Logger.info("Removendo tabela de bx_reputation_handlers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reputation_handlers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_handlers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_reputation_handlers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reputation_handlers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
