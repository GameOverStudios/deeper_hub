defmodule DeeperHub.Core.Data.Migrations.BxWorkspacesData do
  @moduledoc """
  Migration para criar e remover a tabela bx_workspaces_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_workspaces_data.
  """
  def up do
    Logger.info("Criando tabela de bx_workspaces_data...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_workspaces_data (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    views INTEGER NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    votes INTEGER NOT NULL DEFAULT 0,
    rrate REAL NOT NULL DEFAULT 0,
    rvotes INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    sc_up INTEGER NOT NULL DEFAULT 0,
    sc_down INTEGER NOT NULL DEFAULT 0,
    favorites INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL DEFAULT 0,
    reports INTEGER NOT NULL DEFAULT 0,
    featured INTEGER NOT NULL DEFAULT 0,
    allow_view_to TEXT NOT NULL DEFAULT 3,
    allow_post_to TEXT NOT NULL DEFAULT 5,
    allow_contact_to TEXT NOT NULL DEFAULT 3,
    settings TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_workspaces_data criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_workspaces_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_workspaces_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_workspaces_data.
  """
  def down do
    Logger.info("Removendo tabela de bx_workspaces_data...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_workspaces_data
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_workspaces_data removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_workspaces_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_workspaces_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
