defmodule DeeperHub.Core.Data.Migrations.BxAttendantEvents do
  @moduledoc """
  Migration para criar e remover a tabela bx_attendant_events.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_attendant_events.
  """
  def up do
    Logger.info("Criando tabela de bx_attendant_events...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_attendant_events (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    method TEXT NOT NULL,
    event TEXT NOT NULL,
    added INTEGER NULL,
    processed INTEGER NULL,
    "action" TEXT NOT NULL,
    object_id INTEGER NULL,
    profile_id INTEGER NULL,
    module TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_attendant_events criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_attendant_events: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_attendant_events: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_attendant_events.
  """
  def down do
    Logger.info("Removendo tabela de bx_attendant_events...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_attendant_events
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_attendant_events removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_attendant_events: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_attendant_events: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
