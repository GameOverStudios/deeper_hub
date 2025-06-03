defmodule DeeperHub.Core.Data.Migrations.SysPreloader do
  @moduledoc """
  Migration para criar e remover a tabela sys_preloader.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_preloader.
  """
  def up do
    Logger.info("Criando tabela de sys_preloader...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_preloader (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    module TEXT NOT NULL,
    "type" TEXT NOT NULL,
    content TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_preloader criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_preloader: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_preloader: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_preloader.
  """
  def down do
    Logger.info("Removendo tabela de sys_preloader...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_preloader
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_preloader removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_preloader: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_preloader: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
