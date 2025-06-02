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
id int(11) NOT NULL  auto_increment,
transcoder_object varchar(64) NOT NULL,
profile_id int(10) unsigned NOT NULL,
file_url_source varchar(255) NOT NULL,
file_id_source varchar(255) NOT NULL,
file_url_result varchar(255) NOT NULL,
file_ext_result varchar(255) NOT NULL,
file_id_result int(11) NOT NULL,
server varchar(255) NOT NULL,
status enum('pending','processing','complete','failed','delete') NOT NULL,
pid int(10) unsigned NOT NULL DEFAULT 0,
added int(11) NOT NULL,
changed int(11) NOT NULL,
log text NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_queue criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_transcoder_queue: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_transcoder_queue: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
