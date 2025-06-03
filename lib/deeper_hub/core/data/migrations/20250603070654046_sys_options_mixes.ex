defmodule DeeperHub.Core.Data.Migrations.SysOptionsMixes do
  @moduledoc """
  Migration para criar e remover a tabela sys_options_mixes.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_options_mixes.
  """
  def up do
    Logger.info("Criando tabela de sys_options_mixes...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_options_mixes (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "type" TEXT NOT NULL,
    category TEXT NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    dark INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 0,
    published INTEGER NOT NULL DEFAULT 0,
    editable INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_mixes criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_options_mixes: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_options_mixes: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_options_mixes.
  """
  def down do
    Logger.info("Removendo tabela de sys_options_mixes...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_options_mixes
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_mixes removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_options_mixes: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_options_mixes: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
