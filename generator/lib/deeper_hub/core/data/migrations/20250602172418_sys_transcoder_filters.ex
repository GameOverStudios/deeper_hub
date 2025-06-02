defmodule DeeperHub.Core.Data.Migrations.SysTranscoderFilters do
  @moduledoc """
  Migration para criar e remover a tabela sys_transcoder_filters.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_transcoder_filters.
  """
  def up do
    Logger.info("Criando tabela de sys_transcoder_filters...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_transcoder_filters (
id int(11) NOT NULL  auto_increment,
transcoder_object varchar(64) NOT NULL,
filter varchar(32) NOT NULL,
filter_params text NOT NULL,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_filters criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_transcoder_filters: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_transcoder_filters.
  """
  def down do
    Logger.info("Removendo tabela de sys_transcoder_filters...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_transcoder_filters
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_filters removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_transcoder_filters: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
