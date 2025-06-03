defmodule DeeperHub.Core.Data.Migrations.SysSessions do
  @moduledoc """
  Migration para criar e remover a tabela sys_sessions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_sessions.
  """
  def up do
    Logger.info("Criando tabela de sys_sessions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL DEFAULT 0,
    data TEXT NULL,
    date INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_sessions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_sessions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_sessions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_sessions.
  """
  def down do
    Logger.info("Removendo tabela de sys_sessions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_sessions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_sessions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_sessions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_sessions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
