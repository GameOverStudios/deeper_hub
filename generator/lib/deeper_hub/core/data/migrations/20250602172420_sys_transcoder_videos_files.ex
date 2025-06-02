defmodule DeeperHub.Core.Data.Migrations.SysTranscoderVideosFiles do
  @moduledoc """
  Migration para criar e remover a tabela sys_transcoder_videos_files.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_transcoder_videos_files.
  """
  def up do
    Logger.info("Criando tabela de sys_transcoder_videos_files...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_transcoder_videos_files (
id int(11) NOT NULL  auto_increment,
transcoder_object varchar(64) NOT NULL,
file_id int(11) NOT NULL,
handler varchar(255) NOT NULL,
atime int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_videos_files criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_transcoder_videos_files: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_transcoder_videos_files.
  """
  def down do
    Logger.info("Removendo tabela de sys_transcoder_videos_files...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_transcoder_videos_files
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_videos_files removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_transcoder_videos_files: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
