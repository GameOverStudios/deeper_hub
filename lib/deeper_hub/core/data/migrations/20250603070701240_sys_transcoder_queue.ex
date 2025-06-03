defmodule DeeperHub.Core.Data.Migrations.SysTranscoderQueue do
  @moduledoc """
  Migration para criar e remover a tabela sys_transcoder_queue.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_transcoder_queue.
  """
  def up do
    Logger.info("Criando tabela de sys_transcoder_queue...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_transcoder_queue (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    transcoder_object TEXT NOT NULL,
    profile_id INTEGER NOT NULL,
    file_url_source TEXT NOT NULL,
    file_id_source TEXT NOT NULL,
    file_url_result TEXT NOT NULL,
    file_ext_result TEXT NOT NULL,
    file_id_result INTEGER NOT NULL,
    server TEXT NOT NULL,
    status TEXT NOT NULL,
    pid INTEGER NOT NULL DEFAULT 0,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    log TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_queue criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_transcoder_queue: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_transcoder_queue: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_transcoder_queue.
  """
  def down do
    Logger.info("Removendo tabela de sys_transcoder_queue...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_transcoder_queue
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_queue removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_transcoder_queue: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_transcoder_queue: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
