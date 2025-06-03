defmodule DeeperHub.Core.Data.Migrations.SysTranscoderAudioFiles do
  @moduledoc """
  Migration para criar e remover a tabela sys_transcoder_audio_files.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_transcoder_audio_files.
  """
  def up do
    Logger.info("Criando tabela de sys_transcoder_audio_files...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_transcoder_audio_files (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    transcoder_object TEXT NOT NULL,
    file_id INTEGER NOT NULL,
    handler TEXT NOT NULL,
    atime INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_audio_files criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_transcoder_audio_files: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_transcoder_audio_files: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_transcoder_audio_files.
  """
  def down do
    Logger.info("Removendo tabela de sys_transcoder_audio_files...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_transcoder_audio_files
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_audio_files removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_transcoder_audio_files: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_transcoder_audio_files: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
