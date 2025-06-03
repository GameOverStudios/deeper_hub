defmodule DeeperHub.Core.Data.Migrations.BxCnlData do
  @moduledoc """
  Migration para criar e remover a tabela bx_cnl_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_cnl_data.
  """
  def up do
    Logger.info("Criando tabela de bx_cnl_data...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_cnl_data (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    picture INTEGER NOT NULL,
    cover INTEGER NOT NULL,
    cover_data TEXT NOT NULL,
    channel_name TEXT NOT NULL,
    lc_id INTEGER NOT NULL DEFAULT 0,
    lc_date INTEGER NOT NULL DEFAULT 0,
    contents INTEGER NOT NULL DEFAULT 0,
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
    cf INTEGER NOT NULL DEFAULT 1,
    allow_view_to TEXT NULL DEFAULT 3,
    status TEXT NOT NULL DEFAULT 'active',
    status_admin TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_cnl_data criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_cnl_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_cnl_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_cnl_data.
  """
  def down do
    Logger.info("Removendo tabela de bx_cnl_data...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_cnl_data
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_cnl_data removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_cnl_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_cnl_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
