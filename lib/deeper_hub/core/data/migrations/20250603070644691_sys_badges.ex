defmodule DeeperHub.Core.Data.Migrations.SysBadges do
  @moduledoc """
  Migration para criar e remover a tabela sys_badges.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_badges.
  """
  def up do
    Logger.info("Criando tabela de sys_badges...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_badges (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    added INTEGER NOT NULL,
    module TEXT NOT NULL,
    text TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT '''',
    color TEXT NOT NULL,
    fontcolor TEXT NOT NULL,
    is_icon_only INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_badges criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_badges: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_badges: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_badges.
  """
  def down do
    Logger.info("Removendo tabela de sys_badges...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_badges
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_badges removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_badges: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_badges: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
