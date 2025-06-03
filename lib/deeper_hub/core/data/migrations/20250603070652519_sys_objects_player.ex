defmodule DeeperHub.Core.Data.Migrations.SysObjectsPlayer do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_player.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_player.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_player...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_player (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    title TEXT NOT NULL,
    skin TEXT NOT NULL,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_player criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_player: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_player: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_player.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_player...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_player
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_player removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_player: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_player: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
