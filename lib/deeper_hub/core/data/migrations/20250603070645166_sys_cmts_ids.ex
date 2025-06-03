defmodule DeeperHub.Core.Data.Migrations.SysCmtsIds do
  @moduledoc """
  Migration para criar e remover a tabela sys_cmts_ids.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_cmts_ids.
  """
  def up do
    Logger.info("Criando tabela de sys_cmts_ids...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_cmts_ids (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    system_id INTEGER NOT NULL DEFAULT 0,
    cmt_id INTEGER NOT NULL DEFAULT 0,
    author_id INTEGER NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    votes INTEGER NOT NULL DEFAULT 0,
    rrate REAL NOT NULL DEFAULT 0,
    rvotes INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    sc_up INTEGER NOT NULL DEFAULT 0,
    sc_down INTEGER NOT NULL DEFAULT 0,
    reports INTEGER NOT NULL DEFAULT 0,
    status_admin TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_ids criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_cmts_ids: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_cmts_ids: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_cmts_ids.
  """
  def down do
    Logger.info("Removendo tabela de sys_cmts_ids...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_cmts_ids
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_ids removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_cmts_ids: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_cmts_ids: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
