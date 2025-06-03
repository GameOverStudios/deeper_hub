defmodule DeeperHub.Core.Data.Migrations.SysOptionsMixes2options do
  @moduledoc """
  Migration para criar e remover a tabela sys_options_mixes2options.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_options_mixes2options.
  """
  def up do
    Logger.info("Criando tabela de sys_options_mixes2options...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_options_mixes2options (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    option TEXT NOT NULL,
    mix_id INTEGER NOT NULL DEFAULT 0,
    value TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_mixes2options criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_options_mixes2options: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_options_mixes2options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_options_mixes2options.
  """
  def down do
    Logger.info("Removendo tabela de sys_options_mixes2options...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_options_mixes2options
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_options_mixes2options removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_options_mixes2options: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_options_mixes2options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
