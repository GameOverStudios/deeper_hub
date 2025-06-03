defmodule DeeperHub.Core.Data.Migrations.SysCmtsImages2entries do
  @moduledoc """
  Migration para criar e remover a tabela sys_cmts_images2entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_cmts_images2entries.
  """
  def up do
    Logger.info("Criando tabela de sys_cmts_images2entries...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_cmts_images2entries (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    system_id INTEGER NOT NULL DEFAULT 0,
    cmt_id INTEGER NOT NULL DEFAULT 0,
    image_id INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_images2entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_cmts_images2entries: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_cmts_images2entries: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_cmts_images2entries.
  """
  def down do
    Logger.info("Removendo tabela de sys_cmts_images2entries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_cmts_images2entries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_images2entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_cmts_images2entries: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_cmts_images2entries: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
