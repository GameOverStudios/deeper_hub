defmodule DeeperHub.Core.Data.Migrations.SysGridFields do
  @moduledoc """
  Migration para criar e remover a tabela sys_grid_fields.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_grid_fields.
  """
  def up do
    Logger.info("Criando tabela de sys_grid_fields...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_grid_fields (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    width TEXT NOT NULL,
    translatable INTEGER NOT NULL DEFAULT 0,
    chars_limit INTEGER NOT NULL DEFAULT 0,
    params TEXT NOT NULL,
    hidden_on TEXT NOT NULL,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_grid_fields criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_grid_fields: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_grid_fields: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_grid_fields.
  """
  def down do
    Logger.info("Removendo tabela de sys_grid_fields...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_grid_fields
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_grid_fields removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_grid_fields: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_grid_fields: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
