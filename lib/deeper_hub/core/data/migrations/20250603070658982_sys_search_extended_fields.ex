defmodule DeeperHub.Core.Data.Migrations.SysSearchExtendedFields do
  @moduledoc """
  Migration para criar e remover a tabela sys_search_extended_fields.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_search_extended_fields.
  """
  def up do
    Logger.info("Criando tabela de sys_search_extended_fields...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_search_extended_fields (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    name TEXT NOT NULL,
    "type" TEXT NOT NULL,
    caption TEXT NOT NULL,
    info TEXT NOT NULL,
    "values" TEXT NOT NULL DEFAULT '''',
    pass TEXT NOT NULL,
    search_type TEXT NOT NULL,
    search_value TEXT NOT NULL,
    search_operator TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_search_extended_fields criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_search_extended_fields: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_search_extended_fields: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_search_extended_fields.
  """
  def down do
    Logger.info("Removendo tabela de sys_search_extended_fields...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_search_extended_fields
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_search_extended_fields removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_search_extended_fields: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_search_extended_fields: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
