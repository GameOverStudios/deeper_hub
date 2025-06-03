defmodule DeeperHub.Core.Data.Migrations.SysOptionsTypes do
  @moduledoc """
  Migration para criar e remover a tabela sys_options_types.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_options_types.
  """
  def up do
    Logger.info("Criando tabela de sys_options_types...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_options_types (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "group" TEXT NOT NULL,
    name TEXT NOT NULL,
    caption TEXT NOT NULL,
    icon TEXT NOT NULL,
    "order" INTEGER NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_types criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_options_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_options_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_options_types.
  """
  def down do
    Logger.info("Removendo tabela de sys_options_types...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_options_types
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_types removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_options_types: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_options_types: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
