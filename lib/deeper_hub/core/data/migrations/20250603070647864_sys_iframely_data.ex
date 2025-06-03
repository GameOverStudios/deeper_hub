defmodule DeeperHub.Core.Data.Migrations.SysIframelyData do
  @moduledoc """
  Migration para criar e remover a tabela sys_iframely_data.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_iframely_data.
  """
  def up do
    Logger.info("Criando tabela de sys_iframely_data...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_iframely_data (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    url TEXT NULL,
    data TEXT NULL,
    added INTEGER NULL,
    theme TEXT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_iframely_data criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_iframely_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_iframely_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_iframely_data.
  """
  def down do
    Logger.info("Removendo tabela de sys_iframely_data...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_iframely_data
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_iframely_data removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_iframely_data: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_iframely_data: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
