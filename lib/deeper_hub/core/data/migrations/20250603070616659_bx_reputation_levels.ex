defmodule DeeperHub.Core.Data.Migrations.BxReputationLevels do
  @moduledoc """
  Migration para criar e remover a tabela bx_reputation_levels.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reputation_levels.
  """
  def up do
    Logger.info("Criando tabela de bx_reputation_levels...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_reputation_levels (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    icon TEXT NOT NULL,
    points_in INTEGER NOT NULL DEFAULT 0,
    points_out INTEGER NOT NULL DEFAULT 0,
    date INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_levels criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_reputation_levels: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reputation_levels: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reputation_levels.
  """
  def down do
    Logger.info("Removendo tabela de bx_reputation_levels...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reputation_levels
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_levels removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_reputation_levels: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reputation_levels: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
